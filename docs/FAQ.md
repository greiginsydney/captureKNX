# Frequently Asked Questions


- [How can I delete all the data in InfluxDB and start again?](https://github.com/greiginsydney/knxLogger/blob/master/docs/FAQ.md#how-can-I-delete-all-the-data-in-influxdb-and-start-again)
- [Question-next?](https://github.com/greiginsydney/knxLogger/blob/master/docs/FAQ.md#question-next)

<br>

<hr>

## How can I delete all the data in InfluxDB and start again?

If you have a need to flush all the captured Telegrams and start over, InfluxCLI has the solution. Edit this code snippet from the [CLI documentation](https://docs.influxdata.com/influxdb/cloud/write-data/delete-data/) with a start date before you commenced the build, and a stop date that's tomorrow or later. (It's OK with you flushing data to a future-dated event).

```text
sudo influx delete --bucket knxLogger --start 2024-01-01T00:00:00Z --stop 2024-12-31T00:00:00Z
```

<br>

[Top](https://github.com/greiginsydney/knxLogger/blob/master/docs/FAQ.md)

## Question - next
