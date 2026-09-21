import QtQuick 2.12
import QtQuick.Layouts 1.12

BaseWidget {
    id: root
    width: 250 * bw_current_scale
    height: 132 * bw_current_scale
    visible: settings.show_widgets && settings.adsb_enable && settings.adsb_show_nearest_widget
    widgetIdentifier: "adsb_nearest"
    bw_verbose_name: qsTr("ADS-B traffic")
    defaultAlignment: 2
    defaultXOffset: 18
    defaultYOffset: 120
    readonly property bool gpsReady: _fcMavlinkSystem.gps_fix_type >= 2
                                     && !(_fcMavlinkSystem.lat === 0.0 && _fcMavlinkSystem.lon === 0.0)
    property var displayedAircraft: []

    function usableDistance(vehicle) {
        return vehicle && isFinite(vehicle.distance) && vehicle.distance >= 0
    }

    function usableRssi(vehicle) {
        return vehicle && isFinite(vehicle.rssi)
    }

    function refresh() {
        var aircraft = []
        for (var i = 0; i < AdsbVehicleManager.adsbVehicles.count; ++i) {
            var vehicle = AdsbVehicleManager.adsbVehicles.get(i)
            if (vehicle) aircraft.push(vehicle)
        }
        if (gpsReady) {
            aircraft.sort(function(a, b) {
                var ad = root.usableDistance(a) ? a.distance : Number.POSITIVE_INFINITY
                var bd = root.usableDistance(b) ? b.distance : Number.POSITIVE_INFINITY
                return ad - bd
            })
        } else {
            aircraft.sort(function(a, b) {
                var ar = root.usableRssi(a) ? a.rssi : Number.NEGATIVE_INFINITY
                var br = root.usableRssi(b) ? b.rssi : Number.NEGATIVE_INFINITY
                return br - ar
            })
        }
        displayedAircraft = aircraft.slice(0, 3)
    }

    Timer { interval: 1000; running: root.visible; repeat: true; triggeredOnStart: true; onTriggered: root.refresh() }

    Rectangle {
        anchors.fill: parent
        radius: 7 * root.bw_current_scale
        color: root.bw_current_background_color
        opacity: root.bw_current_opacity
        border.color: "#80ffffff"
    }
    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 7 * root.bw_current_scale
        spacing: 3 * root.bw_current_scale
        RowLayout {
            Layout.fillWidth: true
            Rectangle {
                width: 10 * root.bw_current_scale; height: width; radius: width / 2
                color: AdsbVehicleManager.status === 2 ? "#35d36b" : (AdsbVehicleManager.status === 1 ? "#ff5a5a" : "#7d8790")
            }
            Text {
                Layout.fillWidth: true
                text: AdsbVehicleManager.status === 2 ? qsTr("ADS-B WORKING") : (AdsbVehicleManager.status === 1 ? qsTr("ADS-B OFFLINE") : qsTr("ADS-B WAITING"))
                color: "white"; font.bold: true; font.pixelSize: 11 * root.bw_current_scale
            }
            Text {
                text: root.gpsReady ? qsTr("NEAREST") : qsTr("STRONGEST")
                color: "#c8d2dc"; font.pixelSize: 9 * root.bw_current_scale
            }
        }
        Repeater {
            model: root.displayedAircraft
            RowLayout {
                Layout.fillWidth: true
                Text {
                    Layout.fillWidth: true
                    text: modelData.callsign && modelData.callsign.trim().length ? modelData.callsign.trim() : ("ICAO " + (modelData.icaoAddress >>> 0).toString(16).toUpperCase())
                    color: modelData.alert ? "#ff5a5a" : "white"
                    elide: Text.ElideRight; font.pixelSize: 12 * root.bw_current_scale
                }
                Text {
                    text: root.gpsReady && root.usableDistance(modelData)
                          ? (settings.enable_imperial ? (modelData.distance * 0.621371).toFixed(1) + " mi" : modelData.distance.toFixed(1) + " km")
                          : (root.usableRssi(modelData) ? modelData.rssi.toFixed(1) + " dBFS" : qsTr("signal --"))
                    color: "white"; font.bold: true; font.pixelSize: 11 * root.bw_current_scale
                }
            }
        }
        Text {
            visible: root.displayedAircraft.length === 0
            text: AdsbVehicleManager.status === 2 ? qsTr("Receiver ready - no traffic") : qsTr("Waiting for dump1090")
            color: "#c8d2dc"; font.pixelSize: 12 * root.bw_current_scale
        }
    }
}
