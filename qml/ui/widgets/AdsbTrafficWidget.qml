import QtQuick 2.12
import QtQuick.Controls 2.12
import QtQuick.Layouts 1.12
import QtQuick.Window 2.12

BaseWidget {
    id: root

    width: 286 * bw_current_scale
    height: 142 * bw_current_scale
    visible: settings.show_widgets && settings.adsb_enable && settings.adsb_show_nearest_widget
    widgetIdentifier: "adsb_nearest"
    bw_verbose_name: qsTr("ADS-B traffic")
    defaultAlignment: 2
    defaultXOffset: 18
    defaultYOffset: 120

    // Use the same HUD customization and placement contract as the other
    // BaseWidget implementations.
    hasWidgetDetail: true
    widgetDetailWidth: 300
    widgetDetailHeight: 170

    hasWidgetAction: true
    widgetActionWidth: Math.min(900, Math.max(700,
                                             (root.Window.window ? root.Window.window.width : 1280) - 80))
    widgetActionHeight: Math.min(600, Math.max(480,
                                              (root.Window.window ? root.Window.window.height : 720) - 80))

    readonly property color safeColor: "#36d17c"
    readonly property color cautionColor: "#ffb020"
    readonly property color warningColor: "#ff4d5e"
    readonly property color mutedColor: "#91a0ae"
    readonly property color panelColor: "#e80b1118"
    readonly property color panelRaisedColor: "#f017202a"
    readonly property color lineColor: "#334657"
    readonly property color textColor: settings.color_text
    readonly property string textFontFamily: settings.font_text
    readonly property bool gpsReady: _fcMavlinkSystem.gps_fix_type >= 2
                                     && !(_fcMavlinkSystem.lat === 0.0
                                          && _fcMavlinkSystem.lon === 0.0)
    readonly property real ownAltitude: _fcMavlinkSystem.altitude_msl_m

    property var displayedAircraft: []
    property var selectedAircraft: null
    property real radarRangeKm: 10
    property int criticalCount: 0
    property int cautionCount: 0

    function validNumber(value) {
        return value !== undefined && value !== null && isFinite(value)
    }

    function usableDistance(vehicle) {
        return vehicle && validNumber(vehicle.distance) && vehicle.distance >= 0
    }

    function usableRssi(vehicle) {
        return vehicle && validNumber(vehicle.rssi)
    }

    function altitudeDelta(vehicle) {
        if (!vehicle || !gpsReady || !validNumber(vehicle.altitude)
                || !validNumber(ownAltitude)) return NaN
        return vehicle.altitude - ownAltitude
    }

    // 2 = warning, 1 = caution, 0 = normal. Match the existing OpenHD
    // distance/altitude limits, but use absolute vertical separation.
    function threatLevel(vehicle) {
        if (!usableDistance(vehicle)) return vehicle && vehicle.alert ? 2 : 0
        var delta = Math.abs(altitudeDelta(vehicle))
        if (!validNumber(delta)) return vehicle.alert ? 2 : 0
        if (vehicle.alert || (vehicle.distance < 2 && delta < 300)) return 2
        if (vehicle.distance < 5 && delta < 500) return 1
        return 0
    }

    function aircraftColor(vehicle) {
        var level = threatLevel(vehicle)
        return level === 2 ? warningColor : (level === 1 ? cautionColor : safeColor)
    }

    function aircraftName(vehicle) {
        if (!vehicle) return qsTr("No aircraft selected")
        var callsign = vehicle.callsign ? vehicle.callsign.trim() : ""
        return callsign.length ? callsign : ("ICAO " + hexAddress(vehicle.icaoAddress))
    }

    function hexAddress(address) {
        var value = address >>> 0
        var result = value.toString(16).toUpperCase()
        while (result.length < 6) result = "0" + result
        return result
    }

    function formatDistance(vehicle) {
        if (!usableDistance(vehicle)) return qsTr("--")
        return settings.enable_imperial
                ? (vehicle.distance * 0.621371).toFixed(1) + " mi"
                : vehicle.distance.toFixed(1) + " km"
    }

    function formatAltitude(value) {
        if (!validNumber(value)) return qsTr("--")
        return settings.enable_imperial
                ? Math.round(value * 3.28084) + " ft"
                : Math.round(value) + " m"
    }

    function formatAltitudeDelta(vehicle) {
        var delta = altitudeDelta(vehicle)
        if (!validNumber(delta)) return qsTr("--")
        var converted = settings.enable_imperial ? delta * 3.28084 : delta
        return (converted > 0 ? "+" : "") + Math.round(converted)
                + (settings.enable_imperial ? " ft" : " m")
    }

    function formatSpeed(value) {
        if (!validNumber(value)) return qsTr("--")
        return settings.enable_imperial
                ? Math.round(value * 0.621371) + " mph"
                : Math.round(value) + " km/h"
    }

    function formatVerticalSpeed(value) {
        if (!validNumber(value)) return qsTr("--")
        var converted = settings.enable_imperial ? value * 196.8504 : value
        return (converted > 0 ? "+" : "") + Math.round(converted)
                + (settings.enable_imperial ? " ft/min" : " m/s")
    }

    function bearing(lat1, lon1, lat2, lon2) {
        if (!validNumber(lat1) || !validNumber(lon1)
                || !validNumber(lat2) || !validNumber(lon2)) return NaN
        var p1 = lat1 * Math.PI / 180
        var p2 = lat2 * Math.PI / 180
        var dl = (lon2 - lon1) * Math.PI / 180
        var y = Math.sin(dl) * Math.cos(p2)
        var x = Math.cos(p1) * Math.sin(p2)
                - Math.sin(p1) * Math.cos(p2) * Math.cos(dl)
        return (Math.atan2(y, x) * 180 / Math.PI + 360) % 360
    }

    function relativeBearing(vehicle) {
        if (!vehicle || !gpsReady) return NaN
        var absolute = bearing(_fcMavlinkSystem.lat, _fcMavlinkSystem.lon,
                               vehicle.lat, vehicle.lon)
        if (!validNumber(absolute)) return NaN
        return (absolute - _fcMavlinkSystem.hdg + 360) % 360
    }

    function refresh() {
        var aircraft = []
        var warnings = 0
        var cautions = 0
        for (var i = 0; i < AdsbVehicleManager.adsbVehicles.count; ++i) {
            var vehicle = AdsbVehicleManager.adsbVehicles.get(i)
            if (!vehicle) continue
            aircraft.push(vehicle)
            var level = threatLevel(vehicle)
            if (level === 2) ++warnings
            else if (level === 1) ++cautions
        }
        aircraft.sort(function(a, b) {
            if (gpsReady) {
                var ad = usableDistance(a) ? a.distance : Number.POSITIVE_INFINITY
                var bd = usableDistance(b) ? b.distance : Number.POSITIVE_INFINITY
                return ad - bd
            }
            var ar = usableRssi(a) ? a.rssi : Number.NEGATIVE_INFINITY
            var br = usableRssi(b) ? b.rssi : Number.NEGATIVE_INFINITY
            return br - ar
        })
        displayedAircraft = aircraft
        criticalCount = warnings
        cautionCount = cautions

        if (!selectedAircraft && aircraft.length) selectedAircraft = aircraft[0]
        if (selectedAircraft) {
            var stillPresent = false
            for (var j = 0; j < aircraft.length; ++j) {
                if (aircraft[j].icaoAddress === selectedAircraft.icaoAddress) {
                    selectedAircraft = aircraft[j]
                    stillPresent = true
                    break
                }
            }
            if (!stillPresent) selectedAircraft = aircraft.length ? aircraft[0] : null
        }
    }

    Timer {
        interval: 500
        running: root.visible || root.widgetAction.visible
        repeat: true
        triggeredOnStart: true
        onTriggered: root.refresh()
    }

    Rectangle {
        anchors.fill: parent
        radius: 8 * root.bw_current_scale
        color: root.bw_current_background_color
        opacity: root.bw_current_opacity
        border.width: 1
        border.color: root.criticalCount ? root.warningColor
                                         : (root.cautionCount ? root.cautionColor : root.lineColor)
    }

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 9 * root.bw_current_scale
        spacing: 5 * root.bw_current_scale

        RowLayout {
            Layout.fillWidth: true
            spacing: 7 * root.bw_current_scale

            Text {
                text: "\uf072"
                color: root.criticalCount ? root.warningColor
                                          : (root.cautionCount ? root.cautionColor : root.textColor)
                font.family: "Font Awesome 5 Free"
                font.pixelSize: 15 * root.bw_current_scale
            }
            Text {
                text: qsTr("ADS-B TRAFFIC")
                color: root.textColor
                font.family: root.textFontFamily
                font.bold: true
                font.pixelSize: 11 * root.bw_current_scale
            }
            Rectangle {
                width: 7 * root.bw_current_scale
                height: width
                radius: width / 2
                color: AdsbVehicleManager.status === 2 ? root.safeColor
                       : (AdsbVehicleManager.status === 1 ? root.warningColor : root.mutedColor)
            }
            Text {
                Layout.fillWidth: true
                text: root.displayedAircraft.length + " " + qsTr("targets")
                color: root.textColor
                opacity: 0.72
                font.family: root.textFontFamily
                font.pixelSize: 10 * root.bw_current_scale
            }
            Text {
                text: "\uf078"
                color: root.textColor
                font.family: "Font Awesome 5 Free"
                font.pixelSize: 11 * root.bw_current_scale
            }
        }

        Rectangle { Layout.fillWidth: true; height: 1; color: root.lineColor }

        Item {
            Layout.fillWidth: true
            Layout.fillHeight: true

            ColumnLayout {
                id: nearestSummary
                visible: root.displayedAircraft.length > 0
                anchors.fill: parent
                spacing: 3 * root.bw_current_scale
                readonly property var nearest: root.displayedAircraft.length
                                               ? root.displayedAircraft[0] : null

                RowLayout {
                    Layout.fillWidth: true
                    Text {
                        Layout.fillWidth: true
                        text: root.aircraftName(nearestSummary.nearest)
                        color: root.aircraftColor(nearestSummary.nearest)
                        font.family: root.textFontFamily
                        font.bold: true
                        font.pixelSize: 17 * root.bw_current_scale
                        elide: Text.ElideRight
                    }
                    Text {
                        text: root.formatDistance(nearestSummary.nearest)
                        color: root.textColor
                        font.family: root.textFontFamily
                        font.bold: true
                        font.pixelSize: 17 * root.bw_current_scale
                    }
                }
                RowLayout {
                    Layout.fillWidth: true
                    Text {
                        Layout.fillWidth: true
                        text: qsTr("Relative altitude") + "  "
                              + root.formatAltitudeDelta(nearestSummary.nearest)
                        color: root.textColor
                        opacity: 0.78
                        font.family: root.textFontFamily
                        font.pixelSize: 11 * root.bw_current_scale
                    }
                    Text {
                        text: root.threatLevel(nearestSummary.nearest) === 2 ? qsTr("WARNING")
                              : (root.threatLevel(nearestSummary.nearest) === 1
                                 ? qsTr("CAUTION") : qsTr("NEAREST"))
                        color: root.aircraftColor(nearestSummary.nearest)
                        font.family: root.textFontFamily
                        font.bold: true
                        font.pixelSize: 10 * root.bw_current_scale
                    }
                }
                Text {
                    visible: root.displayedAircraft.length > 1
                    text: "+" + (root.displayedAircraft.length - 1) + " " + qsTr("more aircraft")
                    color: root.textColor
                    opacity: 0.72
                    font.family: root.textFontFamily
                    font.pixelSize: 10 * root.bw_current_scale
                }
            }

            Column {
                visible: root.displayedAircraft.length === 0
                anchors.centerIn: parent
                spacing: 4 * root.bw_current_scale
                Text {
                    anchors.horizontalCenter: parent.horizontalCenter
                    text: AdsbVehicleManager.status === 2 ? qsTr("NO TRAFFIC") : qsTr("ADS-B WAITING")
                    color: root.textColor
                    font.family: root.textFontFamily
                    font.bold: true
                    font.pixelSize: 14 * root.bw_current_scale
                }
                Text {
                    anchors.horizontalCenter: parent.horizontalCenter
                    text: AdsbVehicleManager.status === 2
                          ? qsTr("Receiver ready") : qsTr("Waiting for traffic source")
                    color: root.textColor
                    opacity: 0.72
                    font.family: root.textFontFamily
                    font.pixelSize: 10 * root.bw_current_scale
                }
            }
        }
    }

    widgetDetailComponent: ScrollView {
        contentHeight: adsbWidgetControls.height
        ScrollBar.horizontal.policy: ScrollBar.AlwaysOff
        clip: true

        BaseWidgetDefaultUiControlElements {
            id: adsbWidgetControls
            show_vertical_lock: true
            show_horizontal_lock: true
            show_background_color: true
            background_color_target: root
        }
    }

    widgetActionComponent: Rectangle {
            color: root.panelColor
            border.color: root.lineColor
            border.width: 1
            radius: 9

            ColumnLayout {
                anchors.fill: parent
                anchors.margins: 14
                spacing: 10

                RowLayout {
                    Layout.fillWidth: true
                    spacing: 9
                    Text {
                        text: "\uf072"
                        color: root.criticalCount ? root.warningColor : "white"
                        font.family: "Font Awesome 5 Free"
                        font.pixelSize: 21
                    }
                    ColumnLayout {
                        Layout.fillWidth: true
                        spacing: 0
                        Text {
                            text: qsTr("ADS-B AIR TRAFFIC")
                            color: "white"
                            font.bold: true
                            font.pixelSize: 18
                        }
                        Text {
                            text: root.gpsReady ? qsTr("Heading-up view centered on this aircraft")
                                                : qsTr("Waiting for own-aircraft GPS position")
                            color: root.mutedColor
                            font.pixelSize: 11
                        }
                    }
                    Rectangle {
                        height: 30
                        width: statusRow.width + 18
                        radius: 15
                        color: root.criticalCount ? "#35ff4d5e"
                                                  : (root.cautionCount ? "#35ffb020" : "#2436d17c")
                        Row {
                            id: statusRow
                            anchors.centerIn: parent
                            spacing: 6
                            Rectangle {
                                anchors.verticalCenter: parent.verticalCenter
                                width: 7; height: 7; radius: 4
                                color: root.criticalCount ? root.warningColor
                                                         : (root.cautionCount ? root.cautionColor : root.safeColor)
                            }
                            Text {
                                text: root.criticalCount ? root.criticalCount + " " + qsTr("warning")
                                     : (root.cautionCount ? root.cautionCount + " " + qsTr("caution")
                                        : qsTr("Airspace clear"))
                                color: "white"
                                font.bold: true
                                font.pixelSize: 11
                            }
                        }
                    }
                    Rectangle {
                        width: 32; height: 32; radius: 5
                        color: closeArea.pressed ? "#314253" : "#1c2732"
                        Text {
                            anchors.centerIn: parent
                            text: "\uf00d"
                            color: "white"
                            font.family: "Font Awesome 5 Free"
                            font.pixelSize: 14
                        }
                        MouseArea {
                            id: closeArea
                            anchors.fill: parent
                            onClicked: root.widgetAction.close()
                        }
                    }
                }

                Rectangle { Layout.fillWidth: true; height: 1; color: root.lineColor }

                RowLayout {
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    spacing: 10

                    Rectangle {
                        Layout.preferredWidth: Math.max(280, parent.width * 0.38)
                        Layout.fillHeight: true
                        radius: 7
                        color: root.panelRaisedColor
                        border.color: root.lineColor

                        Item {
                            id: radar
                            anchors.fill: parent
                            anchors.margins: 16
                            clip: true
                            property real radiusPx: Math.min(width, height) * 0.43

                            Repeater {
                                model: 4
                                Rectangle {
                                    width: radar.radiusPx * 2 * (index + 1) / 4
                                    height: width
                                    radius: width / 2
                                    anchors.centerIn: parent
                                    color: "transparent"
                                    border.width: 1
                                    border.color: index === 3 ? "#506579" : "#2c3c4b"
                                }
                            }
                            Rectangle {
                                anchors.centerIn: parent
                                width: radar.radiusPx * 2; height: 1
                                color: "#2c3c4b"
                            }
                            Rectangle {
                                anchors.centerIn: parent
                                width: 1; height: radar.radiusPx * 2
                                color: "#2c3c4b"
                            }
                            Text {
                                anchors.horizontalCenter: parent.horizontalCenter
                                anchors.top: parent.top
                                text: qsTr("HDG") + " " + Math.round(_fcMavlinkSystem.hdg) + " deg"
                                color: root.mutedColor
                                font.bold: true
                                font.pixelSize: 10
                            }
                            Text {
                                anchors.right: parent.right
                                anchors.bottom: parent.bottom
                                text: root.radarRangeKm + " km"
                                color: root.mutedColor
                                font.pixelSize: 10
                            }

                            Repeater {
                                model: root.displayedAircraft
                                Item {
                                    readonly property real angle: root.relativeBearing(modelData)
                                    readonly property real distanceRatio: root.usableDistance(modelData)
                                                                         ? Math.min(1, modelData.distance / root.radarRangeKm) : 1
                                    readonly property real radians: (angle - 90) * Math.PI / 180
                                    width: 28; height: 28
                                    x: radar.width / 2 + Math.cos(radians) * radar.radiusPx * distanceRatio - width / 2
                                    y: radar.height / 2 + Math.sin(radians) * radar.radiusPx * distanceRatio - height / 2
                                    visible: root.validNumber(angle) && root.usableDistance(modelData)

                                    Rectangle {
                                        anchors.centerIn: parent
                                        width: 22; height: 22; radius: 11
                                        color: modelData === root.selectedAircraft ? root.aircraftColor(modelData) : "#d9141d27"
                                        border.width: 2
                                        border.color: root.aircraftColor(modelData)
                                    }
                                    Text {
                                        anchors.centerIn: parent
                                        text: "\uf072"
                                        color: modelData === root.selectedAircraft ? "#101820" : root.aircraftColor(modelData)
                                        font.family: "Font Awesome 5 Free"
                                        font.pixelSize: 10
                                        rotation: root.validNumber(modelData.heading)
                                                  ? modelData.heading - _fcMavlinkSystem.hdg : 0
                                    }
                                    MouseArea {
                                        anchors.fill: parent
                                        onClicked: root.selectedAircraft = modelData
                                    }
                                }
                            }

                            Rectangle {
                                anchors.centerIn: parent
                                width: 28; height: 28; radius: 14
                                color: "#168bd2"
                                border.color: "white"
                                border.width: 2
                                Text {
                                    anchors.centerIn: parent
                                    text: "\uf072"
                                    color: "white"
                                    font.family: "Font Awesome 5 Free"
                                    font.pixelSize: 12
                                    rotation: -45
                                }
                            }

                            Row {
                                anchors.left: parent.left
                                anchors.bottom: parent.bottom
                                spacing: 5
                                Repeater {
                                    model: [5, 10, 25, 50]
                                    Rectangle {
                                        width: 34; height: 24; radius: 4
                                        color: root.radarRangeKm === modelData ? "#168bd2" : "#24313e"
                                        Text {
                                            anchors.centerIn: parent
                                            text: modelData
                                            color: "white"
                                            font.pixelSize: 10
                                            font.bold: root.radarRangeKm === modelData
                                        }
                                        MouseArea {
                                            anchors.fill: parent
                                            onClicked: root.radarRangeKm = modelData
                                        }
                                    }
                                }
                            }
                        }
                    }

                    Rectangle {
                        Layout.preferredWidth: Math.max(250, parent.width * 0.31)
                        Layout.fillHeight: true
                        radius: 7
                        color: root.panelRaisedColor
                        border.color: root.lineColor

                        ColumnLayout {
                            anchors.fill: parent
                            anchors.margins: 9
                            spacing: 6
                            RowLayout {
                                Layout.fillWidth: true
                                Text {
                                    Layout.fillWidth: true
                                    text: qsTr("TRAFFIC")
                                    color: "white"
                                    font.bold: true
                                    font.pixelSize: 12
                                }
                                Text {
                                    text: root.displayedAircraft.length
                                    color: root.mutedColor
                                    font.pixelSize: 11
                                }
                            }
                            Rectangle { Layout.fillWidth: true; height: 1; color: root.lineColor }
                            ListView {
                                id: trafficList
                                Layout.fillWidth: true
                                Layout.fillHeight: true
                                clip: true
                                spacing: 4
                                model: root.displayedAircraft
                                delegate: Rectangle {
                                    width: trafficList.width
                                    height: 56
                                    radius: 5
                                    color: modelData === root.selectedAircraft ? "#2b3c4c" : "transparent"
                                    border.width: modelData === root.selectedAircraft ? 1 : 0
                                    border.color: root.aircraftColor(modelData)

                                    Rectangle {
                                        width: 4; radius: 2
                                        anchors.left: parent.left
                                        anchors.top: parent.top
                                        anchors.bottom: parent.bottom
                                        color: root.aircraftColor(modelData)
                                    }
                                    Column {
                                        anchors.left: parent.left
                                        anchors.leftMargin: 12
                                        anchors.verticalCenter: parent.verticalCenter
                                        width: parent.width - 82
                                        spacing: 3
                                        Text {
                                            width: parent.width
                                            text: root.aircraftName(modelData)
                                            color: "white"
                                            font.bold: true
                                            font.pixelSize: 12
                                            elide: Text.ElideRight
                                        }
                                        Text {
                                            text: root.formatAltitudeDelta(modelData) + "  |  "
                                                  + root.formatSpeed(modelData.velocity)
                                            color: root.mutedColor
                                            font.pixelSize: 10
                                        }
                                    }
                                    Text {
                                        anchors.right: parent.right
                                        anchors.rightMargin: 8
                                        anchors.verticalCenter: parent.verticalCenter
                                        text: root.formatDistance(modelData)
                                        color: root.aircraftColor(modelData)
                                        font.bold: true
                                        font.pixelSize: 11
                                    }
                                    MouseArea {
                                        anchors.fill: parent
                                        onClicked: root.selectedAircraft = modelData
                                    }
                                }
                                Text {
                                    visible: trafficList.count === 0
                                    anchors.centerIn: parent
                                    text: qsTr("No aircraft in range")
                                    color: root.mutedColor
                                    font.pixelSize: 12
                                }
                            }
                        }
                    }

                    Rectangle {
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        radius: 7
                        color: root.panelRaisedColor
                        border.color: root.lineColor

                        ColumnLayout {
                            anchors.fill: parent
                            anchors.margins: 12
                            spacing: 8
                            Text {
                                text: qsTr("AIRCRAFT DETAILS")
                                color: "white"
                                font.bold: true
                                font.pixelSize: 12
                            }
                            Rectangle { Layout.fillWidth: true; height: 1; color: root.lineColor }
                            Text {
                                Layout.fillWidth: true
                                text: root.aircraftName(root.selectedAircraft)
                                color: root.aircraftColor(root.selectedAircraft)
                                font.bold: true
                                font.pixelSize: 20
                                elide: Text.ElideRight
                            }
                            Text {
                                text: root.selectedAircraft
                                      ? "ICAO  " + root.hexAddress(root.selectedAircraft.icaoAddress) : "ICAO  ------"
                                color: root.mutedColor
                                font.pixelSize: 11
                            }

                            GridLayout {
                                Layout.fillWidth: true
                                columns: 2
                                columnSpacing: 12
                                rowSpacing: 10

                                DetailValue { title: qsTr("DISTANCE"); value: root.formatDistance(root.selectedAircraft) }
                                DetailValue { title: qsTr("REL. ALTITUDE"); value: root.formatAltitudeDelta(root.selectedAircraft) }
                                DetailValue { title: qsTr("ALTITUDE"); value: root.selectedAircraft ? root.formatAltitude(root.selectedAircraft.altitude) : qsTr("--") }
                                DetailValue { title: qsTr("GROUND SPEED"); value: root.selectedAircraft ? root.formatSpeed(root.selectedAircraft.velocity) : qsTr("--") }
                                DetailValue { title: qsTr("HEADING"); value: root.selectedAircraft && root.validNumber(root.selectedAircraft.heading) ? Math.round(root.selectedAircraft.heading) + " deg" : qsTr("--") }
                                DetailValue { title: qsTr("VERTICAL SPEED"); value: root.selectedAircraft ? root.formatVerticalSpeed(root.selectedAircraft.verticalVel) : qsTr("--") }
                                DetailValue { title: qsTr("LAST SEEN"); value: root.selectedAircraft && root.validNumber(root.selectedAircraft.lastContact) ? root.selectedAircraft.lastContact + " s" : qsTr("--") }
                                DetailValue { title: qsTr("SIGNAL"); value: root.selectedAircraft && root.usableRssi(root.selectedAircraft) ? root.selectedAircraft.rssi.toFixed(1) + " dBFS" : qsTr("--") }
                                }
                            Item { Layout.fillHeight: true }
                            Rectangle {
                                Layout.fillWidth: true
                                height: 38
                                radius: 5
                                color: root.selectedAircraft
                                       ? (root.threatLevel(root.selectedAircraft) === 2 ? "#35ff4d5e"
                                          : (root.threatLevel(root.selectedAircraft) === 1 ? "#35ffb020" : "#2436d17c"))
                                       : "#202b35"
                                Text {
                                    anchors.centerIn: parent
                                    text: !root.selectedAircraft ? qsTr("NO TARGET SELECTED")
                                          : (root.threatLevel(root.selectedAircraft) === 2 ? qsTr("TRAFFIC WARNING")
                                             : (root.threatLevel(root.selectedAircraft) === 1
                                                ? qsTr("TRAFFIC CAUTION") : qsTr("NO CONFLICT DETECTED")))
                                    color: root.selectedAircraft ? root.aircraftColor(root.selectedAircraft) : root.mutedColor
                                    font.bold: true
                                    font.pixelSize: 11
                                }
                            }
                        }
                    }
                }
            }
    }

    component DetailValue: ColumnLayout {
        property string title
        property string value
        Layout.fillWidth: true
        spacing: 1
        Text { text: parent.title; color: root.mutedColor; font.pixelSize: 9 }
        Text { text: parent.value; color: "white"; font.bold: true; font.pixelSize: 13 }
    }
}
