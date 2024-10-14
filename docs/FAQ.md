# Frequently Asked Questions

## General
- [Can I build captureKNX using a microSD card?](#can-i-build-captureKNX-using-a-microsd-card)
- [How do I update captureKNX with a new project file?](#how-do-i-update-captureKNX-with-a-new-project-file)
- [Why is captureKNX logging my valid telegrams as 'error'?](#why-is-captureKNX-logging-my-valid-telegrams-as-error)
- [Why is captureKNX showing a Source Name of 'unknown'?](#Why-is-captureKNX-showing-a-source-name-of-unknown)

## InfluxDB
- [How can I delete all the data in InfluxDB and start again?](#how-can-i-delete-all-the-data-in-influxdb-and-start-again)

## Grafana
- [How do I stop Grafana truncating my DPT values?](#how-do-i-stop-grafana-truncating-my-dpt-values)
- [Why are some Group Addresses not showing in the reports or logs?](#why-are-some-group-addresses-not-showing-in-the-reports-or-logs)

<br/>
<hr/>

### Can I build captureKNX using a microSD card?

Sure - but it's not best practice for what we're doing here.

[microSD](https://simple.wikipedia.org/wiki/MicroSD) cards only have a finite number of read/write cycles in them, and we're writing KNX telegrams to the database **continuously**. Eventually it's going to fail.

We've gone with external storage that's designed to survive the read/write onslaught, and as a bonus the Pi is a LOT faster.

As captureKNX isn't perhaps as 'mission critical' an application as some others, you might choose to build it onto an SD card. None of the installation steps change if you do this.

[Top](#frequently-asked-questions)

<hr>

### How do I update captureKNX with a new project file?

1. Follow the process in [Prepare The Topology Export](/docs/step1-prepare-the-topology-export.md).
2. Copy the file to `/home/pi/`. (I use [WinSCP](https://winscp.net/) for this, but there are plenty of other tools that can do the same job.)
3. Restart the captureKNX service:

```text
sudo systemctl restart captureKNX
```
4. When it restarts, the captureKNX script will detect the presence of a newer project file and extract its content.

[Top](#frequently-asked-questions)
<hr>


### Why is captureKNX logging my valid telegrams as 'error'?

![image](https://github.com/user-attachments/assets/ded055db-8d12-4ccc-87c4-1a4c8b2eb7d5)

This is an example of a telegram that wasn't able to be decoded correctly. captureKNX threw an error which was logged: see `/home/pi/captureKNX/log/captureKNX.log`.

Please raise a [bug report](https://github.com/greiginsydney/captureKNX/issues/new?assignees=greiginsydney&labels=&projects=&template=bug_report.md&title=) for this, including the relevant message from captureKNX.log and a screen-grab showing how ETS' Group Monitor decodes the same telegram.

[Top](#frequently-asked-questions)
<hr>

### Why is captureKNX showing a Source Name of 'unknown'?

![image](https://github.com/user-attachments/assets/75c3d95b-9a21-4cff-8413-ac0705bd779e)

Any time captureKNX retrieves a blank value from the project file it writes it to InfluxDB as 'Unknown'.

In this example the source was one of the 'Additional Addresses' assigned to the router, and the message itself was sent from ETS. As at v1.0.0 these Additional Addresses aren't being assigned a name. ('It's complicated'.)

[Top](#frequently-asked-questions)
<hr>

### How can I delete all the data in InfluxDB and start again?

If you're re-deploying a captureKNX to a new site you'll want to cleanse the existing site's telegrams first, and for that you use the InfluxCLI.

Edit this code snippet from the [CLI documentation](https://docs.influxdata.com/influxdb/cloud/write-data/delete-data/) with a start date before you commenced the build, and a stop date that's tomorrow or later. (It's OK with you flushing data to a future-dated event).

```text
sudo influx delete --bucket captureKNX --start 2024-01-01T00:00:00Z --stop 2024-12-31T00:00:00Z
```

[Top](#frequently-asked-questions)

<hr>


### How do I stop Grafana truncating my DPT values?

By default Grafana seems to treat DPT values as though they're currency, and will turn a switch value of "1.001" into "1.00".

You can fix this by editing the panel and adding a "field override", then select "fields with name" and the DPT field. Now add an "override property", choose "standard options - decimals" and give it a value of 3. Finally, Apply and Save.

This is what the end result will look like:

![image](https://github.com/user-attachments/assets/b783f5bd-cd51-44c1-9a51-ae0bef4e08de)


[Top](#frequently-asked-questions)
<hr>

### Why are some Group Addresses not showing in the reports or logs?

#### It's not in the project file captureKNX is using

This is usually because the Group Address was added after the project file was exported for captureKNX. As captureKNX doesn't know what type of DataPoint the GA is, any telegrams to it are discarded.

Search the captureKNX.log file (in `/home/pi/captureKNX/log`) for the Group Address, or the text 'The telegram has been discarded'.

To resolve this issue, export a new project file, copy it to the Pi and restart the captureKNX service. See [How do I update captureKNX with a new project file?](/docs/FAQ.md#How-do-i-update-captureKNX-with-a-new-project-file)

#### Your captureKNX hasn't seen any traffic to it yet
A less common cause only manifests in new captureKNX installations. Grafana doesn't know a Group Address exists until a Telegram has been sent to it and it's logged in the database. If in doubt, toggle the GA on/off or otherwise send it a message.

[Top](#frequently-asked-questions)
<hr>
