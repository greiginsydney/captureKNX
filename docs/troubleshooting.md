# Troubleshooting

The knxLogger is a consolidation of multiple open-source & freeware software components, all running on the one Raspberry Pi 5 single board computer.

The 'hat' provides the physical interface to the KNX TP Line, and the ensuing components read and format the telegrams, then stuff them in the InfluxDB database. Grafana is the 'visualisation' component that lets you easily review and filter the raw logs, and/or create dashboards of useful values, all of which you access from a web browser.

![image](https://github.com/user-attachments/assets/e46410d2-74dd-42a9-acd8-e19f3be63a16)

If you're encountering problems with the knxLogger, use this diagram to help understand the flow and where to focus your attention.

- [Start here](https://github.com/greiginsydney/knxLogger/blob/main/docs/troubleshooting.md#start-here)
- [knxd](https://github.com/greiginsydney/knxLogger/blob/main/docs/troubleshooting.md#knxd)
- [KNXDClient](https://github.com/greiginsydney/knxLogger/blob/main/docs/troubleshooting.md#knxdclient)
- [knxLogger](https://github.com/greiginsydney/knxLogger/blob/main/docs/troubleshooting.md#knxLogger)
- [telegraf](https://github.com/greiginsydney/knxLogger/blob/main/docs/troubleshooting.md#telegraf)
- [InfluxDB](https://github.com/greiginsydney/knxLogger/blob/main/docs/troubleshooting.md#influxdb)
- [Grafana](https://github.com/greiginsydney/knxLogger/blob/main/docs/troubleshooting.md#grafana)

<hr/>

## Start here

First off, don't forget the knxLogger is an IT device, so MANY problems will be resolved just by turning it off and back on again - or at least a reboot.

`sudo reboot now`

If the problems are continuing after a reboot, run the setup script's `test` mode and see what it reports. A healthy system should report all greens. Any yellows require investigation:

`sudo -E -H ./setup.sh test`

![image](https://github.com/user-attachments/assets/8afd556d-7d82-4953-a8da-d9ca40f6b516)

The tests check common errors and misconfigurations, and will be added to as the knxLogger evolves. It needs to be said however that sometimes the script will report everying PASSing, but the knxLogger's still misbehaving. Further investigation is required.

<br>

[Top](https://github.com/greiginsydney/knxLogger/blob/main/docs/troubleshooting.md#troubleshooting)

<hr>

## knxd

knxd reads what's coming from the bus and makes it available for KNXDClient and the knxLogger script.

You can check if knxd is running OK with `sudo systemctl status knxd`. If there's any red in the output, check if there's anything of interest in the journal (`journalctl | grep knxd`):

#### Opening /dev/ttyKNX1 failed: No such file or directory

```
Oct 08 14:24:41 knxLogger-Weinzierl systemd[1]: Stopped knxd.service - KNX Daemon.
Oct 08 14:24:41 knxLogger-Weinzierl systemd[1]: Starting knxd.service - KNX Daemon...
Oct 08 14:24:41 knxLogger-Weinzierl knxd[1309]: E00000067: [19:B.tpuarts] Opening /dev/ttyKNX1 failed: No such file or directory
Oct 08 14:24:41 knxLogger-Weinzierl knxd[1309]: F00000105: [16:B.tpuarts] Link down, terminating
Oct 08 14:24:41 knxLogger-Weinzierl systemd[1]: Started knxd.service - KNX Daemon.
Oct 08 14:24:41 knxLogger-Weinzierl systemd[1]: knxd.service: Main process exited, code=exited, status=1/FAILURE
Oct 08 14:24:41 knxLogger-Weinzierl systemd[1]: knxd.service: Failed with result 'exit-code'.
```

The config looked good for this one. This is what it's meant to look like, with ttyAMA0 owned by knxd/dialout and its alias ttyKNX1 by root/root:
```
pi@knxLogger-Weinzierl:~ $ ls -l /dev/tty[A-Z]*
crw-rw---- 1 knxd dialout 204, 64 Oct  8 14:35 /dev/ttyAMA0
crw-rw---- 1 root dialout 204, 74 Oct  8 14:32 /dev/ttyAMA10
lrwxrwxrwx 1 root root          7 Oct  8 14:31 /dev/ttyKNX1 -> ttyAMA0
crw-rw---- 1 root dialout   4, 64 Oct  8 14:31 /dev/ttyS0
pi@knxLogger-Weinzierl:~ $
```

This issue was fixed by a reboot.

<br>

[Top](https://github.com/greiginsydney/knxLogger/blob/main/docs/troubleshooting.md#troubleshooting)

<hr>

## KNXDclient

KNXDclient doesn't run as a service, so it's not something you can directly test. Skip to the knxLogger, as it uses KNXDclient to talk to the bus.

<br>

[Top](https://github.com/greiginsydney/knxLogger/blob/main/docs/troubleshooting.md#troubleshooting)

<hr>

## knxLogger

`sudo systemctl status knxLogger.service` should report more green: a green dot, and `active (running)`.

![image](https://github.com/user-attachments/assets/452c757b-8ab2-40f4-b9cf-c55c355b1381)

If text has vanished off to the RHS of the screen (like as shown on the bottom line here) use your right arrow key to scroll the view (and left arrow to return).

Press `Q` to exit this view.

Any errors with the script and its service should be visible. 

Review the error log for obvious issues: `journalctl --no-pager --unit knxLogger`.

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

<br>

[Top](https://github.com/greiginsydney/knxLogger/blob/main/docs/troubleshooting.md#troubleshooting)

<hr>

## telegraf

telegraf runs as a service, so check if it's running OK. The output will look similar to that for the knxLogger.

`sudo systemctl status telegraf.service`

Review the error log for obvious issues: `journalctl --no-pager --unit telegraf`.

Edit `/etc/telegraf/telegraf.conf` to enable debug logging:

  ```text
## Log at debug level.
debug = true
## Log only error level messages.
quiet = false
```

`sudo systemctl restart telegraf.service` to pick up the changes and start logging.

Review the file `/var/log/telegraf/telegraf.log`. (The same file is aliased as `/home/pi/log/telegraf/telegraf.log`.)

Don't forget to turn this back off after, as debug logs will contribute to unnecessary hard drive bloat.

This is an example of a healthy-looking telegraf: The inputs and outputs are 'loaded', and 'connected':

```text
2024-10-02T08:39:30+10:00 I! Loading config: /etc/telegraf/telegraf.conf
2024-10-02T08:39:30+10:00 I! Starting Telegraf 1.32.0 brought to you by InfluxData the makers of InfluxDB
2024-10-02T08:39:30+10:00 I! Available plugins: 235 inputs, 9 aggregators, 32 processors, 26 parsers, 62 outputs, 6 secret-stores
2024-10-02T08:39:30+10:00 I! Loaded inputs: http_listener_v2
2024-10-02T08:39:30+10:00 I! Loaded aggregators:
2024-10-02T08:39:30+10:00 I! Loaded processors:
2024-10-02T08:39:30+10:00 I! Loaded secretstores:
2024-10-02T08:39:30+10:00 I! Loaded outputs: file influxdb_v2
2024-10-02T08:39:30+10:00 I! Tags enabled:
2024-10-02T08:39:30+10:00 I! [agent] Config: Interval:10s, Quiet:false, Hostname:"", Flush Interval:10s
2024-10-02T08:39:30+10:00 D! [agent] Initializing plugins
2024-10-02T08:39:30+10:00 D! [agent] Connecting outputs
2024-10-02T08:39:30+10:00 D! [agent] Attempting connection to [outputs.file]
2024-10-02T08:39:30+10:00 D! [agent] Successfully connected to outputs.file
2024-10-02T08:39:30+10:00 D! [agent] Attempting connection to [outputs.influxdb_v2]
2024-10-02T08:39:30+10:00 D! [agent] Successfully connected to outputs.influxdb_v2
2024-10-02T08:39:30+10:00 D! [agent] Starting service inputs
2024-10-02T08:39:30+10:00 I! [inputs.http_listener_v2] Listening on [::]:8080
2024-10-02T08:39:40+10:00 D! [outputs.file] Buffer fullness: 0 / 10000 metrics
```

### debug_output.log

In the same folder as `telegraf.log` is the file `debug_output.log`. This is an independent log of all telegrams captured by telegraf. Healthy content in this file is a good indicator that everything to this point (the physical connection, hat, knxd, KNXDClient and the knxdLogger) are OK.

<br>

[Top](https://github.com/greiginsydney/knxLogger/blob/main/docs/troubleshooting.md#troubleshooting)

<hr>

## InfluxDB

InfluxDB runs as a service, so check if it's running OK. The output will look similar to that for the other services.

`sudo systemctl status influxdb.service`

Review the error log for obvious issues: `journalctl --no-pager --unit influxdb`. 

<br>

[Top](https://github.com/greiginsydney/knxLogger/blob/main/docs/troubleshooting.md#troubleshooting)

<hr>

## Grafana

Grafana runs as a service, so check if it's running OK. The output will look similar to that for the other services.

`sudo systemctl status grafana-server`

Review the error log for obvious issues: `journalctl --no-pager --unit grafana-server`. 

Also see `/var/log/grafana/grafana.log`. Don't be worried if you see this: 

```text
logger=licensing.renewal t=2024-10-02T09:05:41.329592241+10:00 level=warn msg="failed to load or validate token" err="license token file not found: /var/lib/grafana/license.jwt"
```

We're running the Enterprise *build* of the software, but it runs unlicenced in its freeware guise.

### Not seeing telegrams / Dashboards report TODO?

Check Grafana and InfluxDB are getting along:

1. Browse to Grafana's Data Sources: http://&lt;YourIP&gt;3000/connections/datasources
2. Click on the knxLogger entry.
3. Scroll to the bottom and click on the Test button. This will hopefully reveal success:
   
![image](https://github.com/user-attachments/assets/f496dea5-5e5e-4396-96af-5a1fd90e69a1)

You might alternatively see an error here, indicating authorisation has failed between InfluxDB & Grafana:

![image](https://github.com/user-attachments/assets/898d19ed-2d64-479c-9a9c-b970dabe8f44)

This is usually due to a 'token' error.

Resolution: TODO


<br>

[Top](https://github.com/greiginsydney/knxLogger/blob/main/docs/troubleshooting.md#troubleshooting)

<hr>
