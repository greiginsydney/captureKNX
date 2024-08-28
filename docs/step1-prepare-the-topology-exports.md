# Prepare The Topology Exports


knxLogger listens to the KNX bus and logs all it hears.

Unfortunately what's sent on the bus is only the bare minimums for the devices to talk together; they don't need to know the human names that have been assigned to devices or the group addresses, so they're not present.

For knxLogger to 'capture' this information, we need to extract it from the Topology in ETS, and then the logger script will lookup the associated names as each telegram is received.

> At this stage, knxLogger **doesn't** read the topology file directly. You need to export a Topology Report and a Group Address list, and copy them to the Pi. A direct read of the Topology file is planned for a future update.

## Topology Report

The Topology provides us with the details of each (sending) device.

### Short version:

1. In ETS6, open a `Reports` pane.
2. Navigate to Project Structure / Topology.
3. Click the Export button.
4. Browse to the folder you want the file to go.
5. Set the file name as `TopoExport.csv'.
6. Change the `Save as type` to be `CSV files (*.csv)`.
7. Click Save.

> ETS exports this text in a 16-bit character format that's 'challenging' to read, so we need to cycle the file through a program to convert it to `utf-8'. I use [Notepad++](https://notepad-plus-plus.org/downloads/) and I heartily recommend it to everyone as a brilliant and powerful freeware text editor. The next steps assume you're doing same. If you're using a different editor the process will be similar.

8. Open TopoExport.csv in Notepad-++.
9. Click `Encoding` in the menu at the top. You should see the current formatting highlighted by the dot as `UTF-16 LE BOM`. Select `Convert to UTF-8`:

<p align="center">
<img src="https://github.com/user-attachments/assets/9a20d1df-e280-42ad-8bf1-2fc931cf1224" width="40%">
</p>

10. Save the file and exit NP++.
11. Copy this file to the /home/pi/knxLogger directory on the Pi.

TODO: flesh this out and add screen grabs.
TODO: add an alternative text editor??

## Group Addresses

The Group Address export tells knxLogger both the name and the DPT type for each message, so it's crucial.

> If the file's missing knxLogger won't run, and if a telegram is received for a GA that isn't in the file, that telegram will be discarded.

12. In ETS6, open a `Group Addresses` pane.
13. Right-click on the root node of the Group Addresses and select Export:

<p align="center">
<img src="https://github.com/user-attachments/assets/56c282c7-6646-4c4a-b25f-134875ccb9c4" width="40%">
</p>



TODO: Decide on XML or CSV. 
