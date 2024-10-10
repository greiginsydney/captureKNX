# knxLogger
Build a Raspberry Pi that will log all KNX telegrams to InfluxDB that you can query from a browser any time.

<table>
<tr>
<td>TODO A picture of the completed Pi in its box</td>
<td><p>&#10132;</p></td>
<td width="60%"><p align="center"><img src="https://github.com/user-attachments/assets/4e9b8f70-2fc2-4b0b-b88b-9a16e99a4797">(Click on the image for a higher-resolution view)</p></td>
</tr>
  
</table>

## Features

- Log all KNX network traffic for a year (or longer!) without needing to leave behind a laptop running ETS. (ETS6 will only capture 1,000 telegrams before over-writing them.)
- No fancy hardware. Buy a Raspberry Pi 5, plug a KNX shield on top, add a solid-state drive, stick it in a box (artwork provided here to print your own) and apply power!
- No ETS dongle left unguarded on site.
- Plugs directly into the KNX bus. This means your KNX telegrams aren't permanently spamming your IP network to get to the logger, and means you can log tiny KNX installations that don't have a full-time router or programming interface.
- Easy setup. A bash script installs all the software components. You only need to copy the topology/project file across after exporting it from ETS.
- A fully on-premises solution. Once you've bought the hardware, that's your total outlay. (Late 2024 estimate circa $AUD250 / $US170 / €150.)
- With Grafana you can easily visualise data like daily temperatures or light levels, and overlay heating/lighting control signals.
- A dedicated dashboard replicates ETS' Diagnostics / Group Monitor feature. Debug your logic and other occurrences by filtering the log view by time/date, Group Address, sending device or the value sent.

## Limitations / Restrictions

- The direct-connection to the KNX bus means it can only log the Telegrams seen on that network Line. This will prevent it from seeing all traffic in a multi-area or multi-line network.
- It's not an off-the-shelf product. You buy the components and build it yourself - but there's heaps of documentation here to help you.
- Every telegram to a known Group Address is logged, however it only decodes the most commonly-used DPT types. (This is expected to evolve over time).

## Software architecture

The knxLogger is a consolidation of multiple open-source & freeware software components, all running on the one Raspberry Pi 5 single board computer.

The 'HAT' provides the physical interface to the KNX TP Line, and the ensuing components read and format the telegrams, then stuff them in the InfluxDB database. Grafana is the 'visualisation' component that lets you easily review and filter the raw logs, and/or create dashboards of useful values, all of which you access from a web browser.

![image](https://github.com/user-attachments/assets/e46410d2-74dd-42a9-acd8-e19f3be63a16)


## Credits

knxLogger relies upon the open-source [knxd](https://github.com/knxd/knxd) and [knxdclient](https://github.com/mhthies/knxdclient) projects for its communications, and would be lost without them. If you're feeling generous please visit their sites and send some appreciation in your preferred currency.

## Where to next?

Jump to the [documentation pages](https://github.com/greiginsydney/knxLogger/tree/main/docs) for the shopping list and build instructions.

<br><br>
\- Greig.
