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
    24 : ('Night', 'Day'),
    100: ('Heating', 'Cooling'),    # HVAC FB
    1200: ('Producer', 'Consumer'), # Metering
    1201: ('Negative', 'Positive')  # Metering
}


def DPT3(sub_DPT, value):
    '''
    4-bit dimming
    '''
    direction, count = value
    unit = ""
    if sub_DPT == 7:
        if count == 0:
            decoded = "Break"
        else:
            decoded = "+" if direction else "-"
            stepWidth = int(1 / pow(2,count - 1) * 100) # Rounds to align with ETS6
            decoded = (f'{decoded} {stepWidth}')
            unit = "%"
    else:
        decoded = str(value)
    return (decoded, unit)


'''
def DPT4(sub_DPT, value):
    # It looks like knxd has already decoded DPT 4
    # This code is never called, it's left here just to remind me why
    return (value, '')
'''


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
    knxd has already decoded DPT 6 so for 1 & 10 we're only adding the unit
    '''
    unit = ""
    if sub_DPT == 1:
        unit = "%"
    if sub_DPT == 10:
        pass # 'counter pulses' isn't a unit
    if sub_DPT == 20:
        value = value + 2 ** 8  # Convert from signed back to unsigned
        value = f'{value:b}'    # Is there a better way to represent this DPT than just as 8 bits?
    return (value, unit)


def DPT7(sub_DPT, value):
    '''
    2-octet unsigned value. Counter, time period and others
    '''
    unit = ""
    if sub_DPT in (2, 3, 4):
        unit = "ms"
    elif sub_DPT == 5:
        unit = "s"
    elif sub_DPT == 6:
        unit = "min"
    elif sub_DPT == 7:
        unit = "h"
    elif sub_DPT == 11:
        unit = "mm"
    elif sub_DPT == 12:
        unit = "mA"
    elif sub_DPT == 13:
        unit = "lux"
    elif sub_DPT == 600:
        unit = "°K"
    return (value, unit)


def DPT8(sub_DPT, value):
    '''
    2-octet signed value. Counter, delta time and others
    '''
    unit = ""
    if sub_DPT == 1:
        pass
    elif sub_DPT in (2, 3, 4):
        unit = "ms"
    elif sub_DPT == 5:
        unit = "s"
    elif sub_DPT == 6:
        unit = "min"
    elif sub_DPT == 7:
        unit = "h"
    elif sub_DPT == 10:
        unit = "%"
    elif sub_DPT == 11:
        unit = "°"
    elif sub_DPT == 12:
        unit = "m"
    return (value, unit)


def DPT9(sub_DPT, value):
    '''
    2-octet float value
    '''
    unit = ""
    if sub_DPT == 1:
        unit = "°C"
    elif sub_DPT == 2:
        unit = "K"
    elif sub_DPT == 3:
        unit = "K/h"
    elif sub_DPT == 4:
        unit = "lux"
    elif sub_DPT == 5:
        unit = "m/s"
    elif sub_DPT == 6:
        unit = "Pa"
    elif sub_DPT == 7:
        unit = "%"
    elif sub_DPT == 8:
        unit = "ppm"
    elif sub_DPT == 9:
        unit = "m3/h"
    elif sub_DPT == 10:
        unit = "s"
    elif sub_DPT == 11:
        unit = "ms"
    elif sub_DPT == 20:
        unit = "mV"
    elif sub_DPT == 21:
        unit = "mA"
    elif sub_DPT == 22:
        unit = "W/m2"
    elif sub_DPT == 23:
        unit = "K/%"
    elif sub_DPT == 24:
        unit = "kW"
    elif sub_DPT == 25:
        unit = "l/h"
    elif sub_DPT == 26:
        unit = "l/m2"
    elif sub_DPT == 27:
        unit = "°F"
    elif sub_DPT == 28:
        unit = "km/h"
    elif sub_DPT == 29:
        unit = "g/m-3"
    elif sub_DPT == 30:
        unit = "ug"
    return (value, unit)


def DPT10(sub_DPT, value):
    '''
    Time of day (with optional day of week)
    '''
    DOW = ['Mon', 'Tues', 'Weds', 'Thurs', 'Fri', 'Sat', 'Sun']
    if isinstance(value, tuple):
        # Which it certainly should be!
        time, day = value
        if day:
            value = f'{DOW[day]} {time}'
        else:
            value = f'{time}'
    return (value, '')


def DPT11(sub_DPT, value):
    '''
    Date
    '''
    import datetime
    if isinstance(value, datetime.date):
        value = value.strftime('%d/%m/%Y') # TODO: Do we need to localise this for different regions? How?
    return (value, '')


def DPT12(sub_DPT, value):
    '''
    4-octet unsigned value. Counter pulses & operating hours
    '''
    unit = ""
    if sub_DPT == 1:
        pass
    elif sub_DPT == 100:
        unit = "s"
    elif sub_DPT == 101:
        unit = "min"
    elif sub_DPT == 102:
        unit = "h"
    return (value, unit)


def DPT13(sub_DPT, value):
    '''
    4-octet signed value. Counter pulses & electrical energy
    '''
    unit = ""
    if sub_DPT == 1:
        pass
    elif sub_DPT == 2:
        pass
    elif sub_DPT == 10:
        unit = "Wh"
    elif sub_DPT == 11:
        unit = "VAh"
    elif sub_DPT == 12:
        unit = "VARh"
    elif sub_DPT == 13:
        unit = "kWh"
    elif sub_DPT == 14:
        unit = "kVAh"
    elif sub_DPT == 15:
        unit = "kVARh"
    elif sub_DPT == 16:
        unit = "MWh"
    elif sub_DPT == 100:
        unit = "s"
    return (value, unit)


def DPT14(sub_DPT, value):
    '''
    4-octet float value. Lots of SI(?) units
    '''
    unit = ""
    if sub_DPT == 0:
        unit = "m/s²"
    if sub_DPT == 1:
        unit = "rad/s²"
    elif sub_DPT == 2:
        unit = "J/mol"
    elif sub_DPT == 3:
        unit = "1/s"
    elif sub_DPT == 4:
        unit = "mol"
    elif sub_DPT == 5:
        pass
    elif sub_DPT == 6:
        unit = "rad"
    elif sub_DPT == 7:
        unit = "°"
    elif sub_DPT == 8:
        unit = "Js"
    elif sub_DPT == 9:
        unit = "rad/s"
    elif sub_DPT == 10:
        unit = "m²"
    elif sub_DPT == 11:
        unit = "F"
    elif sub_DPT == 12:
        unit = "C/m²"
    elif sub_DPT == 13:
        unit = "C/m³"
    elif sub_DPT == 14:
        unit = "m²/N"
    elif sub_DPT == 15:
        unit = "S"
    elif sub_DPT == 16:
        unit = "S"
    elif sub_DPT == 17:
        unit = "kg/m³"
    elif sub_DPT == 18:
        unit = "C"
    elif sub_DPT == 19:
        unit = "A"
    elif sub_DPT == 20:
        unit = "A/m²"
    elif sub_DPT == 21:
        unit = "C m"
    elif sub_DPT == 22:
        unit = "C/m²"
    elif sub_DPT == 23:
        unit = "V/m"
    elif sub_DPT == 24:
        unit = "c"
    elif sub_DPT == 25:
        unit = "C/m²"
    elif sub_DPT == 26:
        unit = "C/m²"
    elif sub_DPT == 27:
        unit = "V"
    elif sub_DPT == 28:
        unit = "V"
    elif sub_DPT == 29:
        unit = "Am²"
    elif sub_DPT == 30:
        unit = "V"
    elif sub_DPT == 31:
        unit = "J"
    elif sub_DPT == 32:
        unit = "N"
    elif sub_DPT == 33:
        unit = "Hz"
    elif sub_DPT == 34:
        unit = "rad/s"
    elif sub_DPT == 35:
        unit = "J/K"
    elif sub_DPT == 36:
        unit = "W"
    elif sub_DPT == 37:
        unit = "J"
    elif sub_DPT == 38:
        unit = "Ω"
    elif sub_DPT == 39:
        unit = "m"
    elif sub_DPT == 40:
        unit = "J"
    elif sub_DPT == 41:
        unit = "cd/m²"
    elif sub_DPT == 42:
        unit = "lm"
    elif sub_DPT == 43:
        unit = "cd"
    elif sub_DPT == 44:
        unit = "A/m"
    elif sub_DPT == 45:
        unit = "Wb"
    elif sub_DPT == 46:
        unit = "T"
    elif sub_DPT == 47:
        unit = "Am²"
    elif sub_DPT == 48:
        unit = "T"
    elif sub_DPT == 49:
        unit = "A/m"
    elif sub_DPT == 50:
        unit = "A"
    elif sub_DPT == 51:
        unit = "kg"
    elif sub_DPT == 52:
        unit = "kg/s"
    elif sub_DPT == 53:
        unit = "N/s"
    elif sub_DPT == 54:
        unit = "rad"
    elif sub_DPT == 55:
        unit = "°"
    elif sub_DPT == 56:
        unit = "W"
    elif sub_DPT == 57:
        pass
    elif sub_DPT == 58:
        unit = "Pa"
    elif sub_DPT == 59:
        unit = "Ω"
    elif sub_DPT == 60:
        unit = "Ω"
    elif sub_DPT == 61:
        unit = "Ωm"
    elif sub_DPT == 62:
        unit = "H"
    elif sub_DPT == 63:
        unit = "sr"
    elif sub_DPT == 64:
        unit = "W/m²"
    elif sub_DPT == 65:
        unit = "m/s"
    elif sub_DPT == 66:
        unit = "Pa"
    elif sub_DPT == 67:
        unit = "N/m"
    elif sub_DPT == 68:
        unit = "°C"
    elif sub_DPT == 69:
        unit = "K"
    elif sub_DPT == 70:
        unit = "K"
    elif sub_DPT == 71:
        unit = "J/K"
    elif sub_DPT == 72:
        unit = "W/mK"
    elif sub_DPT == 73:
        unit = "V/K"
    elif sub_DPT == 74:
        unit = "s"
    elif sub_DPT == 75:
        unit = "Nm"
    elif sub_DPT == 76:
        unit = "m³"
    elif sub_DPT == 77:
        unit = "m³/s"
    elif sub_DPT == 78:
        unit = "N"
    elif sub_DPT == 79:
        unit = "J"
    elif sub_DPT == 80:
        unit = "VA"
    return (value, unit)


'''
def DPT16(sub_DPT, value):
    It looks like knxd has already decoded DPT 16
    This code is never called, it's left here just to remind me why
    return (value, '')
'''


def DPT17(sub_DPT, value):
    '''
    1-octet. Displays scene number. Add 1 for zero-offset
    '''
    return (f'#{value + 1}', '')


def DPT18(sub_DPT, value):
    '''
    1-octet. Activate/store scene number
    '''
    if isinstance(value, tuple):
        ActivateOrStore, scene = value
        if ActivateOrStore:
            value = f'Learn #{scene + 1}'
        else:
            value = f'Activate #{scene + 1}'
    return (value, '')


def DPT26(sub_DPT, value):
    '''
    1-octet. Scene info
    '''
    if isinstance(value, tuple):
        ActiveOrInactive, scene = value
        if ActiveOrInactive:
            value = f'Inactive {scene}'
        else:
            value = f'Active {scene}'
    return (value, '')


def DPT29(sub_DPT, value):
    '''
    8-byte signed value. Energy readings
    '''
    unit = ""
    if sub_DPT == 10:
        unit = "Wh"
    elif sub_DPT == 11:
        unit = "VAh"
    elif sub_DPT == 12:
        unit = "VARh"
    return (value, unit)


def DPT232(sub_DPT, value):
    '''
    RGB colour as three bytes, 0-255. Passed by knxdclient as a tuple
    '''
    return ('#{0:X}{1:X}{2:X}'.format(*value), '')
