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

3. Scroll until `Raspberry Pi OS (other)` is in view and click it:

<p align="center">
  <img src="https://github.com/user-attachments/assets/9886b6d9-1de6-4fbe-ab9e-8cbfc5c51ce9" width="50%">
</p>

4. You want the `Raspberry Pi OS Lite (64-bit)` `A port of Debian Trixie with no desktop environment (Compatible with Raspberry Pi 3/4/400/5` version. Click NEXT.

> Trixie is recommended, however Bookworm is still supported.

<p align="center">
<img src="https://github.com/user-attachments/assets/4cc5587b-ce43-4851-a903-2d93d4a396b6" width="50%">
</p>

5. At `Select your storage device`, select the destination device and then `NEXT`:

<p align="center">
<img src="https://github.com/user-attachments/assets/20310362-d674-4415-a8b8-b4a768dd3257" width="50%">
</p>

6. Choose a hostname. I suggest captureKNX will be fine. Click NEXT:

<p align="center">
<img src="https://github.com/user-attachments/assets/798221cf-446a-4c9f-b874-5ea17074831a" width="50%">
</p>

7. Add your localisation settings as applicable and click NEXT:

<p align="center">
<img src="https://github.com/user-attachments/assets/6da22cf2-c83a-4d60-a9c8-ad39832a7923" width="50%">
</p>

8. The Pi has historically used a default username of 'pi' and password 'raspberry'. Here they give you the opportunity to choose somethinmg more secure:

<p align="center">
<img src="https://github.com/user-attachments/assets/6779c12e-7cf8-4f07-80fc-a0c95ead833c" width="50%">
</p>

9. If you'll be using a Wi-Fi connection, add the details here, or just click NEXT:

<p align="center">
<img src="https://github.com/user-attachments/assets/b91773af-7d05-4b1b-8331-479c451d7e9f" width="50%">
</p>

10. Enable SSH so you can administer the Pi over the network. Password authentication is the most common authentication mechanism:

<p align="center">
<img src="https://github.com/user-attachments/assets/71969aed-4f47-4b8b-bae9-5713836a8ae5" width="50%">
</p>

11. Raspberry Pi Connect is a new remote access service. Click 'What is Raspberry Pi Connect' to learn more. I leave it off. Click NEXT:

<p align="center">
<img src="https://github.com/user-attachments/assets/947e8f75-8e2a-4c49-933f-d5f2512dc048" width="50%">
</p>

12. Check your settings are correct and click WRITE:

<p align="center">
<img src="https://github.com/user-attachments/assets/321be3d4-cc58-4a74-b36a-3c4afacd7417" width="50%">
</p>

13. A popup will appear and require you to reconfirm. There is a delay before the button lights up:

<p align="center">
<img src="https://github.com/user-attachments/assets/21269c52-72fc-49b6-915a-53e5480b547c" width="50%">
</p>

14. Writing and verification will take a couple of minutes:

<p align="center">
<img src="https://github.com/user-attachments/assets/368543e5-7d54-4e86-b4b3-fef9d1213802" width="50%">
<br>
<img src="https://github.com/user-attachments/assets/b094e57e-107b-49da-9b18-f18c0367d550" width="50%">
</p>

15. Upon successful completion you'll be prompted to remove the drive and plug it in to the Pi:

<p align="center">
<img src="https://github.com/user-attachments/assets/234463b0-e2ff-4dbf-96d5-271ee63821bd" width="50%">
</p>

16. Done! Jump to [step3-setup-the-Pi.md](/docs/step3-setup-the-Pi.md).

<br/>
<hr>
<br/>

[Top](#prepare-the-pi)
