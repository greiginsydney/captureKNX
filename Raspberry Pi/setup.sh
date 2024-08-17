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

# The main menu is at the bottom (as it needs to follow all of the functions)

# -----------------------------------
# START FUNCTIONS
# -----------------------------------

activate_venv()
{
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
}


setup()
{
	RESULT=$(test_64bit)
	if [[ $RESULT != "64" ]];
	then
		echo -e "\n"$YELLOW"This device is running a 32-bit operating system, which is not supported."$RESET""
		echo -e "\n"$YELLOW"(InfluxDB requires a 64-bit OS)"$RESET""
		echo -e "\n"$YELLOW"Check the docos and re-flash your memory card/SSH"$RESET""
		exit 1
	fi

	mkdir -pv /home/$SUDO_USER/knxLogger
 	mkdir -pv /home/$SUDO_USER/staging
	#cd /home/$SUDO_USER/knxLogger

	if [[ -d /home/${SUDO_USER}/staging/knxLogger/Raspberry\ Pi ]];
	then
		echo -e ""$GREEN"Moving repo files."$RESET""
		# Copy the knxLogger.py file across, if required:
		if [ -f /home/${SUDO_USER}/staging/knxLogger/Raspberry\ Pi/knxLogger.py ];
		then
			if cmp -s /home/${SUDO_USER}/staging/knxLogger/Raspberry\ Pi/knxLogger.py /home/${SUDO_USER}/knxLogger/knxLogger.py;
			then
				echo "Skipped: the file '/home/${SUDO_USER}/knxLogger/knxLogger.py' already exists & the new version is unchanged"
			else
				mv -fv /home/${SUDO_USER}/staging/knxLogger/Raspberry\ Pi/knxLogger.py /home/${SUDO_USER}/knxLogger/knxLogger.py
			fi
		fi

		# Copy the knxLogger.service file across, if required:
		if [ -f /home/${SUDO_USER}/staging/knxLogger/Raspberry\ Pi/knxLogger.service ];
		then
			if cmp -s /home/${SUDO_USER}/staging/knxLogger/Raspberry\ Pi/knxLogger.service /etc/systemd/system/knxLogger.service;
			then
				echo "Skipped: the file '/etc/systemd/system/knxLogger.service' already exists & the new version is unchanged"
			else
				echo -e "\n"$GREEN"Moving knxLogger.service."$RESET""
				mv -fv /home/${SUDO_USER}/staging/knxLogger/Raspberry\ Pi/knxLogger.service /etc/systemd/system/knxLogger.service
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


	set +e #Suspend the error trap
	isKnxd=$(command -v knxd)
	set -e #Resume the error trap
	if [[ "$?" -ne 0 ]];
	#if [[ ! $isKnxd ]];
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


	set +e #Suspend the error trap
	isTelegraf=$(dpkg -s telegraf 2>/dev/null)
	set -e #Resume the error trap
	if [[ "$?" -ne 0 ]];
	#if [[ ! $isTelegraf  ]];
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


	set +e #Suspend the error trap
	isInfluxd=$(command -v influxd)
	set -e #Resume the error trap
	if [[ "$?" -ne 0 ]];
	#if [[ ! $isInfluxd ]];
	then
		echo -e "\n"$GREEN"Installing InfluxDB "$RESET""
		curl -LO https://download.influxdata.com/influxdb/releases/influxdb2_2.7.8-1_arm64.deb
		dpkg -i influxdb2_2.7.8-1_arm64.deb
		systemctl start influxdb # TODO: don't start until the config has been customised
	else
		echo -e "\n"$GREEN"influx is already installed - skipping"$RESET""
		# TODO: Check version and update if there's newer.
	fi


	set +e #Suspend the error trap
	isGrafana=$(dpkg -s grafana-enterprise 2>/dev/null)
	set -e #Resume the error trap
	if [[ "$?" -ne 0 ]];
	#if [[ ! $isGrafana ]];
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


	newLine=$(read_TTY)
	if [[ $newLine ]];
	then
		if [ -f /etc/udev/rules.d/80-knxd.rules ];
		then
			# File already exists. We might be able to skip this if it's been completed previously.
			if [ "$newLine" == "$(cat /etc/udev/rules.d/80-knxd.rules)" ] ;
			then
				# There's only one line in the file and it == 'newLine'
				echo -e "\n"$GREEN"Correct UDEV rule/file already exists. No change required"$RESET""
			else
				sed -i -E "s/^([^#])/#\1/" /etc/udev/rules.d/80-knxd.rules # Comment-out any existing lines	- even if they're correct (a kludge after hours of blood/forehead)
				echo -e "\n"$GREEN"Updated existing UDEV rule/file with new values"$RESET""
				echo -e $newLine >> /etc/udev/rules.d/80-knxd.rules
			fi
		else
			echo -e $newLine >> /etc/udev/rules.d/80-knxd.rules
			echo -e "\n"$GREEN"Created UDEV rule/file OK"$RESET""
		fi
	else
		echo -e "\n"$YELLOW"Failed to find a serial port for UDEV rule creation"$RESET""
	fi


	# Customise knxf.conf
	# Extract the current values:
	echo -e "\n"$GREEN"Customising knxd config."$RESET"\n"
	echo "If you're unsure, just hit Enter/Return"

	# KNXD_OPTS="-e 1.1.15 -E 1.1.240:4 -n knxLogger -D -T -R -S -i  --layer2=tpuarts:/dev/ttyKNX1"

	#Extract the current values:
	OLD_MYADDRESS=$(sed -n -E 's/^KNXD_OPTS.*-e ([[:digit:]]+.[[:digit:]]+.[[:digit:]]+) .*$/\1/p' /etc/knxd.conf)
	OLD_CLTADDR=$(sed -n -E 's/^KNXD_OPTS.* -E ([[:digit:]]+.[[:digit:]]+.[[:digit:]]+):.*$/\1/p' /etc/knxd.conf)
	OLD_CLTNBR=$(sed -n -E 's/^KNXD_OPTS.* -E [[:digit:]]+.[[:digit:]]+.[[:digit:]]+:([[:digit:]]+) .*$/\1/p' /etc/knxd.conf)

	read -e -i "$OLD_MYADDRESS" -p 'My KNX network client address            = ' MYADDRESS
	read -e -i "$OLD_CLTADDR"   -p 'Sending KNX network client start address = ' CLIENTADDR
	read -e -i "$OLD_CLTNBR"    -p 'Sending KNX network client count         = ' CLIENTNBR

	#Paste in the new settings:
	sed -i -E "s|(^KNXD_OPTS.*-e )([[:digit:]]+.[[:digit:]]+.[[:digit:]]+)( .*$)|\1$MYADDRESS\3|" /etc/knxd.conf
	sed -i -E "s|(^KNXD_OPTS.*-E )([[:digit:]]+.[[:digit:]]+.[[:digit:]]+)(:.*$)|\1$CLIENTADDR\3|" /etc/knxd.conf
	sed -i -E "s|(^KNXD_OPTS.*-E )([[:digit:]]+.[[:digit:]]+.[[:digit:]]+:)([[:digit:]]+)( .*$)|\1\2$CLIENTNBR\4|" /etc/knxd.conf

	echo ''
	echo -e "\n"$GREEN"Changed values written to file OK."$RESET""



	# TODO: temporarily exit here. More to come.
	exit 0

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
}


read_TTY()
{
	serial=$(udevadm info -a /dev/ttyAMA0  | grep KERNELS.*serial | cut -d'=' -f3 | xargs )
	id=$(udevadm info -a /dev/ttyAMA0  | grep  \{id\} | cut -d'=' -f3 | xargs )
	if [[ $serial ]];
	then
		if [[ $id ]];
		then
			newLine="ACTION==\"add\", SUBSYSTEM==\"tty\", ATTRS{id}==\"$id\", KERNELS==\"$serial\", SYMLINK+=\"ttyKNX1\", OWNER=\"knxd\""
		else
			newLine="ACTION==\"add\", SUBSYSTEM==\"tty\", KERNELS==\"$serial\", SYMLINK+=\"ttyKNX1\", OWNER=\"knxd\""
		fi
	fi
	echo $newLine
}


test_install()
{
	echo''
	cat /proc/device-tree/model
	echo ''
	release=$(sed -n -E 's/^PRETTY_NAME="(.*)"$/\1/p' /etc/os-release)
	echo $release
	RESULT=$(test_64bit)
	if [[ $RESULT == "64" ]];
	then
		echo -e ""$GREEN"PASS:"$RESET" 64-bit OS"
	else
		echo -e ""$YELLOW"FAIL:"$RESET" 32-bit OS"
	fi
	echo '-------------------------------------'
	isKnxd=$(command -v knxd)
	if [[ $isKnxd ]];
	then
		echo -e ""$GREEN"PASS:"$RESET" knxd installed"
	else
		echo -e ""$YELLOW"FAIL:"$RESET" knxd NOT installed"
	fi

	# TODO: this is broken!!
	# isKnxdClient=$(dpkg -s knxdclient 2>/dev/null)
	if [[ $isKnxdClient ]];
	then
		echo -e ""$GREEN"PASS:"$RESET" knxdclient installed"
	else
		echo -e ""$YELLOW"FAIL:"$RESET" knxdclient NOT installed"
	fi

	isTelegraf=$(dpkg -s telegraf 2>/dev/null)
	if [[ $isTelegraf  ]];
	then
		echo -e ""$GREEN"PASS:"$RESET" telegraf installed"
	else
		echo -e ""$YELLOW"FAIL:"$RESET" telegraf NOT installed"
	fi

	isInfluxd=$(command -v influxd)
	if [[ $isInfluxd ]];
	then
		echo -e ""$GREEN"PASS:"$RESET" influxd installed"
	else
		echo -e ""$YELLOW"FAIL:"$RESET" influxd NOT installed"
	fi

	isGrafana=$(dpkg -s grafana-enterprise 2>/dev/null)
	if [[ $isGrafana ]];
	then
		echo -e ""$GREEN"PASS:"$RESET" grafana installed"
	else
		echo -e ""$YELLOW"FAIL:"$RESET" grafana NOT installed"
	fi
	echo '-------------------------------------'
	if [[ $isKnxd ]]; then
		systemctl is-active --quiet knxd.service && printf ""$GREEN"PASS:"$RESET" %-15s service is running\n" knxd.service        || printf ""$YELLOW"FAIL:"$RESET" %-15s service is dead\n" knxd.service
		systemctl is-active --quiet knxd.socket  && printf ""$GREEN"PASS:"$RESET" %-15s service is running\n" knxd.socket         || printf ""$YELLOW"FAIL:"$RESET" %-15s service is dead\n" knxd.socket; fi
	if [[ $isKnxdClient ]]; then
		systemctl is-active --quiet knxdclient   && printf ""$GREEN"PASS:"$RESET" %-15s service is running\n" knxdclient          || printf ""$YELLOW"FAIL:"$RESET" %-15s service is dead\n" knxdclient; fi
	if [[ $isTelegraf  ]]; then
		systemctl is-active --quiet telegraf     && printf ""$GREEN"PASS:"$RESET" %-15s service is running\n" telegraf            || printf ""$YELLOW"FAIL:"$RESET" %-15s service is dead\n" telegraf; fi
	if [[ $isInfluxd ]]; then
		systemctl is-active --quiet influxd      && printf ""$GREEN"PASS:"$RESET" %-15s service is running\n" influxd             || printf ""$YELLOW"FAIL:"$RESET" %-15s service is dead\n" influxd; fi
	if [[ $isGrafana ]]; then
		systemctl is-active --quiet grafana      && printf ""$GREEN"PASS:"$RESET" %-15s service is running\n" grafana             || printf ""$YELLOW"FAIL:"$RESET" %-15s service is dead\n" grafana; fi
	systemctl is-active --quiet knxLogger        && printf ""$GREEN"PASS:"$RESET" %-15s service is running\n" knxLogger           || printf ""$YELLOW"FAIL:"$RESET" %-15s service is dead\n" knxLogger
	systemctl is-active --quiet hciuart.service  && printf ""$YELLOW"FAIL:"$RESET" %-15s service is RUNNING\n" hciuart.service    || printf ""$GREEN"PASS:"$RESET" %-15s service is dead\n" hciuart.service
	
	echo '-------------------------------------'
	test_config=0
	if grep -q '# Added by setup.sh for the knxLogger' /boot/firmware/config.txt; then
		((test_config=test_config+1)); fi
	if grep -q '^enable_uart=1' /boot/firmware/config.txt; then
		((test_config=test_config+2)); fi
	if grep -q '^dtoverlay=disable-bt' /boot/firmware/config.txt; then
		((test_config=test_config+4)); fi
	if grep -q '^dtoverlay=pi3-disable-bt' /boot/firmware/config.txt; then
		((test_config=test_config+8)); fi
	case $test_config in
		(15)
			echo -e ""$GREEN"PASS:"$RESET" /boot/firmware/config.txt is good"
			;;
		(*)
			echo -e ""$YELLOW"FAIL:"$RESET" /boot/firmware/config.txt is missing required config. Re-run setup"
			;;
	esac
	
	newLine=$(read_TTY)
	if [ -f /etc/udev/rules.d/80-knxd.rules ];
	then
		# File already exists. We might be able to skip this if it's been completed previously.
		if [ "$newLine" == "$(cat /etc/udev/rules.d/80-knxd.rules)" ] ;
		then
			# There's only one line in the file and it == 'newLine'
			echo -e ""$GREEN"PASS:"$RESET" UDEV rule/file is good"
		else
			echo -e ""$YELLOW"FAIL:"$RESET" UDEV file exists but contains either muitple lines or incorrect content"
		fi
	else
		echo -e ""$YELLOW"FAIL:"$RESET" UDEV file does not exist. Re-run setup or check TTY config"
	fi
}


test_64bit()
{
	UNAME=$(uname -a)
	if [[ $UNAME == *"aarch64"* ]];
	then
		echo "64"
	else
		echo "32"
	fi
}

# -----------------------------------
# START FUNCTIONS
# -----------------------------------

# -----------------------------------
# MENU
# -----------------------------------


if [ "$EUID" -ne 0 ];
then
	echo -e "\nPlease re-run as 'sudo -E -H ./setup.sh'"
	echo -e '(Add "test" on the end to test the system)'
	exit 1
fi


case "$1" in
	
	('test')
		activate_venv
		test_install
		;;
	('')
		activate_venv
		setup
		;;
	(*)
		echo -e "\nThe switch '$1' is invalid. Try again.\n"
		exit 1
		;;
esac

# Exit from the script with success (0)
exit 0
