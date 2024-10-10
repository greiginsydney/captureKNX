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
# https://greiginsydney.com/knxlogger


import glob                         # Finding the most recent (youngest) project file
import os                           # Path manipulation
import re                           # Used to decode the topology + escape text fields sent to telegraf
import requests                     # To push the values to telegraf
from xml.dom.minidom import parse   # Decoding the ETS XML file
import zipfile                      # Reading the project file (it's just a ZIP file!)

import common
from common import log
from common import PI_USER_HOME as PI_USER_HOME
from common import ETS_0_XML_FILE as ETS_0_XML_FILE
from common import ETS_PROJECT_XML_FILE as ETS_PROJECT_XML_FILE


def unzip_project_archive():
    '''
    Walk through the user's root folder recursively in search of the most recent (youngest) project file.
    If project file is found, compare its creation time to existing 0.XML & project.XML. If they're *younger*, exit.
    If project file and 0 or Project are OLDER, extract the files.
    If project file not found, just exit, as previous 0.XML & project.XML may already exist.
    '''
    try:
        oldest = 0  # Initialise to 1970
        if os.path.isfile(ETS_0_XML_FILE) and os.path.isfile(ETS_PROJECT_XML_FILE):
            # Good. We have files, that's a start.
            # Check their datestamps:
            oldest = min(os.path.getmtime(ETS_0_XML_FILE),os.path.getmtime(ETS_PROJECT_XML_FILE))

        project_files = glob.glob(PI_USER_HOME + "/**/*.knxproj", recursive = True)
        if project_files:
            project_file = max(project_files, key=os.path.getctime)
            if os.path.getctime(project_file) > oldest:
                log(f'unzip_project_archive: Unzipping {project_file}')
                with zipfile.ZipFile(project_file) as z:
                    allFiles = z.namelist()
                    for etsFile in (os.path.split(ETS_0_XML_FILE)[1], os.path.split(ETS_PROJECT_XML_FILE)[1]):
                        for thisFile in allFiles:
                            if etsFile == thisFile.split('/')[-1]:
                                with open(PI_USER_HOME + '/knxLogger/' + etsFile , 'wb') as f:
                                    f.write(z.read(thisFile))
                                break
            else:
                log(f'unzip_project_archive: existing XML files are younger than {project_file}. Skipping extraction')
        else:
            log(f'unzip_project_archive: No project file found')
    except Exception as e:
        log(f'unzip_project_archive: Exception thrown trying to unzip archive: {e}')

    return


# Decode this Topology data from project.xml (NB: this is an edited extract):

# <?xml version="1.0" encoding="utf-8"?>
# <KNX xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xmlns:xsd="http://www.w3.org/2001/XMLSchema" CreatedBy="ETS6" ToolVersion="6.2.7302.0" xmlns="http://knx.org/xml/project/23">
#   <Project Id="P-00B8">
#      <ProjectInformation Name="MyProject" GroupAddressStyle="ThreeLevel" LastModified="2024-08-26T22:45:00.1307987Z" ArchivedVersion="2022-05-04T07:36:16.4846857Z" ProjectStart="2022-02-10T06:35:34.3087562Z" Comment=""
#
# -----------------------------------------------------------------^

def decode_GroupLevels(filename):
    '''
    Reads topology.xml to determine if we're using Free, Two or Three level group addressing.
    '''
    if not os.path.isfile(filename):
        log(f"decode_GroupLevels: file '{filename}' not found. Aborting")
        print(f"decode_GroupLevels: file '{filename}' not found. Aborting")
        return
    try:
        with open(filename) as file:
            document = parse(file)
    except Exception as e:
        log(f"decode_GroupLevels: Exception thrown trying to read file '{filename}'. {e}")

    try:
        for elements in document.getElementsByTagName('ProjectInformation'):
            GroupAddressStyle = (elements.getAttribute('GroupAddressStyle')).strip()
        if "ThreeLevel" in GroupAddressStyle:
            return 3
        elif "TwoLevel" in GroupAddressStyle:
            return 2
        else:
            return 1
    except Exception as e:
        log(f"decode_GroupLevels: Exception thrown trying to read GA Style from '{filename}'. {e}")


# Decode this Topology data from 0.xml (NB: this is an edited extract):
#
#  <Topology>
#    <Area Id="P-00B8-0_A-2" Address="1" Puid="4">
#      <Line Id="P-00B8-0_L-5" Address="1" Puid="596">
#        <Segment Id="P-00B8-0_S-5" Number="0" MediumTypeRefId="MT-0" Puid="597">
#          <DeviceInstance Id="P-00B8-0_DI-3" Address="20" Name="Garage - DIMMER - DM 4-2 T (4 x dimming actuator, 200 W)"

def decode_Individual_Addresses(filename):
    '''
    Decodes individual addresses from 0.xml. Aborts if file not found: its existence at this stage ISN'T mandatory
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
        for each_location in locations:
            for DeviceInstances in each_location.getElementsByTagName('DeviceInstanceRef'):
                RefId = DeviceInstances.getAttribute('RefId').strip()
                building = floor = room = '' # Flush for each pass, as a device won't always have a floor or room
                node = DeviceInstances
                while node.parentNode:
                    node = node.parentNode
                    if node.nodeName == 'Space':
                        if node.getAttribute('Type') == 'Building':
                            building = (node.getAttribute('Name')).strip()
                        elif node.getAttribute('Type') == 'Floor':
                            floor = (node.getAttribute('Name')).strip()
                        elif node.getAttribute('Type') == 'Room':
                            room = (node.getAttribute('Name')).strip()
                if RefId not in location:
                    location[RefId] = (building, floor, room)
                    #print(f'RefId: {RefId} - Building: {building}, floor: {floor}, room: {room}')

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

def decode_Group_Addresses(filename, grpAddLevels):
    '''
    Decodes group addresses from 0.xml. Aborts if file not found - a fatal error
    Handles one, two or three-level GA's, as previously extracted from PROJECT.XML
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
                                if grpAddLevels == 3:
                                    main = longAddress >> 11
                                    middle = (longAddress >> 8) & 0x07
                                    sub = longAddress & 0b0000000011111111
                                    GA = (f'{main}/{middle}/{sub}')
                                elif grpAddLevels == 2:
                                    main = longAddress >> 11
                                    sub = longAddress & 0b0000011111111111
                                    GA = (f'{main}/{sub}')
                                else:
                                    GA = longAddress

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
