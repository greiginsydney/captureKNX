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


import os
import logging


sudo_username = os.getenv("SUDO_USER")
if sudo_username:
    PI_USER_HOME = os.path.expanduser('~' + sudo_username + '/')
else:
    PI_USER_HOME = os.path.expanduser('~')

CAPTUREKNX_DIR    = os.path.join(PI_USER_HOME, 'captureKNX')
LOGFILE_NAME     = os.path.join(CAPTUREKNX_DIR, 'log', 'captureKNX.log')
ETS_0_XML_FILE     = os.path.join(CAPTUREKNX_DIR, '0.xml')
ETS_PROJECT_XML_FILE     = os.path.join(KNXLOGGER_DIR, 'project.xml')


def init():

    logging.basicConfig(filename=LOGFILE_NAME, filemode='a', format='{asctime} {message}', style='{', datefmt='%Y/%m/%d %H:%M:%S', level=logging.DEBUG)


def log(message):
    try:
        logging.info(message)
    except Exception as e:
        #print(f'error: {e}')
        pass
