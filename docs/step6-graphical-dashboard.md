# A Sample Graphical Dashboard

If you've researched Grafana or watched any of the YouTube links you'll realise it's a VERY powerful tool, and using it to present a tabular Group Monitor is seriously under-using it.

To provide a small head-start, a sample graphical dashboard is included which demonstrates a few of Grafana's graphical features.

If you have similar devices (Group Addresses) that can be used as the raw data, you can have a view looking like this in no time. If not, it's easy to delete the 'panels' you don't have a use for, and re-size the remaining ones to fill in the gaps. More on that later.

<p align="center">
  <img src="https://github.com/user-attachments/assets/bfdb8d53-f848-4898-ba01-601cbdfef43a" width="100%">
</p>

## Dashboards vs Panels

What you see in the image above is a "dashboard", made up of nine separate "panels". If you hover your mouse over any panel and type a 'v', that panel will zoom to full screen (press Esc to return). Click and drag the mouse across an interesting time-period on the timeline graphs to zoom into that duration.

## Temperatures graph

We have multiple temperature and light level sensors, so I've overlaid them on each other for a comparison. The jagged blue line is the temperature in the permanently air-conditioned server/IT room.

Note how the Y-axis (vertical) only ranges from 10° to 30°C, demonstrating how the "auto" axis setting helps maximise the presentation of the data. (You can peg it to fixed minimum and/or maximum values if you prefer). Below the graph is the legend where the three sensors are given a sensible name.

## Light levels graph

Like temperatures, I have two light level sensors showing their readings on top of each other. A key difference here is that both have different Y-axes, which you can see at the left and the right of the graph. That's because one of the sensors reports lux as DPT 7.013 and the other as DPT 9.004. Whilst the raw numeric values differ by more than an order of magnitude, the graphs confirm they're largely in alignment. (If you're curious, the divergence at sunrise and sunset is due to one being on the shaded southern wall whilst the other is west-facing.)

## A "logic analyser" view

This panel is reporting the on/off state of three Switch GA's in the bathroom: the light, the exhaust fan and the heated towel rail. This panel would be a good one to employ when you're debugging the interaction between linked GAs.

A word of warning however is that very brief changes of state will not show on the graph if you're looking at (say) a 24-hour window, not unlike how you can't see the car parked in your driveway on Google Street View if you've zoomed all the way out to space. When troubleshooting, change the time range to more narrowly focus on the time period in question.

## "Breaker trip"

<p align="left">
  <img src="https://github.com/user-attachments/assets/ad2e0a62-cf78-4bfc-83ed-8c5de94c2da0" width="20%">
</p>

<p align="left">
  <img src="https://github.com/user-attachments/assets/04da1cb5-b2a0-452c-80f0-b4596ba1d8f1" width="20%">
</p>

This panel is a "single stat" panel reporting the state of a single GA of DPT 1.xxx. The On/Off state reported by the telegram has been customised with attention-grabbing labels and colours.

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

## Pool pump run count & times

<p align="left">
  <img src="https://github.com/user-attachments/assets/7a5deaf2-fa14-48f2-bf50-2476e62c6909" width="20%">
</p>

Here we see two ways of looking at a boolean (switch) value, in this case my fictitious pool pump. The pump has run three times today, and "No data" reveals I can't figure out (yet) how to show the total run time. Whilst in reality it's reporting my Garage light FB GA, it would work nicely on the door to the coolroom, and show how long it's left open in total, or the "mean" value to report the average of each opening. (As with everything KNX, your creativity is called upon here to make it shine.)


## Your turn! Out of the box it ain't so pretty

Out of the box the sample is less appealing. That's because I've stripped all my specific GA's, for you to add your own.


Your task is to customise it with your local Group Addresses or their names. Here's how to do that:

Basic Steps

The basic steps for every panel are the same:
1. mouse over the panel and type 'e', or alternatively click the vertical ellipsis in the top RH corner and select Edit from the menu that appears.
2. Click in the blank space to the right of 
