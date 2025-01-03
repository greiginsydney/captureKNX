# Troubleshooting

captureKNX is a consolidation of multiple open-source & freeware software components, all running on the one Raspberry Pi 5 single board computer.

The 'HAT' provides the physical interface to the KNX TP Line, and the ensuing components read and format the telegrams, then stuff them in the InfluxDB database. Grafana is the 'visualisation' component that lets you easily review and filter the raw logs, and/or create dashboards of useful values, all of which you access from a web browser.

![image](https://github.com/user-attachments/assets/3d10536b-f79e-4b1d-bc2f-a06846e15518)

If you're encountering problems with captureKNX, use this diagram to help understand the flow and where to focus your attention.

- [Start here](https://github.com/greiginsydney/captureKNX/blob/main/docs/troubleshooting.md#start-here)
- [knxd](https://github.com/greiginsydney/captureKNX/blob/main/docs/troubleshooting.md#knxd)
- [KNXDclient](https://github.com/greiginsydney/captureKNX/blob/main/docs/troubleshooting.md#knxdclient)
- [captureKNX](https://github.com/greiginsydney/captureKNX/blob/main/docs/troubleshooting.md#captureKNX)
- [telegraf](https://github.com/greiginsydney/captureKNX/blob/main/docs/troubleshooting.md#telegraf)
- [InfluxDB](https://github.com/greiginsydney/captureKNX/blob/main/docs/troubleshooting.md#influxdb)
- [Grafana](https://github.com/greiginsydney/captureKNX/blob/main/docs/troubleshooting.md#grafana)

<hr/>

## Start here

First off, don't forget that captureKNX is an IT device, so MANY problems will be resolved just by turning it off and back on again - or at least a reboot.

`sudo reboot now`

If the problems are continuing after a reboot, run the setup script's `test` mode and see what it reports. A healthy system should report all greens. Any yellows require investigation:

`sudo -E -H ./setup.sh test`

![image](https://github.com/user-attachments/assets/50e3d8cc-b1a5-4697-bfb1-415a4f3ebf0f)

The tests check common errors and misconfigurations, and will be added to as captureKNX evolves. It needs to be said however that sometimes the script will report everying PASSing, but captureKNX's still misbehaving. Further investigation is required.

<br>

[Top](#troubleshooting)

<hr>

## knxd

knxd reads what's coming from the bus and makes it available for KNXDclient and the captureKNX script.

You can check if knxd is running OK with `sudo systemctl status knxd`. If there's any red in the output, check if there's anything of interest in the journal (`journalctl | grep knxd`):

#### Opening /dev/ttyKNX1 failed: No such file or directory

```
Oct 08 14:24:41 captureKNX-Weinzierl systemd[1]: Stopped knxd.service - KNX Daemon.
Oct 08 14:24:41 captureKNX-Weinzierl systemd[1]: Starting knxd.service - KNX Daemon...
Oct 08 14:24:41 captureKNX-Weinzierl knxd[1309]: E00000067: [19:B.tpuarts] Opening /dev/ttyKNX1 failed: No such file or directory
Oct 08 14:24:41 captureKNX-Weinzierl knxd[1309]: F00000105: [16:B.tpuarts] Link down, terminating
Oct 08 14:24:41 captureKNX-Weinzierl systemd[1]: Started knxd.service - KNX Daemon.
Oct 08 14:24:41 captureKNX-Weinzierl systemd[1]: knxd.service: Main process exited, code=exited, status=1/FAILURE
Oct 08 14:24:41 captureKNX-Weinzierl systemd[1]: knxd.service: Failed with result 'exit-code'.
```

The config looked good for this one. This is what it's meant to look like, with ttyAMA0 owned by knxd/dialout and its alias ttyKNX1 by root/root:
```
pi@captureKNX-Weinzierl:~ $ ls -l /dev/tty[A-Z]*
crw-rw---- 1 knxd dialout 204, 64 Oct  8 14:35 /dev/ttyAMA0
crw-rw---- 1 root dialout 204, 74 Oct  8 14:32 /dev/ttyAMA10
lrwxrwxrwx 1 root root          7 Oct  8 14:31 /dev/ttyKNX1 -> ttyAMA0
crw-rw---- 1 root dialout   4, 64 Oct  8 14:31 /dev/ttyS0
pi@captureKNX-Weinzierl:~ $
```

This issue was fixed by a reboot.

<br>

[Top](#troubleshooting)

<hr>

## KNXDclient

KNXDclient doesn't run as a service, so it's not something you can directly test. Skip to captureKNX, as it uses KNXDclient to talk to the bus.

<br>

[Top](#troubleshooting)

<hr>

## captureKNX

`sudo systemctl status captureKNX.service` should report more green: a green dot, and `active (running)`.

![image](https://github.com/user-attachments/assets/2a681ca7-4814-4e1d-9dba-4106c41decc8)

If text has vanished off to the RHS of the screen (like as shown on the bottom line here) use your right arrow key to scroll the view (and left arrow to return).

Press `Q` to exit this view.

Any errors with the script and its service should be visible. 

Review the error log for obvious issues: `journalctl --no-pager --unit captureKNX`.

Review the content of the `/home/pi/captureKNX/log/captureKNX.log` file. See if the text "fatal" is logged.

Search for occurrences of the text "unzip_topo_archive". This is logged each time the script is launched. Here are the three possible messages:

#### unzip_topo_archive: No topology file found
Whoops. This is *probably* a fatal error: you've forgotten to copy the project file across, so captureKNX (and KNXDclient) don't know how to interpret the telegrams being received. Worst case: all telegrams are being discarded.

(If you've previously copied a file across and the script's already unzipped it to extract 0.xml and project.xml, its absence won't be fatal.)

#### unzip_topo_archive: Unzipping /home/pi/<filename>.knxproj

The script has found a new/newer project file and it's been unzipped and decoded. The subsequent log messages may point to issues here.

#### unzip_topo_archive: existing XML files are younger than /home/pi/<filename>.knxproj. Skipping extraction

An established (healthy) captureKNX should report this frequently.

If the issue you're chasing is missing telegrams, copy a fresh project file across and restart the captureKNX service with `sudo systemtctl restart captureKNX.service`.

### Still can't start the captureKNX service?

Run it manually (rather than in the background as a service). This should flush out any issues with the script itself:
```
cd ~ && source venv/bin/activate
cd captureKNX
python3 captureKNX.py
```
Fatal errors will be output to the screen. If it runs OK you'll see no output, as anything of interest is logged to `/home/pi/captureKNX/log/captureKNX.log`. You'll need to control-C to break out.

<br>

[Top](#troubleshooting)

<hr>

## telegraf

telegraf runs as a service, so check if it's running OK. The output will look similar to that for captureKNX.

`sudo systemctl status telegraf.service`

Review the error log for obvious issues: `journalctl --no-pager --unit telegraf`.

Edit `/etc/telegraf/telegraf.conf` to enable debug logging:

##### FROM

```text
## Log at debug level.
debug = false
## Log only error level messages.
quiet = true
```

#### TO

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

In the same folder as `telegraf.log` is the file `debug_output.log`. This is an independent log of all telegrams captured by telegraf. Healthy content in this file is a good indicator that everything to this point (the physical connection, hat, knxd, KNXDclient and the knxdLogger) are OK.

<br>

[Top](#troubleshooting)

<hr>

## InfluxDB

InfluxDB runs as a service, so check if it's running OK. The output will look similar to that for the other services.

`sudo systemctl status influxdb.service`

Review the error log for obvious issues: `journalctl --no-pager --unit influxdb`. 

<br>

[Top](#troubleshooting)

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

### Not seeing telegrams / Dashboards broken?

Check Grafana and InfluxDB are getting along:

1. Browse to Grafana's Data Sources: http://&lt;ThePi'sIP&gt;:3000/connections/datasources
2. Click on the captureKNX entry.
3. Scroll to the bottom and click on the Test button. This will hopefully reveal success:
   
![image](https://github.com/user-attachments/assets/182324e6-8b59-472e-b074-643b34ffd0f6)

You might alternatively see an error here, indicating authorisation has failed between InfluxDB & Grafana:

![image](https://github.com/user-attachments/assets/898d19ed-2d64-479c-9a9c-b970dabe8f44)

This is usually due to a 'token' error.

Quick things to try:
   1. Reboot
   2. Re-run setup. Jump to Step 35 in [step3-setup-the-Pi.md](/docs/step3-setup-the-Pi.md#setup)
   3. Does the test step at the completion of the script highlight any problems?

In-depth resolution: TODO. If you encounter this in the field, please log an issue.


<br>

[Top](#troubleshooting)

<hr>
