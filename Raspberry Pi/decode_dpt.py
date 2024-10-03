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
All the DPT types that require effort to decode are here:
Reference: https://support.knx.org/hc/en-us/article_attachments/15392631105682
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
    24 : ('Night', 'Day')
}


def DPT3(sub_DPT, value):

    direction, count = value
    if sub_DPT == 7:
        if count == 0:
            decoded = "Break"
        else:
            decoded = "+" if direction else "-"
            stepWidth = int(1 / pow(2,count - 1) * 100) # Rounds to align with ETS6
            decoded = (f'{decoded} {stepWidth}%')
    else:
        decoded = str(value)
    return decoded


def DPT4(sub_DPT, value):
    '''
    It looks like knxd has already decoded DPT 4
    This code is never called; it's left here just to remind me why
    '''
    return value


def DPT5(sub_DPT, value):
    '''
    8-bit unsigned value. Scaling, angle & percent
    '''
    decoded = value
    unit = ""
    if sub_DPT == 1:
        decoded = round(value / 255 * 100, 1)
        unit = "%"
    elif sub_DPT == 3:
        decoded = round(value / 255 * 360, 1)
        unit ="°"
    elif sub_DPT == 4:
        unit = "%"
    return (decoded, unit)


def DPT6(sub_DPT, value):
    '''
    8-bit signed relative value
    '''
    unit = ""
    if sub_DPT == 1:
        unit = "%"
    elif sub_DPT == 10:
        pass
    if (value & (1 << (7))) != 0:
        value = value - (1 << bits)
    return (value, unit)


def DPT16(sub_DPT, value):
    '''
    It looks like knxd has already decoded DPT 16
    This code is never called; it's left here just to remind me why
    '''
    return value
