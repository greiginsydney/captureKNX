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


'''
DPT sub-type decoding is documented here:
https://support.knx.org/hc/en-us/article_attachments/15392631105682

This file only decodes a fraction of these. More may come over time
'''

DPT1 = {
# <value> : (<TRUE>, <FALSE>)
    0 : ('On', 'Off'), # Not officially defined, but if I get a DPT with no sub-type, I'm calling it ".000"
    1 : ('On', 'Off'),
    2 : ('True', 'False'),
    3 : ('Enable', 'Disable'),
    4 : ('Ramp', 'No ramp'),
    5 : ('Alarm', 'No alarm'),
    6 : ('High', 'Low'),
    7 : ('Increase', 'Decrease'),
    8 : ('Down', 'Up'),
    9 : ('Close', 'Open'),
    10 : ('Start', 'Stop'),
    11 : ('Active', 'Inactive'),
    12 : ('Inverted', 'Not inverted'),
    13 : ('Cyclically', 'Start/Stop'),
    14 : ('Calculated', 'Fixed'),
    15 : ('Reset', 'No action'),
    16 : ('Acknowledge', 'No action'),
    17 : ('Trigger', 'Trigger'),
    18 : ('Occupied', 'Not occupied'),
    19 : ('Open', 'Closed'),
    20 : ('Unused', 'Unused'), #Not defined; unused
    21 : ('Logical AND', 'Logical OR'),
    22 : ('Scene B', 'Scene A'),
    23 : ('Up/Down+Step/Stop', 'Up/Down'),
    24 : ('Night', 'Day'),
}


def DPT5(sub_DPT, value):
    '''
    TODO: return 'decoded' as a tuple with the value type
    '''
    if sub_DPT == 1:
        decoded = round(value / 255 * 100, 1)
    elif sub_DPT == 3:
        decoded = round(value / 255 * 360, 1)
    else:
        decoded = value # 4, 5, 6 & 10 all return the initial value unchanged
    return decoded
    
