
# Database Schema

There'll be someone out there who's interested in this.

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
