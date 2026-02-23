import QtQuick 2.12
import QtQuick.Controls 2.12
import QtQuick.Layouts 1.12
import QtQuick.Shapes 1.12

import OpenHD 1.0

BaseWidget {
    id: linkOverviewWidgetBottom
    width: parent.width
    height: 40

    visible: settings.show_link_overview_widget
        && settings.show_link_overview_widget_bottom
        && settings.show_widgets

    widgetIdentifier: "link_overview_widget_bottom"
    bw_verbose_name: qsTr("LINK OVERVIEW BOTTOM")

    defaultAlignment: 3
    defaultXOffset: 0
    defaultYOffset: 0
    defaultHCenter: true
    defaultVCenter: false

    hasWidgetDetail: true
    disable_dragging: false

    property string linkFont: "Quicksand"
    property string linkMonoFont: "ShareTechMono"
    property real notchWidth: 140
    property real notchDepth: 8
    property real notchSlope: 14
    property real sidePadding: 6
    property real notchSafeWidth: notchWidth + (notchSlope * 2)
    property real slotContentYOffset: 4
    property bool hide_na: true
    property string slot1Selection: "gnd_voltage"
    property string slot2Selection: "gnd_mah"
    property string slot3Selection: "air_voltage"
    property string slot4Selection: "air_current"
    property string slot5Selection: "air_speed"
    property string slot6Selection: "home_distance"
    property string slot7Selection: "satellites"
    property string slot8Selection: "none"
    property var slotLabels: [
        qsTr("Left 1"),
        qsTr("Left 2"),
        qsTr("Left 3"),
        qsTr("Left 4"),
        qsTr("Right 1"),
        qsTr("Right 2"),
        qsTr("Right 3"),
        qsTr("Right 4")
    ]
    property var slotOptions: [
        { label: qsTr("Ground Voltage"), value: "gnd_voltage" },
        { label: qsTr("Ground mAh"), value: "gnd_mah" },
        { label: qsTr("Air Voltage"), value: "air_voltage" },
        { label: qsTr("Air Current"), value: "air_current" },
        { label: qsTr("Air Speed"), value: "air_speed" },
        { label: qsTr("Altitude"), value: "altitude" },
        { label: qsTr("Home Distance"), value: "home_distance" },
        { label: qsTr("Satellites"), value: "satellites" },
        { label: qsTr("None"), value: "none" }
    ]
    property int slot_update_tick: 0

    Component.onCompleted: {
        bw_set_current_scale(1.0);
        bw_set_current_opacity(settings.value("link_overview_widget_opacity", 1.0));
        hide_na = setting_to_bool(settings.value("link_overview_widget_bottom_hide_na", true), true);
        slot1Selection = settings.value("link_overview_widget_bottom_slot_1", slot1Selection);
        slot2Selection = settings.value("link_overview_widget_bottom_slot_2", slot2Selection);
        slot3Selection = settings.value("link_overview_widget_bottom_slot_3", slot3Selection);
        slot4Selection = settings.value("link_overview_widget_bottom_slot_4", slot4Selection);
        slot5Selection = settings.value("link_overview_widget_bottom_slot_5", slot5Selection);
        slot6Selection = settings.value("link_overview_widget_bottom_slot_6", slot6Selection);
        slot7Selection = settings.value("link_overview_widget_bottom_slot_7", slot7Selection);
        slot8Selection = settings.value("link_overview_widget_bottom_slot_8", slot8Selection);
        normalize_slot_selections();
        slot_update_tick++;
        loadAlignment();
    }

    onHide_naChanged: {
        settings.setValue("link_overview_widget_bottom_hide_na", hide_na);
        settings.sync();
    }
    onSlot1SelectionChanged: save_slot_setting(1, slot1Selection)
    onSlot2SelectionChanged: save_slot_setting(2, slot2Selection)
    onSlot3SelectionChanged: save_slot_setting(3, slot3Selection)
    onSlot4SelectionChanged: save_slot_setting(4, slot4Selection)
    onSlot5SelectionChanged: save_slot_setting(5, slot5Selection)
    onSlot6SelectionChanged: save_slot_setting(6, slot6Selection)
    onSlot7SelectionChanged: save_slot_setting(7, slot7Selection)
    onSlot8SelectionChanged: save_slot_setting(8, slot8Selection)

    Connections {
        target: widgetDetail
        function onAboutToHide() {
            apply_slot_settings();
        }
    }

    function setting_to_bool(value, fallback) {
        if (value === true || value === 1 || value === "true") {
            return true;
        }
        if (value === false || value === 0 || value === "false") {
            return false;
        }
        return fallback;
    }

    function save_slot_setting(index, value) {
        settings.setValue("link_overview_widget_bottom_slot_" + index, value);
        settings.sync();
    }

    function apply_slot_settings() {
        normalize_slot_selections();
        save_slot_setting(1, slot1Selection);
        save_slot_setting(2, slot2Selection);
        save_slot_setting(3, slot3Selection);
        save_slot_setting(4, slot4Selection);
        save_slot_setting(5, slot5Selection);
        save_slot_setting(6, slot6Selection);
        save_slot_setting(7, slot7Selection);
        save_slot_setting(8, slot8Selection);
        slot_update_tick++;
    }

    function normalize_slot_selections() {
        var used = {};
        for (var i = 1; i <= 8; i++) {
            var value = get_slot_selection(i);
            if (value === "none") {
                continue;
            }
            if (used[value]) {
                set_slot_selection(i, "none");
            } else {
                used[value] = true;
            }
        }
    }

    function get_slot_selection(index) {
        if (index === 1) return slot1Selection;
        if (index === 2) return slot2Selection;
        if (index === 3) return slot3Selection;
        if (index === 4) return slot4Selection;
        if (index === 5) return slot5Selection;
        if (index === 6) return slot6Selection;
        if (index === 7) return slot7Selection;
        if (index === 8) return slot8Selection;
        return "none";
    }

    function set_slot_selection(index, value) {
        if (index === 1) slot1Selection = value;
        else if (index === 2) slot2Selection = value;
        else if (index === 3) slot3Selection = value;
        else if (index === 4) slot4Selection = value;
        else if (index === 5) slot5Selection = value;
        else if (index === 6) slot6Selection = value;
        else if (index === 7) slot7Selection = value;
        else if (index === 8) slot8Selection = value;
    }

    function find_slot_using(value, excludeIndex) {
        if (value === "none") {
            return -1;
        }
        for (var i = 1; i <= 8; i++) {
            if (i === excludeIndex) {
                continue;
            }
            if (get_slot_selection(i) === value) {
                return i;
            }
        }
        return -1;
    }

    function request_slot_selection(index, value) {
        if (value === get_slot_selection(index)) {
            return;
        }
        var otherIndex = find_slot_using(value, index);
        if (otherIndex > 0) {
            var currentValue = get_slot_selection(index);
            set_slot_selection(otherIndex, currentValue);
        }
        set_slot_selection(index, value);
        slot_update_tick++;
    }

    function slot_index_for_value(value) {
        for (var i = 0; i < slotOptions.length; i++) {
            if (slotOptions[i].value === value) {
                return i;
            }
        }
        return 0;
    }

    function slot_text(selection) {
        var _ = slot_update_tick;
        if (selection === "gnd_voltage") {
            return format_gnd_voltage();
        } else if (selection === "gnd_mah") {
            return format_gnd_mah();
        } else if (selection === "air_voltage") {
            return format_air_voltage();
        } else if (selection === "air_current") {
            return format_air_current();
        } else if (selection === "air_speed") {
            return format_air_speed();
        } else if (selection === "altitude") {
            return format_nav_alt();
        } else if (selection === "home_distance") {
            return format_home_distance();
        } else if (selection === "satellites") {
            return format_nav_sats();
        }
        return "";
    }

    function slot_icon(selection) {
        var _ = slot_update_tick;
        if (selection === "gnd_voltage") {
            return "\uf0ac";
        } else if (selection === "gnd_mah") {
            return "\uf240";
        } else if (selection === "air_voltage") {
            return "\uf072";
        } else if (selection === "air_current") {
            return "\uf0e7";
        } else if (selection === "air_speed") {
            return "\uf3fd";
        } else if (selection === "altitude") {
            return "\uf062";
        } else if (selection === "home_distance") {
            return "\uf015";
        } else if (selection === "satellites") {
            return "\uf7bf";
        }
        return "";
    }

    function slot_is_valid(selection) {
        var text = slot_text(selection);
        return text !== "" && text !== "N/A";
    }

    function slot_visible(selection) {
        if (selection === "none") {
            return false;
        }
        if (!hide_na) {
            return true;
        }
        return slot_is_valid(selection);
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

    function flight_mode_display_text() {
        var mode = format_flight_mode();
        if (mode === "" || mode === "N/A") {
            return qsTr("Manual");
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

    widgetDetailComponent: ScrollView {
        contentHeight: detailColumn.height
        ScrollBar.horizontal.policy: ScrollBar.AlwaysOff
        clip: true

        Column {
            id: detailColumn
            width: parent.width
            spacing: 4

            BaseWidgetDefaultUiControlElements {
                id: idBaseWidgetDefaultUiControlElements
                show_transparency: false
                show_background_color: true
                background_color_target: linkOverviewWidgetBottom
            }

            Item {
                width: parent.width
                height: 32
                Text {
                    text: qsTr("Hide N/A")
                    color: "white"
                    height: parent.height
                    font.bold: true
                    font.pixelSize: detailPanelFontPixels
                    anchors.left: parent.left
                    verticalAlignment: Text.AlignVCenter
                }
                Switch {
                    width: 32
                    height: parent.height
                    anchors.rightMargin: 6
                    anchors.right: parent.right
                    checked: hide_na
                    onCheckedChanged: hide_na = checked
                }
            }

            Repeater {
                model: slotLabels.length
                delegate: Item {
                    width: parent.width
                    height: 32
                    property int slotIndex: index + 1
                    Text {
                        text: slotLabels[index]
                        color: "white"
                        height: parent.height
                        font.bold: true
                        font.pixelSize: detailPanelFontPixels
                        anchors.left: parent.left
                        verticalAlignment: Text.AlignVCenter
                    }
                    ComboBox {
                        id: slotCombo
                        model: slotOptions
                        textRole: "label"
                        currentIndex: slot_index_for_value(get_slot_selection(slotIndex))
                        anchors.right: parent.right
                        anchors.rightMargin: 6
                        anchors.top: parent.top
                        anchors.topMargin: 4
                        width: 160
                        height: parent.height - 4
                        onActivated: {
                            if (index < 0 || index >= slotOptions.length) {
                                return;
                            }
                            request_slot_selection(slotIndex, slotOptions[index].value);
                        }
                    }
                }
            }
        }
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
            opacity: 0.5
            property color fillColor: bw_current_background_color
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

        Item {
            id: contentArea
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.bottom: parent.bottom
            anchors.top: parent.top
            anchors.topMargin: notchDepth
        }

        Text {
            id: flightModeText
            text: flight_mode_display_text()
            anchors.horizontalCenter: parent.horizontalCenter
            anchors.top: parent.top
            anchors.topMargin: 1
            color: settings.color_text
            font.pixelSize: 16
            font.family: linkFont
            font.bold: _fcMavlinkSystem.is_alive && _fcMavlinkSystem.armed
            font.strikeout: _fcMavlinkSystem.is_alive && !_fcMavlinkSystem.armed
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
            id: leftArea
            anchors.left: contentArea.left
            anchors.right: contentArea.horizontalCenter
            anchors.rightMargin: notchSafeWidth / 2
            anchors.bottom: contentArea.bottom
            anchors.top: contentArea.top
            anchors.leftMargin: 20

            RowLayout {
                anchors.fill: parent
                anchors.bottomMargin: 4
                spacing: 12
                Repeater {
                    model: [1, 2, 3, 4]
                    delegate: Item {
                        Layout.fillWidth: true
                        Layout.minimumWidth: 0
                        visible: slot_visible(get_slot_selection(modelData))
                        Row {
                            spacing: 6
                            anchors.horizontalCenter: parent.horizontalCenter
                            anchors.verticalCenter: parent.verticalCenter
                            anchors.verticalCenterOffset: slotContentYOffset
                            Text {
                                visible: slot_icon(get_slot_selection(modelData)) !== ""
                                text: slot_icon(get_slot_selection(modelData))
                                color: settings.color_shape
                                font.pixelSize: 16
                                font.family: "Font Awesome 5 Free"
                                style: Text.Outline
                                styleColor: settings.color_glow
                            }
                            Text {
                                text: slot_text(get_slot_selection(modelData))
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

        Item {
            id: rightArea
            anchors.left: contentArea.horizontalCenter
            anchors.leftMargin: notchSafeWidth / 2
            anchors.right: contentArea.right
            anchors.bottom: contentArea.bottom
            anchors.top: contentArea.top
            anchors.rightMargin: 20

            RowLayout {
                anchors.fill: parent
                anchors.bottomMargin: 4
                spacing: 12
                layoutDirection: Qt.RightToLeft
                Repeater {
                    model: [5, 6, 7, 8]
                    delegate: Item {
                        Layout.fillWidth: true
                        Layout.minimumWidth: 0
                        visible: slot_visible(get_slot_selection(modelData))
                        Row {
                            spacing: 6
                            anchors.horizontalCenter: parent.horizontalCenter
                            anchors.verticalCenter: parent.verticalCenter
                            anchors.verticalCenterOffset: slotContentYOffset
                            layoutDirection: Qt.RightToLeft
                            Text {
                                visible: slot_icon(get_slot_selection(modelData)) !== ""
                                text: slot_icon(get_slot_selection(modelData))
                                color: settings.color_shape
                                font.pixelSize: 16
                                font.family: "Font Awesome 5 Free"
                                style: Text.Outline
                                styleColor: settings.color_glow
                            }
                            Text {
                                text: slot_text(get_slot_selection(modelData))
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
    }
}
