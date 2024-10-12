# This program is free software: you can redistribute it and/or modify it under the terms of the GNU General Public License
# as published by the Free Software Foundation, either version 3 of the License, or (at your option) any later version.
#
# This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied
# warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License along with this program.  If not, see
# <http://www.gnu.org/licenses/>.
#
# This script is part of the captureKNX project, which logs all KNX bus traffic to an InfluxDb for reporting via Grafana
# https://github.com/greiginsydney/captureKNX
# https://greiginsydney.com/captureKNX


import asyncio
import json                         # For sending to telegraf
import knxdclient
import math                         # Sending the 'floor' (main DPT) value to knclient
import requests                     # To push the values to telegraf

from decode_dpt  import *           # Decodes popular DPT sub-types
from decode_project import *        # Read the topo file & decode pysical and group addresses

import common
from common import ETS_0_XML_FILE as ETS_0_XML_FILE
from common import ETS_PROJECT_XML_FILE as ETS_PROJECT_XML_FILE
from common import log


# ////////////////////////////////
# /////////// STATICS ////////////
# ////////////////////////////////

HOST               = "localhost"
PORT               = 8080
PATH               = "/knxd"
URL_STR            = "http://{}:{}{}".format(HOST, PORT, PATH)
HEADERS            = {'Content-type': 'application/json', 'Accept': 'text/plain'}


common.init()          # Initialise the common variables and logging
unzip_project_archive()
GALevels        = decode_GroupLevels(ETS_PROJECT_XML_FILE)
Individual_Data = decode_Individual_Addresses(ETS_0_XML_FILE)
GA_Data         = decode_Group_Addresses(ETS_0_XML_FILE, GALevels)


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
                    log(f'main: Exception decoding a telegram from packet.src {packet.src} - {e}')

                # Decode the DESTINATION (a Group Address):
                DPT = GA_name = ''
                try:
                    DPT, GA_name = GA_Data[str(packet.dst)]
                    DPT_main = int(DPT.split('.')[0])
                    sub_DPT = int(DPT.split('.')[1])
                except Exception as e:
                    # We failed to match on the destination
                    # Discard this telegram as we don't know how to decode the data
                    log(f'main: Exception decoding a telegram to packet.dst {packet.dst}. The telegram has been discarded. {e}')
                    continue

                try:
                    value = knxdclient.decode_value(packet.payload.value, knxdclient.KNXDPT(DPT_main))
                except Exception as e:
                    # We failed to decode the payload
                    # Discard this telegram as we don't know how to decode the data
                    log(f'main: Exception decoding the payload of a telegram to packet.dst {packet.dst}. The telegram has been discarded. {e}')
                    continue
                # log(f'Telegram from {packet.src} to GAD {packet.dst}: {value}') # Raw data, retained here for debugging

                telegram = {}
                telegram['source_address']   = ".".join(map(str,packet.src))
                telegram['source_building']  = building if building else "Unknown"
                telegram['source_floor']     = floor if floor else "Unknown"
                telegram['source_room']      = room if room else "Unknown"
                telegram['source_name']      = source_name if source_name else "Unknown" # It's invalid to send an empty tag to Influx, hence 'Unknown' if required
                telegram['destination']      = "/".join(map(str,packet.dst))
                telegram['destination_name'] = GA_name if GA_name else "Unknown" # It's invalid to send an empty tag to Influx, hence 'Unknown' if required
                telegram['dpt']              = float(DPT) # We only send DPT_main to the knxdclient but the full numerical DPT to Influx (as a float)

                # TODO: is this where we define EVERY sub-type??
                unit = ""
                if DPT_main == 1:
                    try:
                        value_true, value_false = DPT1[sub_DPT]
                        value = value_true if (value) else value_false
                    except:
                        pass    # If we fail a lookup (VERY unlikely) we'll send the original DPT value unchanged
                elif DPT_main in [3, 5, 6, 7, 8, 9, 12]:
                    value, unit = globals()['DPT' + str(DPT_main)](sub_DPT, value) # decode_dpt.py

                if isinstance(value, str):
                    telegram['info'] = value
                elif isinstance(value, float):
                    telegram['info'] = str(round(value, 2))
                elif isinstance(value, (int, bool)):
                    telegram['info'] = str(value)
                elif isinstance(value, tuple):
                    # I think I've weeded out the tuples. This is for debug purposes:
                    log(f'-- TUPLE COMING THROUGH: DPT = {DPT} ')
                    telegram['info'] = str("-".join(map(str,value)))
                else:
                    log(f'Unhandled object type. DPT = {DPT}. Value is {type(value)}')
                    telegram['info'] = value
                if unit:
                    # Only add the 'unit' tag if it's not an empty string
                    telegram['unit'] = unit
                message = {"telegram" : telegram}

                # Post it to telegraf:
                try:
                    response = requests.post(url=URL_STR, json=message)
                    status_code = response.status_code
                    reason = response.reason
                    if response.ok:
                        pass
                        #log(f"Telegram from {telegram['source_address']:7.7} ({telegram['source_name']:30.30}) to GAD {telegram['destination']:7.7} ({telegram['destination_name']:30.30}): {str(telegram['dpt']):6.6} = {telegram['info']}")
                    else:
                        log(f"Telegram from {telegram['source_address']:7.7} ({telegram['source_name']:30.30}) to GAD {telegram['destination']:7.7} ({telegram['destination_name']:30.30}): {str(telegram['dpt']):6.6} = {telegram['info']} - failed with {status_code}, {reason}")
                except Exception as e:
                    log(f'Exception POSTing: {e}')

    except Exception as e:
        log(f'Exception in main: {e}\nDestination was {packet.dst}')

    finally:
        # Let's stop the connection and wait for graceful termination of the receive loop:
        await connection.stop()
        await run_task


asyncio.run(main())


# References:
# Pushing json to telegraf: https://stackoverflow.com/questions/68682076/send-python-output-json-output-to-telegraf-over-http-listener-v2
