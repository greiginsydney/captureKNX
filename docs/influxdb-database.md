# InfluxDB Database

captureKNX formats and sends all the (valid) telegrams it receives to an InfluxDB "time series" database. It does this by first formatting the telegram into a JSON message that's POSTed to telegraf. Telegraf then disassembles this and reassembles it into Influx's "[line protocol](https://docs.influxdata.com/influxdb/v2/reference/syntax/line-protocol/)" to be then added to the database.

> "InfluxDB uses line protocol to write data points. It is a text-based format that provides the measurement, tag set, field set, and timestamp of a data point."

InfluxDB views each "measurement" (KNX Telegrams) as consisting of one or more "tags" and "fields". Tags are effectively the meta-data, whilst the fields are the payload.

captureKNX sends all the source and destination values as fields, with only the datapoint type (DPT), the decoded value, and the unit (where applicable) as tags. You'll see those listed in the [Database Schema](#database-schema) section below as [field keys](#show-field-keys) and [tag keys](#show-tag-keys).

### Extra fields for Grafana graphing

As an aid to Grafana's graphing of the captured data, captureKNX will also send each telegram's payload in its 'natural' format, particularly if it's a `boolean` (i.e. DPT1.xxx), `integer` or `float`. The presence of these extra values in the underlying database allows Grafana to more easily manipulate the data when graphing it. (See the FANCY-DASHBOARD-LINK TODO).

You won't see the fields `boolean`, `integer` and `float` on the included "Group Monitor" dashboard, although they're present, just hidden in that view. (You can make them visible if you wish.) You will however see them presented as an option if you're creating SQL queries for graphing, although that's for the more adventurous or data nerds.

<br/>
<hr/>

# Database Schema

You can use the InfluxCLI to query the database structure.

## SHOW DATABASES

Name: databases

<table>
<tr><th>index</th><th>name</th></tr>
<tr><td>1</td><td>_monitoring</td></tr>
<tr><td>2</td><td>_tasks</td></tr>
<tr><td>3</td><td>captureKNX</td></tr>
</table>

## SHOW MEASUREMENTS

Name: measurements
<table>
<tr><th>index</th><th>name</th></tr>
<tr><td>1</td><td>telegram</td></tr>
</table>

## SHOW TAG KEYS

Name: telegram

<table>
<tr><th>index</th><th>tagKey</th></tr>
<tr><td>1</td><td>destination</td></tr>
<tr><td>2</td><td>destination_name</td></tr>
<tr><td>3</td><td>source_address</td></tr>
<tr><td>4</td><td>source_building</td></tr>
<tr><td>5</td><td>source_floor</td></tr>
<tr><td>6</td><td>source_name</td></tr>
<tr><td>7</td><td>source_room</td></tr>
</table>

## SHOW FIELD KEYS

Name: telegram

<table>
<tr><th>index</th><th>fieldKey</th><th>fieldType</th></tr>
<tr><td>1</td><td>boolean</td><td>boolean</td></tr>
<tr><td>2</td><td>dpt</td><td>float</td></tr>
<tr><td>3</td><td>float</td><td>float</td></tr>
<tr><td>4</td><td>info</td><td>string</td></tr>
<tr><td>5</td><td>integer</td><td>integer</td></tr>
<tr><td>6</td><td>unit</td><td>string</td></tr>
</table>

## SHOW FIELD KEY CARDINALITY

Name: telegram

<table>
<tr><th>index</th><th>count</th></tr>
<tr><td>1</td><td>6.0000000000</td></tr>
</table>

## SHOW TAG KEY CARDINALITY
Name: telegram

<table>
<tr><th>index</th><th>count</th></tr>
<tr><td>1</td><td>7.0000000000</td></tr>
</table>

## SHOW RETENTION POLICIES

<table>
<tr><th>index</th><th>name</th><th>duration</th><th>shardGroupDuration</th><th>replicaN</th><th>default</th></tr>
<tr><td>1</td><td>autogen</td><td>0s</td><td>168h0m0s</td><td>1.0000000000</td><td>true</td></tr>
</table>

<br>

[Top](#influxdb-database)
