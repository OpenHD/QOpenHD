import QtQuick 2.12

Item {
    id: root
    visible: settings.adsb_enable && settings.adsb_show_osd_markers
    enabled: false
    z: 1.5
    property var aircraft: []

    function bearing(lat1, lon1, lat2, lon2) {
        var p1 = lat1 * Math.PI / 180
        var p2 = lat2 * Math.PI / 180
        var dl = (lon2 - lon1) * Math.PI / 180
        var y = Math.sin(dl) * Math.cos(p2)
        var x = Math.cos(p1) * Math.sin(p2) - Math.sin(p1) * Math.cos(p2) * Math.cos(dl)
        return (Math.atan2(y, x) * 180 / Math.PI + 360) % 360
    }
    function relativeAngle(value) {
        return ((value - _fcMavlinkSystem.hdg + 540) % 360) - 180
    }
    function refresh() {
        var result = []
        for (var i = 0; i < AdsbVehicleManager.adsbVehicles.count; ++i) {
            var vehicle = AdsbVehicleManager.adsbVehicles.get(i)
            if (!vehicle || !isFinite(vehicle.lat) || !isFinite(vehicle.lon)) continue
            var angle = relativeAngle(bearing(_fcMavlinkSystem.lat, _fcMavlinkSystem.lon, vehicle.lat, vehicle.lon))
            if (Math.abs(angle) <= 70) result.push(vehicle)
        }
        result.sort(function(a, b) { return a.distance - b.distance })
        aircraft = result.slice(0, 8)
    }

    Timer { interval: 500; running: root.visible; repeat: true; triggeredOnStart: true; onTriggered: root.refresh() }

    Repeater {
        model: root.aircraft
        Item {
            property real direction: root.relativeAngle(root.bearing(_fcMavlinkSystem.lat, _fcMavlinkSystem.lon, modelData.lat, modelData.lon))
            property real altitudeDelta: isFinite(modelData.altitude) ? modelData.altitude - _fcMavlinkSystem.altitude_msl_m : 0
            width: 90; height: 42
            x: Math.max(0, Math.min(root.width - width, root.width / 2 + direction / 70 * root.width / 2 - width / 2))
            y: Math.max(45, Math.min(root.height - height - 45, root.height / 2 - altitudeDelta / 1200 * root.height / 2 - height / 2))
            Rectangle {
                anchors.fill: parent; radius: 6
                color: "#99000000"; border.width: 2
                border.color: modelData.alert ? "#ff4545" : "#ffffff"
            }
            Text {
                anchors.horizontalCenter: parent.horizontalCenter; anchors.top: parent.top; anchors.topMargin: 2
                text: "✈  " + (modelData.callsign && modelData.callsign.trim().length ? modelData.callsign.trim() : modelData.icaoAddress.toString(16).toUpperCase())
                font.pixelSize: 11; font.bold: true; color: "white"
            }
            Text {
                anchors.horizontalCenter: parent.horizontalCenter; anchors.bottom: parent.bottom; anchors.bottomMargin: 2
                text: (settings.enable_imperial ? (modelData.distance * 0.621371).toFixed(1) + " mi" : modelData.distance.toFixed(1) + " km")
                      + (isFinite(modelData.altitude) ? "  " + (altitudeDelta >= 0 ? "+" : "") + Math.round(settings.enable_imperial ? altitudeDelta * 3.28084 : altitudeDelta) + (settings.enable_imperial ? " ft" : " m") : "")
                font.pixelSize: 10; color: "white"
            }
        }
    }
}
