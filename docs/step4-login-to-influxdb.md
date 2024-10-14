# Login to InfluxDB

Truth be told, all going well we don't need this step.

All the requried InfluxDB config was created by the script. It's the database where all the telegrams are logged, but in this implementation we normally won't need to be interacting with it.

If you DO want to have a peek around, login by browsing to http://<thePi'sIP>:8086 using the credentials you entered in response to step 39 in [step3-setup-the-Pi.md](/docs/step3-setup-the-Pi.md). If you went with the defaults, that's captureKNX for both username and password.

<p align="center">
  <img src="https://github.com/user-attachments/assets/7ad553d7-9433-43c1-b3ef-f4b38511773e" width="30%">
</p>

Feel free to jump straight to [step5-login-to-grafana.md](/docs/step5-login-to-grafana.md).
