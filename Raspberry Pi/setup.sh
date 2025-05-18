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

	if systemctl --all --type service | grep -q 'dnsmasq';
	then
		echo -e "\n"$GREEN"dnsmasq is already installed"$RESET""
	else
		echo -e "\n"$GREEN"Installing dnsmasq"$RESET""
		apt-get install dnsmasq -y
		echo -e ""$GREEN"Disabling dnsmasq"$RESET""
		systemctl stop dnsmasq
		systemctl disable dnsmasq
		systemctl mask dnsmasq
	fi


	# Added in 1.0.4 May 2025:
	echo -e "\n"$GREEN"Disabling serial-getty@ttyAMA0.service"$RESET""
	systemctl stop serial-getty@ttyAMA0.service
	systemctl disable serial-getty@ttyAMA0.service
	systemctl mask serial-getty@ttyAMA0.service


	set +e #Suspend the error trap
	#isKnxd=$(command -v knxd)
	isKnxd=$(dpkg -s knxd | grep "Version: " | cut -d ' ' -f2)
	set -e #Resume the error trap
	if [[ $isKnxd ]];
	then
		echo -e "\nCurrent installed version of knxd      = $isKnxd"
		latestKnxdVersion=$(curl --silent "https://raw.githubusercontent.com/knxd/knxd/refs/heads/debian/debian/changelog" | sed -n 's/.*(\(\(.*\)\)).*/\1/p' | head -1 )
		echo -e "Current   online  version of knxd      = $latestKnxdVersion"
		if dpkg --compare-versions $isKnxd "lt" $latestKnxdVersion ;
		then
			echo -e ""$GREEN"TODO: Updating knxd"$RESET""
			
			# TODO: Upgrade installed version
			# TODO: If we upgrade, make sure we don't overwrite the user's previous knxd.conf!
			
		else
			echo -e ""$GREEN"No knxd upgrade required"$RESET""
		fi
	else
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
	fi

	echo ''
	isKnxdClient=$(sudo -u ${SUDO_USER} bash -c "source /home/${SUDO_USER}/venv/bin/activate && pip3 show knxdclient 2>/dev/null | sed -n 's/.*Version:\s\(.*\).*/\1/p'")
	if [[ $isKnxdClient ]];
	then
		echo -e "Current installed version of KNXDclient = $isKnxdClient"
		latestKnxdClientRls=$(curl --silent "https://api.github.com/repos/mhthies/knxdclient/releases/latest" | grep '"tag_name":' | sed -E 's/.*"v([^"]+)".*/\1/')
		echo -e "Current   online  version of KNXDclient = $latestKnxdClientRls"
		if dpkg --compare-versions $isKnxdClient "lt" $latestKnxdClientRls ;
		then
			echo ''
			echo -e ""$GREEN"Updating KNXDclient"$RESET""
			sudo -u ${SUDO_USER} bash -c "source /home/${SUDO_USER}/venv/bin/activate && pip3 install knxdclient --upgrade"
		else
			echo -e ""$GREEN"No KNXDclient upgrade required"$RESET""
		fi
	else
		echo -e "\n"$GREEN"Installing KNXDclient"$RESET""
		sudo -u ${SUDO_USER} bash -c "source /home/${SUDO_USER}/venv/bin/activate && pip3 install knxdclient"
	fi
 
	echo -e "\n"$GREEN"Installing requests"$RESET""
	sudo -u ${SUDO_USER} bash  -c "source /home/${SUDO_USER}/venv/bin/activate && python3 -m pip install requests"

	echo ''
	set +e #Suspend the error trap
	#isTelegraf=$(dpkg -s telegraf 2>/dev/null)
	isTelegraf=$(telegraf --version 2>/dev/null | cut -d ' ' -f2)
	set -e #Resume the error trap
	if [[ $isTelegraf  ]];
	then
		echo -e "\rCurrent installed version of telegraf = $isTelegraf"
		# It's *assumed* the user has performed the 'apt-get update' at Step 26, so the latest telegraf will be available to us
		latestTelegrafRls=$(sudo apt-cache show telegraf | sed -n 's/.*Version:\s\(.*\).*/\1/p' | head -1)
		echo -e "Current   online  version of telegraf = $latestTelegrafRls"
		if dpkg --compare-versions $isTelegraf "lt" $latestTelegrafRls ;
		then
			echo -e ""$GREEN"Updating telegraf"$RESET""
			sudo apt-get install --only-upgrade telegraf -y
		else
			echo -e ""$GREEN"No telegraf upgrade required"$RESET""
		fi
	else
		echo -e "\n"$GREEN"Installing telegraf"$RESET""
		rm -rf /home/$SUDO_USER/staging/telegraf
		mkdir -pv /home/$SUDO_USER/staging/telegraf
		cd /home/${SUDO_USER}/staging/telegraf/
		curl -s https://repos.influxdata.com/influxdata-archive.key > influxdata-archive.key
		echo '943666881a1b8d9b849b74caebf02d3465d6beb716510d86a39f6c8e8dac7515 influxdata-archive.key' | sha256sum -c && cat influxdata-archive.key | gpg --dearmor | sudo tee /etc/apt/trusted.gpg.d/influxdata-archive.gpg > /dev/null
		echo 'deb [signed-by=/etc/apt/trusted.gpg.d/influxdata-archive.gpg] https://repos.influxdata.com/debian stable main' | sudo tee /etc/apt/sources.list.d/influxdata.list
		apt-get update && apt-get install telegraf -y
	fi

	# Suppress noisy error message in OOB telegraf.service (n/a on Debian/Raspbian):
	if grep -q '^ImportCredential=telegraf.*'  /lib/systemd/system/telegraf.service;
	then
		sed -i -E "s|^(\s*ImportCredential=)(.*)$|# \1\2|g" /lib/systemd/system/telegraf.service
	fi


	echo ''
	set +e #Suspend the error trap
	#isInfluxd=$(command -v influxd)
	isInfluxd=$(influxd version 2>/dev/null | cut -d ' ' -f2 | cut -d 'v' -f2 )
	set -e #Resume the error trap
	if [[ $isInfluxd ]];
	then
		echo -e "\rCurrent installed version of InfluxDB = $isInfluxd"
		latestInfluxRls=$(sudo apt-cache show influxdb2 | sed -n 's/.*Version:\s\(.*\).*/\1/p' | head -1)
		echo -e "Current   online  version of InfluxDB = $latestInfluxRls"
		if dpkg --compare-versions $isInfluxd "lt" $latestInfluxRls ;
		then
			echo -e ""$GREEN"Updating InfluxDB"$RESET""
			apt-get install --only-upgrade influxdb2 -y
		else
			echo -e ""$GREEN"No InfluxDB upgrade required"$RESET""
		fi
	else
		echo -e "\n"$GREEN"Installing InfluxDB "$RESET""
		apt-get install influxdb2 -y
	fi

	echo ''
	set +e #Suspend the error trap
	#isGrafana=$(dpkg -s grafana-enterprise 2>/dev/null)
	isGrafana=$(dpkg -s grafana-enterprise | grep "Version: " | cut -d ' ' -f2)
	set -e #Resume the error trap
	if [[ $isGrafana ]];
	then
		echo -e "\rCurrent installed version of grafana  = $isGrafana"
		latestGrafanaRls=$(sudo apt-cache show grafana | sed -n 's/.*Version:\s\(.*\).*/\1/p' | head -1)
		echo -e "Current   online  version of grafana  = $latestGrafanaRls"
		if dpkg --compare-versions $isGrafana "lt" $latestGrafanaRls ;
		then
			echo -e ""$GREEN"Updating grafana"$RESET""
			apt-get install --only-upgrade grafana-enterprise -y
		else
			echo -e ""$GREEN"No grafana upgrade required"$RESET""
		fi
		
	else
		echo -e "\n"$GREEN"Installing grafana"$RESET""
		apt-get install -y apt-transport-https software-properties-common wget
		mkdir -p /etc/apt/keyrings/
		wget -q -O - https://apt.grafana.com/gpg.key | gpg --dearmor | sudo tee /etc/apt/keyrings/grafana.gpg > /dev/null
		echo "deb [signed-by=/etc/apt/keyrings/grafana.gpg] https://apt.grafana.com stable main" | sudo tee -a /etc/apt/sources.list.d/grafana.list
		apt-get update && apt-get install grafana-enterprise -y
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

	# Wi-Fi Power Save
	# Disable Wi-Fi power save mode:
	local activeConnections=$(nmcli -t c s -a | awk '!/loopback/' | cut -d: -f 1  )
	if [ ! -z "$activeConnections" ];
	then
		# Loop through them:
		IFS=$'\n'
		for thisConnection in $activeConnections;
		do
			local wlanId=$(nmcli -t -f NAME,DEVICE connection show | grep $thisConnection | cut -d: -f2)
			if [[ "$wlanId" =~ "wlan" ]];
			then
				local powerSave=$(nmcli -p connection show $thisConnection | grep 802-11-wireless.powersave | cut -s -d : -f 2 | tr -cd '0-9') 
				case $powerSave in
					('')
						echo -e ""$GREEN"INFO:"$RESET" $wlanId returned no Wi-Fi power save value"
						;;
					('2')
						echo -e ""$GREEN"PASS:"$RESET" $wlanId Wi-Fi power save is already OFF"
						;;
					(*)
						echo -e ""$GREEN"PASS:"$RESET" $wlanId Wi-Fi power save has been turned OFF"
						nmcli connection modify $thisConnection 802-11-wireless.powersave 2
						;;
				esac
			fi
		done
		unset IFS
	fi

	echo ''
	echo -e "\n"$GREEN"Done!"$RESET""
	echo ''
}


read_TTY()
{
	serial=$(udevadm info -a /dev/ttyAMA0  | grep KERNELS.*serial\" | cut -d'=' -f3 | xargs )
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
		VERSION=$(< /home/${SUDO_USER}/captureKNX/version)
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
	echo "Hostname: $HOSTNAME"
	release=$(sed -n -E 's/^PRETTY_NAME="(.*)"$/\1/p' /etc/os-release)
	echo "Release : $release"

	# TY Jesse Nickles https://stackoverflow.com/a/71674677/13102734
	DISK_SIZE_TOTAL=$(df -kh . | tail -n1 | awk '{print $2}')
	DISK_SIZE_FREE=$(df -kh . | tail -n1 | awk '{print $4}')
	DISK_PERCENT_USED=$(df -kh . | tail -n1 | awk '{print $5}')
	echo "Storage : $DISK_SIZE_FREE available out of $DISK_SIZE_TOTAL total ($DISK_PERCENT_USED used)"

	PIMODEL=$(tr -d '\0' < /proc/device-tree/model)
	if [[ "$PIMODEL" =~ "Raspberry Pi 5" ]];
	then
		BATTERY_VOLTAGE=$(vcgencmd pmic_read_adc BATT_V | cut -d = -f 2 | cut -d V -f 1 | xargs printf "%.*f\n" 2)
		echo -n "Battery : ${BATTERY_VOLTAGE}V"
		if grep -q 'dtparam=rtc_bbat_vchg=3000000' /boot/firmware/config.txt;
		then
			echo " (charging enabled)"
		else
			echo " (charging not enabled)"
		fi
  		echo -e "\n"$GREEN"PASS:"$RESET $PIMODEL""
	else
		echo -e "\n"$YELLOW"FAIL:"$RESET $PIMODEL""
	fi

	RESULT=$(test_64bit)
	if [[ $RESULT == "64" ]];
	then
		echo -e ""$GREEN"PASS:"$RESET" 64-bit OS"
	else
		echo -e ""$YELLOW"FAIL:"$RESET" 32-bit OS"
	fi
	set +e #Suspend the error trap
	desktop=$(type Xorg 2>&1)
	set -e #Resume the error trap
	matchRegex="not found$"
	if [[ $desktop =~ $matchRegex ]];
	then
		echo -e ""$GREEN"PASS:"$RESET" DESKTOP operating system not installed"
	else
		echo -e ""$YELLOW"FAIL:"$RESET" Unsupported DESKTOP operating system version detected"
	fi

	# ================== START Wi-Fi TESTS ==================
	ap_test=0
	systemctl is-active --quiet dnsmasq && ap_test=$((ap_test+1)) # If dnsmasq is running, add 1
	local activeConnections=$(nmcli -t c s -a | awk '!/loopback/' | cut -d: -f 1  )
	if [ ! -z "$activeConnections" ];
	then
		((ap_test=ap_test+2)) # If we have an active network connection, add 2
		# Loop through them:
		IFS=$'\n'
		for thisConnection in $activeConnections;
		do
			# Look in all 3 possible locations for the matching connectionFile:
			local connectionFile="/etc/NetworkManager/system-connections/"$thisConnection".nmconnection"
			if [ ! -f $connectionFile ];
			then
				local connectionFile="/usr/lib/NetworkManager/system-connections/"$thisConnection".nmconnection"
				if [ ! -f $connectionFile ];
				then
					local connectionFile="/run/NetworkManager/system-connections/"$thisConnection".nmconnection"
				fi
			fi

			if [ -f $connectionFile ];
			then
				local connectedMode=$(grep -r '^mode=' $connectionFile | cut -s -d = -f 2)
				local connectedType=$(grep -r '^type=' $connectionFile | cut -s -d = -f 2)
				local apCount=0   # Just in case we somehow end up with multiple connections. Each success only increments ap_test once
				local noapCount=0 # "
				if [[ $connectedMode == "ap" ]];
				then
					if [[ ($apCount == 0) ]];
					then
						((ap_test=ap_test+4)) # we're an Access Point. Add 4
						apCount=apCount+1
						if [ ! -z "$connectedChannel" ]; then ((ap_test=ap_test+16)); fi
					fi
				elif [[ $connectedMode =~ infra.* ]];
				then
					if [[ ($noapCount == 0) ]];
					then
						((ap_test=ap_test+8)) # we're a client, connected to a Wi-Fi network. Add 8
						noapCount=noapCount+1
					fi
				fi
				if [[ $connectedType == "ethernet" ]];
				then
					isEthernet="true"
				elif [[ $connectedType == "wifi" ]];
				then
					isWiFi="true"
     					local wifiConnection=$thisConnection # Used by the Power-Save test further down
					local wlanId=$(nmcli -t -f NAME,DEVICE connection show | grep $thisConnection | cut -d: -f2)
					local connectedSsid=$(grep -r '^ssid=' $connectionFile | cut -s -d = -f 2)
					local connectedChannel=$(grep -r '^channel=' $connectionFile | cut -s -d = -f 2)
					if [ ! -z "$connectedChannel" ]; then ((ap_test=ap_test+16)); fi
				fi
			else
				echo "Script error: connectionFile '$connectionFile' not found"
			fi
		done
		unset IFS
	fi

	if [[ $isEthernet && $isWiFi ]];
	then
		echo -e ""$YELLOW"WARN:"$RESET" Ethernet AND Wi-Fi connections are active. This can cause connection/performance issues"
	else
		if [[ $isEthernet ]];
		then
			echo -e ""$GREEN"PASS:"$RESET" Network connection is ETHERNET"
		elif [[ $isWiFi ]];
		then
			echo -e ""$GREEN"PASS:"$RESET" Network connection is Wi-Fi"
		else
			echo -e ""$YELLOW"FAIL:"$RESET" No network connection detected"
		fi
	fi

	if [[ $isWiFi ]];
	then
		case $ap_test in
			(0)
				echo -e ""$YELLOW"FAIL:"$RESET" No network connection was detected (0)"
				;;
			(1)
				# dnsmasq is running. That's the sign we SHOULD be an AP
				echo -e ""$YELLOW"FAIL:"$RESET" dnsmasq is running, however no network connection was detected (1)"
				;;
			(2)
				# we have an active network connection
				echo -e ""$YELLOW"FAIL:"$RESET" A network connection was detected, but no Wi-Fi data was found (2)"
				;;
			(3)
				# active network + dnsmasq
				echo -e ""$YELLOW"FAIL:"$RESET" A network connection was detected, but no Wi-Fi data was found (3)"
				;;
			(6)
				# We're an AP & have an active network connection, but no CHANNEL.
				echo -e ""$YELLOW"FAIL:"$RESET" The Pi is its own Wi-Fi network (an Access Point) however no channel has been configured (6)"
				;;
			(7)
				# We're an AP, dmsmasq is running and we have an active network connection.
				echo -e ""$YELLOW"FAIL:"$RESET" The Pi is its own Wi-Fi network (an Access Point) however no channel has been configured (7)"
				;;
			(8)
				# We're a Wi-Fi client
				echo -e ""$YELLOW"PASS:"$RESET" The Pi is a Wi-Fi client, however there is no active network connection (8)"
				;;
			(9)
				# We're a Wi-Fi client HOWEVER dmsmasq is running. (Bad/unexpected)
				echo -e ""$YELLOW"PASS:"$RESET" The Pi is a Wi-Fi client, however there is no active network connection (9)"
				;;
			(10)
				# Good. Wi-Fi client.
				echo -e ""$GREEN"PASS:"$RESET" The Pi is a Wi-Fi client, not an Access Point"
				echo -e ""$GREEN"PASS:"$RESET" It has an active connection to SSID(s): $connectedSsid"
				;;
			(22)
				# Good-ish. Wi-Fi AP.
				echo -e ""$GREEN"PASS:"$RESET" The Pi is its own Wi-Fi network (Access Point)"
				echo -e ""$GREEN"PASS:"$RESET" Its SSID (network name) is '$connectedSsid' and is using channel $connectedChannel"
				echo -e ""$YELLOW"PASS:"$RESET" dnsmasq is not running (22)"
				;;
			(23)
				# Good. Wi-Fi AP.
				echo -e ""$GREEN"PASS:"$RESET" The Pi is its own Wi-Fi network (Access Point)"
				echo -e ""$GREEN"PASS:"$RESET" Its SSID (network name) is '$connectedSsid' and is using channel $connectedChannel"
				;;
			(*)
				echo -e ""$YELLOW"FAIL:"$RESET" Test returned unexpected value $ap_test:"
				echo " 1 = dnsmasq is running"
				echo " 2 = we have an active network connection"
				echo " 4 = we're our own Wi-Fi network (an Access Point)"
				echo " 8 = we're a Wi-Fi client"
				echo "16 = we're our own Wi-Fi network (an Access Point) and have a Wi-Fi channel correctly configured"
				echo ''
				;;
		esac
		powerSave=$(nmcli -p connection show $wifiConnection | grep 802-11-wireless.powersave | cut -s -d : -f 2 | tr -cd '0-9') 
		# echo "|$powerSave|"
		case $powerSave in
			('0')
				echo -e ""$YELLOW"FAIL:"$RESET" $wlanId Wi-Fi power save is set to 'default' (ambiguous)"
				;;
			('1')
				echo -e ""$YELLOW"FAIL:"$RESET" $wlanId Wi-Fi power save is set to 'ignore' (ambiguous)"
				;;
			('2')
				echo -e ""$GREEN"PASS:"$RESET" $wlanId Wi-Fi power save is OFF"
				;;
			('3')
				echo -e ""$YELLOW"FAIL:"$RESET" $wlanId Wi-Fi power save is ON"
				;;
			(*)
				echo -e ""$YELLOW"FAIL:"$RESET" $wlanId Wi-Fi power save test returned an unexpected response: $powerSave"
				;;
		esac
	fi
	echo '-------------------------------------'
	# ================== END Wi-Fi TESTS ==================

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

	isKnxdClient=$(sudo -u ${SUDO_USER} bash -c "source /home/${SUDO_USER}/venv/bin/activate && pip3 show knxdclient 2>/dev/null | sed -n 's/.*Version:\s\(.*\).*/\1/p'")
	if [[ $isKnxdClient ]];
	then
		echo -e ""$GREEN"PASS:"$RESET" KNXDclient installed ($isKnxdClient)"
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
	#isTelegraf=$(dpkg -s telegraf 2>/dev/null)
 	isTelegraf=$(telegraf --version 2>/dev/null | cut -d ' ' -f2)
	set -e #Resume the error trap
	if [[ $isTelegraf  ]];
	then
		echo -e ""$GREEN"PASS:"$RESET" telegraf installed ($isTelegraf)"
	else
		echo -e ""$YELLOW"FAIL:"$RESET" telegraf NOT installed"
	fi

	set +e #Suspend the error trap
	isInfluxd=$(influxd version 2>/dev/null | cut -d ' ' -f2 | cut -d 'v' -f2 )
	set -e #Resume the error trap
	if [[ $isInfluxd ]];
	then
		echo -e ""$GREEN"PASS:"$RESET" InfluxDB installed ($isInfluxd)"
	else
		echo -e ""$YELLOW"FAIL:"$RESET" InfluxDB NOT installed"
	fi

	set +e #Suspend the error trap
	isInfluxCLI=$(command -v influx)
	set -e #Resume the error trap
	if [[ $isInfluxCLI ]];
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
		creationDatestamp=$(stat -c %w /home/$isKnxProject | awk '{gsub(/\.[0-9]* /, " "); print }') # This cuts the ms precision from the timestamp
		echo -e ""$GREEN"PASS:"$RESET" knx project file $isKnxProject found, created $creationDatestamp"
	else
		echo -e ""$YELLOW"FAIL:"$RESET" knx project file NOT found"
		echo -e "      Copy one across to the /home/${SUDO_USER}/ folder and 'sudo systemctl restart captureKNX'"
	fi

	echo '-------------------------------------'
	set +e #Suspend the error trap
	lastTelegram=$(sed -n -E 's/^(.*) ([[:digit:]]+)$/\2/p' /home/pi/log/telegraf/debug_output.log | tail -1)
	if [[ $lastTelegram ]];
	then
		((lastTelegram=lastTelegram/1000000000))
		lastTelegramDate="Unknown"
		lastTelegramDate=$(date -d @"$lastTelegram" +"%Y %b %d %H:%M:%S %Z")
		echo -e "Last successful telegram: $lastTelegramDate"
	else
		echo -e "Last successful telegram unknown. /home/pi/log/telegraf/debug_output.log returned no result. Try again"
	fi
	echo ''
	echo "Test knxd's access to the port with 'knxtool vbusmonitor1 ip:localhost'"
	echo ''
}


make_ap_nmcli ()
{
	echo -e ""$GREEN"make_ap_nmcli"$RESET""
	echo ''
	echo 'This process will setup the Pi as a Wi-Fi access point - its own Wi-Fi network'
	echo '(Control-C to abort at any time)'
	echo ''

	if [[ $(isUserLocal) == "false" ]];
	then
		echo ''
		echo -e ""$YELLOW"This command is not available from a wireless network connection."$RESET""
		echo -e ""$YELLOW"You need to be on a wired network or directly connected to the Pi"$RESET""
		echo ''
		exit
	fi

	# ================== START DHCP ==================
	if  grep -q 'interface=wlan0' /etc/dnsmasq.conf;
	then
		#Read the current values:
		wlanLine=$(sed -n '/interface=wlan0/=' /etc/dnsmasq.conf) #This is the line number that the wlan config starts at
		oldDhcpStartIp=$(sed -n -E "$wlanLine,$ s|^\s*dhcp-range=(.*)$|\1|p" /etc/dnsmasq.conf ) # Delimiter is '|'
		matchRegex="\s*(([0-9]{1,3}\.){3}[0-9]{1,3}),(([0-9]{1,3}\.){3}[0-9]{1,3}),(([0-9]{1,3}\.){3}[0-9]{1,3})," # Bash doesn't do digits as "\d"
		if [[ $oldDhcpStartIp =~ $matchRegex ]] ;
			then
				oldDhcpStartIp=${BASH_REMATCH[1]}
				oldDhcpEndIp=${BASH_REMATCH[3]}
				oldDhcpSubnetMask=${BASH_REMATCH[5]}
			fi
	else
		echo 'No IPs in /etc/dnsmasq.conf. Adding some defaults'
		#Create default values:
		cat <<END >> /etc/dnsmasq.conf
interface=wlan0      # Use the required wireless interface - usually wlan0
	dhcp-range=10.10.10.10,10.10.10.100,255.255.255.0,24h
END
	fi
	#Populate defaults if required:
	if [ -z "$oldPiIpV4" ];         then oldPiIpV4='10.10.10.1'; fi
	if [ -z "$oldDhcpStartIp" ];    then oldDhcpStartIp='10.10.10.10'; fi
	if [ -z "$oldDhcpEndIp" ];      then oldDhcpEndIp='10.10.10.100'; fi
	if [ -z "$oldDhcpSubnetMask" ]; then oldDhcpSubnetMask='255.255.255.0'; fi
	# ================== END DHCP ==================

	# ================= START Wi-Fi =================
	local wlan0Name=$(LANG=C nmcli -t -f GENERAL.CONNECTION device show wlan0 | cut -d: -f2-)
	connectionFile="/etc/NetworkManager/system-connections/"$wlan0Name".nmconnection"
	if [ -f $connectionFile ];
	then
		#local oldWifiSsid=$(grep -r '^ssid=' $connectionFile | cut -s -d = -f 2)
		local oldWifiChannel=$(grep -r '^channel=' $connectionFile | cut -s -d = -f 2)
		local oldWifiPwd=$(grep -r '^psk=' $connectionFile | cut -s -d = -f 2)
	fi
	#local oldWifiCountry=$(LANG=C iw reg get | cut -s -d : -f 1 | head -1 | cut -s -d ' ' -f 2)
	#Populate defaults otherwise:
	if [ -z "$oldWifiSsid" ];    then local oldWifiSsid='captureKNX'; fi
	if [ -z "$oldWifiChannel" ]; then local oldWifiChannel='1'; fi
	if [ -z "$oldWifiPwd" ];     then local oldWifiPwd='myPiNetw0rkAccess!'; fi
	#if [[ ! $oldWifiCountry =~ [a-zA-Z]{2} ]]; then oldWifiCountry=''; fi # Null the value if it's not just two letters
	# ================== END Wi-Fi ==================

	echo 'If unsure of any question, accept the defaults until you get to the SSID and password'
	echo ''
	read -e -i "$oldPiIpV4" -p         'Choose an IP address for the Pi         : ' piIpV4
	read -e -i "$oldDhcpStartIp" -p    'Choose the starting IP address for DCHP : ' dhcpStartIp
	read -e -i "$oldDhcpEndIp" -p      'Choose  the  ending IP address for DCHP : ' dhcpEndIp
	read -e -i "$oldDhcpSubnetMask" -p 'Set the appropriate subnet mask         : ' dhcpSubnetMask

	while true; do
		read -e -i "$oldWifiSsid" -p       'Pick a nice SSID                        : ' wifiSsid
		if [ -z "$wifiSsid" ];
		then
			echo -e ""$YELLOW"ERROR:"$RESET" SSID name cannot be empty."
			echo ''
			continue
		fi
		break
	done

	while true; do
		read -e -i "$oldWifiPwd" -p        'Wi-Fi password                          : ' wifiPwd
		if [ -z "$wifiPwd" ];
		then
			echo -e ""$YELLOW"ERROR:"$RESET" Psk value cannot be empty."
			echo ''
			continue
		elif [ ${#wifiPwd} -lt 8 ];
		then
			echo -e ""$YELLOW"ERROR:"$RESET" Psk must be at least 8 characters."
			echo ''
			continue
		fi
		break
	done

	while true; do
		read -e -i "$oldWifiChannel" -p    'Choose an appropriate Wi-Fi channel     : ' wifiChannel
		if [ -z "$wifiChannel" ];
		then
			echo -e ""$YELLOW"ERROR:"$RESET" Wi-Fi channel cannot be empty."
			echo ''
			continue
		fi
		break
	done

	#read -e -i "$oldWifiCountry" -p    'Set your 2-digit Wi-Fi country           : ' wifiCountry

	#TODO: Validate the IP addresses

	local cidr_mask=$(IPprefix_by_netmask $dhcpSubnetMask)

	echo ''
	echo -e ""$YELLOW"WARNING:"$RESET" If you proceed, any existing wireless connection will end and the Pi will become its own Wi-Fi network (access point)"
	echo -e ""$YELLOW"WARNING:"$RESET" You will find it advertised as SSID '$wifiSsid'"
	echo ''
	read -p "Press any key to continue or ^C to abort " discard
	echo ''
	#Paste in the new settings
	sed -i -E "s/^(\s*dhcp-range=)(.*)$/\1$dhcpStartIp,$dhcpEndIp,$dhcpSubnetMask,24h/" /etc/dnsmasq.conf

	echo 'Enabling dnsmasq'
	systemctl unmask dnsmasq
	systemctl enable dnsmasq
	systemctl start dnsmasq

	# Modify existing hotspot, otherwise delete and start afresh
	if [[ $wlan0Name == "hotspot" ]];
	then
		nmcli con mod hotspot autoconnect yes ssid "$wifiSsid"
	else
		if [[ "$wlan0Name" != "" ]];
		then
			nmcli con del "$wlan0Name"
			sleep 5
		fi
		echo "Creating new Wi-Fi connection to '$wifiSsid'"
		nmcli con add type wifi ifname wlan0 con-name hotspot autoconnect yes ssid "$wifiSsid"
	fi
	nmcli con mod hotspot 802-11-wireless.mode ap 802-11-wireless.band bg 802-11-wireless.channel $wifiChannel #ipv4.method shared
	nmcli con mod hotspot wifi-sec.key-mgmt wpa-psk
	nmcli con mod hotspot wifi-sec.psk "$wifiPwd"
	nmcli con mod hotspot wifi.powersave disable
	nmcli con mod hotspot ipv4.addresses "${piIpV4}/${cidr_mask}" ipv4.method manual
	nmcli con up hotspot
}


unmake_ap_nmcli ()
{
	echo -e ""$GREEN"unmake_ap_nmcli"$RESET""
	echo ''
	echo 'This process will stop the Pi from being a Wi-Fi access point & instead connect to a wired or wireless network'
	echo '(Control-C to abort at any time)'
	echo ''

	if [[ $(isUserLocal) == "false" ]];
	then
		echo ''
		echo -e ""$YELLOW"This command is not available from a wireless network connection."$RESET""
		echo -e ""$YELLOW"You need to be on a wired network or directly connected to the Pi"$RESET""
		echo ''
		exit
	fi

	while true; do
		read -p "Setup a new wireless network? (Select N for wired) [y/n]: " wiredOrWireless
		case $wiredOrWireless in
			(y|Y)
				echo 'Wireless'
				break
				;;
			(n|N)
				echo 'Wired Ethernet'
				break
				;;
			(*)
				continue # Loop until the user provides a Y/N response
				;;
		esac
	done

	if [[ "$wiredOrWireless" =~ [Yy] ]];
	then
		local wlan0Name=$(LANG=C nmcli -t -f GENERAL.CONNECTION device show wlan0 | cut -d: -f2-)
		if [[ $wlan0Name == 'hotspot' ]]; then wlan0Name=''; fi # Suppress auto-populate below if name is 'hotspot'
		while true; do
			read -e -i "$wlan0Name" -p "Set the network's SSID                                  : " newSsid
			if [ -z "$newSsid" ];
			then
				echo -e 'Error: SSID name cannot be empty.'
				echo ''
				continue
			fi
			break
		done

		while true; do
			read -p "Set the network's Psk (password)                        : " newPsk
			if [ -z "$newPsk" ];
			then
				echo -e "Error: Psk value cannot be empty."
				echo ''
				continue
			fi
			break
		done
	fi

	read -p 'Do you want to assign the Pi a static IP address?  [Y/n]: ' staticResponse
	case $staticResponse in
		(y|Y|"")
			local oldPiIpV4=$(LANG=C nmcli -t -f IP4.ADDRESS device show wlan0 | cut -d: -f2- | cut -d/ -f1)
			local oldDhcpSubnetCIDR=$(LANG=C nmcli -t -f IP4.ADDRESS device show wlan0 | cut -d/ -f2-)
			local oldRouter=$(LANG=C nmcli -t -f IP4.GATEWAY device show wlan0 | cut -d: -f2-)
			local oldDnsServers=$(LANG=C nmcli -t -f IP4.DNS device show wlan0 | cut -d: -f2-)

			if [ "$oldDhcpSubnetCIDR" ]; then local oldDhcpSubnetMask=$(CIDRtoNetmask $oldDhcpSubnetCIDR); fi

			read -e -i "$oldPiIpV4" -p         'Choose an IP address for the Pi                         : ' piIpV4
			read -e -i "$oldDhcpSubnetMask" -p 'Set the appropriate subnet mask                         : ' dhcpSubnetMask
			read -e -i "$oldRouter" -p         'Set the router/gateway IP                               : ' router
			read -e -i "$oldDnsServers" -p     'Set the DNS Server(s) (space-delimited)                 : ' DnsServers

			local cidr_mask=$(IPprefix_by_netmask $dhcpSubnetMask)
			;;
		(*)
			echo -n # Do nothing.
			;;
	esac

	echo ''
	if [[ "$wiredOrWireless" =~ [Yy] ]];
	then
		echo -e ""$YELLOW"WARNING:"$RESET" If you proceed, the Pi will become a Wi-Fi *client*"
		echo -e ""$YELLOW"WARNING:"$RESET" It will attempt to connect to the '$newSsid' network"
	else
		echo -e ""$YELLOW"WARNING:"$RESET" If you proceed, the Pi will use the lan0 port for its connectivity"
	fi
	read -p "Press any key to continue or ^C to abort " discard
	echo ''

	if systemctl --all --type service | grep -q 'dnsmasq';
	then
		echo -e ""$GREEN"Disabling dnsmasq"$RESET""
		systemctl stop dnsmasq    # Stop it now
		systemctl disable dnsmasq # Prevents it launching on bootup
		systemctl mask dnsmasq
		echo ''
	fi

	echo 'About to delete the hotspot'
	set +e # Suspend the error trap. The below would otherwise throw a terminating error if 'hotspot' doesn't exist.
	nmcli con del hotspot 2> /dev/null # Suppress any error display.
	set -e # Resume the error trap
	echo 'Back from deleting the hotspot'

	if [[ "$wiredOrWireless" =~ [Yy] ]];
	then
		# Wireless:
		sleep 5 # Sleep briefly having just deleted the hotspot, before creating the new wireless network connection
		echo 'About to connect to Wi-Fi'
		nmcli dev wifi connect "$newSsid" password "$newPsk" ifname wlan0
		echo 'Back from connecting to Wi-Fi'
		# Paste in the new settings
		case $staticResponse in
			(y|Y|"")
				nmcli con mod "$newSsid" ipv4.addresses "${piIpV4}/${cidr_mask}" ipv4.method manual
				nmcli con mod "$newSsid" ipv4.gateway $router
				nmcli con mod "$newSsid" ipv4.dns "$DnsServers"
			;;
			(*)
				nmcli con mod "$newSsid" ipv4.method auto
			;;
		esac
		nmcli con mod "$newSsid" wifi.powersave disable
		echo 'About to con up'
		nmcli con up "$newSsid"
		echo 'Back from con up'
	else
		# Ethernet:
		local eth0Name=$(LANG=C nmcli -t c s | awk '/ethernet/' | cut -d: -f1)
		if [[ ! $eth0Name ]];
		then
			# Bad. No ethernet device found
			echo -e ""$YELLOW"ERROR:"$RESET" No ethernet port found - and Wi-Fi AP has already been deleted"
		else
			# Paste in the new settings
			echo "Modifying Ethernet connection to '$eth0Name'"
			case $staticResponse in
				(y|Y|"")
					nmcli con mod "$eth0Name" ipv4.addresses "${piIpV4}/${cidr_mask}" ipv4.method manual
					nmcli con mod "$eth0Name" ipv4.gateway $router
					nmcli con mod "$eth0Name" ipv4.dns "$DnsServers"
				;;
				(*)
					nmcli con mod "$eth0Name" ipv4.method auto
				;;
			esac
			nmcli con mod "$eth0Name" connection.autoconnect true # Don't honestly know if this is required, but can't hurt?
			echo 'About to con up'
			nmcli con up "$eth0Name"
			echo 'Back from con up'
		fi
	fi
}


# https://stackoverflow.com/questions/50413579/bash-convert-netmask-in-cidr-notation/50414560
IPprefix_by_netmask ()
{
	c=0 x=0$( printf '%o' ${1//./ } )
	while [ $x -gt 0 ]; do
		let c+=$((x%2)) 'x>>=1'
	done
	echo $c ;
}


# https://stackoverflow.com/questions/20762575/explanation-of-convertor-of-cidr-to-netmask-in-linux-shell-netmask2cdir-and-cdir
CIDRtoNetmask ()
{
	# Number of args to shift, 255..255, first non-255 byte, zeroes
	set -- $(( 5 - ($1 / 8) )) 255 255 255 255 $(( (255 << (8 - ($1 % 8))) & 255 )) 0 0 0
	[ $1 -gt 1 ] && shift $1 || shift
	echo ${1-0}.${2-0}.${3-0}.${4-0}
}


isUserLocal ()
{
	whoAmI=$(who am i)
	matchRegex='[0-9]+(\.[0-9]+){3}'
	if [[ $whoAmI =~ $matchRegex ]] ;
	then
		# OK, the user has an IP address. Are they on a wired (OK) or wireless (bad) NIC?
		clientIpAddress=${BASH_REMATCH}
		#echo $clientIpAddress
		wlanClients=$(arp -n | grep 'wlan[[:digit:]]')
		#echo $wlanClients
		if [[ $wlanClients == *"$clientIpAddress"* ]]
		then
			echo "false" # This user is on WiFi. No go
		else
			echo "true"  # This user is connected via an Ethernet NIC
		fi
	else
		echo "true" # This user is directly connected to the Pi. (There is no IP address for this user)
	fi
}


# I'm not sure if this will stay. It's a diagnostic tool at the moment, not (yet?) mentioned in the documentation
test_token()
{
	echo -e "\n"$GREEN"Test tokens"$RESET""
	echo ''
	TELEGRAF_TOKEN=$(sed -n -E 's/^token = \"(.*)\"$/\1/p' /etc/telegraf/telegraf.conf)
	INFLUX_TOKEN=$(sed -n -E 's/^\s*INFLUXDB_INIT_ADMIN_TOKEN=(.*)$/\1/p' /etc/influxdb/captureKNX.env)
	GRAFANA_TOKEN=$(sed -n -E "s/^\s*httpHeaderValue1: 'Token (.*)'$/\1/p" /etc/grafana/provisioning/datasources/grafana-source.yaml)

	if [[ "$TELEGRAF_TOKEN" == "xxxxxxxxx" ]];
	then
		echo -e ""$YELLOW"FAIL:"$RESET" The telegraf token is default. Re-run setup"
		ABORT="True"
	fi

	if [[ "$INFLUX_TOKEN" == "changeme" ]];
	then
		echo -e ""$YELLOW"FAIL:"$RESET" The influxDB token is default. Re-run setup"
		ABORT="True"
	fi

	if [[ "$GRAFANA_TOKEN" == "changeme" ]];
	then
		echo -e ""$YELLOW"FAIL:"$RESET" The grafana token is default. Re-run setup"
		ABORT="True"
	fi

	if [[ $ABORT ]];
	then
		echo ''
		exit 1
	fi

	if [[ "$INFLUX_TOKEN" == "$TELEGRAF_TOKEN" ]];
	then
		if [[ "$INFLUX_TOKEN" == "$GRAFANA_TOKEN" ]];
		then
			echo -e ""$GREEN"PASS:"$RESET" All three tokens are the same"
		else
			echo -e ""$YELLOW"FAIL:"$RESET" Tokens are NOT the same. Check /etc/grafana/provisioning/datasources/grafana-source.yaml"
		fi
	else
		if [[ "$INFLUX_TOKEN" == "$GRAFANA_TOKEN" ]];
		then
			echo -e ""$YELLOW"FAIL:"$RESET" Tokens are NOT the same. Check /etc/telegraf/telegraf.conf"
		else
			if [[ "$TELEGRAF_TOKEN" == "$GRAFANA_TOKEN" ]];
			then
				echo -e ""$YELLOW"FAIL:"$RESET" Tokens are not the same. Check /etc/influxdb/captureKNX.env"
			else
				echo -e ""$YELLOW"FAIL:"$RESET" None of the tokens are the same. Re-run setup"
			fi
		fi
	fi
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


# Enable charging of the RTC backup battery. Only applies to the Pi 5
charge_battery()
{
	PIMODEL=$(tr -d '\0' < /proc/device-tree/model)
	if [[ "$PIMODEL" =~ "Raspberry Pi 5" ]];
	then
  		if ! grep -q '^dtparam=rtc_bbat_vchg=3000000' /boot/firmware/config.txt;
		then
			echo -e 'dtparam=rtc_bbat_vchg=3000000' >> /boot/firmware/config.txt
			echo -e "\n"$GREEN"PASS:"$RESET \'dtparam=rtc_bbat_vchg=3000000\' added to /boot/firmware/config.txt""
		else
			echo -e "\n"$GREEN"INFO:"$RESET \'dtparam=rtc_bbat_vchg=3000000\' is already present in /boot/firmware/config.txt. Nothing to do""
		fi
	else
		echo -e "\n"$YELLOW"FAIL:"$RESET Not a Pi 5. Nothing to do""
	fi
	echo ''
}


# Disable charging of the RTC backup battery. Only applies to the Pi 5
no_charge_battery()
{
	PIMODEL=$(tr -d '\0' < /proc/device-tree/model)
	if [[ "$PIMODEL" =~ "Raspberry Pi 5" ]];
	then
  		if grep -q '^dtparam=rtc_bbat_vchg=3000000' /boot/firmware/config.txt;
		then
			sed -i '/dtparam=rtc_bbat_vchg=3000000/d' /boot/firmware/config.txt
			echo -e "\n"$GREEN"PASS:"$RESET \'dtparam=rtc_bbat_vchg=3000000\' removed from /boot/firmware/config.txt""
		else
			echo -e "\n"$GREEN"INFO:"$RESET \'dtparam=rtc_bbat_vchg=3000000\' is not present in /boot/firmware/config.txt. Nothing to do""
		fi
	else
		echo -e "\n"$YELLOW"FAIL:"$RESET Not a Pi 5. Nothing to do""
	fi
	echo ''
}


# A place for me to test code within the structure of the script.
# Ideally this function will never be released with code present. Let's see how I go.
dev()
{
	echo 'dev'
}


# -----------------------------------
# END FUNCTIONS
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

	('ap')
		make_ap_nmcli
		prompt_for_reboot
		;;
	('noap')
		unmake_ap_nmcli
		prompt_for_reboot
		;;
	('batt')
		charge_battery
		;;
	('nobatt')
		no_charge_battery
		;;
	('dev')
		dev
		;;
	('test')
		activate_venv
		case "$2" in
			('token')
				test_token
				;;
			('')
				test_install
				;;
			(*)
				echo -e "\nThe test '$2' is invalid. Try again.\n"
				exit 1
				;;
		esac
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
		echo -e "\nThe switch '$1' is invalid. Try again. Valid options are 'ap', 'noap', 'batt', 'nobatt' and 'test'\n"
		exit 1
		;;
esac

# Exit from the script with success (0)
exit 0
