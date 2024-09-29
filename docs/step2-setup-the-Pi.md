# Setup the Pi

If you're starting a Pi build from scratch, start here at Step 1.

If you're upgrading or re-running the setup script, you should be able to SSH to the Pi and jump to Step 37.

<hr />

1. Prepare the memory card with the [64-bit Raspberry Pi OS 'Lite'](https://www.raspberrypi.org/software/operating-systems/) image.

> The ["Raspberry Pi Imager"](https://www.raspberrypi.org/software/) app can download and write the image to a memory card for you quickly and easily.

<p align="center">
  <img src="https://github.com/user-attachments/assets/48df65a7-738b-493f-9e3f-3e3defbd3766" width="50%">
</p>

I built mine onto a Pi 4, so select your own hardware as required here, or `No filtering` to see the lot:

<p align="center">
  <img src="https://github.com/user-attachments/assets/a419f62b-e20c-4b1e-810c-6263c4609276" width="50%">
</p>

Having selected the device, now click `Choose OS`. Select `Raspberry Pi OS (other)`:
<p align="center">
  <img src="https://github.com/user-attachments/assets/1583d726-06c1-4b54-b280-9537ce648574" width="50%">
</p>

You want the `Raspberry Pi OS Lite (64-bit)` `A port of Debian Bookworm with no desktop environment (Compatible with Raspberry Pi 3/4/400/5` version.

<p align="center">
<img src="https://github.com/user-attachments/assets/a6ff10f2-6b27-4745-953e-fd7cd7c4871e" width="50%">
</p>

2. With that successfully burnt and verified, transfer the memory stick to the Pi.
3. Add HDMI, power and keyboard connections and turn it on. (You don't need a mouse for this, but add one if you're feeling so inclined).
4. The boot process ends at a login screen. The default credentials are `pi` / `raspberry`.
5. Login.
6. Now we'll perform the basic customisation steps:
7. Run `sudo raspi-config`.
8. Select `(5) Localisation Options` then:
    * `(L3) - change keyboard layout`
    I've never needed to do anything but accept the defaults here. I found the Pi stopped responding for >10s after selecting "no compose key", so just wait for it and it will take you back to the main page.
9. Return to (5) and set `(L2) the timezone`. Select the appropriate options and you'll be returned to the menu.
10. Select `(3) - Interfacing Options`
    * `(P2) Enable SSH` and at the prompt "Would you like the SSH server to be enabled?" change the selection to `<Yes>` and hit return, then return again at the `OK`.
    
11. Select `(1) System Options` and `(S4) Hostname` and give the Pi a recognisable hostname.
12. If you're building this onto a Pi with a wired network connection instead of WiFi, skip the next step. Resume at Step 14.
13. Select `(1) System Options` and `(S1) Wireless LAN`. At this stage we'll be a wifi *client*. When prompted:

    * Select your country
    * Enter the local SSID and passphrase (password). Note that the Pi Zero W's radio is limited to 2.4G, so any attempts to connect to a 5G network will fail.
14. Navigate to `Finish` and DECLINE the prompt to reboot.
15. Run `ifconfig`. In the output, look under "eth0" for wired and "wlan0" for WiFi. There should be a line starting with "inet" followed by an IP address. The absence of this means you're not on a network.

16. Assuming success above, you'll probably want to set a static IP. If you're OK with a dynamic IP (or at least are for the time being) jump to Step 20 and a reboot.

17. From 'Bookworm', the Pi uses Network Manager to manage IP addresses.\[[1](#1-set-a-static-ip-address-on-raspberry-pi-os-bookworm)\]

18. Run `sudo nmcli -p connection show` to show the available network interfaces:

```txt
pi@raspberrypi:~ $ sudo nmcli -p connection show
======================================
  NetworkManager connection profiles
======================================
NAME              UUID                                  TYPE      DEVICE
----------------------------------------------------------------------------------------------------------------
mywifissid        09123456-6ac4-4cf7-8154-701234567892  wifi      wlan0
lo                5612345d-ffff-4ee8-8ef9-12345678990f  loopback  lo
pi@raspberrypi:~ $
```

19. Now execute these three commands in turn, replacing the network name and dummy values here with your own:

```txt
sudo nmcli con mod "mywifissid" ipv4.addresses 10.0.0.220/24 ipv4.method manual
sudo nmcli con mod "mywifissid" ipv4.gateway 10.0.0.1
sudo nmcli con mod "mywifissid" ipv4.dns "10.0.0.1"
```

> If you have more than one DNS server (the last command above), add them all inside the quotes with a space separating each.

20. Reboot the Pi to pickup its new IP address and lock in all the changes made above, including the change to the hostname: `sudo reboot`

21. After it reboots, check it's on the network OK by typing `ifconfig` and check the output now shows the entries you added in Step 19.
(Alternatively, just see if it responds to pings and you can SSH to it on its new IP).

## Remote config via SSH

At this point I abandoned the keyboard and monitor, continuing the config steps from my PC.

22. SSH to the Pi using your preferred client. If you're using Windows 10 you can just do this from a PowerShell window: `ssh <TheIpAddressFromStep18> -l pi` (Note that's a lower-case L).
23. You should see something like this:
```txt
The authenticity of host '192.168.44.1 (192.168.44.1)' can't be established.
ECDSA key fingerprint is SHA256:Ty0Bw6IZqg1234567899006534456778sFKT6QakOZ5PdJk.
Are you sure you want to continue connecting (yes/no)?
```
24. Enter `yes` and press Return
25. The response should look like this:
```txt
Warning: Permanently added '192.168.44.1' (ECDSA) to the list of known hosts.
pi@192.168.44.1's password:
```
26. Enter the password and press Return.
27. It's STRONGLY recommended that you change the password. Run `passwd` and follow your nose.

## Here's where all the software modules are installed. This might take a while:

28. First let's make sure the Pi is all up-to-date:
```txt
sudo apt-get update && sudo apt-get upgrade -y
```

> If this ends with an error "Some index files failed to download. They have been ignored, or old ones used instead." just press up-arrow and return to retry the command. You want to be sure the Pi is healthy and updated before continuing.

> If however you encounter an error saying a certificate is out of date or not valid yet, check that the Pi's real-time clock is correct. `date` on its own will show the date, and you'll set it with this syntax: `sudo date -s '2024-12-25 11:04:00 AEDT'`.

29. `sudo reboot`

Your SSH session will end here. Wait for the Pi to reboot, sign back in again and continue.

30. Confirm your current version of python:

```txt
python3 --version
```
The output should look like this, which confirms python 3.11 (ignore the .2):
```txt
Python 3.11.2
```

31. Update the following command if required with that of the same version number:

```txt
sudo apt install python3.11-venv -y
```
```txt
python3 -m venv venv
```
```txt
source venv/bin/activate
```

32. We need to install git so we can download the repo from GitHub:

```
sudo apt-get install git -y
```

33. This downloads the repo, dropping the structure into a subdirectory called `staging`:

```txt
cd ~
```
```txt
sudo rm -rfd staging
```
```txt
git clone --depth=3 https://github.com/greiginsydney/knxLogger staging/knxLogger
```

> Advanced tip: if you're testing code and want to install a new branch direct from the repo, add `-b <branchName>` on the end of the line.

34. The knxdclient & requests go in here:

```txt
pip3 install knxdclient
```
```txt
python3 -m pip install requests
```

35. Now we need to move the setup.sh script file into its final location:

```txt
mv -fv "staging/knxLogger/Raspberry Pi/setup.sh" ~
``` 

36. All the hard work is done by the script, but it needs to be made executable first:

```txt
sudo chmod +x setup.sh
```

37. Now run it! (Be careful here: the switches are critical. "-E" ensures your user path is passed to the script. Without it the software will be moved to the wrong location, or not at all. "-H" passes the Pi user's home directory.)
```txt
sudo -E -H ./setup.sh
```

38. The FIRST time you run the script on a brand new Pi it's going to run for ~8 minutes (depending on your internet speed) and then prompt you to reboot:

![image](https://github.com/user-attachments/assets/f937f01d-2004-43df-a854-5799a2b7db69)


39. Reconnect to the Pi after it reboots and return to Step 37. Once the required bits have been added, it will stop prompting for reboots (there are two), and continue.

40. 
