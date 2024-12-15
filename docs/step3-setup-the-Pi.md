# Setup the Pi

If you're starting a Pi o/s build from scratch, jump back to [step2-prepare-the-Pi.md](/docs/step2-prepare-the-Pi.md).

If you're upgrading an existing captureKNX the upgrade process is a lot simpler, and that's on the [upgrade](/docs/upgrade.md) page.

If you have previously formatted your drive and the Pi is ready to go, stay here.

<hr />

## Configuration pre-requisite values

The KNX "hat" on the Pi needs some addresses within the KNX topology. It only ever listens, never transmits, but we still need to configure some addresses for it.

The installation will prompt you for them. The default values are four addresses starting from 1.1.250 (hoping they're well out of your active range). Please change these when prompted if they're already in use or captureKNX will live on another TP line.

The script installs the reporting component `InfluxDB`, which also requires a user login name and password for its web interface. The terribly unsecure 'captureKNX' is the default for both, and you should please change them when prompted. 

You'll also be asked for an 'organisation' and a 'bucket'. Neither name are particularly important. The former could be the name of the building, its street name, or something like that. The 'bucket' is the name of the database. 'captureKNX' is as good a value for that as any, but feel free to change it - but be aware it will be visible all the time on the data visualisation screens. (Keep it short too).


| Prompt | What is it? | Default value |
| --- | --- | --- |
| My KNX network client address | A spare physical address | 1.1.250 |
| Sending KNX network client start address | A spare physical address | The above + 1 |
| Sending KNX network client count | How many sending client addresses to reserve | 1 |
| INFLUXDB_INIT_USERNAME | Influx web user login | captureKNX |
| INFLUXDB_INIT_PASSWORD | InfluxDB web user password | captureKNX |
| INFLUXDB_INIT_ORG | An 'organisation name' | captureKNX |
| INFLUXDB_INIT_BUCKET | The database name | captureKNX |
| INFLUXDB_INIT_RETENTION | How long to retain the data | "52w", a full year |

<br>

<hr />

## Let's Go!


1. With the OS successfully burnt and verified, plug the drive into the Pi.
2. Add HDMI, power and keyboard connections and turn it on. (You don't need a mouse for this.)
3. The boot process ends at a login screen.
4. Login. The default credentials are `pi` / `raspberry`.
5. Now we'll perform the basic customisation steps:
6. Run `sudo raspi-config`.
7. Select `(5) Localisation Options` then:
    * `(L3) - change keyboard layout`
    I've never needed to do anything but accept the defaults here. I found the Pi stopped responding for >10s after selecting "no compose key", so just wait for it and it will take you back to the main page.
8. Return to (5) and set `(L2) the timezone`. Select the appropriate options and you'll be returned to the menu.
9. Select `(3) - Interfacing Options`
    * `(P2) Enable SSH` and at the prompt "Would you like the SSH server to be enabled?" change the selection to `<Yes>` and hit return, then return again at the `OK`.
    
10. Select `(1) System Options` and `(S4) Hostname` and give the Pi a recognisable hostname.
11. If you're building this Pi with a wired network connection instead of WiFi, skip the next step. Resume at Step 13.
12. Select `(1) System Options` and `(S1) Wireless LAN`. At this stage we'll be a wifi *client*. When prompted:

    * Select your country
    * Enter the local SSID and passphrase (password). Note that the Pi's radio is limited to 2.4G, so any attempts to connect to a 5G network will fail.
13. Navigate to `Finish` and DECLINE the prompt to reboot.
14. Run `ifconfig`. In the output, look under "eth0" for wired and "wlan0" for WiFi. There should be a line starting with "inet" followed by an IP address. The absence of this means you're not on a network.

15. Assuming success above, you'll probably want to set a static IP. If you're OK with a dynamic IP (or at least are for the time being) jump to Step 18 and a reboot.

16. Run `sudo nmcli -p connection show` to show the available network interfaces:

```txt
pi@raspberrypi:~ $ sudo nmcli -p connection show
======================================
  NetworkManager connection profiles
======================================
NAME                UUID                                  TYPE      DEVICE
----------------------------------------------------------------------------------------------------------------
Wired connection 1  641a2489-7d88-34f2-be45-c6a189593cc8  ethernet  eth0
mywifissid          09123456-6ac4-4cf7-8154-701234567892  wifi      wlan0
lo                  5612345d-ffff-4ee8-8ef9-12345678990f  loopback  lo
pi@raspberrypi:~ $
```

17. Now execute these three commands in turn, replacing the network name and dummy values here with your own:

```txt
sudo nmcli con mod "mywifissid" ipv4.addresses 10.0.0.220/24 ipv4.method manual
sudo nmcli con mod "mywifissid" ipv4.gateway 10.0.0.1
sudo nmcli con mod "mywifissid" ipv4.dns "10.0.0.1"
```

> If you have more than one DNS server (the last command above), add them all inside the quotes with a space separating each.

18. Reboot the Pi to pickup its new IP address and lock in all the changes made above, including the change to the hostname: `sudo reboot`

19. After it reboots, check it's on the network OK by typing `ifconfig` and check the output now shows the entries you added in Step 17.
(Alternatively, just see if it responds to pings and you can SSH to it on its new IP).

## Remote config via SSH

At this point I abandoned the keyboard and monitor, continuing the config steps from my PC.

20. SSH to the Pi using your preferred client. If you're using Windows 10 you can just do this from a PowerShell window: `ssh <TheIpAddressFromStep17> -l pi` (Note that's a lower-case L).
21. You should see something like this:
```txt
The authenticity of host '10.0.0.220 (10.0.0.220)' can't be established.
ECDSA key fingerprint is SHA256:Ty0Bw6IZqg1234567899006534456778sFKT6QakOZ5PdJk.
Are you sure you want to continue connecting (yes/no)?
```
22. Enter `yes` and press Return
23. The response should look like this:
```txt
Warning: Permanently added '10.0.0.220' (ECDSA) to the list of known hosts.
pi@10.0.0.220's password:
```
24. Enter the password and press Return.
25. It's STRONGLY recommended that you change the password. Run `passwd` and follow your nose.

## Here's where all the software modules are installed

26. First let's make sure the Pi is all up-to-date:
```txt
sudo apt-get update && sudo apt-get upgrade -y
```

> If this ends with an error "Some index files failed to download. They have been ignored, or old ones used instead." just press up-arrow and return to retry the command. You want to be sure the Pi is healthy and updated before continuing.

> If however you encounter an error saying a certificate is out of date or not valid yet, check that the Pi's real-time clock is correct. `date` on its own will show the date, and you'll set it with this syntax: `sudo date -s '2024-12-25 11:04:00 AEDT'`.

27. `sudo reboot`

Your SSH session will end here. Wait for the Pi to reboot, reconnect, sign back in again and continue.

28. Confirm your current version of python:

```txt
python3 --version
```
The output should look like this, which confirms python 3.11 (ignore the .2):
```txt
Python 3.11.2
```

29. Update the following command if required with that of the same version number:

```txt
sudo apt install python3.11-venv -y
```
```txt
python3 -m venv venv
```
```txt
source venv/bin/activate
```

30. We need to install git so we can download the repo from GitHub:

```
sudo apt-get install git -y
```

31. This downloads the repo, dropping the structure into a subdirectory called `staging`:

```txt
cd ~
```
```txt
sudo rm -rfd staging
```
```txt
git clone --depth=1 https://github.com/greiginsydney/captureKNX staging/captureKNX
```

> Advanced tip: if you're testing code and want to install a new branch direct from the repo, add `-b <branchName>` on the end of the line.

32. This step currently spare.

33. Now we need to move the setup.sh script file into its final location:

```txt
mv -fv "staging/captureKNX/Raspberry Pi/setup.sh" ~
``` 

34. All the hard work is done by the script, but it needs to be made executable first:

```txt
sudo chmod +x setup.sh
```
<br id="setup"/>

35. Now run it! (Be careful here: the switches are critical. "-E" ensures your user path is passed to the script. Without it the software will be moved to the wrong location, or not at all. "-H" passes the Pi user's home directory.)
```txt
sudo -E -H ./setup.sh
```

36. The FIRST time you run the script on a brand new Pi it's going to run for ~8-9 minutes (depending on your internet speed) and then prompt you to reboot:

![image](https://github.com/user-attachments/assets/f9723c88-8f30-4699-b85e-9b024a3c1fe0)

37. Reconnect to the Pi after it reboots and return to Step 35. (Pressing up-arrow should offer you the `sudo -E -H ./setup.sh` command to save you re-typing it.)

38. It will seem to instantly prompt for another reboot. Consent to that and again up-arrow to re-run setup when you re-connect:

![image](https://github.com/user-attachments/assets/ac22daaa-5163-46d9-94d1-385b346f9b65)

39. Here's where the user input foreshadowed at the top comes in. You'll be prompted for answers to these values, but in most cases you'll be OK with hitting return to accept the defaults (although you WILL need to respond correctly to the question of which HAT is installed):

![image](https://github.com/user-attachments/assets/52cba5f6-31b2-40bc-9a6b-873c048ead13)

40. When the installation completes the script will report "Done" and execute a test:

![image](https://github.com/user-attachments/assets/846a6409-b300-442e-ae53-401978dec239)

If the Pi isn't plugged in to the KNX bus at this stage, it's expected that knxd.service will show as "dead". In this example I hadn't yet copied the project file across, and this is also highlighted.

41. captureKNX won't send ANY telegrams anywhere without the project file, so if you haven't aready, copy it across before proceeding.

42. Your next step is to to plug the Pi into the bus and continue with testing.

> You should always try to shut the Pi down before you turn it off: `sudo shutdown now` - or press the button on the rear of the box next to the power LED, and wait a few seconds until the LED turns red.

Jump to [step4-login-to-influxdb](/docs/step4-login-to-influxdb.md)

<br>

[Top](#setup-the-pi)

<hr/>
