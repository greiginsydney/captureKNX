# captureKNX documentation

If you're new to captureKNX, there's plenty of documentation to whet your whistle.

## Shopping list

The [shopping list](/docs/shopping-list.md) itemises everything you'll need, and gives some config options.

## Installation & commissioning steps

1. [Prepare the topology export](/docs/step1-prepare-the-topology-export.md) - start here by exporting the topology (project file) in ETS.

2. [Prepare the Pi](/docs/step2-prepare-the-pi.md) shows you how to get the operating system image onto a solid state drive.

3. [Setup the Pi](/docs/step3-setup-the-Pi.md) walks you through the process to install all the software on the Pi. (The setup script does all the hard work!)
4. [Login to InfluxDB](/docs/step4-login-to-influxdb.md) shows you how to login to InfluxDB, although this will be seldom required.
5. [Login to Grafana](/docs/step5-login-to-grafana.md) is where all the fun happens. This page introduces you to the provided "Group Monitor dashboard" that shows your telegrams.
6. A [Graphical Dashboard](/docs/step6-graphical-dashboard.md) is included with the installation, however you'll need to invest a little effort customising it to the GA's on YOUR network - but that's explained here.
7. [Setup the Pi as an Access Point](/docs/setup-the-Pi-as-an-access-point.md) is optional. Follow this process if you don't have an existing data network on site, and/or want to have the Pi become its own Wi-Fi network.

## Debugging / troubleshooting

- [Troubleshooting](/docs/troubleshooting.md).
- The [Frequently Asked Questions](/docs/FAQ.md) page is mostly answers to the "how do I...?" questions users might ask.

## Upgrading

The upgrade process is essentially the same as a new installation. The setup script detects the presence of an existing version and reacts accordingly.

Read more on the [Upgrade](/docs/upgrade.md) page.

## Advanced Applications

If you're wondering if captureKNX has any more tricks up its sleeve, have a look at the [Advanced Applications](/docs/advanced-applications.md) page.
<br>

<hr />

[Top](#captureKNX-documentation)

