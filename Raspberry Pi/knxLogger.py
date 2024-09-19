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
import glob                         # Finding the most recent (youngest) topo file
import json                         # For sending to telegraf
import knxdclient
import logging
import math                         # Sending the 'floor' (main DPT) value to knclient
import os                           # Path manipulation
import re                           # Used to decode the topology + escape text fields sent to telegraf
import requests                     # To push the values to telegraf
from xml.dom.minidom import parse   # Decoding the ETS XML file
import zipfile                      # Reading the topology file (it's just a ZIP file!)

from decode_dpt import DPT1         # Decodes certain DPT sub-types


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
ETS_XML_FILE     = os.path.join(KNXLOGGER_DIR, '0.xml')

GA_LEVELS        = 3 # Set as 2 or 3 depending on your implementation. (Read by decode_Group_Addresses)


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


def unzip_topo_archive():
    '''
    Walk through the user's root folder recursively in search of the most recent (youngest) topo file.
    If found, extract \P-00B8\0.xml and exit.
    If not found, just exit, as a previous 0.xml may already exist.
    '''
    try:
        topo_files = glob.glob(PI_USER_HOME + "/**/*.knxproj", recursive = True)
        if topo_files:
            topo_file = max(topo_files, key=os.path.getctime)
            with zipfile.ZipFile(topo_file) as z:
                with open(PI_USER_HOME +'/knxLogger/0.xml', 'wb') as f:
                    f.write(z.read('P-00B8/0.xml'))
        else:
            log(f'unzip_topo_archive: No topology file found')
    except Exception as e:
        log(f'unzip_topo_archive: Exception thrown trying to unzip archive: {e}')

    return


# Decode this Topology data (NB: this is an edited extract):
#
#  <Topology>
#    <Area Id="P-00B8-0_A-2" Address="1" Puid="4">
#      <Line Id="P-00B8-0_L-5" Address="1" Puid="596">
#        <Segment Id="P-00B8-0_S-5" Number="0" MediumTypeRefId="MT-0" Puid="597">
#          <DeviceInstance Id="P-00B8-0_DI-3" Address="20" Name="Garage - DIMMER - DM 4-2 T (4 x dimming actuator, 200 W)"

def decode_Individual_Addresses(filename):
    '''
    Decodes individual addresses from 0.xml. Aborts if file not found: its existence at this stage ISN'T mandatory
    TODO: Loop through again and extract the Location information
    Returns a dictionary where the key is the individual address, and the value is a tuple of location and name
    '''
    data = {}
    location = {}
    # Parse XML from a file object
    if not os.path.isfile(filename):
        log(f"decode_Addresses: file '{filename}' not found. Aborting")
        print(f"decode_Addresses: file '{filename}' not found. Aborting")
        return
    try:
        with open(filename) as file:
            document = parse(file)
    except Exception as e:
        log(f"decode_ETS_GA_Export: Exception thrown trying to read file '{filename}'. {e}")

    try:
        locations = document.getElementsByTagName('Locations')
        for node in locations:
            for buildings in node.getElementsByTagName('Space'):
                for floors in buildings.getElementsByTagName('Space'):
                    for rooms in floors.getElementsByTagName('Space'):
                        for DeviceInstances in rooms.getElementsByTagName('DeviceInstanceRef'):
                            building = (buildings.getAttribute('Name')).strip()
                            floor    = (floors.getAttribute('Name')).strip()
                            room    = (rooms.getAttribute('Name')).strip()
                            RefId   = (DeviceInstances.getAttribute('RefId')).strip()
                            if RefId:
                                if RefId not in location:
                                    location[RefId] = (building, floor, room)
        
    except Exception as e:
        print(f"decode_Individual_Addresses: Exception thrown at line {e.__traceback__.tb_lineno} trying to read rooms from '{filename}'. {e}")
        log(f"decode_Individual_Addresses: Exception thrown at line {e.__traceback__.tb_lineno} trying to read rooms from '{filename}'. {e}")

    try:
        topo = document.getElementsByTagName('Topology')
        for node in topo:
            for areas in node.getElementsByTagName('Area'):
                for lines in areas.getElementsByTagName('Line'):
                    for segments in lines.getElementsByTagName('Segment'):
                        for DeviceInstances in segments.getElementsByTagName('DeviceInstance'):
                            area     = (areas.getAttribute('Address')).strip()
                            line     = (lines.getAttribute('Address')).strip()
                            device   = (DeviceInstances.getAttribute('Address')).strip()
                            name     = (DeviceInstances.getAttribute('Name')).strip()
                            deviceId = (DeviceInstances.getAttribute('Id')).strip()
                            try:
                                device_location = location[deviceId]
                            except:
                                device_location = ('', '', '')
                            if device:
                                deviceAddress = (f'{area}.{line}.{device}')
                                if deviceAddress not in data:
                                    data[deviceAddress] = (device_location, name)
                            # Routers and the X1 have 'additional addresses' as well:
                            for AdditionalAddresses in DeviceInstances.getElementsByTagName('AdditionalAddresses'):
                                for EachAddress in AdditionalAddresses.getElementsByTagName('Address'):
                                    device = (EachAddress.getAttribute('Address')).strip()
                                    name   = (EachAddress.getAttribute('Name')).strip()
                                    deviceAddress = (f'{area}.{line}.{device}')
                                    if deviceAddress not in data:
                                        data[deviceAddress] = (device_location, name)
    except Exception as e:
        print(f"decode_Individual_Addresses: Exception thrown trying to read file '{filename}'. {e}")
        log(f"decode_Individual_Addresses: Exception thrown trying to read file '{filename}'. {e}")

    return data


# Decode this Group Address data:
#
# <GroupAddresses>
#   <GroupRanges>
#     <GroupRange Id="P-00B8-0_GR-1" RangeStart="1" RangeEnd="2047" Name="MASTER BEDROOM" Puid="606">
#       <GroupRange Id="P-00B8-0_GR-21" RangeStart="1" RangeEnd="255" Name="Lighting" Puid="1024">
#         <GroupAddress Id="P-00B8-0_GA-623" Address="1" Name="Bedroom LX SW" DatapointType="DPST-1-1" Puid="1568" />

def decode_Group_Addresses(filename):
    '''
    Decodes group addresses from 0.xml. Aborts if file not found - a fatal error
    Handles either two- and three-level GA's, using a STATIC VAR declared above, set/changed by the setup script (TODO)
    Returns a dictionary where the key is the GA address, and the value is a tuple of datapoint type and name
    '''
    data = {}
    # Parse XML from a file object
    if not os.path.isfile(filename):
        log(f"decode_Group_Addresses: file '{filename}' not found. Aborting")
        print(f"decode_Group_Addresses: file '{filename}' not found. Aborting")
        return
    try:
        with open(filename) as file:
            document = parse(file)
    except Exception as e:
        log(f"decode_Group_Addresses: Exception thrown trying to read file '{filename}'. {e}")

    try:
        for GAs in document.getElementsByTagName('GroupAddresses'):
            for GroupRanges in GAs.getElementsByTagName('GroupRanges'):
                for GroupRange in GroupRanges.getElementsByTagName('GroupRange'):
                    for GroupRange2 in GroupRange.getElementsByTagName('GroupRange'):
                        for GroupAddress in GroupRange2.getElementsByTagName('GroupAddress'):
                            longAddress   = int((GroupAddress.getAttribute('Address')).strip())
                            name          = (GroupAddress.getAttribute('Name')).strip()
                            DptString     = (GroupAddress.getAttribute('DatapointType')).strip()

                            if longAddress and DptString:
                                # Both the address and DPT are crucial. Discard this GA if either is absent
                                # Bit decoding thanks to: https://knxer.net/?p=49
                                if GA_LEVELS == 3:
                                    main = longAddress >> 11
                                    middle = (longAddress >> 8) & 0x07
                                    sub = longAddress & 0b0000000011111111
                                    GA = (f'{main}/{middle}/{sub}')
                                else:
                                    main = longAddress >> 11
                                    sub = longAddress & 0b0000011111111111
                                    GA = (f'{main}/{sub}')

                                # Turn the DPT back into a *string* that resembles a float: "DPST-5-1" becomes 5.001
                                # (I couldn't get the trailing zeroes to work for all types as a float, so it's now a string)
                                
                                DPT_split = DptString.split('-')
                                if len(DPT_split) == 2:
                                    # Rare, possibly junk value, maybe an old GA no longer used. e.g. "DPST-1" Format to 1.000
                                    # Valid occurrences are seen in ETS as (e.g.) DPT "9.*", a 2-byte float not fully defined.
                                    sub_dpt = '000'
                                elif len(DPT_split) == 3:
                                    sub_dpt = DPT_split[2].zfill(3) #Right-justifies sub-dpt to three digits.
                                else:
                                    # A broken DPT? Discard the whole GA
                                    print(f"decode_Group_Addresses: Failed to decode sub-type from '{DptString}' for Group Address {GA}. The GA has been discarded")
                                    continue

                                DPT = DPT_split[1] + '.' + sub_dpt

                                if GA not in data:
                                    data[GA] = (DPT, name)

                            else:
                                log(f'decode_Group_Addresses discarded incomplete address=|{longAddress}|, name=|{name}|, DptString=|{DptString}|')

    except Exception as e:
        print(f"decode_Group_Addresses: Exception thrown at line {e.__traceback__.tb_lineno} trying to parse XML. {e}")
        log(f"decode_Group_Addresses: Exception thrown at line {e.__traceback__.tb_lineno} trying to parse XML. {e}")

    return data


unzip_topo_archive()

Individual_Data = decode_Individual_Addresses(ETS_XML_FILE)

GA_Data   = decode_Group_Addresses(ETS_XML_FILE)


async def main() -> None:
    '''
    Asynchronously receives telegrams, decodes the data, and POSTs it as JSON to telegraf for logging
    Some types of failures will cause the telegram to be discarded, all of which are captured in the logfile
    '''
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
                building = floor = room = source_name = ''
                try:
                    (building, floor, room), source_name = Individual_Data[str(packet.src)]
                except Exception as e:
                    # We failed to ID the source. Not fatal, it will be sent as 'Unknown'
                    source_name = ''
                    print(f'main: Exception decoding a telegram from packet.src {packet.src} - {e}')

                # Decode the DESTINATION (a Group Address):
                DPT = GA_name = ''
                try:
                    DPT, GA_name = GA_Data[str(packet.dst)]
                    DPT_main = int(DPT.split('.')[0])
                except Exception as e:
                    # We failed to match on the destination
                    # Discard this telegram as we don't know how to decode the data
                    print(f'main: Exception decoding a telegram to packet.dst {packet.dst}. The telegram has been discarded. {e}')
                    continue

                try:
                    value = knxdclient.decode_value(packet.payload.value, knxdclient.KNXDPT(DPT_main))
                except Exception as e:
                    # We failed to decode the payload
                    # Discard this telegram as we don't know how to decode the data
                    print(f'main: Exception decoding the payload of a telegram to packet.dst {packet.dst}. The telegram has been discarded. {e}')
                    continue
                # print(f'Telegram from {packet.src} to GAD {packet.dst}: {value}') # Raw data, retained here for debugging

                telegram = {}
                telegram['source_address']   = ".".join(map(str,packet.src))
                telegram['source_building']  = building if (building) else ("Unknown")
                telegram['source_floor']     = floor if (floor) else ("Unknown")
                telegram['source_room']      = room if (room) else ("Unknown")
                telegram['source_name']      = ('"' + source_name + '"') if (source_name) else ("Unknown") # It's invalid to send an empty tag to Influx, hence 'Unknown' if required
                telegram['destination']      = "/".join(map(str,packet.dst))
                telegram['destination_name'] = ('"' + GA_name + '"') if (GA_name) else ("Unknown") # It's invalid to send an empty tag to Influx, hence 'Unknown' if required
                telegram['dpt']              = float(DPT) # We only send DPT_main to the knxdclient but the full numerical DPT to Influx
                
                # TODO: is this where we define EVERY sub-type??
                if DPT_main == 1:
                    value_true, value_false = DPT1[sub_DPT]
                    value = value_true if (value) else value_false
                elif DPT_main in [3, 4, 5, 16]:
                    globals()['DPT' + str(DPT_main](sub_DPT, value)

                if isinstance(value, str):
                    telegram[str(DPT)] = '"' + value + '"'
                elif isinstance(value, float):
                    telegram[str(DPT)] = round(value, 2)
                elif isinstance(value, (int, bool)):
                    telegram[str(DPT)] = value
                elif isinstance(value, tuple):
                    print('-- TUPLE COMING THROUGH ')
                    telegram[str(DPT)] = "-".join(map(str,value))
                else:
                    print(f'Unhandled object type. Value is {type(value)}')
                message = {"telegram" : telegram}

                #print(message)
                #continue

                # Post it to telegraf:
                try:
                    response = requests.post(url=URL_STR, json=message)
                    status_code = response.status_code
                    reason = response.reason
                    if response.ok:
                        print(f'Telegram from {packet.src} ({source_name}) to GAD {packet.dst} ({GA_name}): {DPT} = {telegram[str(DPT)]}')
                    else:
                        print(f'Telegram from {packet.src} ({source_name}) to GAD {packet.dst} ({GA_name}): {DPT} = {telegram[str(DPT)]} - failed with {status_code}, {reason}')
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
