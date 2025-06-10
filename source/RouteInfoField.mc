using Toybox.Application;
using Toybox.WatchUi;
using Toybox.Position;
using Toybox.Gfx;
using Toybox.Lang;
using Toybox.System;
using Toybox.Xml;

/**
 * RouteInfoField
 *
 * A simple data field that reads a GPX route from resources, calculates
 * total distance and climb, determines progress based on the current
 * GPS position, and reports distance to any waypoints in the file.
 */
class RouteInfoField extends WatchUi.DataField {
    var trkpts = [];
    var wpts = [];
    var totalDist = 0.0;
    var totalClimb = 0.0;
    var parsed = false;

    function initialize() {
        DataField.initialize();
    }

    function parseGpx() {
        var gpxData = Rez.getText("route_gpx");
        var xml = Xml.fromXml(gpxData);
        var lastPt = null;
        if (xml.has("wpt")) {
            foreach (var w in xml.getAll("wpt")) {
                wpts += w;
            }
        }
        var trkseg = xml.findNode("trk/trkseg");
        if (trkseg != null) {
            foreach (var pt in trkseg.getAll("trkpt")) {
                var lat = pt.get("lat").toNumber();
                var lon = pt.get("lon").toNumber();
                var ele = pt.getChildText("ele").toNumber();
                var pos = { :lat => lat, :lon => lon, :ele => ele };
                if (lastPt != null) {
                    var dist = Position.distance(lastPt[:lat], lastPt[:lon], lat, lon);
                    totalDist += dist;
                    var climb = ele - lastPt[:ele];
                    if (climb > 0) {
                        totalClimb += climb;
                    }
                }
                lastPt = pos;
                trkpts += pos;
            }
        }
        parsed = true;
    }

    function onUpdate(dc) {
        if (!parsed) {
            parseGpx();
        }

        var info = Position.getInfo();
        if (info == null || !info[:positionAvailable]) {
            dc.clear();
            dc.drawText(0, 0, Gfx.FONT_XTINY, "GPS unavailable");
            return;
        }

        var currLat = info[:latitude];
        var currLon = info[:longitude];

        var traveled = 0.0;
        var progress = 0.0;
        var lastPt = null;
        foreach (var pt in trkpts) {
            if (lastPt != null) {
                var segDist = Position.distance(lastPt[:lat], lastPt[:lon], pt[:lat], pt[:lon]);
                traveled += segDist;
                var distToCurr = Position.distance(lastPt[:lat], lastPt[:lon], currLat, currLon);
                var distToNext = Position.distance(currLat, currLon, pt[:lat], pt[:lon]);
                if (distToCurr + distToNext - segDist < 1) {
                    progress = (traveled - segDist + distToCurr) / totalDist;
                    break;
                }
            }
            lastPt = pt;
        }

        dc.clear();
        var y = 0;
        dc.drawText(0, y, Gfx.FONT_XTINY, Lang.format("Dist %.0fm Climb %.0fm", [totalDist, totalClimb]));
        y += 12;
        dc.drawText(0, y, Gfx.FONT_XTINY, Lang.format("Progress %.1f%%", [progress * 100]));
        y += 12;
        foreach (var w in wpts) {
            var wLat = w.get("lat").toNumber();
            var wLon = w.get("lon").toNumber();
            var wName = w.getChildText("name");
            var distToWpt = Position.distance(currLat, currLon, wLat, wLon);
            dc.drawText(0, y, Gfx.FONT_XTINY, wName + ": " + Lang.format("%.0fm", [distToWpt]));
            y += 12;
        }
    }
}
