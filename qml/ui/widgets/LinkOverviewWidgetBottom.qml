import QtQuick 2.12
import QtQuick.Controls 2.12
import QtQuick.Layouts 1.12
import QtQuick.Shapes 1.12
import QtQuick.Window 2.12

import OpenHD 1.0
import "../elements"

BaseWidget {
    id: linkOverviewWidgetBottom
    width: parent.width
    height: 40

    visible: settings.show_link_overview_widget
        && settings.show_link_overview_widget_bottom
        && settings.show_widgets

    widgetPreviewContent: widgetInner
    widgetIdentifier: "link_overview_widget_bottom"
    bw_verbose_name: qsTr("LINK OVERVIEW BOTTOM")

    defaultAlignment: 3
    defaultXOffset: 0
    defaultYOffset: 0
    defaultHCenter: true
    defaultVCenter: false
    widgetActionWidth: 320

    hasWidgetDetail: true
    widgetDetailWidth: Math.min(420, Window.window ? Window.window.width - 24 : 420)
    widgetDetailHeight: Math.min(560, Window.window ? Window.window.height - 24 : 560)
    hasWidgetAction: true
    disable_dragging: true
    spanParentWidth: true

    bw_scale_identifier: "link_overview_widget_scale"
    bw_background_color_identifier: "link_overview_widget_bg_color"
    bw_opacity_identifier: "link_overview_widget_opacity"

    property string linkFont: settings.osd_bottom_bar_font || "Quicksand"
    property string linkMonoFont: settings.osd_bottom_bar_font || "ShareTechMono"
    readonly property color barBackgroundColor: settings.osd_bottom_bar_background_color || bw_current_background_color
    readonly property color barTextColor: settings.osd_bottom_bar_text_color || settings.color_text
    readonly property color barShapeColor: settings.osd_bottom_bar_text_color || settings.color_shape
    property real notchWidth: 140
    property real notchDepth: 8
    property real notchSlope: 14
    property real sidePadding: 6
    property real notchSafeWidth: notchWidth + (notchSlope * 2)
    property real slotContentYOffset: 4
    property bool hide_na: true
    property bool flight_mode_long_press_handled: false
    property string m_ardupilot_mav_type: _fcMavlinkAction.ardupilot_mav_type
    property var flightModeOptions: [
        "RTL",
        "STABILIZE",
        "LOITER",
        "CIRCLE",
        "AUTO",
        "AUTOTUNE",
        "MANUAL",
        "FBWA",
        "FBWB",
        "QSTABILIZE",
        "QHOVER",
        "QLOITER",
        "QLAND",
        "QRTL",
        "ALT_HOLD",
        "POSHOLD",
        "ACRO",
        "GUIDED",
        "LAND",
        "SMART_RTL",
        "ZIGZAG",
        "AUTO_RTL",
        "CRUISE",
        "TAKEOFF"
    ]
    property string slot1Selection: "gnd_voltage"
    property string slot2Selection: "gnd_mah"
    property string slot3Selection: "air_voltage"
    property string slot4Selection: "air_current"
    property string slot5Selection: "air_speed"
    property string slot6Selection: "home_distance"
    property string slot7Selection: "none"
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
        // Keep the legacy value so existing saved bottom-bar layouts remain valid.
        { label: qsTr("Battery Percent"), value: "gas_percent" },
        { label: qsTr("Air Speed"), value: "air_speed" },
        { label: qsTr("GPS Speed"), value: "gps_speed" },
        { label: qsTr("Wind Speed & Direction"), value: "wind_speed" },
        { label: qsTr("Altitude"), value: "altitude" },
        { label: qsTr("Home Distance"), value: "home_distance" },
        { label: qsTr("None"), value: "none" }
    ]
    property int slot_update_tick: 0

    function sync_shared_style_from_settings() {
        if (bw_current_scale !== settings.link_overview_widget_scale) {
            bw_current_scale = settings.link_overview_widget_scale;
        }
        if (bw_current_opacity !== settings.link_overview_widget_opacity) {
            bw_current_opacity = settings.link_overview_widget_opacity;
        }
        if (bw_current_background_color !== settings.link_overview_widget_bg_color) {
            bw_current_background_color = settings.link_overview_widget_bg_color;
        }
    }

    function bw_set_current_scale(scale) {
        if (scale <= 0 || scale >= 500) {
            console.warn("perhaps invalid widget scale");
        }
        if (bw_current_scale !== scale) {
            bw_current_scale = scale;
        }
        if (settings.link_overview_widget_scale !== scale) {
            settings.link_overview_widget_scale = scale;
        }
    }

    function bw_set_current_opacity(opacity) {
        if (opacity <= 0 || opacity > 1) {
            console.warn("perhaps invalid widget opacity");
        }
        if (bw_current_opacity !== opacity) {
            bw_current_opacity = opacity;
        }
        if (settings.link_overview_widget_opacity !== opacity) {
            settings.link_overview_widget_opacity = opacity;
        }
    }

    Connections {
        target: settings
        function onLink_overview_widget_scaleChanged() {
            if (bw_current_scale !== settings.link_overview_widget_scale) {
                bw_current_scale = settings.link_overview_widget_scale;
            }
        }
        function onLink_overview_widget_opacityChanged() {
            if (bw_current_opacity !== settings.link_overview_widget_opacity) {
                bw_current_opacity = settings.link_overview_widget_opacity;
            }
        }
        function onLink_overview_widget_bg_colorChanged() {
            if (bw_current_background_color !== settings.link_overview_widget_bg_color) {
                bw_current_background_color = settings.link_overview_widget_bg_color;
            }
        }
    }

    Component.onCompleted: {
        sync_shared_style_from_settings();
        var savedGps = String(settings.value("gps_callout_last_position", "")).split(",")
        if (savedGps.length === 2 && savedGps[0].length && savedGps[1].length
                && validGpsCoordinates(Number(savedGps[0]), Number(savedGps[1])))
            lastGpsPosition = Qt.point(Number(savedGps[0]), Number(savedGps[1]))
        Qt.callLater(rememberGpsPosition)
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
            // Satellites now have a permanent place at the right edge.
            if (value === "satellites") {
                set_slot_selection(i, "none");
                continue;
            }
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

    function slot_label(selection) {
        for (var i = 0; i < slotOptions.length; i++) {
            if (slotOptions[i].value === selection) {
                return slotOptions[i].label;
            }
        }
        return selection;
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
        } else if (selection === "gas_percent") {
            return format_battery_percent();
        } else if (selection === "air_speed") {
            return format_air_speed();
        } else if (selection === "gps_speed") {
            return format_gps_speed();
        } else if (selection === "wind_speed") {
            return format_wind_speed();
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
        } else if (selection === "gas_percent") {
            return battery_percent_icon();
        } else if (selection === "air_speed") {
            return "\uf3fd";
        } else if (selection === "gps_speed") {
            return "\uf5a0";
        } else if (selection === "wind_speed") {
            return "\uf72e";
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
        var v = previewTelemetry("_fcMavlinkSystem", "battery_voltage_volt", _fcMavlinkSystem.battery_voltage_volt);
        if (!_fcMavlinkSystem.is_alive || v <= 0) {
            return "N/A";
        }
        return Number(v).toLocaleString(Qt.locale(), 'f', 1) + "V";
    }

    function format_air_current() {
        var a = previewTelemetry("_fcMavlinkSystem", "battery_current_ampere", _fcMavlinkSystem.battery_current_ampere);
        if (!_fcMavlinkSystem.is_alive) {
            return "N/A";
        }
        return Number(a).toLocaleString(Qt.locale(), 'f', 1) + "A";
    }

    function format_battery_percent() {
        if (!_fcMavlinkSystem.is_alive) {
            return "N/A";
        }
        var percent = previewTelemetry("_fcMavlinkSystem", "battery_percent", _fcMavlinkSystem.battery_percent);
        if (percent < 0 || percent > 100) {
            return "N/A";
        }
        return Math.round(percent) + "%";
    }

    function battery_percent_icon() {
        var percent = previewTelemetry("_fcMavlinkSystem", "battery_percent", _fcMavlinkSystem.battery_percent);
        if (!_fcMavlinkSystem.is_alive || percent < 0 || percent > 100) {
            return "\uf240";
        }
        if (percent <= 10) return "\uf244";
        if (percent <= 35) return "\uf243";
        if (percent <= 60) return "\uf242";
        if (percent <= 85) return "\uf241";
        return "\uf240";
    }

    function format_wind_speed() {
        if (!_fcMavlinkSystem.is_alive) {
            return "N/A";
        }
        var raw = settings.wind_plane_copter ? previewTelemetry("_fcMavlinkSystem", "wind_speed", _fcMavlinkSystem.wind_speed) : previewTelemetry("_fcMavlinkSystem", "mav_wind_speed", _fcMavlinkSystem.mav_wind_speed);
        var direction = settings.wind_plane_copter ? previewTelemetry("_fcMavlinkSystem", "wind_direction", _fcMavlinkSystem.wind_direction) : previewTelemetry("_fcMavlinkSystem", "mav_wind_direction", _fcMavlinkSystem.mav_wind_direction);
        if (raw < 0) {
            return "N/A";
        }
        var factor = 1.0;
        var unitLabel = "m/s";
        if (settings.wind_unit === "km/h") {
            factor = 3.6;
            unitLabel = "km/h";
        } else if (settings.wind_unit === "mph") {
            factor = 2.237;
            unitLabel = "mph";
        }
        direction = ((direction % 360) + 360) % 360;
        return Number(raw * factor).toLocaleString(Qt.locale(), "f", 0) + " " + unitLabel
            + " " + Math.round(direction) + "°";
    }

    function format_air_mah() {
        var mah = previewTelemetry("_fcMavlinkSystem", "battery_consumed_mah", _fcMavlinkSystem.battery_consumed_mah);
        if (!_fcMavlinkSystem.is_alive || mah <= 0) {
            return "N/A";
        }
        return Number(mah).toLocaleString(Qt.locale(), 'f', 0) + "mAh";
    }

    function format_nav_sats() {
        if (gpsPreviewActive) return "12"
        var sats = previewTelemetry("_fcMavlinkSystem", "satellites_visible", _fcMavlinkSystem.satellites_visible);
        if (!_fcMavlinkSystem.is_alive || sats < 0) {
            return "N/A";
        }
        return "" + sats;
    }

    function validGpsCoordinates(lat, lon) {
        return isFinite(lat) && isFinite(lon) && Math.abs(lat) <= 90 && Math.abs(lon) <= 180
            && (lat !== 0 || lon !== 0)
    }
    readonly property bool gpsPositionAvailable: _fcMavlinkSystem.is_alive
        && _fcMavlinkSystem.gps_fix_type >= 2
        && validGpsCoordinates(_fcMavlinkSystem.lat, _fcMavlinkSystem.lon)
    readonly property bool gpsSimulationActive: typeof _uiSimulator !== "undefined" && _uiSimulator.active
    readonly property var liveGpsPosition: gpsPositionAvailable && !gpsSimulationActive
        ? Qt.point(_fcMavlinkSystem.lat, _fcMavlinkSystem.lon) : null
    property var lastGpsPosition: null
    onLiveGpsPositionChanged: Qt.callLater(rememberGpsPosition)

    function rememberGpsPosition() {
        if (liveGpsPosition === null) {
            if (gpsSaveTimer.running) {
                gpsSaveTimer.stop()
                saveLastGpsPosition()
            }
            return
        }
        if (lastGpsPosition && lastGpsPosition.x === liveGpsPosition.x && lastGpsPosition.y === liveGpsPosition.y)
            return
        var firstFix = lastGpsPosition === null
        lastGpsPosition = liveGpsPosition
        if (firstFix) saveLastGpsPosition()
        else gpsSaveTimer.start()
    }

    function saveLastGpsPosition() {
        if (!lastGpsPosition) return
        settings.setValue("gps_callout_last_position", lastGpsPosition.x + "," + lastGpsPosition.y)
        settings.sync()
    }

    // Group latitude and longitude notifications and limit settings writes during flight.
    Timer {
        id: gpsSaveTimer
        interval: 500
        onTriggered: saveLastGpsPosition()
    }

    property bool gpsPreviewRequested: typeof QOPENHD_GPS_PREVIEW !== "undefined" && QOPENHD_GPS_PREVIEW
    readonly property bool gpsPreviewActive: gpsPreviewRequested && !gpsPositionAvailable
    readonly property bool showingSavedGpsPosition: !gpsPositionAvailable && !gpsPreviewActive && lastGpsPosition !== null
    function gps_coordinate(latitude) {
        if (!gpsPositionAvailable && !gpsPreviewActive && !lastGpsPosition) return qsTr("Unavailable")
        var value = gpsPreviewActive ? (latitude ? 50.110924 : 8.682127)
            : gpsPositionAvailable ? (latitude ? _fcMavlinkSystem.lat : _fcMavlinkSystem.lon)
            : (latitude ? lastGpsPosition.x : lastGpsPosition.y)
        if (settings.gps_hide_identity_using_offset)
            value += latitude ? settings.hide_identity_latitude_offset : settings.hide_identity_longitude_offset
        var direction = latitude ? (value < 0 ? "S" : "N") : (value < 0 ? "W" : "E")
        var coordinate = Math.abs(value).toFixed(6) + "\u00b0 " + direction
        return latitude && showingSavedGpsPosition ? qsTr("Last %1").arg(coordinate) : coordinate
    }

    function set_gps_callout_open(open) {
        settings.gps_position_popup_open = open
        settings.setValue("gps_position_popup_open", open)
        settings.sync()
    }

    function format_nav_alt() {
        var alt = previewTelemetry("_fcMavlinkSystem", "altitude_rel_m", _fcMavlinkSystem.altitude_rel_m);
        if (!_fcMavlinkSystem.is_alive) {
            return "N/A";
        }
        return (settings.enable_imperial || settings.enable_hybrid) ? Math.round(alt * 3.28084) + "ft" : Math.round(alt) + "m";
    }

    function format_nav_time() {
        var t = previewTelemetry("_fcMavlinkSystem", "flight_time", _fcMavlinkSystem.flight_time);
        if (!_fcMavlinkSystem.is_alive || t === "") {
            return "N/A";
        }
        return t;
    }

    function format_flight_mode() {
        var mode = previewTelemetry("_fcMavlinkSystem", "flight_mode", _fcMavlinkSystem.flight_mode);
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
        var t = previewTelemetry("_fcMavlinkSystem", "flight_time", _fcMavlinkSystem.flight_time);
        if (!_fcMavlinkSystem.is_alive || t === "") {
            return "00:00";
        }
        if (typeof t === "string") {
            if (t.indexOf(":") !== -1) {
                var parts = t.split(":");
                if (parts.length === 2 || parts.length === 3) {
                    var hours = parts.length === 3 ? Number(parts[0]) : 0;
                    var minutes = Number(parts[parts.length - 2]);
                    var seconds = Number(parts[parts.length - 1]);
                    if (isFinite(hours) && isFinite(minutes) && isFinite(seconds))
                        return seconds_to_mmss(hours * 3600 + minutes * 60 + seconds);
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
        var distance = previewTelemetry("_fcMavlinkSystem", "home_distance", _fcMavlinkSystem.home_distance);
        var unit = "m";
        var use_imperial = settings.value("enable_imperial", false);
        if (use_imperial === true || use_imperial === 1 || use_imperial === "true") {
            unit = "ft";
            distance = distance * 3.28084;
        }
        return Number(distance).toLocaleString(Qt.locale(), "f", 1) + unit;
    }

    function format_air_speed() {
        return format_speed(previewTelemetry("_fcMavlinkSystem", "air_speed_meter_per_second", _fcMavlinkSystem.air_speed_meter_per_second));
    }

    function format_gps_speed() {
        return format_speed(previewTelemetry("_fcMavlinkSystem", "ground_speed_meter_per_second", _fcMavlinkSystem.ground_speed_meter_per_second));
    }

    function format_speed(speed_mps) {
        if (!_fcMavlinkSystem.is_alive) {
            return "N/A";
        }
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
        var mv = previewTelemetry("_ohdSystemGround", "ina219_voltage_millivolt", _ohdSystemGround.ina219_voltage_millivolt);
        if (mv <= 0) {
            return "N/A";
        }
        return Number(mv / 1000.0).toLocaleString(Qt.locale(), 'f', 1) + "V";
    }

    function format_gnd_current() {
        var ma = previewTelemetry("_ohdSystemGround", "ina219_current_milliamps", _ohdSystemGround.ina219_current_milliamps);
        if (ma <= 0) {
            return "N/A";
        }
        return Number(ma / 1000.0).toLocaleString(Qt.locale(), 'f', 1) + "A";
    }

    function format_gnd_mah() {
        return "N/A";
    }

    function format_gnd_rssi() {
        var rssi = previewTelemetry("_ohdSystemGround", "current_rx_signal_quality", _ohdSystemGround.current_rx_signal_quality);
        if (rssi < 0) {
            return "N/A";
        }
        return rssi + "%";
    }

    widgetActionComponent: Loader {
        active: widgetAction.visible
        asynchronous: true
        sourceComponent: ScrollView {
            contentHeight: actionColumn.implicitHeight
            ScrollBar.horizontal.policy: ScrollBar.AlwaysOff
            clip: true

            ColumnLayout {
                id: actionColumn
                width: parent.width
                spacing: 4

                Item {
                    width: parent.width
                    height: 24
                    Text {
                        text: qsTr("Mode: %1").arg(format_flight_mode())
                        color: "white"
                        height: parent.height
                        font.bold: true
                        font.family: linkFont
                        font.pixelSize: detailPanelFontPixels
                        anchors.left: parent.left
                        verticalAlignment: Text.AlignVCenter
                    }
                }
                Item {
                    width: parent.width
                    height: 24
                    Text {
                        text: qsTr("Time: %1").arg(format_nav_time())
                        color: "white"
                        height: parent.height
                        font.bold: true
                        font.family: linkMonoFont
                        font.pixelSize: detailPanelFontPixels
                        anchors.left: parent.left
                        verticalAlignment: Text.AlignVCenter
                    }
                }

                Repeater {
                    model: 8
                    delegate: Item {
                        width: parent.width
                        height: 24
                        property int slotIndex: index + 1
                        property string slotSelection: get_slot_selection(slotIndex)
                        visible: slotSelection !== "none"
                        Text {
                            text: slot_label(slotSelection)
                            color: "white"
                            height: parent.height
                            font.bold: true
                            font.family: linkFont
                            font.pixelSize: detailPanelFontPixels
                            anchors.left: parent.left
                            verticalAlignment: Text.AlignVCenter
                        }
                        Text {
                            text: slot_text(slotSelection)
                            color: "white"
                            height: parent.height
                            font.bold: true
                            font.family: linkMonoFont
                            font.pixelSize: detailPanelFontPixels
                            anchors.right: parent.right
                            verticalAlignment: Text.AlignVCenter
                        }
                    }
                }
            }
        }
    }

    widgetDetailComponent: Loader {
        objectName: "bottomBarSettingsLoader"
        active: widgetDetail.visible
        asynchronous: true
        sourceComponent: ScrollView {
            objectName: "bottomBarSettingsScroll"
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

                RowLayout {
                    width: parent.width
                    Text {
                        Layout.fillWidth: true
                        text: qsTr("Scramble GPS coordinates")
                        color: "white"
                        font.bold: true
                        font.pixelSize: detailPanelFontPixels
                        wrapMode: Text.WordWrap
                    }
                    Switch {
                        objectName: "bottomBarGpsScramble"
                        Accessible.name: qsTr("Scramble GPS coordinates")
                        checked: settings.gps_hide_identity_using_offset
                        onToggled: {
                            settings.gps_hide_identity_using_offset = checked
                            settings.setValue("gps_hide_identity_using_offset", checked)
                            settings.sync()
                        }
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
                        DarkComboBox {
                            id: slotCombo
                            objectName: "bottomBarSlot" + slotIndex
                            model: slotOptions
                            textRole: "label"
                            currentIndex: slot_index_for_value(get_slot_selection(slotIndex))
                            anchors.right: parent.right
                            anchors.rightMargin: 6
                            anchors.top: parent.top
                            anchors.topMargin: 4
                            width: 160
                            height: parent.height - 4
                            onActivated: function(index) {
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
    }

    Item {
        id: widgetInner
        objectName: "bottomBarVisual"
        // Scale the content without narrowing the full-width bar.
        width: parent.width / Math.max(0.01,bw_current_scale)
        height: parent.height
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.alignWhenCentered: false
        anchors.bottom: parent.bottom
        transformOrigin: Item.Bottom
        opacity: widgetGalleryPreview ? 1 : bw_current_opacity
        scale: bw_current_scale
        clip: false

        Shape {
            id: baseShape
            objectName: "bottomBarBackground"
            anchors.fill: parent
            opacity: 0.5
            property color fillColor: barBackgroundColor
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

        // The flight-mode area below is above this surface and keeps its own
        // gestures. Holds on the remaining bar open its configuration.
        MouseArea {
            objectName: "bottomBarSettingsHold"
            anchors.fill: parent
            enabled: !widgetGalleryPreview
            preventStealing: true
            onPressAndHold: {
                widgetAction.close()
                widgetDetail.focus = true
                widgetDetail.open()
            }
        }

        Text {
            id: flightModeText
            objectName: "bottomBarFlightModeText"
            text: flight_mode_display_text()
            anchors.horizontalCenter: parent.horizontalCenter
            anchors.top: parent.top
            anchors.topMargin: 1
            color: settings.osd_bottom_bar_text_color || settings.color_text
            font.pixelSize: 16
            font.family: linkFont
            font.bold: _fcMavlinkSystem.is_alive && _fcMavlinkSystem.armed
            font.strikeout: _fcMavlinkSystem.is_alive && !_fcMavlinkSystem.armed
            style: Text.Outline
            styleColor: settings.color_glow
        }

        MouseArea {
            id: flightModeTouchArea
            anchors.horizontalCenter: parent.horizontalCenter
            anchors.top: parent.top
            width: Math.max(110, notchSafeWidth)
            height: 36
            acceptedButtons: Qt.LeftButton
            preventStealing: true

            onPressed: {
                flight_mode_long_press_handled = false
            }

            onClicked: {
                mouse.accepted = true
                if (flight_mode_long_press_handled) {
                    return
                }
                if (!_fcMavlinkSystem.is_alive) {
                    return
                }
                if (flightModeQuickPicker.opened) {
                    flightModeQuickPicker.close()
                } else {
                    flightModeQuickPicker.open()
                }
            }

            onPressAndHold: {
                mouse.accepted = true
                flight_mode_long_press_handled = true
                if (!_fcMavlinkSystem.is_alive) {
                    return
                }
                if (_fcMavlinkSystem.armed) {
                    return
                }
                _fcMavlinkAction.arm_fc_async(true)
                _qopenhd.show_toast(qsTr("Arming command sent"))
                flightModeQuickPicker.close()
            }
        }

        Text {
            text: format_flight_time_short()
            anchors.horizontalCenter: parent.horizontalCenter
            anchors.top: flightModeText.bottom
            anchors.topMargin: -2
            color: settings.osd_bottom_bar_text_color || settings.color_text
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
                                color: settings.osd_bottom_bar_text_color || settings.color_shape
                                font.pixelSize: 16
                                font.family: "Font Awesome 5 Free"
                                style: Text.Outline
                                styleColor: settings.color_glow
                            }
                            Text {
                                text: slot_text(get_slot_selection(modelData))
                                color: settings.osd_bottom_bar_text_color || settings.color_text
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
            objectName: "bottomBarRightSlots"
            anchors.left: contentArea.horizontalCenter
            anchors.leftMargin: notchSafeWidth / 2
            anchors.right: fixedSatellites.left
            anchors.bottom: contentArea.bottom
            anchors.top: contentArea.top
            anchors.rightMargin: 12

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
                                color: settings.osd_bottom_bar_text_color || settings.color_shape
                                font.pixelSize: 16
                                font.family: "Font Awesome 5 Free"
                                style: Text.Outline
                                styleColor: settings.color_glow
                            }
                            Text {
                                text: slot_text(get_slot_selection(modelData))
                                color: settings.osd_bottom_bar_text_color || settings.color_text
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
            id: fixedSatellites
            objectName: "bottomBarSatellites"
            Accessible.role: Accessible.Button
            Accessible.name: qsTr("Satellites: %1. GPS position").arg(format_nav_sats())
            Accessible.onPressAction: set_gps_callout_open(!settings.gps_position_popup_open)
            anchors.right: parent.right
            anchors.rightMargin: 12
            anchors.top: parent.top
            anchors.bottom: parent.bottom
            width: Math.max(48, satelliteValues.implicitWidth + 12)
            Row {
                id: satelliteValues
                anchors.centerIn: parent
                anchors.verticalCenterOffset: slotContentYOffset
                spacing: 6
                Rectangle {
                    id: satelliteIcon
                    objectName: "bottomBarSatelliteIcon"
                    width: 30; height: 30; radius: 15
                    color: settings.gps_position_popup_open ? Qt.rgba(barShapeColor.r, barShapeColor.g, barShapeColor.b, 0.12) : "transparent"
                    border.width: settings.gps_position_popup_open ? 1 : 0
                    border.color: barShapeColor
                    Text {
                        anchors.centerIn: parent
                        text: "\uf7bf"
                        color: settings.osd_bottom_bar_text_color || settings.color_shape
                        font.family: "Font Awesome 5 Free"
                        font.pixelSize: 18
                        style: Text.Outline
                        styleColor: settings.color_glow
                    }
                }
                Text {
                    id: satelliteCount
                    objectName: "bottomBarSatelliteCount"
                    anchors.verticalCenter: parent.verticalCenter
                    text: format_nav_sats()
                    color: barTextColor
                    font.family: linkFont
                    font.pixelSize: 16
                    style: Text.Outline
                    styleColor: settings.color_glow
                }
            }
            MouseArea {
                objectName: "bottomBarGpsTouch"
                anchors.fill: parent
                enabled: !widgetGalleryPreview
                cursorShape: Qt.PointingHandCursor
                onClicked: set_gps_callout_open(!settings.gps_position_popup_open)
                onPressAndHold: {
                    widgetDetail.focus = true
                    widgetDetail.open()
                }
            }
        }

        GpsPositionPopup {
            id: gpsPositionPopup
            objectName: "bottomBarGpsPopup"
            x: Math.max(8, parent.width - width - 12)
            y: -height + 2
            z: 10
            expanded: settings.gps_position_popup_open
            pointerX: fixedSatellites.x + satelliteValues.x + satelliteIcon.x + satelliteIcon.width / 2 - x
            latitudeText: gps_coordinate(true)
            longitudeText: gps_coordinate(false)
            textFont: satelliteCount.font.family
            textPixelSize: satelliteCount.font.pixelSize
            panelColor: baseShape.fillColor
            backgroundOpacity: baseShape.opacity
            textColor: showingSavedGpsPosition || gpsPreviewActive || (gpsPositionAvailable && gpsSimulationActive)
                ? settings.color_warn : satelliteCount.color
            accentColor: barShapeColor
            onExpansionRequested: function(expanded) { set_gps_callout_open(expanded) }
        }
    }

    Popup {
        id: flightModeQuickPicker
        parent: Overlay.overlay
        width: Math.min(300, parent.width - 24)
        height: Math.min(flightModeQuickPickerContent.implicitHeight + 16, parent.height - 24)
        modal: false
        focus: true
        closePolicy: Popup.CloseOnPressOutside | Popup.CloseOnEscape
        x: Math.round((parent.width - width) / 2)
        y: Math.round((parent.height - height) / 2)

        background: Rectangle {
            color: "#000000"
            opacity: 0.92
            radius: 8
            border.width: 1
            border.color: "#335a73"
        }

        contentItem: Flickable {
            clip: true
            contentHeight: flightModeQuickPickerContent.implicitHeight

            Column {
                id: flightModeQuickPickerContent
                width: flightModeQuickPicker.width - 16
                x: 8
                y: 8
                spacing: 6

                Text {
                    width: parent.width
                    text: qsTr("Flight mode")
                    color: "white"
                    font.bold: true
                    font.pixelSize: 14
                    horizontalAlignment: Text.AlignHCenter
                }

                Text {
                    width: parent.width
                    text: qsTr("Long press current mode to arm")
                    color: "#c7d4dd"
                    font.pixelSize: 12
                    horizontalAlignment: Text.AlignHCenter
                }

                Repeater {
                    model: flightModeOptions

                    delegate: Button {
                        width: parent.width
                        height: 34
                        visible: {
                            var _ = m_ardupilot_mav_type
                            return _fcMavlinkAction.has_mapping(modelData)
                        }
                        text: modelData

                        onClicked: {
                            _fcMavlinkAction.flight_mode_cmd_async_string(modelData)
                            flightModeQuickPicker.close()
                        }
                    }
                }
            }
        }
    }
}
