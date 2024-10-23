# A sample graphical dashboard

If you've researched Grafana or watched any of the YouTube links you'll realise it's a VERY powerful tool, and using it to present a tabular Group Monitor is seriously under-using it.

To provide a small head-start, a sample graphical dashboard is included which demonstrates a few of Grafana's graphical features.

If you have similar devices (Group Addresses) that can be used as the raw data, you can have a view looking like this in no time. If not, it's easy to delete the 'panels' you don't have a use for, and re-size or duplicate the remaining ones to fill in the gaps. More on that later.

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

## Current temperature

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

Here are two ways of looking at a boolean (switch) value, in this case my fictitious pool pump. The pump has run three times today, and "No data" reveals I can't figure out (yet) how to show the total run time. Whilst in reality it's reporting my Garage light FB GA, it would work nicely on the door to the coolroom, and show how long it's left open in total today/this shift. Changing the formula to calculate the "mean" value would report the average duration of each opening. (As with so much in KNX, your creativity is called upon here to make it shine.)

<br>

[Top](#a-sample-graphical-dashboard)

<hr/>

## Your turn! Out of the box it ain't so pretty

Out of the box the sample is less appealing. That's because I've stripped all my specific GA's, for you to add your own.

<p align="center">
  <img src="https://github.com/user-attachments/assets/1579b9ef-7bd9-4ad3-ae4b-7680e8efd284" width="100%">
</p>

Your task is to customise it with your local Group Addresses or their names. Here's how to do that.

## Basic steps

The basic steps for every panel are the same:
1. Mouse over the panel and type `e`, or alternatively click the vertical ellipsis in the top RH corner and select `Edit` from the menu that appears.
2. In the "queries" section, click on my dummy name "TODO":

<p align="center">
  <img src="https://github.com/user-attachments/assets/bb88b09e-b7fe-4fc5-b819-13dc1816424f" width="100%">
</p>

3. A popup will appear with all of the possible GA names from which you can choose. Type in the "Choose" box to filter, or scroll then click on your selection.

> Only after a GA has been logged by captureKNX will it appear in that list. If an expected group name isn't appearing, trigger a telegram to it and retry.

4. If the GA you chose is a compatible DPT type for the type of panel, the top half of the graph should change from No Data to show something. If not, click "float" (highlighted here in yellow) and change it to "integer" (assuming this is a numeric value you're working with).

> I've built all these panels referencing the GA names, technically referred to here as "destination_name::tag". If you prefer, you can re-base them to filter on the GA value itself. Just click on "destination_name::tag" (highlighted here in blue) and another popup will present other options to filter by. "destination::tag" is the GA itself (e.g. 1/0/7).

5. By default the full GA name is shown in the legend under the graph. If you want something more succinct, add that in the `ALIAS` field, shown here with the dummy value "sensor4".
6. In the top LH corner of the above image it shows "Queries (2)". That's telling you this panel is making two separate queries to the database, so scroll further (query "B" is shown) and select a valid GA for it.
7. For most panels that should be all you need to do to recover them. Click `Save dashboard` in the top RH corner, then `Save` on the Save Dashboard flyout.
8. Back in the top right, click `Back to dashboard` to be returned to the main dashboard view to select another panel.
9. Repeat the above steps until you've allocated the GA for all the panels you want to retain.

## Extra steps

Some of the panels may require a little more tweaking.

### Bathroom "logic analyser"

The "logic analyser" panel turns boolean (on/off) values into the numbers 1 and 0, then literally adds an offset to the vales of Fan and Heat to place them above the Light on the graph.

This happens on the "Transformations" tab, and if you've set friendly ALIASES, these will need to be updated.

10. Edit the bathroom panel.
11. Click "Transformations":

<p align="center">
  <img src="https://github.com/user-attachments/assets/c6721f9c-6fc7-4402-9065-017eeef677b8" width="100%">
</p>

12. Click all three field values and select the names (or aliases) that were set on the Queries tab. The little "switch" icon indicates that we're converting the field type of boolean (switch) to a Number. Here I've shown one complete, with two still unset. Hopefully in completing this step the graph will have correctly resolved itself. If you later change an ALIAS, you'll need to revisit and update the Transformation.

13. Finally, the calculated 'offset alias' names are showing on the legend under the table. To correct them, scroll towards the bottom of the right hand column until you reach the `Overrides`. Open each of the named ones in turn and customise them to your environment. Change the 'not found' fields with the current ones, then update the Display Name. As soon as you tab off that field the panel should update.

<p align="centre">
  <img src="https://github.com/user-attachments/assets/5936ea67-cf27-4ab8-80ce-e4a164e500cd" width="40%">
</p>

14. Save the dashboard.

### Changing threshold values & colours

When you're editing a panel, the right-hand column provides all the controls for changing the display type (at the very top), whether the Y axis is fixed or follows the data, the thresholds and their colours. This is where you would change the capacity of the rainwater tank and the colours, the colour of the temperature, and the graduations in the Powerwall bar.

<p align="centre">
  <img src="https://github.com/user-attachments/assets/96eaca0d-8180-4676-8fc7-b3fabc4bb076" width="40%">
</p>

### Value mappings

Value mappings is also another powerful way of reformatting the data. This is how the "Breaker Trip" panel turns 'alarm/no alarm' into 'breaker trip/normal', and how the bathroom's logic analyser turns what are in reality numerical values into 'on/off' labels.

<p align="centre">
  <img src="https://github.com/user-attachments/assets/a7833103-23d6-46d4-9a2b-08c66af34209" width="40%">
</p>

<br>

[Top](#a-sample-graphical-dashboard)

<hr/>
