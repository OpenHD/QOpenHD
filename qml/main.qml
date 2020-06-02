import QtQuick 2.12
import QtQuick.Controls 2.12
import QtQuick.Controls.Styles 1.4
import QtQuick.Layouts 1.0
import QtGraphicalEffects 1.12
import Qt.labs.settings 1.0

import OpenHD 1.0

import "./ui"
import "./ui/widgets"


ApplicationWindow {
    id: applicationWindow
    visible: true
    width: 800
    height: 480
    minimumHeight: 320
    minimumWidth: 480
    title: qsTr("Open.HD")
    color: EnableMainVideo ? "black" : "#00000000"

    visibility: UseFullscreen ? "FullScreen" : "AutomaticVisibility"

    property bool initialised: false

    Component.onCompleted: {
        if (!initialised) {
            hudOverlayGrid.messageHUD.pushMessage("Initializing", 1)
            initialised = true;
        }
    }

    /* this is not used but must stay right here, it forces qmlglsink to completely
       initialize the rendering system early. Without this, the next GstGLVideoItem
       to be initialized, depending on the order they appear in the QML, will simply
       not work on desktop linux. */
    Loader {
        source: (EnableGStreamer && EnableMainVideo && EnablePiP)  ? "DummyVideoGStreamer.qml" : ""
    }

    function default_mavlink_sysid() {
        if (IsRaspPi) {
            return 220;
        }
        if (IsMac) {
            return 221;
        }
        if (IsiOS) {
            return 222;
        }
        if (IsAndroid) {
            return 223;
        }
        if (IsWindows) {
            return 224;
        }
        if (IsDesktopLinux) {
            return 225;
        }
    }

    /*
     * Local app settings. Uses the "user defaults" system on Mac/iOS, the Registry on Windows,
     * and equivalent settings systems on Linux and Android
     *
     */
    Settings {
        id: settings
        property double global_scale: 1.0

        property int main_video_port: 5600
        property int pip_video_port: 5601
        property int lte_video_port: 8000
        property int battery_cells: 3

        property int mavlink_sysid: default_mavlink_sysid()

        property bool show_pip_video: false
        property double pip_video_opacity: 1

        property bool enable_software_video_decoder: false
        property bool enable_rtp: true
        property bool enable_lte_video: false
        property bool hide_watermark: false

        property bool enable_speech: true
        property bool enable_imperial: false
        property bool enable_rc: false

        property string color_shape: "white"
        property string color_text: "white"
        property string color_glow: "black"

        property string bar_behavior: "red"

        property double ground_power_opacity: 1
        
        property int log_level: 3

        property bool show_downlink_rssi: true
        property double downlink_rssi_opacity: 1
        property bool downlink_rssi_show_lost_damaged: false
        property bool downlink_cards_right: false

        property bool show_uplink_rssi: true
        property double uplink_rssi_opacity: 1

        property bool show_bitrate: true
        property double bitrate_opacity: 1
        property bool bitrate_showall: false

        property bool show_air_battery: true
        property double air_battery_opacity: 1
        property bool air_battery_showall: false
        property bool air_battery_by_cell: false

        property bool show_gps: true
        property double gps_opacity: 1

        property bool show_home_distance: true
        property double home_distance_opacity: 1

        property bool show_flight_timer: true
        property double flight_timer_opacity: 1

        property bool show_flight_mode: true
        property double flight_mode_opacity: 1

        property bool show_flight_distance: true
        property double distance_opacity: 1

        property bool show_flight_mah: true
        property bool air_battery_mah_source: true
        property double mah_opacity: 1

        property bool show_ground_status: true
        property double ground_status_opacity: 1

        property bool show_air_status: true
        property double air_status_opacity: 1

        property bool show_message_hud: true
        property double message_hud_opacity: 1

        property bool show_horizon: true
        property bool horizon_invert_pitch: false
        property bool horizon_invert_roll: false
        property int horizon_size: 1
        property double horizon_opacity: 1
        property int horizon_ladder_spacing: 10
        property bool show_horizon_ladder: true

        property bool show_fpv: true
        property bool fpv_dynamic: true
        property int fpv_sensitivity: 5
        property double fpv_opacity: 1

        property bool show_speed: true
        property bool speed_airspeed_gps: false
        property double speed_opacity: 1
        property double speed_size: 1
        property bool show_speed_ladder: true
        property int speed_range: 100
        property int speed_minimum: 0

        property bool show_heading: true
        property bool heading_inav: false
        property double heading_opacity: 1
        property double heading_size: 1
        property bool show_heading_ladder: true
        property bool heading_ladder_text: true //true:letters/false:numbers

        property bool show_altitude: true
        property bool altitude_rel_msl: false
        property double altitude_opacity: 1
        property double altitude_size: 1
        property bool show_altitude_ladder: true
        property int altitude_range: 100

        property bool show_altitude_second: true
        property bool altitude_second_msl_rel: false
        property double altitude_second_opacity: 1

        property bool show_arrow: true
        property bool arrow_invert: false
        property double arrow_opacity: 1

        property bool show_map: false

        property double map_opacity: 1
        property bool map_orientation: false
        property bool map_shape_circle: false

        property int map_zoom: 18

        property bool show_throttle: true
        property double throttle_opacity: 1

        property bool show_control: false
        property double control_opacity: 1

        property bool double_control: true
        property bool control_rev_pitch: false
        property bool control_rev_roll: false
        property bool control_rev_yaw: false
        property bool control_rev_throttle: false

        property bool show_gpio: false
        property int selected_map_provider: 0
        property int selected_map_variant: 0

        property bool show_vibration: false
        property double vibration_opacity: 1

        property bool show_vsi: true
        property double vsi_opacity: 1
        property int vsi_max: 20

        property bool show_wind: false
        property double wind_opacity: 1
        property bool wind_plane_copter: true
        property bool wind_arrow_circle: true
        //tumbler value had to be split into two values..
        property double wind_tumbler_decimal: 5
        property double wind_tumbler_tens: 13
        property double wind_max_quad_speed: wind_tumbler_tens+(wind_tumbler_decimal*.1)

    }


    FrSkyTelemetry {
        id: frskyTelemetry
    }

    //MSPTelemetry {
    //    id: mspTelemetry
    //}

    SmartportTelemetry {
        id: smartportTelemetry
    }

    LTMTelemetry {
        id: ltmTelemetry
    }

    VectorTelemetry {
        id: vectorTelemetry
    }

    Loader {
        anchors.fill: parent
        z: 1.0
        source: {
            if (EnableGStreamer && EnableMainVideo) {
                return "MainVideoGStreamer.qml";
            }
            if (IsRaspPi && EnableVideoRender && EnableMainVideo) {
                return "MainVideoRender.qml";
            }

            if (IsMac && EnableVideoRender && EnableMainVideo) {
                return "MainVideoRender.qml";
            }
            if (IsiOS && EnableVideoRender && EnableMainVideo) {
                return "MainVideoRender.qml";
            }
            return ""
        }
    }

    Connections {
        target: OpenHD
        function onMessageReceived(message, level) {
            if (level >= settings.log_level) {
                hudOverlayGrid.messageHUD.pushMessage(message, level)
            }
        }
    }

    Connections {
        target: LocalMessage
        function onMessageReceived(message, level) {
            if (level >= settings.log_level) {
                hudOverlayGrid.messageHUD.pushMessage(message, level)
            }
        }
    }

    // UI areas

    UpperOverlayBar {
        id: upperOverlayBar
        onSettingsButtonClicked: {
            settings_panel.openSettings();
        }
    }

    HUDOverlayGrid {
        id: hudOverlayGrid
        anchors.fill: parent
        z: 3.0
    }

    LowerOverlayBar {
        id: lowerOverlayBar
    }


    SettingsPopup {
        id: settings_panel
        visible: false
        onLocalMessage: {
            hudOverlayGrid.messageHUD.pushMessage(message, level)
        }
    }

    Shortcut {
        sequence: "Ctrl+F12"
        onActivated: {
            OpenHDPi.activate_console()
            OpenHDPi.stop_app()
        }
    }
}

/*##^##
Designer {
    D{i:6;anchors_y:8}D{i:7;anchors_y:32}D{i:8;anchors_y:32}D{i:9;anchors_y:8}D{i:10;anchors_y:32}
D{i:11;anchors_y:32}D{i:12;anchors_y:11}D{i:13;anchors_y:11}D{i:14;anchors_x:62}D{i:15;anchors_x:128}
D{i:16;anchors_x:136;anchors_y:11}D{i:17;anchors_x:82;anchors_y:8}D{i:19;anchors_y:8}
D{i:21;anchors_y:31}D{i:22;anchors_y:8}D{i:23;anchors_y:11}D{i:24;anchors_y:32}
}
##^##*/
