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


isDocker=$(which docker)
if [[ isDocker != "" ]];
then
	echo -e "\n"$GREEN"Docker already exists"$RESET""
else
	echo -e "\n"$GREEN"Docker not found. Installing."$RESET""

	# Install docker. This is the process from here:
	# https://docs.docker.com/engine/install/debian/

	# Add Docker's official GPG key:
	apt-get update
	apt-get install ca-certificates curl
	install -m 0755 -d /etc/apt/keyrings
	curl -fsSL https://download.docker.com/linux/debian/gpg -o /etc/apt/keyrings/docker.asc
	chmod a+r /etc/apt/keyrings/docker.asc

	# Add the repository to Apt sources:
	echo \
	  "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.asc] https://download.docker.com/linux/debian \
	  $(. /etc/os-release && echo "$VERSION_CODENAME") stable" | \
	   tee /etc/apt/sources.list.d/docker.list > /dev/null
	apt-get update

	apt-get install docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
	echo -e "\n"$GREEN"End of Docker install steps."$RESET""
	echo ''
fi


git clone https://github.com/huntabyte/tig-stack.git
cd tig-stack



apt install python3-pip -y
pip3 install pyserial

mkdir -pv /home/$SUDO_USER/knxLogger
cd /home/$SUDO_USER/knxLogger

# Copy the knxLogger.service file across, if required:
if [ -f knxLogger.service ];
	then
		if cmp -s knxLogger.service /etc/systemd/system/knxLogger.service;
		then
			echo "Skipped: the file '/etc/systemd/system/knxLogger.service' already exists & the new version is unchanged"
		else
			mv -fv knxLogger.service /etc/systemd/system/knxLogger.service
		fi
fi

# Customise config.txt:
if grep -q '# Added by setup.sh for the knxLogger' /boot/firmware/config.txt;
  then
	  echo -e "\n"$GREEN"UART changes to config.txt already exist"$RESET""
	else
		echo -e "\n"$GREEN"Adding UART changes to config.txt"$RESET""
    echo '# Added by setup.sh for the knxLogger' >> /boot/firmware/config.txt
		echo '# Refer https://hackaday.io/project/171850/instructions' >> /boot/firmware/config.txt
    echo 'enable_uart=1' >> /boot/firmware/config.txt
    echo 'dtoverlay=disable-bt' >> /boot/firmware/config.txt
fi


