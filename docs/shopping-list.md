# Shopping list

To build the knxLogger as described, you'll need the following parts.

Your outlay will be approximately $USD200 / $AUD260, although this does _not_ include shipping costs or the cost of a 3D-printed enclusure.

## Variations

There are a number of different variations:

- Drive storage
  -   an external USB3 SSD. This is the default presented here. More reliable and way faster than a microSD card
  -   microSD card. Not officially supported. More about that [here](/docs/FAQ.md#can-i-build-the-knxlogger-using-a-microsd-card)
  -   a PCIe NVMe drive. The most expensive option, complicated to setup, but delivers a VERY compact box and blindingly fast performance. See [NVMe storage](/docs/advanced-applications.md#nvme-storage)
- KNX interface board
  -  Tijl's board from Tindie
  -  the Weinzierl 838 kBerry

<hr/>

### Raspberry Pi 5

You DEFINITELY need a Pi 5, as we're asking a lot of this poor little SBC.

It doesn't use much memory, so the 2GB version will be fine.

* I sourced mine from [Core Electronics](https://core-electronics.com.au/raspberry-pi-5-model-b-2gb.html) here in Newcastle AU for $AUD82.
* I can't find the 2GB version on [Amazon.com](https://amzn.to/4e2eQiR) yet, but here's the 4G for $US70.

### Pi 5 power supply

Don't skimp and re-use an old Pi4 power supply, as you run the risk of the Pi not booting up automatically. Remember it also has to power the SSD.

* [Core Electronics](https://core-electronics.com.au/raspberry-pi-5-power-supply-usb-c-pd-27w-white.html) again. $AUD21
* [Amazon.com](https://amzn.to/3AGWUvP) has the US version for $US19.

### Pi 5 cooling fan

We've gone with a discrete 30x30x7mm cooling fan here, and it's essential it has a 4-pin JST connector.

You can't use the official 'Active Cooler' because it won't fit under either of the suggested KNX 'HATs'. It's also a 'blower' fan so it won't do even if you separate it from the heatsink and mount it to the side of the box.

Here are the only ones we've found so far:
* [Ali Express](https://www.aliexpress.com/item/1005006278639024.html)
* [eBay AU](https://www.ebay.com/itm/305302554079) (but shipping from China)
* Amazon AU - none found
* Amazon US - none found

<hr/>

### 2.5" Solid State Drive

Buy the smallest 2.5" SATA SSD you can find.

A basic installation - before you start logging - only consumes 4G.

The smallest I can source today is 240G @ $AUD33 ($US22).

[Amazon.com](https://amzn.to/3YYApg4) has a Kingston for $US25.

### 2.5" SATA SSD adapter cable

Make sure you get a USB3.x version, and one that's been tested and found compatible with the Pi. (If you buy your adapter from the same place you get your Pi you should be good.)

[Core Electronics](https://core-electronics.com.au/pimoroni-sata-hard-drive-to-usb-adapter.html) sells the [Pimoroni ADP001](https://shop.pimoroni.com/products/sata-hard-drive-to-usb-adapter?variant=14241654983) for $AUD18.

You'll get similar from [Amazon](https://amzn.to/3AJnPr3) in the US for $US10 (but I can't say for sure it's going to work with the Pi).

<hr/> 

### KNX Pi HAT - option 1: Tijl/Tindie

I used Tijl's KNX Pi HAT from [Tindie](https://www.tindie.com/products/cpu20/knx-raspberry-pi-hat/) for most of my development. This seems to be permanently out of stock until enough people join the waitlist, then they do a production run of new boards.

<p align="center">
  <img src="https://github.com/user-attachments/assets/956aabb9-2975-4a0e-a448-cbec3ba2f691" width="30%">
</p>

$USD67 / $AUD100

### Raspberry Pi "stackable" header (Tijl hat only)

This header extends the lengths of the Pi's GPIO header pins so they'll reach the KNX hat mounted high above.
Core has a [Raspberry Pi Extra-Long Stacking Header (2x20 pins)](https://core-electronics.com.au/stacking-2x20.html) for $AUD2.40, and the [Pololu-2748 Stackable 0.100″ Female Header: 2x20-pin, Straight](https://core-electronics.com.au/stackable-0-100-female-header-2x20-pin-straight.html) for $4.95. ([Pololu link](https://www.pololu.com/product/2748))

### KNX Pi HAT - option 2: Weinzierl 838 kBerry

<p align="center">
  <img src="https://github.com/user-attachments/assets/0d0d85d4-6b17-463c-901e-e14561c4833a" width="30%">
</p>
<p align="center">Image credit: <a href="https://knxshoponline.co.uk/knx-baos-module-838-kberry" target="_blank">KNX Shop online UK</a></p>

The [Weinzierl 838 kBerry](https://weinzierl.de/en/products/knx-baos-modul-838/) is another plugin daughterboard (HAT) for the Pi.

You can get those in Australia, NZ or the UK from [Ivory Egg](https://ivoryegg.com.au/shop/products/weinzierl-weinzierl-knx-baos-module-838-kberry).

$USD123 / $AUD180

<hr/> 

### Mounting screws and spacers (Tijl hat only)

The Pi hat from Tindie needs to be screwed to the Pi, and this pair of boards then slot into the custom housing below.

You need 2.5mm machine screws, washers, and 20mm threaded spacers. I get mine from Mouser:

8 x 6mm long machine screws & washers
4 x 20mm long threaded spacers

Let's call it $10.

### Mounting screws (Weinzierl hat only)

Weinzierl's hat has no holes for mounting screws, and is instead held in position by lugs in the case and lid.

In this configuration the Pi itself is screwed into the base of the case.

You need 4 x 2.5mm self-tappers or machine screws.

Let's call it $10 just to keep the maths even.


### A housing to put it all in

My partner Rocky has designed a case you can print for all this to fit inside. The art is on TODO.

<hr/>
<br>
Note that any Amazon links on this page are Affiliate links. I may earn some recognition if you go there, but you pay no extra for this.
