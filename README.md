# knxLogger
Build a Raspberry Pi that will log all KNX traffic to InfluxDB &amp; query it from a browser any time.

## Features

- No fancy hardware. Buy a Raspberry Pi 5, plug a KNX shield on top, add a solid-state drive, stick it in a box (artwork provided here to print your own) and apply power!
- Plugs directly into the KNX bus. This means your KNX telegrams aren't permanently spamming your IP network to get to the logger, and means you can log tiny KNX installations that don't have a full-time router or programming interface.
- Easy setup. A bash script installs all the software components. You only need to copy the topology/project file across after exporting it from ETS.
- A fully on-premises solution. Once you've bought the hardware, that's your total outlay. (Late 2024 estimate circa $AUD250 / $US170 / €150.)
- With Grafana you can easily visualise data like daily temperatures or light levels, and overlay heating/lighting control signals.
- Debug your logic and other occurrences by filtering the log view by time/date, Group Address, sending device or the value sent.
- Add "[remote.it](https://www.remote.it/)" for full remote access, without needing firewall holes or other complicated setup. (Remote.it is free for non-commercial use!)

## Limitations / Restrictions

- The direct-connection to the KNX bus means it can only log the Telegrams seen on that network Line. This will prevent it from seeing all traffic in a multi-area or multi-line network.
- It's not an off-the-shelf product. You buy the components and build it yourself - but there's heaps of documentation here to help you.
- Every telegram to a known Group Address is logged, however it only decodes the most commonly-used DPT types. (This is expected to evolve over time).
- Even though the Raspberry Pi 5 is the fastest Pi made it can still be a little slow, especially on initial login to the Influx or Grafana web pages.

## Credits

knxLogger relies upon the open-source [knxd](https://github.com/knxd/knxd) and [knxdclient](https://github.com/mhthies/knxdclient) projects for its communications, and would be lost without them. If you're feeling generous please visit their sites and send some appreciation in your preferred currency.

## Where to next?

Jump to the [documentation pages](https://github.com/greiginsydney/knxLogger/tree/main/docs) for the shopping list and build instructions.

<br><br>
\- Greig.
