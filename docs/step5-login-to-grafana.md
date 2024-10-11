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

4. In the navigation tree down the LHS, select Connections, then Data sources, and click on the name of the knxLogger source. (Only the text is clickable, not the whole grey banner.)

<p align="center">
  <img src="https://github.com/user-attachments/assets/5ffa8aa9-c90d-4a54-8f88-8e28a6b69f3f" width="100%">
</p>

5. Scroll to the bottom and click `Test`. It should reveal the "datasource is working" message. That confirms we're connecting to InfluxDB and able to read the telegrams stored there.

<p align="center">
  <img src="https://github.com/user-attachments/assets/30546847-fbaa-4d5f-aff6-4269c2bfe492" width="100%">
</p>

> If it says "0 measurements found" that's bad. The most likely cause is you've not yet copied the KNX Project file to the Pi, or forgot to restart the knxLogger service after doing so.

6. Click Dashboards in the navigation tree, then select the Group Monitor:

<p align="center">
  <img src="https://github.com/user-attachments/assets/5001028f-9350-418e-8925-6c26e5c062b2" width="100%">
</p>

7. The telegrams that have been received since the installation will be here:

<p align="center">
  <img src="https://github.com/user-attachments/assets/7531f7d6-8b13-4b17-b838-6e539359be4e" width="100%">
</p>

There are a few things you can easily do with this view:
- click (7) and (8) to maximise the view, removing some of the clutter
- Click the vertical ellipsis (9) to edit this dashboard "panel". (It only becomes visible when your mouse is within the panel.) Let's not go there just yet...
- (10) lets you filter the time window you're seeing
- (11) will refresh the view, and to its right (hidden by the 8) is a "v" that lets you choose an auto-refresh rate
- Click any of the column headings (12) to sort the view by that element

## Welcome to your knxLogger!

In [step6-grafana-tips.md](/docs/step6-grafana-tips.md) (TODO) you'll find some tips to help you do things like re-size, hide/reveal, re-label, and more.

You might also find some answers on the [FAQ page](/docs/FAQ.md).

<br>

[Top](/docs/step5-login-to-grafana#login-to-grafana)

<hr>
