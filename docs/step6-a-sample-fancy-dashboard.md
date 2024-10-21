# A Sample Fancy Dashboard

If you've researched Grafana or watched any of the YouTube links you'll realise it's a VERY powerful tool, and using it to present a tabular Group Monitor is seriously under-using it.

To provide a small head-start, a "sample fancy dashboard" is included which demonstrates a few of Grafana's graphical features.


## Temperatures graph

We have multiple temperature and light level sensors, so I've overlaid them on each other for a comparison. The jagged blue line is the temperature in the air-conditioned computer-room.

Note how the Y-axis (vertical) only ranges from 10° to 30°C, demonstrating how the "auto" axis setting helps maximise the presentation of the data. (You can peg it to fixed minimum and/or maximum values if you prefer). Below the graph is the legend where the three sensors are given a sensible name.

## Light levels graph

Like temperatures, I have two light level sensors showing their readings on top of each other. A key difference here is that both have different Y-axes, which you can see at the left and the right of the graph. That's because one of the sensors reports lux as DPT 7.013 and the other as DPT 9.004. Whilst the raw numeric values differ by more than an order of magnitude, the graphs confirm they're largely in alignment. (If you're curious, the divergence at sunrise and sunset is due to one being on the shaded southern wall whilst the other is west-facing.)

## A "logic analyser" view

This panel is reporting the on/off state of three Switch GA's in the bathroom: the light, the exhaust fan and the ceiling heater. This panel would be a good one to employ when you're debugging the interaction between linked GAs.

A word of warning however is that very brief changes of state will not show on the graph if you're looking at (say) a 24-hour window, not unlike how you can't see the car parked in your driveway from space on Google Street View if you've zoomed all the way out to show the entire city or country. When troubleshooting, change the time range to more narrowly focus on the time period in question.

## "Breaker trip"

<p align="left">
  <img src="https://github.com/user-attachments/assets/ad2e0a62-cf78-4bfc-83ed-8c5de94c2da0" width="20%">
</p>

<p align="left">
  <img src="https://github.com/user-attachments/assets/04da1cb5-b2a0-452c-80f0-b4596ba1d8f1" width="20%">
</p>

This panel is a "single stat" panel reporting the state of a single Switch GA (DPT 1.). The On/Off state reported by the telegram has been customised with attention-grabbing labels and colours.

## Current Temperature

<p align="left">
  <img src="https://github.com/user-attachments/assets/6f4f865b-3acd-4556-99f1-188c1d7b60f4" width="20%">
</p>

The current temperature is a different way of presenting a "single stat" panel. Not apparent in this image is the colouring which changes as the temperature moves between thresholds.

## Powerwall state of charge

<p align="left">
  <img src="https://github.com/user-attachments/assets/45a1a201-67e6-4be7-bc19-c6a7d2c1b9d3" width="20%">
</p>

This is a "bar gauge", reporting a value that's represented as a percentage. The graduation reflects the user-selectable colour thresholds.

## Rainwater tank level

<p align="left">
  <img src="https://github.com/user-attachments/assets/0791311d-6408-423f-81c8-6c2d3f0f6167" width="20%">
</p>

The rainwater tank level is represented as a "gauge", with my own addition of the colour and markers every 500L. In this example the GA would be reporting the value in litres.


## Heading - "your turn"

Out of the box the sample is less appealing. Your task is to customise it with your local Group Addresses or their names. Here's how to do that:
