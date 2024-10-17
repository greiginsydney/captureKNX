# A Sample Fancy Dashboard

If you've researched Grafana or watched any of the YouTube links you'll realise it's a VERY powerful tool, and using it to present a tabular Group Monitor is seriously under-using it.

To provide a small head-start, a "sample fancy dashboard" is included which demonstrates a few of Grafana's graphical features.


## Temperatures graph

I have multiple temperature and light level sensors, so I've overlaid them on each other to compare their differences. The jagged blue line is reporting the temperatures in the air-conditioned computer-room.

Note that the Y-axis (vertical) has been set to start at 10°C and only goes to 30. Below the graph is the legend where the three sensors are given a sensible name.

## Light levels graph

Like temperatures, I have two light level sensors showing their readings on top of each other. A key difference here is that both have different Y-axes. That's because one of the sensors reports lux as DPT 7.013 and the other as DPT 9.004, and the values values differ wildly from each other even though they're reporting the same thing.

## Bathroom logic

This panel is reporting the on/off state of three GA's in the bathroom: the light, the exhaust fan and the ceiling heater. This panel would be a good one to employ when you're debugging the interaction between linked GAs.

A word of warning however is that very brief changes of state will disappear in the view if you're zoomed out to (say) a 24-hour view. If you're troubleshooting, change the time range to narrowly focus on the time period in question.

## "Breaker trip"

This panel is reporting the state of a single GA, but the On/Off value reported by the telegram has been customised with attention-grabbing labels and colours.

## Current Temperature

The current temperature is a "single stat" view. Not apparent in this image is the colouring which changes as the temperature moves between thresholds.

## Powerwall state of charge

This is a "bar gauge", reporting a value that's represented as a percentage. The graduation reflects the user-selectable colour thresholds.

## Rainwater tank level

The rainwater tank level is represented as a "gauge", with my own addition of the colour and markers every 500L. In this example the GA would be reporting the value in litres.


Out of the box the sample is less appealing. Your task is to customise it with your local Group Addresses or their names. Here's how to do that:
