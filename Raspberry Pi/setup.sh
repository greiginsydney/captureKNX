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

if [[ -d /home/${SUDO_USER}/knxLogger/Raspberry\ Pi ]];
then
	echo -e ""$GREEN"Moving repo files."$RESET""
	# Copy the knxLogger.py file across, if required:
	if [ -f /home/${SUDO_USER}/knxLogger/Raspberry\ Pi/knxLogger.py ];
	then
		if cmp -s /home/${SUDO_USER}/knxLogger/Raspberry\ Pi/knxLogger.py /home/${SUDO_USER}/knxLogger/knxLogger.py;
		then
			echo "Skipped: the file '/home/${SUDO_USER}/knxLogger/knxLogger.py' already exists & the new version is unchanged"
   			rm -fr /home/${SUDO_USER}/knxLogger/knxLogger.py
		else
			mv -fv /home/${SUDO_USER}/knxLogger/Raspberry\ Pi/knxLogger.py /home/${SUDO_USER}/knxLogger/knxLogger.py
		fi
	fi

	# Copy the knxLogger.service file across, if required:
	if [ -f /home/${SUDO_USER}/knxLogger/Raspberry\ Pi/knxLogger.service ];
	then
		if cmp -s /home/${SUDO_USER}/knxLogger/Raspberry\ Pi/knxLogger.service /etc/systemd/system/knxLogger.service;
		then
			echo "Skipped: the file '/etc/systemd/system/knxLogger.service' already exists & the new version is unchanged"
    			rm -fr /home/${SUDO_USER}/knxLogger/knxLogger.service
		else
			echo -e "\n"$GREEN"Moving knxLogger.service."$RESET""
			mv -fv /home/${SUDO_USER}/knxLogger/Raspberry\ Pi/knxLogger.service /etc/systemd/system/knxLogger.service
		fi
	fi
	# chmod 644 /etc/systemd/system/knxLogger.service - TODO. DO I NEED THIS??
	echo -e ""$GREEN"Enabling knxLogger.service"$RESET""
	systemctl enable knxLogger.service


	#TODO: once all wanted files are removed, delete the Pi folder: 
	# rm -fr /home/${SUDO_USER}/knxLogger/
else
	echo -e "\n"$YELLOW"No repo files to move."$RESET""
fi;


echo -e "\n"$GREEN"Installing git python3-pip knxd knxd-tools"$RESET""
apt-get install git python3-pip knxd knxd-tools -y
echo -e "\n"$GREEN"Installing rsyslog"$RESET""
sudo apt install rsyslog -y
echo -e "\n"$GREEN"Installing knxdclient requests"$RESET""
pip3 install knxdclient requests
echo ''


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
fi


echo -e "\n"$GREEN"Cleanup. Deleting packages NLR"$RESET""
sudo rm influxdb2_2.7.8-1_arm64.deb
sudo rm grafana-enterprise_11.1.3_arm64.deb


# Customise /boot/firmware/config.txt:
if grep -q '# Added by setup.sh for the knxLogger' /boot/firmware/config.txt;
	then
		echo -e "\n"$GREEN"UART changes to config.txt already exist"$RESET""
	else
		echo -e "\n"$GREEN"Adding UART changes to config.txt"$RESET""
		echo -e '\n# Added by setup.sh for the knxLogger' >> /boot/firmware/config.txt
		echo '# Refer https://hackaday.io/project/171850/instructions' >> /boot/firmware/config.txt
		echo -e 'enable_uart=1\ndtoverlay=disable-bt' >> /boot/firmware/config.txt
		echo -e "\n"$GREEN"Added UART changes to config.txt OK"$RESET""
fi


#Extract the current values:
OLD_USERNAME=$(sed -n -E 's/^\s*DOCKER_INFLUXDB_INIT_USERNAME=(.*)$/\1/p' /home/$SUDO_USER/tig-stack/.env)
OLD_PASSWORD=$(sed -n -E 's/^\s*DOCKER_INFLUXDB_INIT_PASSWORD=(.*)$/\1/p' /home/$SUDO_USER/tig-stack/.env)
OLD_TOKEN=$(sed -n -E 's/^\s*DOCKER_INFLUXDB_INIT_ADMIN_TOKEN=(.*)$/\1/p' /home/$SUDO_USER/tig-stack/.env)
OLD_ORG=$(sed -n -E 's/^\s*DOCKER_INFLUXDB_INIT_ORG=(.*)$/\1/p' /home/$SUDO_USER/tig-stack/.env)
OLD_BUCKET=$(sed -n -E 's/^\s*DOCKER_INFLUXDB_INIT_BUCKET=(.*)$/\1/p' /home/$SUDO_USER/tig-stack/.env)
OLD_RETENTION=$(sed -n -E 's/^\s*DOCKER_INFLUXDB_INIT_RETENTION=(.*)$/\1/p' /home/$SUDO_USER/tig-stack/.env)
OLD_INFLUX_PORT=$(sed -n -E 's/^\s*DOCKER_INFLUXDB_INIT_PORT=(.*)$/\1/p' /home/$SUDO_USER/tig-stack/.env)
OLD_HOST=$(sed -n -E 's/^\s*DOCKER_INFLUXDB_INIT_HOST=(.*)$/\1/p' /home/$SUDO_USER/tig-stack/.env)
OLD_PATH=$(sed -n -E 's/^\s*TELEGRAF_CFG_PATH=(.*)$/\1/p' /home/$SUDO_USER/tig-stack/.env)
OLD_GRAFANA_PORT=$(sed -n -E 's/^\s*GRAFANA_PORT=(.*)$/\1/p' /home/$SUDO_USER/tig-stack/.env)

read -e -i "$OLD_USERNAME" -p     'DOCKER_INFLUXDB_INIT_USERNAME    = ' USERNAME
read -e -i "$OLD_PASSWORD" -p     'DOCKER_INFLUXDB_INIT_PASSWORD    = ' PASSWORD
read -e -i "$OLD_TOKEN" -p        'DOCKER_INFLUXDB_INIT_ADMIN_TOKEN = ' TOKEN
read -e -i "$OLD_ORG" -p          'DOCKER_INFLUXDB_INIT_ORG         = ' ORG
read -e -i "$OLD_BUCKET" -p       'DOCKER_INFLUXDB_INIT_BUCKET      = ' BUCKET
read -e -i "$OLD_RETENTION" -p    'DOCKER_INFLUXDB_INIT_RETENTION   = ' RETENTION
read -e -i "$OLD_INFLUX_PORT" -p  'DOCKER_INFLUXDB_INIT_PORT        = ' INFLUX_PORT
read -e -i "$OLD_HOST" -p         'DOCKER_INFLUXDB_INIT_HOST        = ' HOST
read -e -i "$OLD_PATH" -p         'TELEGRAF_CFG_PATH                = ' TELEGRAF_CFG_PATH # PATH is a reserved word
read -e -i "$OLD_GRAFANA_PORT" -p 'GRAFANA_PORT                     = ' GRAFANA_PORT

#Paste in the new settings. (I used "|" as the delimiter for all, as "/" is in the replacement for the path
sed -i -E "s|^(\s*DOCKER_INFLUXDB_INIT_USERNAME=)(.*)|\1$USERNAME|" /home/$SUDO_USER/tig-stack/.env
sed -i -E "s|^(\s*DOCKER_INFLUXDB_INIT_PASSWORD=)(.*)|\1$PASSWORD|" /home/$SUDO_USER/tig-stack/.env
sed -i -E "s|^(\s*DOCKER_INFLUXDB_INIT_ADMIN_TOKEN=)(.*)|\1$TOKEN|" /home/$SUDO_USER/tig-stack/.env
sed -i -E "s|^(\s*DOCKER_INFLUXDB_INIT_ORG=)(.*)|\1$ORG|" /home/$SUDO_USER/tig-stack/.env
sed -i -E "s|^(\s*DOCKER_INFLUXDB_INIT_BUCKET=)(.*)|\1$BUCKET|" /home/$SUDO_USER/tig-stack/.env
sed -i -E "s|^(\s*DOCKER_INFLUXDB_INIT_RETENTION=)(.*)|\1$RETENTION|" /home/$SUDO_USER/tig-stack/.env
sed -i -E "s|^(\s*DOCKER_INFLUXDB_INIT_PORT=)(.*)|\1$INFLUX_PORT|" /home/$SUDO_USER/tig-stack/.env
sed -i -E "s|^(\s*DOCKER_INFLUXDB_INIT_HOST=)(.*)|\1$HOST|" /home/$SUDO_USER/tig-stack/.env
sed -i -E "s|^(\s*TELEGRAF_CFG_PATH=)(.*)|\1$TELEGRAF_CFG_PATH|" /home/$SUDO_USER/tig-stack/.env
sed -i -E "s|^(\s*GRAFANA_PORT=)(.*)|\1$GRAFANA_PORT|" /home/$SUDO_USER/tig-stack/.env

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



echo ''
echo -e "\n"$GREEN"Done!"$RESET""
