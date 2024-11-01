# captureKNX
Build a Raspberry Pi that will capture all KNX telegrams to InfluxDB that you can query from a browser any time.

## Build it

<p align="middle">
   <img src="https://github.com/user-attachments/assets/601a0ffd-1d30-4b11-9865-6705eee95161" width="60%">
</p>

## Log it

<p align="middle">
<img src="https://github.com/user-attachments/assets/4e9b8f70-2fc2-4b0b-b88b-9a16e99a4797" width="60%">
</p>

## Visualise it

<p align="middle">
<img src="https://github.com/user-attachments/assets/8af1a54e-a5ae-4098-8ebd-75bc780ff318" width="60%">
</p>

## Features

- Capture KNX telegrams for a year (or longer!) without needing to leave behind a laptop running ETS. (ETS6 will only capture 1,000 telegrams before over-writing them.)
- No fancy hardware. Buy a Raspberry Pi 5, plug a KNX shield on top, add a solid-state drive, stick it in a box (artwork provided here to print your own) and apply power!
- No valuable ETS dongle left unguarded on site.
- Plugs directly into the KNX bus. This means KNX telegrams aren't permanently spamming the IP network, and means you can capture tiny KNX installations that don't have a full-time router or programming interface.
- Easy setup. A bash script installs all the software components. You only need to copy the topology/project file across after exporting it from ETS.
- A fully on-premises solution. Once you've bought the hardware, that's your total outlay. (Late 2024 estimate circa $AUD250 / $US170 / €150.)
- A dedicated dashboard replicates ETS' Diagnostics / Group Monitor feature. Debug your logic and other occurrences by filtering the captured view by time/date, Group Address, sending device or the value sent. (Preview the power of this [here](/docs/step5-login-to-grafana.md#demo)).
- With Grafana you can easily visualise data like daily temperatures or light levels, and overlay heating/lighting control signals.
- Hunting down bugs? [Grafana can send you an alert](/docs/advanced-applications.md#setup-grafana-alerting) when a specific telegram is seen!

## Limitations / Restrictions

- The direct-connection to the KNX bus means it can only capture the telegrams seen on that network Line. This will prevent it from seeing all traffic in a multi-area or multi-line network (without extra configuration).
- It's not an off-the-shelf product. You buy the components and build it yourself - but there's heaps of documentation here to help you.
- Every telegram to a known Group Address is captured, however some esoteric DPT types might be misinterpreted or mis-represented. (Log an issue and we'll work to resolve this.)
- If your installation is a works in progress, each time you create Group Addresses you'll need to close/export/import the updated project file so captureKNX knows how to decode the incoming data. (Telegrams to unknown GA's will be discarded.)
- (Currently) English-only, and hasn't been tested in any other languages. Contributions welcome!
- KNX Secure is not supported. (This is a limitation imposed by [knxd](https://github.com/knxd/knxd), which interfaces to and decodes the bus.)

## Software architecture

captureKNX is a consolidation of multiple open-source & freeware software components, all running on the one Raspberry Pi 5 single board computer.

The 'HAT' provides the physical interface to the KNX TP Line, and the ensuing components read and format the telegrams, then stuff them in the InfluxDB database. Grafana is the 'visualisation' component that lets you easily review and filter the raw captures, and/or create dashboards of useful values, all of which you access from a web browser.

![image](https://github.com/user-attachments/assets/a4ba8e35-8c87-4f54-a2df-e4ff7d9a9aaa)

## InfluxDB & Grafana

captureKNX stores all the telegrams in a 'time series' database called InfluxDB, and the reporting all happens in Grafana.

If you're wanting to better understand the architecture and what you're getting yourself in for before you take the plunge and buy a Pi and HAT, have a look at the pages [step5-login-to-grafana.md](/docs/step5-login-to-grafana.md) and [step6-graphical-dashboard.md](/docs/step6-graphical-dashboard.md).

If you're interested in graphical dashboards and the power of Grafana, I STRONGLY recommend you watch the YouTube video playlist ["What is Observability - Grafana for Beginners"](https://youtube.com/playlist?list=PLDGkOdUX1Ujo27m6qiTPPCpFHVfyKq9jT&si=q5BIC9lkn3LJmBc6). That playlist builds a great understanding, and by Episode 8 you're creating a dashboard that looks remarkably like the one provided here in [step6-graphical-dashboard.md](/docs/step6-graphical-dashboard.md).

Having said that, if you just want to capture and analyse telegrams everything's provided here for you, so don't let the apparent complexity of Grafana and SQL database queries put you off.

InfluxDB and Grafana both have active supporter communities should you want to delve deeper into the reporting of your stored telegrams. (By all means I welcome you sharing your Dashboards with fellow captureKNX users - the [project's Wiki page](https://github.com/greiginsydney/captureKNX/wiki) would be a great place for those.)

## Credits

captureKNX relies upon the open-source [knxd](https://github.com/knxd/knxd) and [KNXDclient](https://github.com/mhthies/knxdclient) projects for its communications, and would be lost without them. If you're feeling generous please visit their sites and send some appreciation in your preferred currency:

- [knxd](https://github.com/knxd/knxd#compensation--personal-statement)
- KNXDclient (TODO)

... and you're certainly welcome to [buy me a coffee](https://buymeacoffee.com/greiginsydney) or throw a few currency units into [my PayPal account](https://www.paypal.com/paypalme/greiginsydney/) too!

## Where to next?

Jump to the [documentation pages](/docs/README.md) for the shopping list and build instructions.

<br><br>
\- Greig.
