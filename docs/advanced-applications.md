# Advanced Applications

The captureKNX described here is a stand-alone on-site device, however if you're a little more adventurous, here are a few more things you can do with it:

- [Setup the Pi as a Wi-Fi Access Point](#setup-the-pi-as-a-wi-fi-access-point)
- [Bake the Wi-Fi credentials into the Pi when you format the drive](#bake-the-Wi-Fi-credentials-into-the-Pi-when-you-format-the-drive)
- [InfluxDB Cloud](#influxdb-cloud)
- [Add remote.it for remote access](#add-remoteit-for-remote-access)
- [NVMe Storage](#nvme-storage)
- [Setup Grafana Alerting](#setup-grafana-alerting)
- [Enable Passwordless SSH from Windows](#Enable-passwordless-ssh-from-windows)


<hr/> 

## Setup the Pi as a Wi-Fi Access Point

<p align="right">
  <img src="https://github.com/user-attachments/assets/f5cd44ab-5219-4930-a20e-c2b0d0e73914" width="25%">
</p>

Let's say you're in the process of configuring and debugging a new KNX installation, but the customer's IT infrastructure's not been commissioned yet. If you can't get the captureKNX onto a network, how can you talk to it?

Not a problem, just turn its host Pi *into* the network! The Raspberry Pi's in-built Wi-Fi radio is able to behave as a Wi-Fi network of its own. You can leave the captureKNX on-site, and each day connect your PC to it and review the logs from overnight and the day before. When the customer's network is provisioned, just flip the captureKNX back to being a client (whether that be wired or wireless).

Note that the Raspberry Pi's on-board hardware only supports 2.4GHz wireless, not 5GHz. (If you have a need for the 5GHz band, you can plug in a USB Wi-Fi dongle.)

The process is documented in [setup-the-Pi-as-an-access-point.md](/docs/setup-the-Pi-as-an-access-point.md)

[Top](#advanced-applications)

<hr>

## Bake the Wi-Fi credentials into the Pi when you format the drive

If your captureKNX will be using Wi-Fi for its network connectivity, you can automatically add the Wi-Fi credentials when you format the storage device, which is a great time-saver.

This somewhat hidden menu in the Raspberry Pi Imager software is accessed with control-shift-x:

<p align="center">
  <img src="https://github.com/user-attachments/assets/ba0f4070-dcd0-4b15-88fd-0a951da6cce6" width="50%">
</p>

Also, don't forget to enable SSH on the Services tab, and the 'use password authentication' option.

[Top](#advanced-applications)

<hr>

## InfluxDB Cloud

<table>
<tr>
  <td><img src="https://github.com/user-attachments/assets/c10f084f-b698-41cc-ba80-40de2f46dddd" width="40%"></td>
  <td><img src="https://github.com/user-attachments/assets/b91e0c99-a018-4654-af1c-3a8df782e55a" width="100%"></td>
</tr>
</table>

The captureKNX uses the free on-site version of InfluxDB. You might see this referenced as their "OSS" version.

They also have a cloud offering, [InfluxDB Cloud](https://www.influxdata.com/products/influxdb-cloud/).

If you're looking at making the captureKNX's captured telegrams accessible off-site, it's possible to have telegraf push them out to an instance of InfluxDB Cloud, and from there you can use [Grafana Cloud](https://grafana.com/products/cloud/) to visualise it.

The setup and config of these are beyond the scope of this project, but they remain an option.

All you need to do is add a new `[[outputs.influxdb_v2]]` section to `/etc/telegraf/telegraf.conf`.

[Top](#advanced-applications)

<hr>

## Add remote.it for remote access

For those looking for a way of keeping the KNX telegrams on-site but still having access on-demand, check out [remote.it](https://www.remote.it/), which is free for non-commercial use.

I've previously used it on the intvlm8r project (which also uses the Raspberry Pi). The setup process for that is [here](https://github.com/greiginsydney/Intervalometerator/blob/master/docs/setup-remote.it.md#install-remoteit).

[Top](#advanced-applications)

<hr>

## NVMe Storage

If you're looking for the most compact physical build and ultimate performance, replace the USB-connected SSD drive with a PCIe NVMe drive.

<p align="center">
  <img src="https://github.com/user-attachments/assets/903e71ea-904d-4c49-8aec-246f632b0470" width="50%">
</p>

Using an NVMe drive is a more complicated setup process because out of the box the Pi won't natively boot to a drive connected to its PCIe port.

We used the [Pimoroni NVMe Base for Raspberry Pi 5](https://shop.pimoroni.com/products/nvme-base?variant=41219587178579), which we sourced from [Core Electronics](https://core-electronics.com.au/nvme-base-for-raspberry-pi-5-nvme-base.html) here in Newcastle for $AUD31. Pimoroni has a [VERY detailed page](https://learn.pimoroni.com/article/getting-started-with-nvme-base) that takes you through the setup steps.

[Amazon.com](https://amzn.to/47WDNKM) has a Chinese equivalent for $USD16.

The image shown here is of the Weinzierl HAT with the Pimoroni NVMe Base. Download the case files from [printables](https://www.printables.com/model/1059175-captureknx-case-for-weinzierl-knx-hat-pimoroni-nvm).

[Top](#advanced-applications)

<hr>

## Setup Grafana Alerting

Grafana has a powerful alerting capability. It can send notifications to a range of destinations, including e-mail and webhooks, as well as numerous third-party applications.

<p align="center">
  <img src="https://github.com/user-attachments/assets/02fa0eff-ea9a-4147-abe4-53705e951198" width="100%">
</p>

References:

- [Get started with Grafana Alerting - Part 1](https://grafana.com/tutorials/alerting-get-started/)
- Watch [Creating alerts with Grafana | Grafana for Beginners Ep 11](https://youtu.be/6W8Nu4b_PXM?si=J4pcHWQqumGRUV31)

&nbsp;<br>

[Top](#advanced-applications)

<hr>

## Enable Passwordless SSH from Windows

It will speed your build times if you enable passwordless SSH from Windows, and it's a simple process.

I've condensed the info from [this post](https://endjin.com/blog/2019/09/passwordless-ssh-from-windows-10-to-raspberry-pi):
&nbsp;<br>

1. Open a PowerShell prompt on Windows
2. `ssh-keygen` and hit return through all the prompts
3. Where it says "Your public key has been saved in...", copy that path to the clipboard
4. Type `scp`, a space, then paste the .pub file path from above - but don't hit return yet
5. Add a trailing space
6. Now copy and paste `pi@10.10.10.10:~\.ssh\authorized_keys`, changing the IP to your Pi before you hit return
7. Enter the Pi's password and hit return
8. Done! You should now be able to ssh to the Pi and not need the password!

The copy line you created in steps 4-6 should look like this:
```
scp C:\Users\YourUser/.ssh/id_ed23456.pub pi@10.10.10.10:~\.ssh\authorized_keys
```

[Top](#advanced-applications)

<hr>
