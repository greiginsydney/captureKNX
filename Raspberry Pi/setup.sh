#!/bin/bash

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



set -e # The -e switch will cause the script to exit should any command return a non-zero value

# keep track of the last executed command
# https://intoli.com/blog/exit-on-errors-in-bash-scripts/
trap 'last_command=$current_command; current_command=$BASH_COMMAND' DEBUG
# echo an error message before exiting
trap 'echo "\"${last_command}\"" command failed with exit code $?.' ERR

#Shell note for n00bs like me: in Shell scripting, 0 is success and true. Anything else is shades of false/fail.

# -----------------------------------
# CONSTANTS
# -----------------------------------

GREEN="\033[38;5;10m"
YELLOW="\033[38;5;11m"
GREY="\033[38;5;60m"
RESET="\033[0m"


# -----------------------------------
# LET'S GO!
# -----------------------------------

while true;
	do
		if [[ "$VIRTUAL_ENV" != "" ]];
		then
			VENV_ACTIVE=1
			echo -e ""$GREEN"Virtual environment active."$RESET""
			break
		else
			if [[ ! $TRIED ]];
			then
				echo -e "\n"$YELLOW"Virtual environment NOT active. Attempting to activate."$RESET""
				source "venv/bin/activate"
				TRIED==1
			else
				VENV_ACTIVE=0
				break
				fi;
		fi;
	done

if [[ ($VENV_ACTIVE == 0) ]];
then
	echo -e "\n"$YELLOW"The required virtual environment could not be activated"$RESET""
	echo "Please execute the command 'source venv/bin/activate' and re-run the script."
	echo -e "If that fails, check you have correctly created the required VENV. Review \nReview \nhttps://github.com/greiginsydney/knxLogger/blob/bookworm/docs/step1-setup-the-Pi.md"
	echo ''
	exit
fi

mkdir -pv /home/$SUDO_USER/knxLogger
cd /home/$SUDO_USER/knxLogger

if [[ -d /home/${SUDO_USER}/staging/Raspberry\ Pi ]];
then
	echo -e ""$GREEN"Moving repo files."$RESET""
	# Copy the knxLogger.py file across, if required:
	if [ -f /home/${SUDO_USER}/staging/Raspberry\ Pi/knxLogger.py ];
	then
		if cmp -s /home/${SUDO_USER}/staging/Raspberry\ Pi/knxLogger.py /home/${SUDO_USER}/knxLogger/knxLogger.py;
		then
			echo "Skipped: the file '/home/${SUDO_USER}/knxLogger/knxLogger.py' already exists & the new version is unchanged"
		else
			mv -fv /home/${SUDO_USER}/staging/Raspberry\ Pi/knxLogger.py /home/${SUDO_USER}/knxLogger/knxLogger.py
		fi
	fi

	# Copy the knxLogger.service file across, if required:
	if [ -f /home/${SUDO_USER}/staging/Raspberry\ Pi/knxLogger.service ];
	then
		if cmp -s /home/${SUDO_USER}/staging/Raspberry\ Pi/knxLogger.service /etc/systemd/system/knxLogger.service;
		then
			echo "Skipped: the file '/etc/systemd/system/knxLogger.service' already exists & the new version is unchanged"
		else
			echo -e "\n"$GREEN"Moving knxLogger.service."$RESET""
			mv -fv /home/${SUDO_USER}/staging/Raspberry\ Pi/knxLogger.service /etc/systemd/system/knxLogger.service
		fi
	fi
	# chmod 644 /etc/systemd/system/knxLogger.service - TODO. DO I NEED THIS??
	echo -e ""$GREEN"Enabling knxLogger.service"$RESET""
	systemctl enable knxLogger.service


	#TODO: once all wanted files are removed, delete the staging folder - this needs to take place at the END of the script.
	# rm -fr /home/${SUDO_USER}/staging/ NOT HERE
else
	echo -e "\n"$YELLOW"No repo files to move."$RESET""
fi;


echo -e "\n"$GREEN"Installing git python3-pip"$RESET""
apt-get install git python3-pip -y
echo -e "\n"$GREEN"Installing rsyslog"$RESET""
sudo apt install rsyslog -y
echo -e "\n"$GREEN"Installing requests"$RESET""
apt-get install python3-requests


isKnxd=$(command -v knxd)
if [[ ! $isKnxd ]];
then
	echo -e "\n"$GREEN"Installing knxd "$RESET""
	apt-get install git-core -y
	git clone -b debian https://github.com/knxd/knxd.git
	sh knxd/install-debian.sh
else
	echo -e "\n"$GREEN"knxd is already installed - skipping"$RESET""
	# TODO: Check version and update if there's newer.
fi


# echo -e "\n"$GREEN"Installing knxdclient"$RESET""
# sudo pip3 install knxdclient


isTelegraf=$(dpkg -s telegraf 2>/dev/null)
if [[ ! $isTelegraf  ]];
then
        echo -e "\n"$GREEN"Installing telegraf"$RESET""
	curl -s https://repos.influxdata.com/influxdata-archive.key > influxdata-archive.key
	echo '943666881a1b8d9b849b74caebf02d3465d6beb716510d86a39f6c8e8dac7515 influxdata-archive.key' | sha256sum -c && cat influxdata-archive.key | gpg --dearmor | sudo tee /etc/apt/trusted.gpg.d/influxdata-archive.gpg > /dev/null
	echo 'deb [signed-by=/etc/apt/trusted.gpg.d/influxdata-archive.gpg] https://repos.influxdata.com/debian stable main' | sudo tee /etc/apt/sources.list.d/influxdata.list
	apt-get update && sudo apt-get install telegraf -y
else
	echo -e "\n"$GREEN"telegraf is already installed - skipping"$RESET""
	# TODO: Check version and update if there's newer.
fi


isInfluxd=$(command -v influxd)
if [[ ! $isInfluxd ]];
then
	echo -e "\n"$GREEN"Installing InfluxDB "$RESET""
	curl -LO https://download.influxdata.com/influxdb/releases/influxdb2_2.7.8-1_arm64.deb
	dpkg -i influxdb2_2.7.8-1_arm64.deb
	systemctl start influxdb # TODO: don't start until the config has been customised
else
	echo -e "\n"$GREEN"influx is already installed - skipping"$RESET""
	# TODO: Check version and update if there's newer.
fi


isGrafana=$(dpkg -s grafana-enterprise 2>/dev/null)
if [[ ! $isGrafana ]];
then
	echo -e "\n"$GREEN"Installing grafana"$RESET""
	apt-get install -y apt-transport-https software-properties-common wget
	mkdir -p /etc/apt/keyrings/
	wget -q -O - https://apt.grafana.com/gpg.key | gpg --dearmor | sudo tee /etc/apt/keyrings/grafana.gpg > /dev/null
	echo "deb [signed-by=/etc/apt/keyrings/grafana.gpg] https://apt.grafana.com stable main" | sudo tee -a /etc/apt/sources.list.d/grafana.list
	apt-get update
	apt-get install grafana-enterprise -y
	sudo systemctl daemon-reload
	sudo systemctl start grafana-server # TODO: don't start until the config has been customised
	sudo systemctl enable grafana-server
else
	echo -e "\n"$GREEN"grafana is already installed - skipping"$RESET""
	# TODO: Check version and update if there's newer.
fi

# Customise /boot/firmware/config.txt:
if grep -q '# Added by setup.sh for the knxLogger' /boot/firmware/config.txt;
then
	echo -e "\n"$GREEN"UART changes to config.txt already exist"$RESET""
else
	echo -e "\n"$GREEN"Adding UART changes to config.txt"$RESET""
	echo -e '\n# Added by setup.sh for the knxLogger' >> /boot/firmware/config.txt
fi
if ! grep -q '^enable_uart=1' /boot/firmware/config.txt;
then
	echo -e 'enable_uart=1' >> /boot/firmware/config.txt
fi
if ! grep -q '^dtoverlay=disable-bt' /boot/firmware/config.txt;
then
	echo -e 'dtoverlay=disable-bt' >> /boot/firmware/config.txt
fi
if ! grep -q '^dtoverlay=pi3-disable-bt' /boot/firmware/config.txt;
then
	echo -e 'dtoverlay=pi3-disable-bt' >> /boot/firmware/config.txt
fi


# Customise knxd.conf:
echo -e "\n"$GREEN"Customising the config."$RESET""
echo 'If any value is unknown, just hit Enter'

# Extract the current values:
OLD_MYADDRESS=$(sed -n -E 's/^KNXD_OPTS.*-e ([[:digit:]]+.[[:digit:]]+.[[:digit:]]+) .*$/\1/p' /etc/knxd.conf)

read -e -i "$OLD_MYADDRESS" -p     'KNX network client address = ' MYADDRESS

#Paste in the new settings:
sed -i -E "s|(^KNXD_OPTS.*-e )([[:digit:]]+.[[:digit:]]+.[[:digit:]]+)( .*$)|\1$MYADDRESS\3|" /etc/knxd.conf
echo ''
echo -e "\n"$GREEN"Changed values written to file OK."$RESET""


echo -e "\n"$GREEN"Customising the telegraph.conf file."$RESET""
# These 3 lines need to be un-commented, and the port number changed:
# [[inputs.socket_listener]]
#   # service_address = "tcp://:8094"
#   # data_format = "influx"

sed -i -E 's/^\s*#\s*(\[\[inputs.socket_listener\]\])/\1/g' /home/$SUDO_USER/tig-stack/telegraf/telegraf.conf #Un-comments the socket line
#Find the line number that 'inputs.socket_listener' starts at:
SocketLine=$(sed -n '/\[\[inputs.socket_listener\]\]/=' /home/$SUDO_USER/tig-stack/telegraf/telegraf.conf)
sed -i -E "$SocketLine,$ s|^\s*#*\s*#*\s*(service_address = \"tcp://:)(.*)\"(.*)|\\17654\"|" /home/$SUDO_USER/tig-stack/telegraf/telegraf.conf
sed -i -E "$SocketLine,$ s/^\s*#*\s*#*\s*(data_format = \"influx\")(.*)/\\1/" /home/$SUDO_USER/tig-stack/telegraf/telegraf.conf
echo -e "\n"$GREEN"Changed values written to file OK."$RESET""


echo -e "\n"$GREEN"Cleanup. Deleting packages NLR"$RESET""
sudo rm -f influxdb2_2.7.8-1_arm64.deb
sudo rm -f grafana-enterprise_11.1.3_arm64.deb
# rm -fr /home/${SUDO_USER}/staging/

echo ''
echo -e "\n"$GREEN"Done!"$RESET""
