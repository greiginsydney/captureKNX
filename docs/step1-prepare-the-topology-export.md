# Prepare The Topology Export

captureKNX listens to the KNX bus and logs all it hears.

Unfortunately what's sent on the bus is only the bare minimums for the devices to talk together; they don't need to know the human names that have been assigned to devices or the group addresses, so they're not present.

For captureKNX to 'capture' this information, we need to extract it from the Topology in ETS, and then the logger script will lookup the associated names as each telegram is received.


## Topology Export

The Topology provides us with the details of each sending device, the Group Address a Telegram is sent to, and the nature of the data being sent (the DPT).

> Note that the Topology can't be password-protected. If it is, either remove the password, export and reinstate, or create a copy of the project and remove the password.

1. In ETS6, close the project if you have it open.
2. On the 'Overview' tab, locate the project file and hover the mouse over it:

<p align="center">
<img src="https://github.com/user-attachments/assets/7e0225ff-7884-4c2c-b12d-2b229cc3d891" width="30%">
</p>

3. Click 'Export' on the mini-menu that appears when you hover, and save the project file on your machine.
4. Copy this file to the /home/pi/ directory on the Pi. (You don't need to change its name or do anything else).

> Not sure how to copy? I use a great util called "WinSCP".


TODO: Can I prompt for the password on the Pi to allow the extraction to take place?
