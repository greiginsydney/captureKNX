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
# This script is part of the captureKNX project, which logs all KNX bus traffic to an InfluxDb for reporting via Grafana
# https://github.com/greiginsydney/captureKNX
# https://greiginsydney.com/captureKNX



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
					echo -e "\nVirtual environment NOT active. Attempting to activate"
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
		echo -e "If that fails, check you have correctly created the required VENV. Review \nReview \nhttps://github.com/greiginsydney/captureKNX/blob/bookworm/docs/step1-setup-the-Pi.md"
		echo ''
		exit
	fi
}


setup1()
{
	RESULT=$(test_64bit)
	if [[ $RESULT != "64" ]];
	then
		echo -e "\n"$YELLOW"This device is running a 32-bit operating system, which is not supported."$RESET""
		echo -e "\n"$YELLOW"(InfluxDB requires a 64-bit OS)"$RESET""
		echo -e "\n"$YELLOW"Check the docos and re-flash your memory card/SSH"$RESET""
		exit 1
	fi

	mkdir -p /home/$SUDO_USER/captureKNX/log
	chown $SUDO_USER:$SUDO_USER /home/$SUDO_USER/captureKNX/
	mkdir -p /home/$SUDO_USER/staging
	#cd /home/$SUDO_USER/captureKNX

	if [[ -d /home/${SUDO_USER}/staging/captureKNX/Raspberry\ Pi ]];
	then
		echo -e "\n"$GREEN"Moving repo files."$RESET""

		# Python files: captureKNX, decode_project, decode_dpt & common.py:
		find /home/${SUDO_USER}/staging/captureKNX/Raspberry\ Pi/ -maxdepth 1 -type f -name '*.py*' -exec mv -fv {} /home/${SUDO_USER}/captureKNX/ \;

		# captureKNX.service:
		if [ -f /home/${SUDO_USER}/staging/captureKNX/Raspberry\ Pi/captureKNX.service ];
		then
			if cmp -s /home/${SUDO_USER}/staging/captureKNX/Raspberry\ Pi/captureKNX.service /etc/systemd/system/captureKNX.service;
			then
				echo "Skipped: the file '/etc/systemd/system/captureKNX.service' already exists & the new version is unchanged"
			else
				mv -fv /home/${SUDO_USER}/staging/captureKNX/Raspberry\ Pi/captureKNX.service /etc/systemd/system/captureKNX.service
			fi
		fi

		# telegraf.conf:
		if [ -f /home/${SUDO_USER}/staging/captureKNX/Raspberry\ Pi/telegraf.conf ];
		then
			if cmp -s /home/${SUDO_USER}/staging/captureKNX/Raspberry\ Pi/telegraf.conf /etc/telegraf/telegraf.conf;
			then
				echo "Skipped: the file '/etc/telegraf/telegraf.conf' already exists & the new version is unchanged"
			else
				if [ -f /etc/telegraf/telegraf.conf ];
				then
					echo "Skipped: a customised version of '/etc/telegraf/telegraf.conf' already exists"
				else
					mkdir -p /etc/telegraf/
					mv -fv /home/${SUDO_USER}/staging/captureKNX/Raspberry\ Pi/telegraf.conf /etc/telegraf/telegraf.conf
				fi
			fi
		fi

		# grafana-source.yaml:
		if [ -f /home/${SUDO_USER}/staging/captureKNX/Raspberry\ Pi/grafana/grafana-source.yaml ];
		then
			if cmp -s /home/${SUDO_USER}/staging/captureKNX/Raspberry\ Pi/grafana/grafana-source.yaml /etc/grafana/provisioning/datasources/grafana-source.yaml;
			then
				echo "Skipped: the file /etc/grafana/provisioning/datasources/grafana-source.yaml' already exists & the new version is unchanged"
			else
				[ -f /etc/grafana/provisioning/datasources/grafana-source.yaml ] && mv -fv /etc/grafana/provisioning/datasources/grafana-source.yaml /etc/grafana/provisioning/datasources/grafana-source.yaml.old
				mkdir -p /etc/grafana/provisioning/datasources/
				mv -fv /home/${SUDO_USER}/staging/captureKNX/Raspberry\ Pi/grafana/grafana-source.yaml /etc/grafana/provisioning/datasources/grafana-source.yaml
			fi
		fi

		# captureKNX-dashboards.yaml:
		if [ -f /home/${SUDO_USER}/staging/captureKNX/Raspberry\ Pi/grafana/captureKNX-dashboards.yaml ];
		then
			if cmp -s /home/${SUDO_USER}/staging/captureKNX/Raspberry\ Pi/grafana/captureKNX-dashboards.yaml /etc/grafana/provisioning/dashboards/captureKNX-dashboards.yaml;
			then
				echo "Skipped: the file /etc/grafana/provisioning/dashboards/captureKNX-dashboards.yaml already exists & the new version is unchanged"
			else
				[ -f /etc/grafana/provisioning/dashboards/captureKNX-dashboards.yaml ] && mv -fv /etc/grafana/provisioning/dashboards/captureKNX-dashboards.yaml /etc/grafana/provisioning/dashboards/captureKNX-dashboards.yaml.old
				mkdir -p /etc/grafana/provisioning/dashboards/
				mv -fv /home/${SUDO_USER}/staging/captureKNX/Raspberry\ Pi/grafana/captureKNX-dashboards.yaml /etc/grafana/provisioning/dashboards/captureKNX-dashboards.yaml
			fi
		fi

		# group-monitor.json:
		if [ -f /home/${SUDO_USER}/staging/captureKNX/Raspberry\ Pi/grafana/group-monitor.json ];
		then
			if cmp -s /home/${SUDO_USER}/staging/captureKNX/Raspberry\ Pi/grafana/group-monitor.json /etc/grafana/provisioning/dashboards/group-monitor.json;
			then
				echo "Skipped: the file /etc/grafana/provisioning/dashboards/group-monitor.json already exists & the new version is unchanged"
			else
				if [ -f /etc/grafana/provisioning/dashboards/group-monitor.json ];
				then
					# File already exists. Copy new version over as ".new" (will not be used by Grafana)
					echo "A newer version of the file 'group-monitor.json' has been copied to /etc/grafana/provisioning/dashboards/ as '.new'"
					mv -fv /home/${SUDO_USER}/staging/captureKNX/Raspberry\ Pi/grafana/group-monitor.json /etc/grafana/provisioning/dashboards/group-monitor.json.new
				else
					# Does not exist. Create directory and copy the file
					mkdir -p /etc/grafana/provisioning/dashboards/
					mv -fv /home/${SUDO_USER}/staging/captureKNX/Raspberry\ Pi/grafana/group-monitor.json /etc/grafana/provisioning/dashboards/group-monitor.json
				fi
			fi
		fi

		# sample-graphical-dashboard.json:
		if [ -f /home/${SUDO_USER}/staging/captureKNX/Raspberry\ Pi/grafana/sample-graphical-dashboard.json ];
		then
			if cmp -s /home/${SUDO_USER}/staging/captureKNX/Raspberry\ Pi/grafana/sample-graphical-dashboard.json /etc/grafana/provisioning/dashboards/sample-graphical-dashboard.json;
			then
				echo "Skipped: the file /etc/grafana/provisioning/dashboards/sample-graphical-dashboard.json' already exists & the new version is unchanged"
			else
				if [ -f /etc/grafana/provisioning/dashboards/sample-graphical-dashboard.json ];
				then
					# File already exists. Copy new version over as ".new" (will not be used by Grafana)
					echo "A newer version of the file 'sample-graphical-dashboard.json' has been copied to /etc/grafana/provisioning/dashboards/ as '.new'"
					mv -fv /home/${SUDO_USER}/staging/captureKNX/Raspberry\ Pi/grafana/sample-graphical-dashboard.json /etc/grafana/provisioning/dashboards/sample-graphical-dashboard.json.new
				else
					# Does not exist. Create directory and copy the file
					mkdir -p /etc/grafana/provisioning/dashboards/
					mv -fv /home/${SUDO_USER}/staging/captureKNX/Raspberry\ Pi/grafana/sample-graphical-dashboard.json /etc/grafana/provisioning/dashboards/sample-graphical-dashboard.json
				fi
			fi
		fi

		# captureKNX.env:
		if [ -f /home/${SUDO_USER}/staging/captureKNX/Raspberry\ Pi/captureKNX.env ];
		then
			if cmp -s /home/${SUDO_USER}/staging/captureKNX/Raspberry\ Pi/captureKNX.env /etc/influxdb/captureKNX.env;
			then
				echo "Skipped: the file '/etc/influxdb/captureKNX.env' already exists & the new version is unchanged"
			else
				if [ -f /etc/influxdb/captureKNX.env ];
				then
					echo "Skipped: a customised version of '/etc/influxdb/captureKNX.env' already exists"
				else
					mkdir -p /etc/influxdb/
					mv -fv /home/${SUDO_USER}/staging/captureKNX/Raspberry\ Pi/captureKNX.env /etc/influxdb/captureKNX.env
				fi
			fi
		fi

		# captureKNX.logrotate:
		if [ -f /home/${SUDO_USER}/staging/captureKNX/Raspberry\ Pi/captureKNX.logrotate ];
		then
			if cmp -s /home/${SUDO_USER}/staging/captureKNX/Raspberry\ Pi/captureKNX.logrotate /etc/logrotate.d/captureKNX.logrotate;
			then
				echo "Skipped: the file '/etc/logrotate.d/captureKNX.logrotate' already exists & the new version is unchanged"
			else
				mv -fv /home/${SUDO_USER}/staging/captureKNX/Raspberry\ Pi/captureKNX.logrotate /etc/logrotate.d/captureKNX.logrotate
			fi
		fi
		if ! chown --quiet root /etc/logrotate.d/captureKNX.logrotate ;
		then
			echo -e "\n"$YELLOW"Error trying to 'chown' logrotate"$RESET""
		fi
		if ! chgrp --quiet root /etc/logrotate.d/captureKNX.logrotate ;
		then
			echo -e "\n"$YELLOW"Error trying to 'chgrp' logrotate"$RESET""
		fi

		touch /home/${SUDO_USER}/captureKNX/log/captureKNX.log
		chown $SUDO_USER:$SUDO_USER /home/$SUDO_USER/captureKNX/log/captureKNX.log

		# version:
		if [ -f /home/${SUDO_USER}/staging/captureKNX/Raspberry\ Pi/version ];
		then
			mv -fv /home/${SUDO_USER}/staging/captureKNX/Raspberry\ Pi/version /home/${SUDO_USER}/captureKNX/version
		fi

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
		rm -rf /home/$SUDO_USER/staging/knxd
		mkdir -pv /home/$SUDO_USER/staging/knxd
		cd /home/${SUDO_USER}/staging/knxd/
		apt-get install git-core -y
		git clone -b debian https://github.com/knxd/knxd.git
		sh knxd/install-debian.sh

		# Paste in captureKNX's new default device addresses:
		sed -i -E "s|(^KNXD_OPTS.*-e )([[:digit:]]+.[[:digit:]]+.[[:digit:]]+)( .*$)|\11.1.250\3|" /etc/knxd.conf
		sed -i -E "s|(^KNXD_OPTS.*-E )([[:digit:]]+.[[:digit:]]+.[[:digit:]]+)(:.*$)|\11.1.251\3|" /etc/knxd.conf
		sed -i -E "s|(^KNXD_OPTS.*-E )([[:digit:]]+.[[:digit:]]+.[[:digit:]]+:)([[:digit:]]+)( .*$)|\1\21\4|" /etc/knxd.conf
		# Set data source to be ttyKNX1 & assume Tijl's HAT:
		sed -i -E "s|^(KNXD_OPTS=.*)( -b ip:)(.*)|\1 -b tpuarts:/dev/ttyKNX1\3|" /etc/knxd.conf
	else
		echo -e "\n"$GREEN"knxd is already installed - skipping"$RESET""
		# knxdVersion=$(dpkg -s knxd | grep "Version: " | cut -d ' ' -f2)
		# echo -e "\rCurrent  installed version of knxd = $knxdVersion"
		# TODO: Check version and update if there's newer.
	fi

	echo -e "\n"$GREEN"Installing KNXDclient"$RESET""
	sudo  -u ${SUDO_USER} bash -c "source /home/${SUDO_USER}/venv/bin/activate && pip3 install knxdclient"
	echo -e "\n"$GREEN"Installing requests"$RESET""
	sudo -u ${SUDO_USER} bash  -c "source /home/${SUDO_USER}/venv/bin/activate && python3 -m pip install requests"

	set +e #Suspend the error trap
	isTelegraf=$(dpkg -s telegraf 2>/dev/null)
	set -e #Resume the error trap
	if [[ ! $isTelegraf  ]];
	then
		echo -e "\n"$GREEN"Installing telegraf"$RESET""
		rm -rf /home/$SUDO_USER/staging/telegraf
		mkdir -pv /home/$SUDO_USER/staging/telegraf
		cd /home/${SUDO_USER}/staging/telegraf/
		curl -s https://repos.influxdata.com/influxdata-archive.key > influxdata-archive.key
		echo '943666881a1b8d9b849b74caebf02d3465d6beb716510d86a39f6c8e8dac7515 influxdata-archive.key' | sha256sum -c && cat influxdata-archive.key | gpg --dearmor | sudo tee /etc/apt/trusted.gpg.d/influxdata-archive.gpg > /dev/null
		echo 'deb [signed-by=/etc/apt/trusted.gpg.d/influxdata-archive.gpg] https://repos.influxdata.com/debian stable main' | sudo tee /etc/apt/sources.list.d/influxdata.list
		apt-get update && sudo apt-get install telegraf -y
	else
		echo -e "\n"$GREEN"telegraf is already installed - skipping"$RESET""
		# telegrafVersion=$(telegraf --version | cut -d ' ' -f2)
		# echo -e "\rCurrent  installed version of telegraf = $telegrafVersion"
		# TODO: Check version and update if there's newer.
	fi

	# Suppress noisy error message in OOB telegraf.service (n/a on Debian/Raspbian):
	if grep -q '^ImportCredential=telegraf.*'  /lib/systemd/system/telegraf.service;
	then
		sed -i -E "s|^(\s*ImportCredential=)(.*)$|# \1\2|g" /lib/systemd/system/telegraf.service
	fi


	set +e #Suspend the error trap
	isInfluxd=$(command -v influxd)
	set -e #Resume the error trap
	if [[ ! $isInfluxd ]];
	then
		echo -e "\n"$GREEN"Installing InfluxDB "$RESET""
		apt-get install influxdb2 -y
	else
		echo -e "\n"$GREEN"InfluxDB is already installed - skipping"$RESET""
		# influxVersion=$(influxd version | cut -d ' ' -f2)
		# echo -e "\rCurrent  installed version of InfluxDB = $influxVersion"
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
	else
		echo -e "\n"$GREEN"grafana is already installed - skipping"$RESET""
		# grafanaVersion=$(dpkg -s grafana-enterprise | grep "Version: " | cut -d ' ' -f2)
		# echo -e "\rCurrent  installed version of grafana = $grafanaVersion"
		# TODO: Check version and update if there's newer.
	fi

	# grafana-source.yaml:
	if [ -f /home/${SUDO_USER}/staging/captureKNX/Raspberry\ Pi/grafana-source.yaml ];
	then
		if cmp -s /home/${SUDO_USER}/staging/captureKNX/Raspberry\ Pi/grafana-source.yaml /etc/grafana/provisioning/datasources/grafana-source.yaml;
		then
			echo "Skipped: the file '/etc/grafana/provisioning/datasources/grafana-source.yaml' already exists & the new version is unchanged"
		else
			mv -fv /home/${SUDO_USER}/staging/captureKNX/Raspberry\ Pi/grafana-source.yaml /etc/grafana/provisioning/datasources/grafana-source.yaml
		fi
	fi

	if [ $SUDO_USER != 'pi' ];
	then
		echo -e ""$GREEN"Changing user from default:"$RESET" Updated hard-coded user references to new user $SUDO_USER"
		sed -i "s|/pi/|/$SUDO_USER/|g" /etc/systemd/system/captureKNX.service
		sed -i "s|User=pi|User=$SUDO_USER|g" /etc/systemd/system/captureKNX.service
		sed -i "s|/pi/|/$SUDO_USER/|g" /etc/logrotate.d/captureKNX.logrotate
	fi

	# hciuart needs to be stopped and disabled before we can control the TTY port
	systemctl stop hciuart.service
	systemctl disable hciuart.service
	systemctl mask hciuart.service


	# Customise /boot/firmware/config.txt:
	NEEDS_REBOOT=''
	if ! grep -q '# Added by setup.sh for captureKNX' /boot/firmware/config.txt;
	then
		echo -e "\n"$GREEN"Adding UART changes to config.txt"$RESET""
		echo -e '\n# Added by setup.sh for captureKNX' >> /boot/firmware/config.txt
	fi

	if ! grep -q '^enable_uart=1' /boot/firmware/config.txt;
	then
		echo -e 'enable_uart=1' >> /boot/firmware/config.txt
		NEEDS_REBOOT='yes'
	fi

	if ! grep -q '^dtoverlay=disable-bt' /boot/firmware/config.txt;
	then
		echo -e 'dtoverlay=disable-bt' >> /boot/firmware/config.txt
		NEEDS_REBOOT='yes'
	fi

	if ! grep -q '^dtoverlay=pi3-disable-bt' /boot/firmware/config.txt;
	then
		echo -e 'dtoverlay=pi3-disable-bt' >> /boot/firmware/config.txt
		NEEDS_REBOOT='yes'
	fi

	if ! grep -q '^dtparam=uart0' /boot/firmware/config.txt;
	then
		echo -e 'dtparam=uart0' >> /boot/firmware/config.txt
		NEEDS_REBOOT='yes'
	fi

	if [[ $NEEDS_REBOOT ]];
	then
		touch /home/${SUDO_USER}/setup1_complete
		echo ''
		echo 'A reboot is required before continuing. Reboot and simply re-run the script'
		prompt_for_reboot
	else
		echo -e "\n"$GREEN"UART changes to config.txt already exist"$RESET""
	fi
}


setup2()
{
	if [ -f /home/${SUDO_USER}/setup1_complete ];
	then
		rm -rf /home/${SUDO_USER}/setup1_complete
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
		touch /home/${SUDO_USER}/setup2_complete
		echo ''
		echo 'A reboot is required before continuing. Reboot and simply re-run the script'
		prompt_for_reboot
	fi
}


setup3()
{
	if [ -f /home/${SUDO_USER}/setup2_complete ];
	then
		rm -rf /home/${SUDO_USER}/setup2_complete
	fi

	# Customise knxd.conf
	# Extract the current values:
	echo -e "\n"$GREEN"Customising knxd config."$RESET"\n"
	echo "If you're unsure, just hit Enter/Return"

	# This is the default: KNXD_OPTS="-e 0.0.1 -E 0.0.2:8 -u /tmp/eib -b ip:"
	# Needs to look like:  KNXD_OPTS="-e 0.0.1 -E 0.0.2:8 -n captureKNX -b tpuarts:/dev/ttyKNX1"  (Tijl)
	#         or           KNXD_OPTS="-e 0.0.1 -E 0.0.2:8 -n captureKNX -b ft12cemi:/dev/ttyKNX1" (Weinzierl)

	#Extract the current values:
	OLD_MYADDRESS=$(sed -n -E 's/^KNXD_OPTS.*-e ([[:digit:]]+.[[:digit:]]+.[[:digit:]]+) .*$/\1/p' /etc/knxd.conf)
	OLD_CLTADDR=$(sed -n -E 's/^KNXD_OPTS.* -E ([[:digit:]]+.[[:digit:]]+.[[:digit:]]+):.*$/\1/p' /etc/knxd.conf)
	OLD_CLTNBR=$(sed -n -E 's/^KNXD_OPTS.* -E [[:digit:]]+.[[:digit:]]+.[[:digit:]]+:([[:digit:]]+) .*$/\1/p' /etc/knxd.conf)

	HAT_TYPE=$(sed -n -E 's/^KNXD_OPTS.* (.*):\/dev\/ttyKNX1\"$/\1/p' /etc/knxd.conf)
	if [[ $HAT_TYPE == "tpuarts" ]];
	then
		HAT_INDEX=0
	else
		HAT_INDEX=1
	fi
	HATS=("Tijl/Tindie" "Weinzierl kBerry")
	HAT_METHOD=("tpuarts" "ft12cemi")
	echo ''
	echo "captureKNX is set to use the ${HATS[HAT_INDEX]} HAT"
	read -p "Change to the ${HATS[1 - HAT_INDEX]} HAT? [y/N]: " CHG_HAT
	case $CHG_HAT in
		(y|Y)
			HAT_TYPE=${HAT_METHOD[1 - HAT_INDEX]}
			;;
		(*)
			:
			;;
	esac

	read -e -i "$OLD_MYADDRESS" -p 'My KNX network client address            = ' MYADDRESS
	if [[ ! $OLD_MYADDRESS == $MYADDRESS ]];
	then
		# The user changed the start address. Add one and offer it as the suggested client start address:
		PREFIX=$(echo $MYADDRESS | cut -d "." -f-2)
		SUFFIX=$(echo $MYADDRESS | cut -d "." -f3)
		SUFFIX=$((SUFFIX+1))
		OLD_CLTADDR=$PREFIX.$SUFFIX
	fi
	read -e -i "$OLD_CLTADDR"   -p 'Sending KNX network client start address = ' CLIENTADDR
	read -e -i "$OLD_CLTNBR"    -p 'Sending KNX network client count         = ' CLIENTNBR

	OLD_KNXD_CHECKSUM=$(md5sum /etc/knxd.conf)
	#Paste in the new settings:
	sed -i -E "s|(^KNXD_OPTS.*-e )([[:digit:]]+.[[:digit:]]+.[[:digit:]]+)( .*$)|\1$MYADDRESS\3|" /etc/knxd.conf
	sed -i -E "s|(^KNXD_OPTS.*-E )([[:digit:]]+.[[:digit:]]+.[[:digit:]]+)(:.*$)|\1$CLIENTADDR\3|" /etc/knxd.conf
	sed -i -E "s|(^KNXD_OPTS.*-E )([[:digit:]]+.[[:digit:]]+.[[:digit:]]+:)([[:digit:]]+)( .*$)|\1\2$CLIENTNBR\4|" /etc/knxd.conf
	sed -i -E "s|(^KNXD_OPTS.*-b )(.*)(:/dev/ttyKNX1\")$|\1$HAT_TYPE\3|" /etc/knxd.conf

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
	NEW_KNXD_CHECKSUM=$(md5sum /etc/knxd.conf)
	if [[ $NEW_KNXD_CHECKSUM != $OLD_KNXD_CHECKSUM ]];
	then
		echo -e ""$GREEN"Changed values written to /etc/knxd.conf OK"$RESET""
	else
		echo -e ""$GREEN"No changes made to /etc/knxd.conf"$RESET""
	fi


	# Customise influxDB
	# Extract the current values:
	echo -e "\n"$GREEN"Customising influxDB config."$RESET"\n"
	echo "If you're unsure, just hit Enter/Return"

	# Extract the current values:
	OLD_USERNAME=$(sed -n -E 's/^\s*INFLUXDB_INIT_USERNAME=(.*)$/\1/p' /etc/influxdb/captureKNX.env)
	OLD_PASSWORD=$(sed -n -E 's/^\s*INFLUXDB_INIT_PASSWORD=(.*)$/\1/p' /etc/influxdb/captureKNX.env)

	# We won't prompt the user for the token but do it here:
	if grep -q "INFLUXDB_INIT_ADMIN_TOKEN=changeme" /etc/influxdb/captureKNX.env;
	then
		TOKEN=$(openssl rand -hex 32)
	else
		TOKEN=$(sed -n -E 's/^\s*INFLUXDB_INIT_ADMIN_TOKEN=(.*)$/\1/p' /etc/influxdb/captureKNX.env)
	fi

	OLD_ORG=$(sed -n -E 's/^\s*INFLUXDB_INIT_ORG=(.*)$/\1/p' /etc/influxdb/captureKNX.env)
	OLD_BUCKET=$(sed -n -E 's/^\s*INFLUXDB_INIT_BUCKET=(.*)$/\1/p' /etc/influxdb/captureKNX.env)
	OLD_RETENTION=$(sed -n -E 's/^\s*INFLUXDB_INIT_RETENTION=(.*)$/\1/p' /etc/influxdb/captureKNX.env)
	# I'm not prompting the user, however these still need to be read so they can be stuffed into influx setup:
	HOST=$(sed -n -E 's/^\s*INFLUXDB_INIT_HOST=(.*)$/\1/p' /etc/influxdb/captureKNX.env)
	PORT=$(sed -n -E 's/^\s*GRAFANA_PORT=(.*)$/\1/p' /etc/influxdb/captureKNX.env)

	read -e -i "$OLD_USERNAME" -p   'INFLUXDB_INIT_USERNAME    = ' USERNAME
	read -e -i "$OLD_PASSWORD" -p   'INFLUXDB_INIT_PASSWORD    = ' PASSWORD
	# read -e -i "$OLD_TOKEN" -p      'INFLUXDB_INIT_ADMIN_TOKEN = ' TOKEN
	read -e -i "$OLD_ORG" -p        'INFLUXDB_INIT_ORG         = ' ORG
	read -e -i "$OLD_BUCKET" -p     'INFLUXDB_INIT_BUCKET      = ' BUCKET
	read -e -i "$OLD_RETENTION" -p  'INFLUXDB_INIT_RETENTION   = ' RETENTION
	# read -e -i "$OLD_HOST" -p       'INFLUXDB_INIT_HOST        = ' HOST
	# read -e -i "$OLD_PORT" -p       'GRAFANA_PORT              = ' PORT

	OLD_INFLUX_CHECKSUM=$(md5sum /etc/influxdb/captureKNX.env)
	#Paste in the new settings. (I used "|" as the delimiter for all, as "/" is in the replacement for the path
	sed -i -E "s|^(\s*INFLUXDB_INIT_USERNAME=)(.*)|\1$USERNAME|"   /etc/influxdb/captureKNX.env
	sed -i -E "s|^(\s*INFLUXDB_INIT_PASSWORD=)(.*)|\1$PASSWORD|"   /etc/influxdb/captureKNX.env
	sed -i -E "s|^(\s*INFLUXDB_INIT_ADMIN_TOKEN=)(.*)|\1$TOKEN|"   /etc/influxdb/captureKNX.env
	sed -i -E "s|^(\s*INFLUXDB_INIT_ORG=)(.*)|\1$ORG|"             /etc/influxdb/captureKNX.env
	sed -i -E "s|^(\s*INFLUXDB_INIT_BUCKET=)(.*)|\1$BUCKET|"       /etc/influxdb/captureKNX.env
	sed -i -E "s|^(\s*INFLUXDB_INIT_RETENTION=)(.*)|\1$RETENTION|" /etc/influxdb/captureKNX.env
	# sed -i -E "s|^(\s*INFLUXDB_INIT_HOST=)(.*)|\1$HOST|"           /etc/influxdb/captureKNX.env
	# sed -i -E "s|^(\s*GRAFANA_PORT=)(.*)|\1$PORT|"                 /etc/influxdb/captureKNX.env
	NEW_INFLUX_CHECKSUM=$(md5sum /etc/influxdb/captureKNX.env)
	if [[ $NEW_INFLUX_CHECKSUM != $OLD_INFLUX_CHECKSUM ]];
	then
		echo -e ""$GREEN"Changed values written to /etc/influxdb/captureKNX.env OK."$RESET""
	else
		echo -e ""$GREEN"No changes made to /etc/influxdb/captureKNX.env"$RESET""
	fi

	# Paste the values into telegraf.conf:
	OLD_TELEGRAF_CHECKSUM=$(md5sum /etc/telegraf/telegraf.conf)
	outputLine=$(sed -n '/^\[\[outputs.influxdb_v2\]\]/=' /etc/telegraf/telegraf.conf) #This is the line number that the output plugin starts at
	if [[ $outputLine ]];
	then
		# Make sure telegraf is using the same values. (These override anything in telegraf.conf)
		if ! grep -q "^token = \"$TOKEN\"$" /etc/telegraf/telegraf.conf;
		then
			sed -i -E "$outputLine,$ s|^(^token = \")(.*)$|\1$TOKEN\"|"   /etc/telegraf/telegraf.conf
		fi
		if ! grep -q "^organization = \"$ORG\"$" /etc/telegraf/telegraf.conf;
		then
			sed -i -E "$outputLine,$ s|^(^organization = \")(.*)$|\1$ORG\"|"   /etc/telegraf/telegraf.conf
		fi
		if ! grep -q "^bucket = \"$BUCKET\"$" /etc/telegraf/telegraf.conf;
		then
			sed -i -E "$outputLine,$ s|^(^bucket = \")(.*)$|\1$BUCKET\"|"   /etc/telegraf/telegraf.conf
		fi
	else
		echo -e ""$YELLOW"Failed to find [[outputs.influxdb_v2]] in /etc/telegraf/telegraf.conf"$RESET""
	fi
	NEW_TELEGRAF_CHECKSUM=$(md5sum /etc/telegraf/telegraf.conf)
	if [[ $NEW_TELEGRAF_CHECKSUM != $OLD_TELEGRAF_CHECKSUM ]];
	then
		echo -e ""$GREEN"Changed values written to /etc/telegraf/telegraf.conf OK."$RESET""
	else
		echo -e ""$GREEN"No changes made to /etc/telegraf/telegraf.conf"$RESET""
	fi

	# Add our custom .env to the service:
	if ! grep -q '^EnvironmentFile=-/etc/influxdb/captureKNX.env' /lib/systemd/system/influxdb.service;
	then
		sed -i '/EnvironmentFile=-\/etc\/default\/influxdb2/a EnvironmentFile=-/etc/influxdb/captureKNX.env' /lib/systemd/system/influxdb.service
	fi
	# echo ''

	# Create initial InfluxDB config:
	# Has it already been created?
	set +e #Suspend the error trap
	isInfluxConfigured=$(influx config list --hide-headers 2>&1)
	set -e #Resume the error trap
	# echo "-----------"
	# echo "OUTPUT >>> $isInfluxConfigured"
	# echo "-----------"
	if [[ ! $isInfluxConfigured ]];
	then
		echo -e "\n"$GREEN"InfluxDB has not been set up"$RESET""

		set +e #Suspend the error trap
		isInfluxSetup=$(influx setup --skip-verify --org $ORG --bucket $BUCKET --retention $RETENTION --username $USERNAME --password $PASSWORD --token $TOKEN --force --hide-headers 2>&1)
		set -e #Resume the error trap
		# echo "OUTPUT >>> $isInfluxSetup"
		if [[ $isInfluxSetup == *"has already been set up"* ]];
		then
			echo -e "\n"$GREEN"InfluxDB has already been set up"$RESET""
		elif [[ $isInfluxSetup =~ $ORG ]];
		then
			echo -e "\n"$GREEN"InfluxDB config created OK"$RESET""
		else
			echo "isInfluxSetup: $isInfluxSetup"
			echo -e ""$YELLOW"Creating the initial InfluxDB config threw an error. Re-run setup and cross your fingers"$RESET""
		fi

	elif [[ $isInfluxConfigured == *"captureKNX"* ]];
	then
		echo -e "\n"$GREEN"Skipping: InfluxDB has already been set up"$RESET""
	fi

	# Create / update initial InfluxDB telegraf config:
	# Does one exist already:
	set +e #Suspend the error trap
	IsInfluxTelegrafs=$(influx telegrafs --hide-headers 2>&1)
	set -e #Resume the error trap
	# echo "OUTPUT >>> $IsInfluxTelegrafs"
	if [[ $IsInfluxTelegrafs == *"unknown command"* ]];
	then
		echo "isTelegrafConfiguration returned: $isTelegrafConfiguration"
		echo -e ""$YELLOW"Querying InfluxDB *telegraf* config threw an error. Re-run setup and cross your fingers"$RESET""
	elif [[ $IsInfluxTelegrafs == *"captureKNX"* ]];
	then
		# Config exists? Run an UPDATE. Pull the ID out of IsInfluxTelegrafs:
		echo -e "\nInfluxDB telegraf config already exists. Updating"
		EXISTING_ID=$(echo $IsInfluxTelegrafs | cut -d ' ' -f1)
		set +e #Suspend the error trap
		isTelegrafUpdated=$(influx telegrafs update -id $EXISTING_ID -n "captureKNX" -d "Created by setup.sh" -f /etc/telegraf/telegraf.conf --hide-headers 2>&1)
		set -e #Resume the error trap
		# echo "OUTPUT >>> $isTelegrafUpdated"
		if [[ $isTelegrafUpdated == *"unknown command"* ]];
		then
			echo "isTelegrafUpdated returned: $isTelegrafUpdated"
			echo -e ""$YELLOW"Querying InfluxDB *telegraf* config threw an error. Re-run setup and cross your fingers"$RESET""
		elif [[ $isTelegrafUpdated == *"captureKNX"* ]];
		then
			echo -e "\n"$GREEN"InfluxDB telegraf config updated OK"$RESET""
		fi
	elif [[ "$IsInfluxTelegrafs" == "" ]];
	then
		echo -e "\n"$GREEN"No InfluxDB *telegraf* config found. Creating new"$RESET""
		# Create new:
		set +e #Suspend the error trap
		isTelegrafConfiguration=$(influx telegrafs create -n "captureKNX" -d "Created by setup.sh" -f /etc/telegraf/telegraf.conf 2>&1)
		set -e #Resume the error trap
		# echo "OUTPUT >>> $isTelegrafConfiguration"
		if [[ $isTelegrafConfiguration == *"has already been set up"* ]];
		then
			# This should never be seen, as the previous test should have captured it:
			echo -e "\n"$GREEN"isTelegrafConfiguration has already been set up"$RESET""
		elif [[ $isTelegrafConfiguration == *"Created by setup.sh"* ]];
		then
			echo -e "\n"$GREEN"InfluxDB telegraf config created OK"$RESET""
		else
			echo "isTelegrafConfiguration returned: $isTelegrafConfiguration"
			echo -e ""$YELLOW"Creating the initial InfluxDB *telegraf* config threw an error. Re-run setup and cross your fingers"$RESET""
		fi
	else
		echo "isTelegrafConfiguration returned: $isTelegrafConfiguration"
		echo -e ""$YELLOW"Querying InfluxDB *telegraf* config threw an unexpected error. Re-run setup and cross your fingers"$RESET""
	fi

	# Copy the TOKEN into the Grafana source yaml file:
	if grep -q "Token changeme" /etc/grafana/provisioning/datasources/grafana-source.yaml;
	then
		sed -i -E "s|^(.*Token )(changeme)(.*)|\1$TOKEN\3|" /etc/grafana/provisioning/datasources/grafana-source.yaml
	fi

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
	fi

	if [[ $NEW_TELEGRAF_CHECKSUM != $OLD_TELEGRAF_CHECKSUM ]];
	then
		# The config has changed. Restart the services to pickup the new values
		echo -e ""$GREEN"Config has changed. Restarting telegraf"$RESET""
		systemctl restart telegraf
	fi

	systemctl enable influxdb
	systemctl restart influxdb
	systemctl enable grafana-server
	systemctl restart grafana-server

	echo -e ""$GREEN"Enabling captureKNX.service"$RESET""
	systemctl enable captureKNX.service
	systemctl restart captureKNX.service

	echo -e "\n"$GREEN"Cleanup. Deleting packages NLR"$RESET""
	apt-get purge bluez -y
 	rm -f influxdb2_2.7.8-1_arm64.deb
	rm -f grafana-enterprise_11.1.3_arm64.deb
	rm -rfd /home/${SUDO_USER}/staging/

	# Add a shortcut for the logs folder:
	ln -sfnv /var/log/ /home/${SUDO_USER}/log

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
	latestcaptureKNXRls=$(curl --silent "https://api.github.com/repos/greiginsydney/captureKNX/releases/latest" | grep '"tag_name":' | sed -E 's/.*"v([^"]+)".*/\1/')
	if [[ "$latestcaptureKNXRls" == "" ]];
	then
		echo -e ""$YELLOW"Latest release of captureKNX is    unknown""$RESET"
	else
		echo "Latest release of captureKNX is    v$latestcaptureKNXRls"
	fi
	if [ -f /home/${SUDO_USER}/captureKNX/version ];
	then
		VERSION=$(cat /home/${SUDO_USER}/captureKNX/version)
		if [[ $VERSION == $latestcaptureKNXRls ]];
		then
			echo -e ""$GREEN"Installed version of captureKNX is v$VERSION""$RESET"
		elif [[ "$latestcaptureKNXRls" == "" ]];
		then
			echo "Installed version of captureKNX is v$VERSION"
		else
			echo -e ""$YELLOW"Installed version of captureKNX is v$VERSION""$RESET"
		fi
	else
		echo -e ""$YELLOW"Version file not found"$RESET""
	fi
	echo ''
	HOSTNAME=$(uname -n)
	echo $HOSTNAME
	cat /proc/device-tree/model
	echo ''
	release=$(sed -n -E 's/^PRETTY_NAME="(.*)"$/\1/p' /etc/os-release)
	echo $release

	# TY Jesse Nickles https://stackoverflow.com/a/71674677/13102734
	DISK_SIZE_TOTAL=$(df -kh . | tail -n1 | awk '{print $2}')
	DISK_SIZE_FREE=$(df -kh . | tail -n1 | awk '{print $4}')
	DISK_PERCENT_USED=$(df -kh . | tail -n1 | awk '{print $5}')
	echo "$DISK_SIZE_FREE available out of $DISK_SIZE_TOTAL total ($DISK_PERCENT_USED used)"

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
		knxdVersion=$(dpkg -s knxd | grep "Version: " | cut -d ' ' -f2)
		echo -e ""$GREEN"PASS:"$RESET" knxd installed ($knxdVersion)"
	else
		echo -e ""$YELLOW"FAIL:"$RESET" knxd NOT installed"
	fi

	isKnxdClient=$(find /home/${SUDO_USER}/venv -type d -name knxdclient)
	if [[ $isKnxdClient ]];
	#if [[ -d /home/${SUDO_USER}/venv/lib knxdclient ]];
	then
		echo -e ""$GREEN"PASS:"$RESET" KNXDclient installed"
	else
		echo -e ""$YELLOW"FAIL:"$RESET" KNXDclient NOT installed"
	fi

	PIP_LIST=$(pip3 list)
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
		telegrafVersion=$(telegraf --version | cut -d ' ' -f2)
		echo -e ""$GREEN"PASS:"$RESET" telegraf installed ($telegrafVersion)"
	else
		echo -e ""$YELLOW"FAIL:"$RESET" telegraf NOT installed"
	fi

	set +e #Suspend the error trap
	isInfluxd=$(command -v influxd)
	set -e #Resume the error trap
	if [[ $isInfluxd ]];
	then
		influxVersion=$(influxd version | cut -d ' ' -f2)
		echo -e ""$GREEN"PASS:"$RESET" InfluxDB installed ($influxVersion)"
	else
		echo -e ""$YELLOW"FAIL:"$RESET" InfluxDB NOT installed"
	fi

	set +e #Suspend the error trap
	isInfluxCLI=$(command -v influx)
	set -e #Resume the error trap
	if [[ $isInfluxd ]];
	then
		echo -e ""$GREEN"PASS:"$RESET" InfluxCLI installed"
	else
		echo -e ""$YELLOW"FAIL:"$RESET" InfluxCLI NOT installed"
	fi

	set +e #Suspend the error trap
	isGrafana=$(dpkg -s grafana-enterprise 2>/dev/null)
	set -e #Resume the error trap
	if [[ $isGrafana ]];
	then
		grafanaVersion=$(dpkg -s grafana-enterprise | grep "Version: " | cut -d ' ' -f2)
		echo -e ""$GREEN"PASS:"$RESET" grafana installed ($grafanaVersion)"
	else
		echo -e ""$YELLOW"FAIL:"$RESET" grafana NOT installed"
	fi
	echo '-------------------------------------'
	if [[ $isKnxd ]]; then
		systemctl is-active --quiet knxd.service   && printf ""$GREEN"PASS:"$RESET" %-15s service is running\n" knxd.service        || printf ""$YELLOW"FAIL:"$RESET" %-15s service is dead\n" knxd.service
		systemctl is-active --quiet knxd.socket    && printf ""$GREEN"PASS:"$RESET" %-15s service is running\n" knxd.socket         || printf ""$YELLOW"FAIL:"$RESET" %-15s service is dead\n" knxd.socket; fi
	systemctl is-active --quiet captureKNX          && printf ""$GREEN"PASS:"$RESET" %-15s service is running\n" captureKNX           || printf ""$YELLOW"FAIL:"$RESET" %-15s service is dead\n" captureKNX
	if [[ $isTelegraf  ]]; then
		systemctl is-active --quiet telegraf       && printf ""$GREEN"PASS:"$RESET" %-15s service is running\n" telegraf            || printf ""$YELLOW"FAIL:"$RESET" %-15s service is dead\n" telegraf; fi
	if [[ $isInfluxd ]]; then
		systemctl is-active --quiet influxd        && printf ""$GREEN"PASS:"$RESET" %-15s service is running\n" influxd             || printf ""$YELLOW"FAIL:"$RESET" %-15s service is dead\n" influxd; fi
	if [[ $isGrafana ]]; then
		systemctl is-active --quiet grafana-server && printf ""$GREEN"PASS:"$RESET" %-15s service is running\n" grafana             || printf ""$YELLOW"FAIL:"$RESET" %-15s service is dead\n" grafana; fi
	systemctl is-active --quiet hciuart.service    && printf ""$YELLOW"FAIL:"$RESET" %-15s service is RUNNING. (That's bad)\n" hciuart.service    || printf ""$GREEN"PASS:"$RESET" %-15s service is dead - which is good\n" hciuart.service

	echo '-------------------------------------'
	test_config=0
	if grep -q '# Added by setup.sh for captureKNX' /boot/firmware/config.txt; then
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
			echo -e ""$YELLOW"FAIL:"$RESET" /etc/udev/rules.d/80-knxd.rules exists but contains either multiple lines or incorrect content"
		fi
	else
		echo -e ""$YELLOW"FAIL:"$RESET" UDEV file does not exist. Re-run setup or check TTY config"
	fi

	if grep -q -E " -n $HOSTNAME (.*)-b tpuarts:/dev/ttyKNX1" /etc/knxd.conf;
	then
		echo -e ""$GREEN"PASS:"$RESET" /etc/knxd.conf is good. Configured for Tijl/Tindie HAT"
	elif grep -q -E " -n $HOSTNAME (.*)-b ft12cemi:/dev/ttyKNX1" /etc/knxd.conf;
	then
		echo -e ""$GREEN"PASS:"$RESET" /etc/knxd.conf is good. Configured for Weinzierl kBerry HAT"
	else
		echo -e ""$YELLOW"FAIL:"$RESET" /etc/knxd.conf is missing required config. Re-run setup"
	fi

	if [ -d /home/${SUDO_USER}/log ];
	then
		echo -n "Checking /home/${SUDO_USER}/log/telegraf/telegraf.log"
		telegraf_error=$(sed -n -E '/^(.*) (.*)field type conflict(.*)$/h;${x;p;}' /home/${SUDO_USER}/log/telegraf/telegraf.log)
		if [[ $telegraf_error ]];
		then
			echo -e '\r-------------------------------------      '
			echo -e "\r"$YELLOW"FAIL:"$RESET" /home/${SUDO_USER}/log/telegraf/telegraf.log shows a 'field type conflict'. Telegrams are being discarded"
			echo ''
			echo $telegraf_error
		else
			echo -e "\r"$GREEN"PASS:"$RESET" /home/${SUDO_USER}/log/telegraf/telegraf.log logged no 'field type conflicts'"
		fi
	else
		echo -e '\r-------------------------------------      '
		echo -e "\r"$YELLOW"FAIL: SETUP HAS NOT COMPLETED. Re-run setup"$RESET""
	fi

	echo '-------------------------------------'

	isKnxProject=$(find /home/${SUDO_USER}/ -type f -name '*.knxproj' -printf '%T@ %p\n' | sort -n | tail -1 | cut -f3- -d "/")
	if [[ $isKnxProject ]];
	then
		echo -e ""$GREEN"PASS:"$RESET" knx project file $isKnxProject found"
	else
		echo -e ""$YELLOW"FAIL:"$RESET" knx project file NOT found"
		echo -e "      Copy one across to the /home/${SUDO_USER}/ folder and 'sudo systemctl restart captureKNX'"
	fi

	echo '-------------------------------------'
	echo ''
	echo "Test knxd's access to the port with 'knxtool vbusmonitor1 ip:localhost'"
	echo ''
}


prompt_for_reboot()
{
	echo ''
	read -p 'Reboot now? [Y/n]: ' rebootResponse
	case $rebootResponse in
		(y|Y|"")
			echo 'Bye!'
			exec reboot now
			;;
		(*)
			return
			;;
	esac
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
		if [ -f /home/${SUDO_USER}/setup2_complete ];
		then
			setup3
		elif [ -f /home/${SUDO_USER}/setup1_complete ];
		then
			setup2
			setup3
		else
			setup1
			setup2
			setup3
		fi
		test_install
		;;
	(*)
		echo -e "\nThe switch '$1' is invalid. Try again.\n"
		exit 1
		;;
esac

# Exit from the script with success (0)
exit 0
