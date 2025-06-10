using Toybox.Application;
using Toybox.WatchUi;
using Toybox.Position;
using Toybox.Gfx;
using Toybox.Lang;
using Toybox.System;
using Toybox.Xml;

class RouteInfoApp extends Application.AppBase {

    function initialize() {
        AppBase.initialize();
    }

    function onStart() {
        var gpxData = Rez.getText("route_gpx");
        var xml = Xml.fromXml(gpxData);
        var trkpts = [];
        var wpts = [];
        var totalDist = 0.0;
        var totalClimb = 0.0;
        var lastPt = null;

        if (xml.has("wpt")) {
            foreach (var w in xml.getAll("wpt")) {
                wpts += w;
            }
        }

        var trksegs = xml.findNode("trk/trkseg");
        if (trksegs != null) {
            foreach (var pt in trksegs.getAll("trkpt")) {
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

        System.println("Total distance: " + totalDist + " meters");
        System.println("Total climb: " + totalClimb + " meters");

        // Get current position
        var info = Position.getInfo();
        if (info != null && info[:positionAvailable]) {
            var currLat = info[:latitude];
            var currLon = info[:longitude];

            // Find progress along track
            var traveled = 0.0;
            lastPt = null;
            var progress = 0.0;
            foreach (var pt in trkpts) {
                if (lastPt != null) {
                    var segDist = Position.distance(lastPt[:lat], lastPt[:lon], pt[:lat], pt[:lon]);
                    traveled += segDist;
                    var distToCurr = Position.distance(lastPt[:lat], lastPt[:lon], currLat, currLon);
                    var distToNext = Position.distance(currLat, currLon, pt[:lat], pt[:lon]);
                    // If current point is between lastPt and pt
                    if (distToCurr + distToNext - segDist < 1) {
                        progress = (traveled - segDist + distToCurr) / totalDist;
                        break;
                    }
                }
                lastPt = pt;
            }
            System.println("Progress: " + (progress * 100) + "%");

            foreach (var w in wpts) {
                var wLat = w.get("lat").toNumber();
                var wLon = w.get("lon").toNumber();
                var wName = w.getChildText("name");
                var distToWpt = Position.distance(currLat, currLon, wLat, wLon);
                System.println("Distance to " + wName + ": " + distToWpt + " meters");
            }
        } else {
            System.println("GPS position not available");
        }
    }

    function getInitialView() {
        return new RouteInfoView();
    }
}

class RouteInfoView extends WatchUi.View {
    function initialize() {
        View.initialize();
    }

    function onShow() {
    }

    function onHide() {
    }

    function onUpdate(dc) {
        dc.clear();
        dc.drawText(10, 10, Gfx.FONT_XTINY, "Route Info App");
    }
}
