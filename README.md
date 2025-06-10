# RouteInfo

A simple Garmin Connect IQ data field that reads a GPX file and reports route statistics.

## Features

* Parse a GPX file from the app resources using simple string parsing (no Toybox.Xml).
* Calculate total track distance and total climb.
* Show progress on the route relative to the device GPS position.
* Display distance from the current position to waypoints.

## Building

Requires the Garmin Connect IQ SDK. Build using:

```bash
monkeydo RouteInfoField.mc [device]
```

## Sample GPX

The `src/resources/route.gpx` file contains a small sample route used by the app.
