# This program is free software: you can redistribute it and/or modify it under the terms of the GNU General Public License
# as published by the Free Software Foundation, either version 3 of the License, or (at your option) any later version.
#
# This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied
# warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License along with this program.  If not, see
# <http://www.gnu.org/licenses/>.
#
# This script is part of the knxLogger project, which logs all KNX bus traffic to an InfluxDb for reporting via Grafana
# https://github.com/greiginsydney/knxLogger
# https://greiginsydney.com/knx-logger


import asyncio
import csv                          # Reading the topology export
import json                         # For sending to telegraf
import knxdclient
import logging
import math                         # Sending the 'floor' (main DPT) value to knclient
import os                           # Path manipulation
import re                           # Used to decode the topology + escape text fields sent to telegraf
import requests                     # To push the values to telegraf
from xml.dom.minidom import parse   # Decoding the ETS XML file


# ////////////////////////////////
# /////////// STATICS ////////////
# ////////////////////////////////

sudo_username = os.getenv("SUDO_USER")
if sudo_username:
    PI_USER_HOME = os.path.expanduser('~' + sudo_username + '/')
else:
    PI_USER_HOME = os.path.expanduser('~')
KNXLOGGER_DIR    = os.path.join(PI_USER_HOME, 'knxLogger')
LOGFILE_NAME     = os.path.join(KNXLOGGER_DIR, 'knxLogger.log')
ETS_TOPO_FILE    = os.path.join(KNXLOGGER_DIR, 'TopoExport.csv')
ETS_GA_FILE      = os.path.join(KNXLOGGER_DIR, 'GroupExport.xml')

HOST               = "localhost"
PORT               = 8080
PATH               = "/knxd"
URL_STR            = "http://{}:{}{}".format(HOST, PORT, PATH)
HEADERS            = {'Content-type': 'application/json', 'Accept': 'text/plain'}

logging.basicConfig(filename=LOGFILE_NAME, filemode='a', format='{asctime} {message}', style='{', datefmt='%Y/%m/%d %H:%M:%S', level=logging.DEBUG)

def log(message):
    try:
        logging.info(message)
    except Exception as e:
        #print(f'error: {e}')
        pass


# Decode this Topology data (NB: this is an edited extract):
#
# ,,Installation Notes,,,,,,,,,,,,,,,,,,,,
# ,,1.1,,,TP,,TP line,,,,,,,,,,,,,,,
# ,,1.1.-,,,MEAN WELL Enterprises Co. Ltd.,,,,,KNX-20E-640,,KNX-20E-640 Power Supply (230V/640mA),,,,,,,,, ,
# ,,1.1.0,,,Weinzierl Engineering GmbH,,,,,KNX IP Router 752 secure,,KNX IP Router 752 secure,,,,,,,KNX IP Router 752 secure,,Accepted,
# ,,,1.1.1 KNXnet/IP tunneling interface,,,,,,,,,,,,,,,,,,,
# ,,,1.1.2 KNXnet/IP tunneling interface,,,,,,,,,,,,,,,,,,,
# ,,1.1.12,,,ABB,,,,,2CDG 110 273 R0011,,"DG/S1.64.5.1 DALI Gateway,Premium,1f,MDRC",,,,,,,DALI Premium 1f/1.4,, ,
# ,,1.1.130,,,Hager Electro,,,,,TXB322,,2-fold input / 2-fold output Status indication,,,,,,,SXB322,, ,

def decode_ETS_Topology_Export(filename):
    # Parse XML from a file object
    if not os.path.isfile(filename):
        log(f"decode_ETS_Topology_Export: file '{filename}' not found. Aborting")
        print(f"decode_ETS_Topology_Export: file '{filename}' not found. Aborting")
        return
    data = {}
    try:
        with open(filename, 'rt', encoding="utf-8") as f:
            reader = csv.reader(f, delimiter=',', quotechar='"')
            for line in reader:
                # The device ID will be in one of these two columns:
                deviceAddress = None
                description = None
                room = None
                matched = re.match("([0-9]\.[0-9]{1,2}\.[0-9]{1,3})", line[2])
                if matched:
                    deviceAddress = matched.group(1)
                if deviceAddress == None: continue
                room = line[12]
                if not room:
                    # TODO: can I find the room elsewhere?
                    pass
                # We matched on a device. Pull its description - column M, split index 12.
                description = line[3]
                if not description:
                    # TODO: can I find the description elsewhere?
                    pass

                if deviceAddress not in data:
                    data[deviceAddress] = (room, description)

    except Exception as e:
        print(f"decode_ETS_Topology_Export: Exception thrown trying to read file '{filename}'. {e}")
        log(f"decode_ETS_Topology_Export: Exception thrown trying to read file '{filename}'. {e}")

    return data



# Decode this Group Address data:
#
# <GroupAddress Name="Bedroom LX SW FB" Address="0/0/2" DPTs="DPST-1-1" />
# <GroupAddress Name="Bedroom LX rel DIM" Address="0/0/3" DPTs="DPST-3-7" />
# <GroupAddress Name="Bedroom LX DIM value %" Address="0/0/4" DPTs="DPST-5-1" />

def decode_ETS_GA_Export(filename):
    # Parse XML from a file object
    if not os.path.isfile(filename):
        log(f"decode_ETS_GA_Export: file '{filename}' not found. Aborting")
        print(f"decode_ETS_GA_Export: file '{filename}' not found. Aborting")
        return
    try:
        with open(filename) as file:
            document = parse(file)
        GAs = document.getElementsByTagName('GroupAddress')
    except Exception as e:
        log(f"decode_ETS_GA_Export: Exception thrown trying to read file '{filename}'. {e}")

    data = {}

    for GA in GAs:
        # discard those with any empty values. (Mostly likely only the DPT type for an unused GA)
        if not GA.hasAttribute('Name'):
            log(f'decode_ETS_GA_Export: Group Address {GA} has no Name and was discarded')
            continue
        if not GA.hasAttribute('Address'):
            log(f'decode_ETS_GA_Export: Group Address {GA} has no Address and was discarded')
            continue
        if not GA.hasAttribute('DPTs'):
            log(f'decode_ETS_GA_Export: Group Address {GA} has no DPT and was discarded')
            continue
        name = GA.getAttribute('Name') # TODO: will this fall over if there's a quotation mark in the name?
        address = (GA.getAttribute('Address')).split('/')

        #Turn the DPT back into a float: "DPST-5-1" becomes 5.001
        DPT_split = GA.getAttribute('DPTs').split('-')
        if len(DPT_split) == 2:
            # Rare, possibly junk value, maybe an old GA no longer used. e.g. "DPST-1" Format to 1.000
            # Valid occurrences are seen in ETS as (e.g.) DPT "9.*", a 2-bytpe float not fully defined.
            sub_dpt = float("{:.3f}".format(0))
        elif len(DPT_split) == 3:
            sub_dpt = float((DPT_split)[2]) / 1000
        else:
            # A broken DPT? Discard the whole GA
            log(f"decode_ETS_GA_Export: Failed to decode sub-type from '{DPT_split}' for Group Address {GA}. The GA has been discarded")
            continue
        DPT = int(DPT_split[1]) + sub_dpt
        if not isinstance(DPT, float):
            # It *should* be a float by now. If not, discard it
            log(f"decode_ETS_GA_Export: DPT '{DPT}' for Group Address {GA} is not a float. The GA has been discarded")
            continue
        data[knxdclient.GroupAddress(int(address[0]), int(address[1]), int(address[2]))] = (DPT, name)

    return data


Topo_Data = decode_ETS_Topology_Export(ETS_TOPO_FILE)

GA_Data   = decode_ETS_GA_Export(ETS_GA_FILE)


async def main() -> None:
    connection = knxdclient.KNXDConnection()
    await connection.connect()
    try:
        # Start run task and open group socket
        run_task = asyncio.create_task(connection.run())
        await connection.open_group_socket()

        # Iterate asynchronously over incoming group telegrams
        packet: knxdclient.ReceivedGroupAPDU
        async for packet in connection.iterate_group_telegrams():
            if packet.payload.type in (knxdclient.KNXDAPDUType.WRITE, knxdclient.KNXDAPDUType.RESPONSE):
                # Decode and log incoming group WRITE and RESPONSE telegrams

                # Decode the SOURCE (from the Topology):
                source_name = None
                room = None
                try:
                    room, source_name = Topo_Data[str(packet.src)]
                except Exception as e:
                    # We failed to ID the source. Not fatal, it will be sent as 'Unknown'
                    source_name = None
                    print(f'main: Exception decoding a telegram from packet.src {packet.src} - {e}')

                # Decode the DESTINATION (a Group Address):
                try:
                    DPT, GA_name = GA_Data[packet.dst]
                    DPT_main = math.floor(DPT)
                except Exception as e:
                    # We failed to match on the destination
                    # Discard this telegram as we don't know how to decode the data
                    print(f'main: Exception decoding a telegram to packet.dst {packet.dst}. The telegram has been discarded')
                    continue

                try:
                    value = knxdclient.decode_value(packet.payload.value, knxdclient.KNXDPT(DPT_main))
                except Exception as e:
                    # We failed to decode the payload
                    # Discard this telegram as we don't know how to decode the data
                    print(f'main: Exception decoding the payload of a telegram to packet.dst {packet.dst}. The telegram has been discarded')
                    continue
                # print(f'Telegram from {packet.src} to GAD {packet.dst}: {value}') # Raw data, retained here for debugging

                telegram = {}
                telegram['source_address'] = ".".join(map(str,packet.src))
                telegram['source_room'] = room if (room) else 'Unknown'
                telegram['source_name'] = re.escape(source_name) if (source_name) else 'Unknown' # It's invalid to send an empty tag to Influx, hence 'Unknown' if required
                telegram['destination'] = "/".join(map(str,packet.dst))
                telegram['destination_name'] = re.escape(GA_name) if (GA_name) else 'Unknown' # It's invalid to send an empty tag to Influx, hence 'Unknown' if required
                telegram['dpt'] = DPT # We send DPT_main to the knxdclient but the full numerical DPT to Influx
                #telegram['value'] = 'discardme'
                #Ugh! The value could be one of MANY types:
                # TODO: is this where we define EVERY sub-type??
                if isinstance(value, str):
                    telegram[str(DPT)] = "'" + value + "'"
                elif isinstance(value, (float, int, bool)):
                    telegram[str(DPT)] = value
                elif isinstance(value, tuple):
                    print('-- TUPLE COMING THROUGH ')
                    telegram[str(DPT)] = "-".join(map(str,value))
                else:
                    print(f'Unhandled object type. Value is {type(value)}')
                message = {"telegram" : telegram}

                # Post it to telegraf:
                try:
                    response = requests.post(url=URL_STR, json=message)
                    status_code = response.status_code
                    reason = response.reason
                    if response.ok:
                        print(f'Telegram from {packet.src} ({source_name}) to GAD {packet.dst} ({GA_name}): {value}.')
                    else:
                        print(f'Telegram from {packet.src} ({source_name}) to GAD {packet.dst} ({GA_name}): {value} - failed with {status_code}, {reason}.')
                except Exception as e:
                    print(f'Exception POSTing: {e}')

    except Exception as e:
        print(f'Exception in main: {e}\nDestination was {packet.dst}')

    finally:
        # Let's stop the connection and wait for graceful termination of the receive loop:
        await connection.stop()
        await run_task


asyncio.run(main())


# References:
# Pushing json to telegraf: https://stackoverflow.com/questions/68682076/send-python-output-json-output-to-telegraf-over-http-listener-v2
