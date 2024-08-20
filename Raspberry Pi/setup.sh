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

	mkdir -p /home/$SUDO_USER/knxLogger
	mkdir -p /home/$SUDO_USER/staging
	#cd /home/$SUDO_USER/knxLogger
	if [[ -d /home/${SUDO_USER}/staging/knxLogger/Raspberry\ Pi ]];
	then
		echo -e "\n"$GREEN"Moving repo files."$RESET""
		# knxLogger.py:
		if [ -f /home/${SUDO_USER}/staging/knxLogger/Raspberry\ Pi/knxLogger.py ];
		then
			if cmp -s /home/${SUDO_USER}/staging/knxLogger/Raspberry\ Pi/knxLogger.py /home/${SUDO_USER}/knxLogger/knxLogger.py;
			then
				echo "Skipped: the file '/home/${SUDO_USER}/knxLogger/knxLogger.py' already exists & the new version is unchanged"
			else
				mv -fv /home/${SUDO_USER}/staging/knxLogger/Raspberry\ Pi/knxLogger.py /home/${SUDO_USER}/knxLogger/knxLogger.py
			fi
		fi

		# knxLogger.service:
		if [ -f /home/${SUDO_USER}/staging/knxLogger/Raspberry\ Pi/knxLogger.service ];
		then
			if cmp -s /home/${SUDO_USER}/staging/knxLogger/Raspberry\ Pi/knxLogger.service /etc/systemd/system/knxLogger.service;
			then
				echo "Skipped: the file '/etc/systemd/system/knxLogger.service' already exists & the new version is unchanged"
			else
				mv -fv /home/${SUDO_USER}/staging/knxLogger/Raspberry\ Pi/knxLogger.service /etc/systemd/system/knxLogger.service
			fi
		fi

		# telegraf.conf:
		if [ -f /home/${SUDO_USER}/staging/knxLogger/Raspberry\ Pi/telegraf.conf ];
		then
			if cmp -s /home/${SUDO_USER}/staging/knxLogger/Raspberry\ Pi/telegraf.conf /etc/telegraf/telegraf.conf;
			then
				echo "Skipped: the file '/etc/telegraf/telegraf.conf' already exists & the new version is unchanged"
			else
				[ -f /etc/telegraf/telegraf.conf ] && mv -fv /etc/telegraf/telegraf.conf /etc/telegraf/telegraf.conf.old
				mkdir -p /etc/telegraf/
				mv -fv /home/${SUDO_USER}/staging/knxLogger/Raspberry\ Pi/telegraf.conf /etc/telegraf/telegraf.conf
			fi
		fi

		# knxLogger.logrotate:
		if [ -f /home/${SUDO_USER}/staging/knxLogger/Raspberry\ Pi/knxLogger.logrotate ];
		then
			if cmp -s /home/${SUDO_USER}/staging/knxLogger/Raspberry\ Pi/knxLogger.logrotate /etc/logrotate.d/knxLogger.logrotate;
			then
				echo "Skipped: the file '/etc/logrotate.d/knxLogger.logrotate' already exists & the new version is unchanged"
			else
				mv -fv /home/${SUDO_USER}/staging/knxLogger/Raspberry\ Pi/knxLogger.logrotate /etc/logrotate.d/knxLogger.logrotate
			fi
		fi
		chown root /etc/logrotate.d/knxLogger.logrotate
		chgrp root /etc/logrotate.d/knxLogger.logrotate


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
	if [[ ! $isKnxd ]];
	then
		echo -e "\n"$GREEN"Installing knxd "$RESET""
		mkdir -pv /home/$SUDO_USER/staging/knxd
		cd /home/${SUDO_USER}/staging/knxd/
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
	if [[ ! $isTelegraf  ]];
	then
		echo -e "\n"$GREEN"Installing telegraf"$RESET""
		mkdir -pv /home/$SUDO_USER/staging/telegraf
		cd /home/${SUDO_USER}/staging/telegraf/
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
	if [[ ! $isInfluxd ]];
	then
		mkdir -pv /home/$SUDO_USER/staging/influxd
		cd /home/${SUDO_USER}/staging/influxd/
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
		echo ''
  		echo 'A reboot is required before continuing. Reboot and simply re-run the script'
		echo ''
  		exit 0
	fi

	if ! grep -q '^dtoverlay=disable-bt' /boot/firmware/config.txt;
	then
		echo -e 'dtoverlay=disable-bt' >> /boot/firmware/config.txt
	fi

	if ! grep -q '^dtoverlay=pi3-disable-bt' /boot/firmware/config.txt;
	then
		echo -e 'dtoverlay=pi3-disable-bt' >> /boot/firmware/config.txt
	fi


	NEEDS_REBOOT=''
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
				NEEDS_REBOOT='yes'
			fi
		else
			echo -e $newLine >> /etc/udev/rules.d/80-knxd.rules
			echo -e "\n"$GREEN"Created UDEV rule/file OK"$RESET""
			NEEDS_REBOOT='yes'
		fi
	else
		echo -e "\n"$YELLOW"Failed to find a serial port for UDEV rule creation"$RESET""
	fi
	if [[ $NEEDS_REBOOT ]];
	then
		echo ''
  		echo 'A reboot is required before continuing. Reboot and simply re-run the script'
		echo ''
  		exit 0
	fi


	# Customise knxf.conf
	# Extract the current values:
	echo -e "\n"$GREEN"Customising knxd config."$RESET"\n"
	echo "If you're unsure, just hit Enter/Return"

	# This is the default: KNXD_OPTS="-e 0.0.1 -E 0.0.2:8 -u /tmp/eib -b ip:"
	# Needs to look like:  KNXD_OPTS="-e 0.0.1 -E 0.0.2:8 -n knxLogger --layer2=tpuarts:/dev/ttyKNX1"

	#Extract the current values:
	OLD_MYADDRESS=$(sed -n -E 's/^KNXD_OPTS.*-e ([[:digit:]]+.[[:digit:]]+.[[:digit:]]+) .*$/\1/p' /etc/knxd.conf)
	OLD_CLTADDR=$(sed -n -E 's/^KNXD_OPTS.* -E ([[:digit:]]+.[[:digit:]]+.[[:digit:]]+):.*$/\1/p' /etc/knxd.conf)
	OLD_CLTNBR=$(sed -n -E 's/^KNXD_OPTS.* -E [[:digit:]]+.[[:digit:]]+.[[:digit:]]+:([[:digit:]]+) .*$/\1/p' /etc/knxd.conf)

	read -e -i "$OLD_MYADDRESS" -p 'My KNX network client address            = ' MYADDRESS
	read -e -i "$OLD_CLTADDR"   -p 'Sending KNX network client start address = ' CLIENTADDR
	read -e -i "$OLD_CLTNBR"    -p 'Sending KNX network client count         = ' CLIENTNBR

	OLD_FILE_CHECKSUM=$(md5sum /etc/knxd.conf)
	#Paste in the new settings:
	sed -i -E "s|(^KNXD_OPTS.*-e )([[:digit:]]+.[[:digit:]]+.[[:digit:]]+)( .*$)|\1$MYADDRESS\3|" /etc/knxd.conf
	sed -i -E "s|(^KNXD_OPTS.*-E )([[:digit:]]+.[[:digit:]]+.[[:digit:]]+)(:.*$)|\1$CLIENTADDR\3|" /etc/knxd.conf
	sed -i -E "s|(^KNXD_OPTS.*-E )([[:digit:]]+.[[:digit:]]+.[[:digit:]]+:)([[:digit:]]+)( .*$)|\1\2$CLIENTNBR\4|" /etc/knxd.conf
	# Delete "-u /tmp/eib":
	sed -i -E "s|^(KNXD_OPTS=.*)( -u /tmp/eib)(.*)|\1\3|" /etc/knxd.conf
	# Insert hostname:
	HOSTNAME=$(uname -n)
	if ! grep -q " -n $HOSTNAME " /etc/knxd.conf;
	then
		sed -i -E "s|^(KNXD_OPTS=.*)( -E [[:digit:]]+.[[:digit:]]+.[[:digit:]]+:[[:digit:]]+)(.*)$|\1\2 -n $HOSTNAME\3|" /etc/knxd.conf
	fi
	# Set data source to be ttyKNX1:
	sed -i -E "s|^(KNXD_OPTS=.*)( -b ip:)(.*)|\1 --layer2=tpuarts:/dev/ttyKNX1\3|" /etc/knxd.conf
	NEW_FILE_CHECKSUM=$(md5sum /etc/knxd.conf)
	if [[ $NEW_FILE_CHECKSUM != $OLD_FILE_CHECKSUM ]];
	then
		echo -e ""$GREEN"Changed values written to file OK"$RESET""
	else
		echo -e ""$GREEN"No changes made"$RESET""
	fi
	echo ''


	# Customise influxDB
	# Extract the current values:
	echo -e "\n"$GREEN"Customising influxDB config."$RESET"\n"
	echo "If you're unsure, just hit Enter/Return"

	#Extract the current values:
	OLD_USERNAME=$(sed -n -E 's/^\s*INFLUXDB_INIT_USERNAME=(.*)$/\1/p' /home/$SUDO_USER/staging/knxLogger/Raspberry\ Pi/influxDB.env)
	OLD_PASSWORD=$(sed -n -E 's/^\s*INFLUXDB_INIT_PASSWORD=(.*)$/\1/p' /home/$SUDO_USER/staging/knxLogger/Raspberry\ Pi/influxDB.env)
	OLD_TOKEN=$(sed -n -E 's/^\s*INFLUXDB_INIT_ADMIN_TOKEN=(.*)$/\1/p' /home/$SUDO_USER/staging/knxLogger/Raspberry\ Pi/influxDB.env)
	OLD_ORG=$(sed -n -E 's/^\s*INFLUXDB_INIT_ORG=(.*)$/\1/p' /home/$SUDO_USER/staging/knxLogger/Raspberry\ Pi/influxDB.env)
	OLD_BUCKET=$(sed -n -E 's/^\s*INFLUXDB_INIT_BUCKET=(.*)$/\1/p' /home/$SUDO_USER/staging/knxLogger/Raspberry\ Pi/influxDB.env)
	OLD_RETENTION=$(sed -n -E 's/^\s*INFLUXDB_INIT_RETENTION=(.*)$/\1/p' /home/$SUDO_USER/staging/knxLogger/Raspberry\ Pi/influxDB.env)
	OLD_HOST=$(sed -n -E 's/^\s*INFLUXDB_INIT_HOST=(.*)$/\1/p' /home/$SUDO_USER/staging/knxLogger/Raspberry\ Pi/influxDB.env)
	OLD_PORT=$(sed -n -E 's/^\s*GRAFANA_PORT=(.*)$/\1/p' /home/$SUDO_USER/staging/knxLogger/Raspberry\ Pi/influxDB.env)

	read -e -i "$OLD_USERNAME" -p   'INFLUXDB_INIT_USERNAME    = ' USERNAME
	read -e -i "$OLD_PASSWORD" -p   'INFLUXDB_INIT_PASSWORD    = ' PASSWORD
	read -e -i "$OLD_TOKEN" -p      'INFLUXDB_INIT_ADMIN_TOKEN = ' TOKEN
	read -e -i "$OLD_ORG" -p        'INFLUXDB_INIT_ORG         = ' ORG
	read -e -i "$OLD_BUCKET" -p     'INFLUXDB_INIT_BUCKET      = ' BUCKET
	read -e -i "$OLD_RETENTION" -p  'INFLUXDB_INIT_RETENTION   = ' RETENTION
	read -e -i "$OLD_HOST" -p       'INFLUXDB_INIT_HOST        = ' HOST
	read -e -i "$OLD_PORT" -p       'GRAFANA_PORT              = ' PORT

	OLD_FILE_CHECKSUM=$(md5sum /home/$SUDO_USER/staging/knxLogger/Raspberry\ Pi/influxDB.env)
	#Paste in the new settings. (I used "|" as the delimiter for all, as "/" is in the replacement for the path
	sed -i -E "s|^(\s*INFLUXDB_INIT_USERNAME=)(.*)|\1$USERNAME|" /home/$SUDO_USER/staging/knxLogger/Raspberry\ Pi/influxDB.env
	sed -i -E "s|^(\s*INFLUXDB_INIT_PASSWORD=)(.*)|\1$PASSWORD|" /home/$SUDO_USER/staging/knxLogger/Raspberry\ Pi/influxDB.env
	sed -i -E "s|^(\s*INFLUXDB_INIT_ADMIN_TOKEN=)(.*)|\1$TOKEN|" /home/$SUDO_USER/staging/knxLogger/Raspberry\ Pi/influxDB.env
	sed -i -E "s|^(\s*INFLUXDB_INIT_ORG=)(.*)|\1$ORG|" /home/$SUDO_USER/staging/knxLogger/Raspberry\ Pi/influxDB.env
	sed -i -E "s|^(\s*INFLUXDB_INIT_BUCKET=)(.*)|\1$BUCKET|" /home/$SUDO_USER/staging/knxLogger/Raspberry\ Pi/influxDB.env
	sed -i -E "s|^(\s*INFLUXDB_INIT_RETENTION=)(.*)|\1$RETENTION|" /home/$SUDO_USER/staging/knxLogger/Raspberry\ Pi/influxDB.env
	sed -i -E "s|^(\s*INFLUXDB_INIT_HOST=)(.*)|\1$HOST|" /home/$SUDO_USER/staging/knxLogger/Raspberry\ Pi/influxDB.env
	sed -i -E "s|^(\s*GRAFANA_PORT=)(.*)|\1$PORT|" /home/$SUDO_USER/staging/knxLogger/Raspberry\ Pi/influxDB.env
	NEW_FILE_CHECKSUM=$(md5sum /home/$SUDO_USER/staging/knxLogger/Raspberry\ Pi/influxDB.env)
	if [[ $NEW_FILE_CHECKSUM != $OLD_FILE_CHECKSUM ]];
	then
		echo -e ""$GREEN"Changed values written to file OK."$RESET""
	else
		echo -e ""$GREEN"No changes made"$RESET""
	fi
	echo ''


	# -----------------------------------
	# LET'S START IT UP!
	# -----------------------------------

	systemctl daemon-reload
	if [[ $NEW_KNXD_CHECKSUM != $OLD_KNXD_CHECKSUM ]];
	then
		# The config has changed. Restart the services to pickup the new values
		echo -e ""$GREEN"Config has changed. Restarting knxd.socket"$RESET""
		systemctl restart knxd.socket
		echo -e ""$GREEN"Config has changed. Restarting knxd.service"$RESET""
		systemctl restart knxd.service
	else
		if ! systemctl is-active --quiet knxd.socket;  then echo "Starting knxd.socket";  systemctl start knxd.socket; fi
		if ! systemctl is-active --quiet knxd.service; then echo "Starting knxd.service"; systemctl start knxd.service; fi
	fi

	# chmod 644 /etc/systemd/system/knxLogger.service - TODO. DO I NEED THIS??
	echo -e ""$GREEN"TODO - Enabling knxLogger.service"$RESET""
	#systemctl enable knxLogger.service
	#systemctl start knxLogger.service


	echo -e "\n"$GREEN"Cleanup. Deleting packages NLR"$RESET""
	sudo rm -f influxdb2_2.7.8-1_arm64.deb
	sudo rm -f grafana-enterprise_11.1.3_arm64.deb
	rm -rfd /home/${SUDO_USER}/staging/

	echo ''
	echo -e "\n"$GREEN"Done!"$RESET""
	echo ''
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
	echo ''
	HOSTNAME=$(uname -n)
	echo $HOSTNAME
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
	set +e #Suspend the error trap
	isKnxd=$(command -v knxd)
	set -e #Resume the error trap
	if [[ $isKnxd ]];
	then
		echo -e ""$GREEN"PASS:"$RESET" knxd installed"
	else
		echo -e ""$YELLOW"FAIL:"$RESET" knxd NOT installed"
	fi

	PIP_LIST=$(pip list)
	# TODO: This bit's still broken, always reports FALSE
	if [[ $PIP_LIST == *"knxdclient"* ]];
	then
		echo -e ""$GREEN"PASS:"$RESET" knxdclient installed"
	else
		echo -e ""$YELLOW"FAIL:"$RESET" knxdclient NOT installed"
	fi
	if [[ $PIP_LIST == *"requests"* ]];
	then
		echo -e ""$GREEN"PASS:"$RESET" requests installed"
	else
		echo -e ""$YELLOW"FAIL:"$RESET" requests NOT installed"
	fi

	set +e #Suspend the error trap
	isTelegraf=$(dpkg -s telegraf 2>/dev/null)
	set -e #Resume the error trap
	if [[ $isTelegraf  ]];
	then
		echo -e ""$GREEN"PASS:"$RESET" telegraf installed"
	else
		echo -e ""$YELLOW"FAIL:"$RESET" telegraf NOT installed"
	fi

	set +e #Suspend the error trap
	isInfluxd=$(command -v influxd)
	set -e #Resume the error trap
	if [[ $isInfluxd ]];
	then
		echo -e ""$GREEN"PASS:"$RESET" influxd installed"
	else
		echo -e ""$YELLOW"FAIL:"$RESET" influxd NOT installed"
	fi

	set +e #Suspend the error trap
	isGrafana=$(dpkg -s grafana-enterprise 2>/dev/null)
	set -e #Resume the error trap
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
			echo -e ""$GREEN"PASS:"$RESET" /etc/udev/rules.d/80-knxd.rules is good"
		else
			echo -e ""$YELLOW"FAIL:"$RESET" /etc/udev/rules.d/80-knxd.rules exists but contains either muitple lines or incorrect content"
		fi
	else
		echo -e ""$YELLOW"FAIL:"$RESET" UDEV file does not exist. Re-run setup or check TTY config"
	fi

	if grep -q -E " -n $HOSTNAME (.*)--layer2=tpuarts:/dev/ttyKNX1" /etc/knxd.conf;
	then
		echo -e ""$GREEN"PASS:"$RESET" /etc/knxd.conf is good"
	else
		echo -e ""$YELLOW"FAIL:"$RESET" /etc/knxd.conf is missing required config. Re-run setup"
	fi

	echo ''
	echo "Test knxd's access to the port with 'knxtool vbusmonitor1 ip:localhost'"
	echo ''
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
