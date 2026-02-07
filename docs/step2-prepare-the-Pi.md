# Prepare the Pi

You use the [Raspberry Pi Imager](https://www.raspberrypi.com/software/) to download and burn the Pi's operating system onto suitable storage medium.

Download and install that first.

The process to copy the operating system onto your Pi will vary slightly depending on the storage type you've selected:

- [USB-connected SSD](#usb-connected-ssd)

- [PCIe NVMe](/docs/advanced-applications.md#nvme-storage)


## USB-connected SSD

1. Plug the drive into your PC and launch the Raspberry Pi Imager.

2. Click `Raspberry Pi 5` and NEXT:

<p align="center">
  <img src="https://github.com/user-attachments/assets/004cb38e-22f1-4ba4-b83d-8614d8fc7a35" width="50%">
</p>

3. Skipped:

4. Scroll until `Raspberry Pi OS (other)` is in view and click it:

<p align="center">
  <img src="https://github.com/user-attachments/assets/9886b6d9-1de6-4fbe-ab9e-8cbfc5c51ce9" width="50%">
</p>

5. You want the `Raspberry Pi OS Lite (64-bit)` `A port of Debian Trixie with no desktop environment (Compatible with Raspberry Pi 3/4/400/5` version. Click NEXT.

<p align="center">
<img src="https://github.com/user-attachments/assets/4cc5587b-ce43-4851-a903-2d93d4a396b6" width="50%">
</p>

6. At `Select your storage device`, select the destination device and then `NEXT`:

<p align="center">
<img src="https://github.com/user-attachments/assets/20310362-d674-4415-a8b8-b4a768dd3257" width="50%">
</p>

7. If you've [previously baked your Wi-Fi settings into the Imager](/docs/advanced-applications.md#plug-and-play---bake-the-wi-fi-credentials-into-the-pi), you'll be asked if you want to use them in this instance. Click YES to have them applied when the card is formatted:

<p align="center">
<img src="https://github.com/user-attachments/assets/d11380c9-1a42-40f2-a0a9-dd8f970727c4" width="50%">
</p>

8. At the "Are you sure?" prompt, **double-check** you've selected the correct drive before clicking YES:

<p align="center">
<img src="https://github.com/user-attachments/assets/aa80d04d-dfd8-47fb-8fdb-bc4906f305fa" width="50%">
</p>

9. The OS will be written and then verified:

<p align="center">
<img src="https://github.com/user-attachments/assets/36896c36-b51e-4017-8fd1-a829d1ab4227" width="50%">
</p>

10. Upon successful completion you'll be prompted to remove the drive and plug it in to the Pi:

<p align="center">
<img src="https://github.com/user-attachments/assets/72380dd2-dd84-4b3d-bf05-87917a465b63" width="50%">
</p>

11. Done! Jump to [step3-setup-the-Pi.md](/docs/step3-setup-the-Pi.md).

<br/>
<hr>
<br/>

[Top](#prepare-the-pi)
