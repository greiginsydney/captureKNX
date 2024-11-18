## Setup the Pi as an Access Point
You should only perform the steps here once you've completed the config steps and tested the Pi.

This process will drop it off any active Wi-Fi network and turn it into its own network and Access Point, at which time it will lose Internet access and be unable to load new software components.

Skip this document entirely if you're NOT wanting the Pi to be a Wi-Fi Access Point and accept client connections directly.\[[1](#1-configuring-the-pi-as-a-Wi-Fi-ap)\] \[[2](#2-setting-up-a-raspberry-pi-as-an-access-point-in-a-standalone-network-nat)\]


- [Make AP](#make-ap)
- [Revert to wired connection: 'unmake' AP](#unmake-ap)

## Starting from scratch?
Jump to [step 1 - prepare the topology export](/docs/step1-prepare-the-topology-export.md).

## Make AP

1. Run the setup script with the "ap" attribute:
```txt
sudo -E ./setup.sh ap
```

2. The script will prompt you for all the required values. On its first run out of the box it will offer default values. These will usually be safe to use, but by all means change the SSID and Wi-Fi password from the defaults:

```txt
This process will configure the Pi as a Wi-Fi access point - its own Wi-Fi network
(Control-C to abort at any time)

If unsure of any question, accept the defaults until you get to the SSID and password

Choose an IP address for the Pi        : 10.10.10.1
Choose the starting IP address for DCHP: 10.10.10.10
Choose  the  ending IP address for DCHP: 10.10.10.100
Set the appropriate subnet mask        : 255.255.255.0
Pick a nice SSID                       : captureKNX
Choose a better password than this     : myPiNetw0rkAccess!
Choose an appropriate Wi-Fi channel    : 1
```

> The default radio channel #1 is valid around the world, HOWEVER you may find it congested in your area and choosing another may provide better connectivity.\[[3](#3-list-of-wlan-channels)\]

3. Upon completion the script will prompt for a reboot. 

```txt
WARNING: After the next reboot, the Pi will come up as a Wi-Fi access point!
Reboot now? [Y/n]:
```

> After this reboot you'll need to connect to it on its new IP address, and you'll be again prompted to trust it.



## Un-make AP

1. If at any time you want to switch the Pi from being an Access Point to being a client on another network, run:
```txt
sudo -E ./setup.sh noap

This process will stop the Pi from being a Wi-Fi access point & instead connect to a wired or wireless network
(Control-C to abort at any time)

Setup a new wireless network? (Select N for wired) [y/n]:
```

2. If you choose Y, the script will then prompt you to set or reconfirm the Wi-Fi details:
```txt
Set your two-letter Wi-Fi country code : AU
Set the network's SSID                 : yourWi-FiSSID
Set the network's Psk (password)       : 12345Password!
```

3. In the next step you have the option of setting a static IP address and related values. If you respond 'n' to this prompt, the Pi will request a dynamic IP address from the network:
```txt
Do you want to assign the Pi a static IP address? [Y/n]: y
Choose an IP address for the Pi         : 192.168.19.123
Set the appropriate subnet mask         : 255.255.255.0
Set the Router IP                       : 192.168.19.1
Set the DNS Server(s) (space-delimited) : 192.168.19.2
```

3. Upon completion the script will advise of the impending change and prompt for a reboot. 

3a. Wireless:

```txt
WARNING: If you proceed, the Pi will become a Wi-Fi *client*
WARNING: It will attempt to connect to the 'abortretryignore' network
Press any key to continue or ^C to abort

Reboot now? [Y/n]:
```

3b. Wired:

TODO

## Debugging

### Can't find the Pi's Wi-Fi network?
- TODO
### Can see but can't connect to the Pi's Wi-Fi network?
- check the dnsmasq service is running OK: `sudo service dnsmasq status`
- is the Pi's local IP showing correctly in the wlan0 section of `ifconfig`?

<br>
<hr >

## References

#### [1] [Configuring the Pi as a Wi-Fi AP](https://github.com/SurferTim/documentation/blob/6bc583965254fa292a470990c40b145f553f6b34/configuration/wireless/access-point.md)
#### [2] [Setting up a Raspberry Pi as an access point in a standalone network (NAT)](https://www.raspberrypi.org/documentation/configuration/wireless/access-point.md)
#### [3] [List of WLAN channels](https://en.wikipedia.org/wiki/List_of_WLAN_channels#2.4_GHz_(802.11b/g/n/ax))
