# Shopping list

To build the captureKNX as described, you'll need the following parts.

Your outlay will be approximately $USD200 / $AUD260, although this does _not_ include shipping costs or the cost of a 3D-printed enclosure.

## Variations

There are a number of different variations:

- Drive storage
  -   an external USB3 SSD. This is the default presented here. More reliable and way faster than a microSD card
  -   microSD card. Not officially supported. More about that [here](/docs/FAQ.md#can-i-build-the-captureKNX-using-a-microsd-card)
  -   a PCIe NVMe drive. The most expensive option, complicated to setup, but delivers a VERY compact box and blindingly fast performance. See [NVMe storage](/docs/advanced-applications.md#nvme-storage)
- KNX interface board
  -  Tijl's board from Tindie
  -  the Weinzierl 838 kBerry

<hr/>

### Raspberry Pi 5

You DEFINITELY need a Pi 5, as we're asking a lot of this little SBC.

It doesn't use much memory, so the 2GB version will be fine.

- I sourced mine from [Core Electronics](https://core-electronics.com.au/raspberry-pi-5-model-b-2gb.html) here in Newcastle AU for $AUD82
- I can't find the 2GB version on [Amazon.com](https://amzn.to/4e2eQiR) yet, but here's the 4G for $US70

### Pi 5 power supply

Don't skimp and re-use an old Pi4 power supply, as you run the risk of the Pi not booting up automatically. Remember it also has to power the SSD.

- [Core Electronics](https://core-electronics.com.au/raspberry-pi-5-power-supply-usb-c-pd-27w-white.html) again. $AUD21
- [Amazon.com](https://amzn.to/3AGWUvP) has the US version for $US19

### Low-profile heatsink for Raspberry Pi 5

The Pi 5 doesn't ship with one, but the chipset gets BURNY hot. You definitely need a heatsink and fan.

- Core has The Pi Hut's 105875 [Low-profile Heatsink for Raspberry Pi 5](https://core-electronics.com.au/low-profile-heatsink-raspberry-pi-5.html) for $AUD6.25
- An alternative is Waveshare's 26415 [Passive Aluminum Heatsink For Raspberry Pi 5](https://core-electronics.com.au/passive-aluminum-heatsink-for-raspberry-pi-5.html) for $AUD4.80
- [The Pi Hut](https://thepihut.com/products/low-profile-heatsink-for-raspberry-pi-5) - £2.92 excl. VAT
- [Waveshare](https://www.waveshare.com/pi5-active-cooler-c.htm) - $US3
- [Amazon.com](https://amzn.to/3Y9cSa9) - $US7.68

### Pi 5 cooling fan

We've gone with a discrete 30x30x7mm cooling fan here, and it's essential it has a 4-pin JST connector.

You can't use the official 'Active Cooler' because it won't fit under either of the suggested KNX 'HATs'. It's also a 'blower' fan so it won't do even if you separate it from the heatsink and mount it to the side of the box.

Here are the only ones we've found so far:
* [Ali Express](https://www.aliexpress.com/item/1005006278639024.html)
* [eBay AU](https://www.ebay.com/itm/305302554079) (but shipping from China)
* Amazon AU - none found
* Amazon US - none found

### micro-HDMI to HDMI adapter cable (optional?)

If this is your first Pi 4 or 5 project you probably won't already have one of these in your toolbox, but the people who sell the Pi will have these in abundance.

You only need this for the initial build steps, and you can actually skip it altogether if you've pre-stuffed some Wi-Fi credentials into the SSD or are using an Ethernet connection, and are able to query the local DHCP server to find out the Pi's IP address. But it's a nice-to-have.

- Core Electronics [Micro-HDMI to Standard HDMI 1M Cable](https://core-electronics.com.au/raspberry-pi-micro-hdmi-to-standard-hdmi-1m-cable.html) for $AU9
- Amazon.com has a [6' 4K Micro HDMI to HDMI Male Cable Adapter](https://amzn.to/4f6dFiZ) for $US9

### USB Keyboard (optional?)

Again, if you're new to the Pi you're probably going to need to plug a keyboard into it to perform the setup steps. As above, if you're able to get the Pi on a network and determine its IP address, you can skip this and do all the config from your destktop/laptop.

<hr/>

### 2.5" Solid State Drive

Buy the smallest 2.5" SATA SSD you can find.

A basic installation - before you start logging - only consumes 4G.

The smallest I can source today is 240G @ $AUD33 ($US22).

[Amazon.com](https://amzn.to/3YYApg4) has a Kingston for $US25

### 2.5" SATA SSD adapter cable

Make sure you get a USB3.x version, and one that's been tested and found compatible with the Pi. (If you buy your adapter from the same place you get your Pi you should be good.)

[Core Electronics](https://core-electronics.com.au/pimoroni-sata-hard-drive-to-usb-adapter.html) sells the [Pimoroni ADP001](https://shop.pimoroni.com/products/sata-hard-drive-to-usb-adapter?variant=14241654983) for $AUD18.

You'll get similar from [Amazon](https://amzn.to/3AJnPr3) in the US for $US10 (but I can't say for sure it's going to work with the Pi).

<hr/> 

### KNX Pi HAT - option 1: Tijl/Tindie

I used Tijl's KNX Pi HAT from [Tindie](https://www.tindie.com/products/cpu20/knx-raspberry-pi-HAT/) for most of my development. This seems to be permanently out of stock until enough people join the waitlist, then they do a production run of new boards.

<p align="center">
  <img src="https://github.com/user-attachments/assets/956aabb9-2975-4a0e-a448-cbec3ba2f691" width="30%">
</p>

$USD67 / $AUD100

### KNX Pi HAT - option 2: Weinzierl 838 kBerry

<p align="center">
  <img src="https://github.com/user-attachments/assets/858f8284-b68a-489c-af83-7137fa928886" width="30%">
</p>

The [Weinzierl 838 kBerry](https://weinzierl.de/en/products/knx-baos-modul-838/) is another plugin daughterboard (HAT) for the Pi.

You can get those in Australia, NZ or the UK from [Ivory Egg](https://ivoryegg.com.au/shop/products/weinzierl-weinzierl-knx-baos-module-838-kberry).

$USD123 / $AUD180

<hr/> 

### Raspberry Pi "stackable" header

Both of the above boards sit a little close to the processor of the Pi, and it's going to need some air flow. We used \*TWO\* headers to give enough height.

- Core has the [Pololu-2748 Stackable 0.100″ Female Header: 2x20-pin, Straight](https://core-electronics.com.au/stackable-0-100-female-header-2x20-pin-straight.html) for $4.95. ([Pololu link](https://www.pololu.com/product/2748))
- Core also has a [Raspberry Pi Extra-Long Stacking Header (2x20 pins)](https://core-electronics.com.au/stacking-2x20.html) [NB: untested] for $AUD2.40
- [Amazon.com GeeekPi 2x20 40 Pin Stacking Female Header Kit for Raspberry Pi](https://amzn.to/3Yn1GIm) $US14 (13 piece kit)
- [Amazon.com Geekworm 2x20 40 Pin Stacking Female Header Kit for Raspberry Pi](https://amzn.to/48bDHyX) $US10 (10 piece kit)

### Mounting screws and spacers - Tijl HAT

The Pi HAT from Tindie needs to be screwed to the Pi, and this pair of boards then slot into the custom housing below.

- 4 x 5-6mm long M3 machine screws. Mounts the SSD to the case
- 8 x 5-6mm long M2.5 pan head machine screws. Mounts the Pi to the case and the HAT to the Pi
- 4 x 21mm long M2.5 female-female threaded spacers

I get my spacers from [Mouser](https://au.mouser.com/c/electromechanical/hardware/standoffs-spacers/?q=m2.5%20spacer&gender=Female%20%2F%20Female&length=21%20mm&material=Aluminum~~Brass%7C~Stainless%20Steel~~Steel&thread%20size=M2.5~~M2.5%20x%200.45&rp=electromechanical%2Fhardware%2Fstandoffs-spacers%7C~Thread%20Size%7C~Gender%7C~Material) or Element14/Farnell - or if you're up for it, you can 3D-print them (see below for a link).

Let's call it $10.

### Mounting screws - Weinzierl HAT

Weinzierl's HAT has no holes for mounting screws, and is instead held in position by lugs in the case and lid.

- 4 x 5-6mm long M3 machine screws. Mounts the SSD to the case
- 4 x 5-6mm long M2.5 pan head machine screws (or 4 x 4G self-tappers). Mounts the Pi to the case

Let's call it $10 just to keep the maths even.

<hr/>

### A housing to put it all in

My partner Ozrocky has designed a case you can print for all this to fit inside. The art is on Printables:

- [Tijl's HAT + SSD](https://www.printables.com/model/1041238-captureknx-ssd-case-for-tijl-knx-hat)
- [Weinzierl HAT + SSD](https://www.printables.com/model/1042200-captureknx-ssd-case-for-weinzierl-knx-hat)

<hr/>
<br>
Note that any Amazon links on this page are Affiliate links. I may earn some recognition if you go there, but you pay no extra for this.

<br>&nbsp;

[Top](#shopping-list)
