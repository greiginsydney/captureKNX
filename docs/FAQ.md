# Frequently Asked Questions

## General
- [How do I update the logger with a new topology file?](/docs/FAQ.md#How-do-i-update-the-logger-with-a-new-topology-file)

## InfluxDB
- [How can I delete all the data in InfluxDB and start again?](/docs/FAQ.md#how-can-I-delete-all-the-data-in-influxdb-and-start-again)

## Grafana
- [How do I stop Grafana truncating my DPT values?](/docs/FAQ.md#how-do-i-stop-grafana-truncating-my-dpt-values)
- [Why are some Group Addresses not showing in the reports or logs?](/docs/FAQ.md#why-are-some-group-addresses-not-showing-in-the-reports-or-logs)

<br/>
<hr/>

### How do I update the logger with a new topology file?

1. Follow the process in [Prepare The Topology Export](/docs/step1-prepare-the-topology-export.md)
2. Copy the file to `/home/pi/`. (I use [WinSCP](https://winscp.net/) for this, but there are plenty of other tools that can do the same job.)
3. Restart the knxLogger service:

```text
sudo systemctl restart knxLogger
```
4. When it restarts, the logger script will detect the presence of a newer topo file and extract its content.

[Top](/docs/FAQ.md#frequently-asked-questions)


<hr>


### How can I delete all the data in InfluxDB and start again?

If you have a need to flush all the captured Telegrams and start over, InfluxCLI has the solution. Edit this code snippet from the [CLI documentation](https://docs.influxdata.com/influxdb/cloud/write-data/delete-data/) with a start date before you commenced the build, and a stop date that's tomorrow or later. (It's OK with you flushing data to a future-dated event).

```text
sudo influx delete --bucket knxLogger --start 2024-01-01T00:00:00Z --stop 2024-12-31T00:00:00Z
```

[Top](/docs/FAQ.md#frequently-asked-questions)

<hr>


### How do I stop Grafana truncating my DPT values?

By default Grafana seems to treat DPT values as though they're currency, and will turn a switch value of "1.001" into "1.00".

You can fix this by editing the panel and adding a "field override", then select "fields with name" and the DPT field. Now add an "override property", choose "standard options - decimals" and give it a value of 3. Finally, Apply and Save.

This is what the final result will look like:

![image](https://github.com/user-attachments/assets/b783f5bd-cd51-44c1-9a51-ae0bef4e08de)


[Top](/docs/FAQ.md#frequently-asked-questions)
<hr>

## Some Group Addresses are not showing in the reports or logs

This is usually because the Group Address has been created since the topology/project file that knxLogger is using, and as knxLogger doesn't know what type of DataPoint the GA is, it's discarded.

Export a new topo file, copy it to the Pi and restart the knxLogger service. See [How do I update the logger with a new topology file?](/docs/FAQ.md#How-do-i-update-the-logger-with-a-new-topology-file)

[Top](/docs/FAQ.md#frequently-asked-questions)
<hr>
