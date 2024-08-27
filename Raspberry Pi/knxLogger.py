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
import json                         # For sending to telegraf
import knxdclient
import math                         # Sending the 'floor' (main DPT) value to knclient
import re                           # Used to escape text fields send to telegraf
import requests                     # To push the values to telegraf
from xml.dom.minidom import parse   # Decoding the ETS XML file

# Decode this:
#
# <GroupAddress Name="Bedroom LX SW FB" Address="0/0/2" DPTs="DPST-1-1" />
# <GroupAddress Name="Bedroom LX rel DIM" Address="0/0/3" DPTs="DPST-3-7" />
# <GroupAddress Name="Bedroom LX DIM value %" Address="0/0/4" DPTs="DPST-5-1" />

host = "localhost"
port = 8080
path = "/knxd"
url_str = "http://{}:{}{}".format(host, port, path)
headers = {'Content-type': 'application/json', 'Accept': 'text/plain'}


ETS_ExportFile = 'GroupExport.xml'

def decode_ETS_Export(filename):
    # Parse XML from a file object
    with open("GroupExport.xml") as file:
        document = parse(file)
    GAs = document.getElementsByTagName('GroupAddress')

    data = {}

    for GA in GAs:
        # discard those with any empty values. (Mostly likely only the DPT type for an unused GA)
        if not GA.hasAttribute('Name'):
            continue
        if not GA.hasAttribute('Address'):
            continue
        if not GA.hasAttribute('DPTs'):
            continue
        name = GA.getAttribute('Name')
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
            continue
        DPT = int(DPT_split[1]) + sub_dpt
        data[knxdclient.GroupAddress(int(address[0]), int(address[1]), int(address[2]))] = (DPT, name)

    return data


GA_Data = decode_ETS_Export(ETS_ExportFile)


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
                    # TODO
                    
                # Decode the DESTINATION (a Group Address):
                try:
                    DPT, GA_name = GA_Data[packet.dst]
                    DPT_main = math.floor(DPT)
                except:
                    # We failed to match on the destination.
                    # Discard this, as we don't know how to decode the data
                    continue
                try:
                    value = knxdclient.decode_value(packet.payload.value, knxdclient.KNXDPT(DPT_main))
                except:
                    # We failed to match on the destination.
                    # Discard this, as we don't know how to decode the data
                    continue
                print(f'Telegram from {packet.src} to GAD {packet.dst}: {value}')

                telegram = {}
                telegram['source_address'] = ".".join(map(str,packet.src))
                telegram['source_name'] = re.escape('Unknown') # TODO: Paste source name here. NB: it's invalid to send an empty tag to Influx
                telegram['destination'] = "/".join(map(str,packet.dst))
                telegram['destination_name'] = GA_name if (GA_name) else 'Unknown' # It's invalid to send an empty tag to Influx, hence 'Unknown' if required
                telegram['dpt'] = DPT # We send DPT_main to the knxdclient but the full numerical DPT to Influx

                #Ugh! The value could be one of MANY types:
                # TODO: is this where we define EVERY sub-type??
                if isinstance(value, str):
                    telegram['info'] = "'" + value + "'"
                elif isinstance(value, (float, int, bool)):
                    telegram['info'] = value
                elif isinstance(value, tuple):
                    print('-- TUPLE COMING THROUGH ')
                    telegram['info'] = "-".join(map(str,value))
                else:
                    print(f'Unhandled object type. Value is {type(value)}')
                message = {"telegram" : telegram}

                # Post it to telegraf:
                try:
                    response = requests.post(url=url_str, json=message)
                    status_code = response.status_code
                    reason = response.reason
                    if response.ok:
                        print(f'Telegram from {packet.src} to GAD {packet.dst} ({GA_name}): {value}.')
                    else:
                        print(f'Telegram from {packet.src} to GAD {packet.dst} ({GA_name}): {value} - failed with {status_code}, {reason}.')
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
