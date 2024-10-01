# Troubleshooting

The knxLogger is a consolidation of multiple open-source & freeware software components, all running on the one Raspberry Pi 5 single board computer.

The 'hat' provides the physical interface to the KNX TP Line, and the ensuing components read and format the telegrams, then stuff them in the InfluxDB database. Grafana is the 'visualisation' component that lets you easily review and filter the raw logs, and/or create dashboards of useful values, all of which you access from a web browser.

![image](https://github.com/user-attachments/assets/e46410d2-74dd-42a9-acd8-e19f3be63a16)

If you're encountering problems with the knxLogger, use this diagram to help understand the flow and where to focus your attention.

## Start here

First off, don't forget the knxLogger is an IT device, so MANY problems will be resolved just by turning it off and back on again - or at least a reboot.

`sudo reboot now`

If the problems are continuing after a reboot, run the setup script's `test` mode and see what it reports. A healthy system should report all greens. Any yellows require investigation:

`sudo -E -H ./setup.sh test`

![image](https://github.com/user-attachments/assets/8afd556d-7d82-4953-a8da-d9ca40f6b516)

The tests check common errors and misconfigurations, and will be added to as the knxLogger evolves. It needs to be said however that sometimes the script will report everying PASSing, but the knxLogger's still misbehaving. Further investigation is required.


## knxd

knxd reads what's coming from the bus and makes it available for KNXDClient and the knxLogger script.

TODO

## KNXDclient

KNXDclient doesn't run as a service, so it's not something you can directly test. Skip to the knxLogger, as it uses KNXDclient to talk to the bus.

## knxLogger

`sudo systemctl status knxLogger.service` should report more green: a green dot, and `active (running)`.

![image](https://github.com/user-attachments/assets/452c757b-8ab2-40f4-b9cf-c55c355b1381)

If text has vanished off to the RHS of the screen (like as shown on the bottom line here) use your right arrow key to scroll the view (and left arrow to return).

Press `Q` to exit this view.

Any errors with the script and its service should be visible.

Review the content of the `/home/pi/knxLogger/knxLogger.log` file. 

Search for occurrences of the text "unzip_topo_archive". This is logged each time the script is launched. Here are the three possible messages:

#### unzip_topo_archive: No topology file found
Whoops. This is *probably* a fatal error: you've forgotten to copy the project file across, so knxLogger (and KNXDClient) don't know how to interpret the telegrams being received. Worst case: all telegrams are being discarded.

(If you've previously copied a file across and the script's already unzipped it to extract 0.xml and project.xml, its absence won't be fatal.)

#### unzip_topo_archive: Unzipping /home/pi/5AB-20240926.knxproj

The script has found a new/newer project file and it's been unzipped and decoded. The subsequent log messages may point to issues here.

#### unzip_topo_archive: existing XML files are younger than /home/pi/5AB-20240926.knxproj. Skipping extraction

An established (healthy) knxLogger should report this frequently.

If the issue you're chasing is missing telegrams, copy a fresh project file across and restart the knxLogger service with `sudo systemtctl restart knxLogger.service`.


## telegraf

telegraf runs as a service, so check if it's running OK. The output will look similar to that for the konxLogger.

`sudo systemctl status telegraf.service`

Edit `/etc/telegraf/telegraf.conf` to enable debug logging:

  ```text
## Log at debug level.
debug = true
## Log only error level messages.
quiet = false
```
Don't forget to turn this back off after, as debug logs will contribute to unnecessary hard drive bloat.

## InfluxDB

TODO 

## Grafana

TODO
