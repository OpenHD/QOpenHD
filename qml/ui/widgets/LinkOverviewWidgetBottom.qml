import QtQuick 2.12
import QtQuick.Controls 2.12
import QtQuick.Layouts 1.12
import QtQuick.Shapes 1.12

import OpenHD 1.0

BaseWidget {
    id: linkOverviewWidgetBottom
    width: parent.width
    height: 40

    visible: settings.show_link_overview_widget && settings.show_widgets

    widgetIdentifier: "link_overview_widget_bottom"
    bw_verbose_name: qsTr("LINK OVERVIEW BOTTOM")

    defaultAlignment: 3
    defaultXOffset: 0
    defaultYOffset: 0
    defaultHCenter: true
    defaultVCenter: false

    hasWidgetDetail: false
    disable_dragging: false

    property string linkFont: "Quicksand"
    property string linkMonoFont: "ShareTechMono"
    property real notchWidth: 140
    property real notchDepth: 8
    property real notchSlope: 14
    property real sidePadding: 6

    Component.onCompleted: {
        bw_set_current_scale(1.0);
        bw_set_current_opacity(settings.value("link_overview_widget_opacity", 1.0));
        settings.setValue(alignmentIdentifier, 3);
        settings.setValue(xOffsetIdentifier, 0);
        settings.setValue(yOffsetIdentifier, 0);
        settings.setValue(hCenterIdentifier, true);
        settings.setValue(vCenterIdentifier, false);
        settings.sync();
        loadAlignment();
    }

    function format_air_voltage() {
        var v = _fcMavlinkSystem.battery_voltage_volt;
        if (!_fcMavlinkSystem.is_alive || v <= 0) {
            return "N/A";
        }
        return Number(v).toLocaleString(Qt.locale(), 'f', 1) + "V";
    }

    function format_air_current() {
        var a = _fcMavlinkSystem.battery_current_ampere;
        if (!_fcMavlinkSystem.is_alive) {
            return "N/A";
        }
        return Number(a).toLocaleString(Qt.locale(), 'f', 1) + "A";
    }

    function format_air_mah() {
        var mah = _fcMavlinkSystem.battery_consumed_mah;
        if (!_fcMavlinkSystem.is_alive || mah <= 0) {
            return "N/A";
        }
        return Number(mah).toLocaleString(Qt.locale(), 'f', 0) + "mAh";
    }

    function format_nav_sats() {
        var sats = _fcMavlinkSystem.satellites_visible;
        if (!_fcMavlinkSystem.is_alive || sats <= 0) {
            return "N/A";
        }
        return "" + sats;
    }

    function format_nav_alt() {
        var alt = _fcMavlinkSystem.altitude_rel_m;
        if (!_fcMavlinkSystem.is_alive) {
            return "N/A";
        }
        return Math.round(alt) + "m";
    }

    function format_nav_time() {
        var t = _fcMavlinkSystem.flight_time;
        if (!_fcMavlinkSystem.is_alive || t === "") {
            return "N/A";
        }
        return t;
    }

    function format_flight_mode() {
        var mode = _fcMavlinkSystem.flight_mode;
        if (!_fcMavlinkSystem.is_alive || mode === "") {
            return "N/A";
        }
        return mode;
    }

    function pad2(value) {
        var str = "" + value;
        if (str.length < 2) {
            str = "0" + str;
        }
        return str;
    }

    function seconds_to_mmss(seconds) {
        var total = Math.max(0, Math.floor(seconds));
        var m = Math.floor(total / 60);
        var s = total % 60;
        return pad2(m) + ":" + pad2(s);
    }

    function format_flight_time_short() {
        var t = _fcMavlinkSystem.flight_time;
        if (!_fcMavlinkSystem.is_alive || t === "") {
            return "00:00";
        }
        if (typeof t === "string") {
            if (t.indexOf(":") !== -1) {
                var parts = t.split(":");
                if (parts.length >= 2) {
                    var mPart = parts.length === 2 ? parts[0] : parts[parts.length - 2];
                    var sPart = parts[parts.length - 1];
                    return pad2(mPart) + ":" + pad2(sPart);
                }
            }
            var asNum = parseInt(t);
            if (!isNaN(asNum)) {
                return seconds_to_mmss(asNum);
            }
        } else if (typeof t === "number") {
            return seconds_to_mmss(t);
        }
        return "00:00";
    }

    function format_home_distance() {
        if (!_fcMavlinkSystem.is_alive) {
            return "N/A";
        }
        var distance = _fcMavlinkSystem.home_distance;
        var unit = "m";
        var use_imperial = settings.value("enable_imperial", false);
        if (use_imperial === true || use_imperial === 1 || use_imperial === "true") {
            unit = "ft";
            distance = distance * 3.28084;
        }
        return Number(distance).toLocaleString(Qt.locale(), "f", 1) + unit;
    }

    function format_air_speed() {
        if (!_fcMavlinkSystem.is_alive) {
            return "N/A";
        }
        var speed_mps = _fcMavlinkSystem.air_speed_meter_per_second;
        if (speed_mps < 0) {
            return "N/A";
        }
        var speed = speed_mps;
        var unit = " m/s";
        if (settings.enable_imperial) {
            speed = speed_mps * 2.23694;
            unit = " mph";
        } else if (settings.speed_ladder_use_kmh) {
            speed = speed_mps * 3.6;
            unit = " kph";
        }
        var text = Number(speed).toLocaleString(Qt.locale(), "f", 0);
        if (settings.speed_ladder_show_unit && speed < 99) {
            text += unit;
        }
        return text;
    }

    function format_gnd_voltage() {
        var mv = _ohdSystemGround.ina219_voltage_millivolt;
        if (mv <= 0) {
            return "N/A";
        }
        return Number(mv / 1000.0).toLocaleString(Qt.locale(), 'f', 1) + "V";
    }

    function format_gnd_current() {
        var ma = _ohdSystemGround.ina219_current_milliamps;
        if (ma <= 0) {
            return "N/A";
        }
        return Number(ma / 1000.0).toLocaleString(Qt.locale(), 'f', 1) + "A";
    }

    function format_gnd_mah() {
        return "N/A";
    }

    function format_gnd_rssi() {
        var rssi = _ohdSystemGround.current_rx_signal_quality;
        if (rssi < 0) {
            return "N/A";
        }
        return rssi + "%";
    }

    Item {
        id: widgetInner
        anchors.fill: parent
        opacity: bw_current_opacity
        scale: Math.min(1.0, bw_current_scale)
        clip: false

        Shape {
            id: baseShape
            anchors.fill: parent
            property color fillColor: Qt.rgba(0, 0, 0, 0.5)
            property real topY: notchDepth
            property real notchStartX: (width - notchWidth) / 2
            property real notchEndX: notchStartX + notchWidth
            property real notchLeft: Math.max(sidePadding, notchStartX - notchSlope)
            property real notchRight: Math.min(width - sidePadding, notchEndX + notchSlope)

            ShapePath {
                strokeWidth: 0
                strokeColor: "transparent"
                fillColor: baseShape.fillColor
                startX: 0
                startY: baseShape.topY
                PathLine { x: baseShape.notchLeft; y: baseShape.topY }
                PathLine { x: baseShape.notchStartX; y: 0 }
                PathLine { x: baseShape.notchEndX; y: 0 }
                PathLine { x: baseShape.notchRight; y: baseShape.topY }
                PathLine { x: width; y: baseShape.topY }
                PathLine { x: width; y: height }
                PathLine { x: 0; y: height }
                PathLine { x: 0; y: baseShape.topY }
            }
        }

        Text {
            id: flightModeText
            text: format_flight_mode()
            anchors.horizontalCenter: parent.horizontalCenter
            anchors.top: parent.top
            anchors.topMargin: 1
            color: settings.color_text
            font.pixelSize: 16
            font.family: linkFont
            style: Text.Outline
            styleColor: settings.color_glow
        }

        Text {
            text: format_flight_time_short()
            anchors.horizontalCenter: parent.horizontalCenter
            anchors.top: flightModeText.bottom
            anchors.topMargin: -2
            color: settings.color_text
            font.pixelSize: 16
            font.family: linkMonoFont
            style: Text.Outline
            styleColor: settings.color_glow
        }

        Item {
            id: contentArea
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.bottom: parent.bottom
            anchors.top: parent.top
            anchors.topMargin: notchDepth
        }

        RowLayout {
            id: mainRow
            anchors.left: contentArea.left
            anchors.right: contentArea.right
            anchors.top: contentArea.top
            anchors.bottom: contentArea.bottom
            anchors.leftMargin: 20
            anchors.rightMargin: 20
            spacing: 12

            Item {
                Layout.fillWidth: true
                Layout.preferredWidth: parent.width * 0.66
                Row {
                    spacing: 16
                    anchors.left: parent.left
                    anchors.verticalCenter: parent.verticalCenter
                    anchors.verticalCenterOffset: 4
                    Text {
                        text: "\uf0ac"
                        color: settings.color_shape
                        font.pixelSize: 16
                        font.family: "Font Awesome 5 Free"
                        style: Text.Outline
                        styleColor: settings.color_glow
                    }
                    Text {
                        text: format_gnd_voltage()
                        color: settings.color_text
                        font.pixelSize: 16
                        font.family: linkFont
                        style: Text.Outline
                        styleColor: settings.color_glow
                    }
                    Text {
                        text: format_gnd_mah()
                        color: settings.color_text
                        font.pixelSize: 16
                        font.family: linkFont
                        style: Text.Outline
                        styleColor: settings.color_glow
                    }
                    Text {
                        text: "\uf072"
                        color: settings.color_shape
                        font.pixelSize: 16
                        font.family: "Font Awesome 5 Free"
                        style: Text.Outline
                        styleColor: settings.color_glow
                    }
                    Text {
                        text: format_air_voltage()
                        color: settings.color_text
                        font.pixelSize: 16
                        font.family: linkFont
                        style: Text.Outline
                        styleColor: settings.color_glow
                    }
                    Text {
                        text: format_air_current()
                        color: settings.color_text
                        font.pixelSize: 16
                        font.family: linkFont
                        style: Text.Outline
                        styleColor: settings.color_glow
                    }
                }
            }

            Item {
                Layout.fillWidth: true
                Layout.preferredWidth: parent.width * 0.34
                Row {
                    spacing: 16
                    anchors.right: parent.right
                    anchors.verticalCenter: parent.verticalCenter
                    anchors.verticalCenterOffset: 4
                    layoutDirection: Qt.RightToLeft
                    Text {
                        text: "\uf3fd"
                        color: settings.color_shape
                        font.pixelSize: 16
                        font.family: "Font Awesome 5 Free"
                        style: Text.Outline
                        styleColor: settings.color_glow
                    }
                    Text {
                        text: format_air_speed()
                        color: settings.color_text
                        font.pixelSize: 16
                        font.family: linkFont
                        style: Text.Outline
                        styleColor: settings.color_glow
                    }
                    Text {
                        text: "\uf015"
                        color: settings.color_shape
                        font.pixelSize: 16
                        font.family: "Font Awesome 5 Free"
                        style: Text.Outline
                        styleColor: settings.color_glow
                    }
                    Text {
                        text: format_home_distance()
                        color: settings.color_text
                        font.pixelSize: 16
                        font.family: linkFont
                        style: Text.Outline
                        styleColor: settings.color_glow
                    }
                    Text {
                        text: "\uf7bf"
                        color: settings.color_shape
                        font.pixelSize: 16
                        font.family: "Font Awesome 5 Free"
                        style: Text.Outline
                        styleColor: settings.color_glow
                    }
                    Text {
                        text: format_nav_sats()
                        color: settings.color_text
                        font.pixelSize: 16
                        font.family: linkFont
                        style: Text.Outline
                        styleColor: settings.color_glow
                    }
                }
            }
        }
    }
}
