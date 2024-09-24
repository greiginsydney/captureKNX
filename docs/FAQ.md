# Frequently Asked Questions


- [How can I delete all the data in InfluxDB and start again?](https://github.com/greiginsydney/knxLogger/blob/master/docs/FAQ.md#how-can-I-delete-all-the-data-in-influxdb-and-start-again)
- [How do I stop Grafana truncating my DPT values?](https://github.com/greiginsydney/knxLogger/blob/master/docs/FAQ.md#how-do-i-stop-grafana-truncating-my-dpt-values)
- [Question-next?](https://github.com/greiginsydney/knxLogger/blob/master/docs/FAQ.md#question-next)

<br>

<hr>

## How can I delete all the data in InfluxDB and start again?

If you have a need to flush all the captured Telegrams and start over, InfluxCLI has the solution. Edit this code snippet from the [CLI documentation](https://docs.influxdata.com/influxdb/cloud/write-data/delete-data/) with a start date before you commenced the build, and a stop date that's tomorrow or later. (It's OK with you flushing data to a future-dated event).

```text
sudo influx delete --bucket knxLogger --start 2024-01-01T00:00:00Z --stop 2024-12-31T00:00:00Z
```

[Top](https://github.com/greiginsydney/knxLogger/blob/master/docs/FAQ.md)

<br>

## How do I stop Grafana truncating my DPT values?

By default Grafana seems to treat DPT values as though they're currency, and will turn a switch value of "1.001" into "1.00".

You can fix this by editing the panel and adding a "field override", then select "fields with name" and the DPT field. Now add an "override property", choose "standard options - decimals" and give it a value of 3. Finally, Apply and Save.

This is what the final result will look like:

![image](https://github.com/user-attachments/assets/b783f5bd-cd51-44c1-9a51-ae0bef4e08de)



[Top](https://github.com/greiginsydney/knxLogger/blob/master/docs/FAQ.md)

<br>

## Question - next
