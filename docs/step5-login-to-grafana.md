# Login to Grafana

OK, here's where all the fun happens.

1. Browse to http://<thePi'sIP>:3000 and login with the default credentials: `admin`/`admin`.

<p align="center">
  <img src="https://github.com/user-attachments/assets/1f0bd78c-334e-46e0-a281-d608a3c10742" width="30%">
</p>



2. You'll be prompted to change the password:

<p align="center">
  <img src="https://github.com/user-attachments/assets/3b052fa6-d226-4d5f-9131-ad4297375a55" width="30%">
</p>

3. Next you'll be taken to the main "Welcome to Grafana" page:

<p align="center">
  <img src="https://github.com/user-attachments/assets/1909d0da-4983-4b68-bbcc-6f7102b6be36" width="100%">
</p>

4. In the navigation tree down the LHS, select Connections, then Data sources, and click on the name of the captureKNX source. (Only the text is clickable, not the whole grey banner.)

<p align="center">
  <img src="https://github.com/user-attachments/assets/a5dd08be-1e5b-4d84-bf6a-b5a244c3632a" width="100%">
</p>

5. Scroll to the bottom and click `Test`. It should reveal the "datasource is working" message. That confirms we're connecting to InfluxDB and able to read the telegrams stored there.

<p align="center">
  <img src="https://github.com/user-attachments/assets/5f04b5a0-85ec-4777-a20f-d77c894568d4" width="100%">
</p>

> If it says "0 measurements found" that's bad. The most likely cause is you've not yet copied the KNX Project file to the Pi, or forgot to restart the captureKNX service after doing so.

6. Click Dashboards in the navigation tree, then select the Group Monitor:

<p align="center">
  <img src="https://github.com/user-attachments/assets/5001028f-9350-418e-8925-6c26e5c062b2" width="100%">
</p>

7. The telegrams that have been received since the installation will be here: <br id="demo"/>

<p align="center">
  <img src="https://github.com/user-attachments/assets/37bdf35d-dd13-4d7c-a1ba-51e3e7edc2fe" width="100%">
</p>

There are a few things you can easily do with this view:
- Click (7) and (8) to maximise the view, removing some of the clutter
- Click the vertical ellipsis (9) to edit this dashboard "panel". (It only becomes visible when your mouse is within the panel.) Let's not go there just yet...
- (10) lets you adjust the time window you're seeing. 'last 5 minutes' is the narrowest, through 'today so far' and many longer time periods
- (11) will refresh the view, and to its right is a "v" that lets you choose an auto-refresh rate (with every 5 seconds selected at the moment)
- Click the arrow next to the Time label (12) to order all records by oldest or newest at the top
- Click any of the OTHER column headings to instead sort them alphabetically ascending or descending. (The arrow will move to that column to show the view is being sorted by that element)
- Click the funnel icon (14) next to any of the titles to filter to one or more values. This is INCREDIBLY powerful!! You can filter on multiple columns at the same time, and each will show the funnel in blue so you can see at a glance what's flavouring the current view

You'll find more navigation and management tips on the Grafana page "[Use dashboards](https://grafana.com/docs/grafana/latest/dashboards/use-dashboards/)".

**Welcome to your captureKNX!**

## A Graphical Dashboard 

The Group Monitor dashboard works out of the box, capturing and displaying in near real time (delayed by ~5 seconds) all telegrams sent to the bus.

In [step6-graphical-dashboard](/docs/step6-graphical-dashboard.md) you'll find an example of a graphical dashboard that shows your telegrams in a much more visually appealing manner, although you're going to have to customise it with the relevant Group Addresses on YOUR network.

<br>

[Top](#login-to-grafana)

<hr>
