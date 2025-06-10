using Toybox.Application;
using Toybox.WatchUi;
using Toybox.Position;
using Toybox.Gfx;
using Toybox.Lang;
using Toybox.System;

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

    function _getAttr(line, attr) {
        var key = attr + "=\"";
        var idx = line.indexOf(key);
        if (idx < 0) { return null; }
        idx += key.length();
        var endIdx = line.indexOf("\"", idx);
        return line.substring(idx, endIdx);
    }

    function _getTag(line, tag) {
        var startTag = "<" + tag + ">";
        var endTag = "</" + tag + ">";
        var startIdx = line.indexOf(startTag);
        if (startIdx < 0) { return null; }
        startIdx += startTag.length();
        var endIdx = line.indexOf(endTag, startIdx);
        return line.substring(startIdx, endIdx);
    }

    function parseGpx() {
        var gpxData = Rez.getText("route_gpx");
        var lines = gpxData.split("\n");
        var lastPt = null;
        foreach (var line in lines) {
            var l = line.trim();
            if (l.startsWith("<wpt")) {
                var lat = _getAttr(l, "lat").toNumber();
                var lon = _getAttr(l, "lon").toNumber();
                var name = _getTag(l, "name");
                wpts += { :lat => lat, :lon => lon, :name => name };
            } else if (l.startsWith("<trkpt")) {
                var lat = _getAttr(l, "lat").toNumber();
                var lon = _getAttr(l, "lon").toNumber();
                var ele = _getTag(l, "ele").toNumber();
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
            var wLat = w[:lat];
            var wLon = w[:lon];
            var wName = w[:name];
            var distToWpt = Position.distance(currLat, currLon, wLat, wLon);
            dc.drawText(0, y, Gfx.FONT_XTINY, wName + ": " + Lang.format("%.0fm", [distToWpt]));
            y += 12;
        }
    }
}
