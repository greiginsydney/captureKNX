# Prepare the Pi

You use the [Raspberry Pi Imager](https://www.raspberrypi.com/software/) to download and burn the Pi's operating system onto suitable storage medium.

Download and install that first.

The process to copy the operating system onto your Pi will vary slightly depending on the storage type you've selected:

- [USB-connected SSD](#usb-connected-ssd)

- [PCIe NVMe](/docs/advanced-applications.md#nvme-storage)


## USB-connected SSD

1. Plug the drive into your PC and launch the Raspberry Pi Imager.

2. Click `CHOOSE DEVICE`:

<p align="center">
  <img src="https://github.com/user-attachments/assets/48df65a7-738b-493f-9e3f-3e3defbd3766" width="50%">
</p>

3. Select a Pi 5:
 
<p align="center">
  <img src="https://github.com/user-attachments/assets/a9378ecd-231c-4dd5-99e9-89180171a1d0" width="50%">
</p>

4. Having selected the device, now click `CHOOSE OS` and select `Raspberry Pi OS (other)`:
<p align="center">
  <img src="https://github.com/user-attachments/assets/1583d726-06c1-4b54-b280-9537ce648574" width="50%">
</p>

5. You want the `Raspberry Pi OS Lite (64-bit)` `A port of Debian Bookworm with no desktop environment (Compatible with Raspberry Pi 3/4/400/5` version.

<p align="center">
<img src="https://github.com/user-attachments/assets/a6ff10f2-6b27-4745-953e-fd7cd7c4871e" width="50%">
</p>

6. Now click `CHOOSE STORAGE`, select the destination device and then `NEXT`:

<p align="center">
<img src="https://github.com/user-attachments/assets/a2443a96-bf9a-4673-a62e-5c9ddb08d7b2" width="50%">
</p>

7. At the "Are you sure?" prompt, **double-check** you've selected the correct drive before clicking YES:

<p align="center">
<img src="https://github.com/user-attachments/assets/aa80d04d-dfd8-47fb-8fdb-bc4906f305fa" width="50%">
</p>

8. The OS will be written and then verified:

<p align="center">
<img src="https://github.com/user-attachments/assets/36896c36-b51e-4017-8fd1-a829d1ab4227" width="50%">
</p>

9. Upon successful completion you'll be prompted to remove the drive and plug it in to the Pi:

<p align="center">
<img src="https://github.com/user-attachments/assets/2dddabd4-85a7-4a96-9335-74cd7959549a" width="50%">
</p>

10. Done! Jump to [step3-setup-the-Pi.md](/docs/step3-setup-the-Pi.md).

<br/>
<hr>
<br/>

[Top](#prepare-the-pi)
