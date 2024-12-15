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


# This test script is a tool for when I'm developing new DPTs and need to send encoded packets to the bus.
# It's not something I expect captureKNX users will have a use for and it's not documented in the repo anywhere.

# This script is simply Michael's example from https://github.com/mhthies/knxdclient/blob/master/README.md#usage-example,
# although it may evolve over time.


import asyncio
import knxdclient
import logging


logging.basicConfig(filename='txKNX.log', filemode='a', format='{asctime} {message}', style='{', datefmt='%Y/%m/%d %H:%M:%S', level=logging.DEBUG)

def log(message):
    try:
        logging.info(message)
    except Exception as e:
        print(f'error: {e}')


def handler(packet: knxdclient.ReceivedGroupAPDU) -> None:
    print("Received group telegram: {}".format(packet))


async def main() -> None:
    # Raises a TimeoutError after 30 seconds of not receiving any traffic. This argument is optional
    connection = knxdclient.KNXDConnection(timeout=30.0) 
    connection.set_group_apdu_handler(handler)
    await connection.connect()
    # Connection was successful. Start receive loop:
    run_task = asyncio.create_task(connection.run())
    # Now that the receive loop is running, we can open the KNXd Group Socket:
    await connection.open_group_socket()
    # Startup completed. Now our `handler()` will receive incoming telegrams and we can send some:
    
    # await connection.group_write(knxdclient.GroupAddress(1,0,1),
        # knxdclient.KNXDAPDUType.WRITE,
        # knxdclient.encode_value(True, knxdclient.KNXDPT.BOOLEAN))
        
    await connection.group_write(knxdclient.GroupAddress(17,3,18),
        knxdclient.KNXDAPDUType.WRITE,
        #knxdclient.encode_value(bytes([0x10, 0xCC, 0x0A]), knxdclient.KNXDPT.COLOUR_RGB))
        #knxdclient.encode_value(bytes([127, 00, 32]), knxdclient.KNXDPT.COLOUR_RGB))
        knxdclient.encode_value(bytes([0x80, 0x0A, 0x33]), knxdclient.KNXDPT.COLOUR_RGB))

    await asyncio.sleep(5)
    # Let's stop the connection and wait for graceful termination of the receive loop:
    await connection.stop()
    await run_task


asyncio.run(main())
