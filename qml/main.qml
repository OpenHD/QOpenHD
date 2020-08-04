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

        property string locale: "en"

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
        property double downlink_rssi_size: 1

        property bool show_uplink_rssi: true
        property double uplink_rssi_opacity: 1
        property double uplink_rssi_size: 1

        property bool show_rc_rssi: false
        property double rc_rssi_opacity: 1
        property double rc_rssi_size: 1

        property bool show_bitrate: true
        property double bitrate_opacity: 1
        property bool bitrate_show_skip_fail_count: false
        property double bitrate_size: 1

        property bool show_air_battery: true
        property double air_battery_opacity: 1
        property bool air_battery_show_voltage_current: false
        property bool air_battery_show_single_cell: false
        property double air_battery_size: 1

        property bool show_gps: true
        property double gps_opacity: 1
        property bool gps_show_all: false
        property double gps_size: 1

        property bool show_home_distance: true
        property double home_distance_opacity: 1
        property double home_distance_size: 1

        property bool show_flight_timer: true
        property double flight_timer_opacity: 1
        property double flight_timer_size: 1

        property bool show_flight_mode: true
        property double flight_mode_opacity: 1
        property double flight_mode_size: 1

        property bool show_flight_distance: true
        property double flight_distance_opacity: 1
        property double flight_distance_size: 1

        property bool show_flight_mah: true
        property bool flight_mah_use_telemetry: true
        property double mah_opacity: 1
        property double mah_size: 1

        property bool show_fc_temp: true
        property double fc_temp_opacity: 1
        property double fc_temp_size: 1

        property bool show_ground_status: true
        property double ground_status_opacity: 1
        property double ground_status_size: 1

        property bool show_air_status: true
        property double air_status_opacity: 1
        property double air_status_size: 1

        property bool show_message_hud: true
        property double message_hud_opacity: 1
        property double message_hud_size: 1

        property bool show_horizon: true
        property bool horizon_invert_pitch: false
        property bool horizon_invert_roll: false
        property int horizon_size: 1
        property double horizon_opacity: 1
        property int horizon_ladder_spacing: 10        
        property bool show_horizon_ladder: true
        property bool show_horizon_heading_ladder: true
        property bool show_horizon_home: true

        property bool heading_inav: false //shared between heading and horizon
        property bool heading_ladder_text: true //shared between heading and horizon

        property bool show_heading: true
        property double heading_opacity: 1
        property double heading_size: 1
        property bool show_heading_ladder: true

        property bool show_fpv: true
        property bool fpv_dynamic: true
        property int fpv_sensitivity: 5
        property double fpv_opacity: 1
        property double fpv_size: 1

        property bool show_speed: true
        property bool speed_airspeed_gps: false
        property double speed_opacity: 1
        property double speed_size: 1
        property bool show_speed_ladder: true
        property int speed_range: 100
        property int speed_minimum: 0

        property bool show_altitude: true
        property bool altitude_rel_msl: false
        property double altitude_opacity: 1
        property double altitude_size: 1
        property bool show_altitude_ladder: true
        property int altitude_range: 100

        property bool show_altitude_second: true
        property bool altitude_second_msl_rel: false
        property double altitude_second_opacity: 1
        property double altitude_second_size: 1

        property bool show_arrow: true
        property bool arrow_invert: false
        property double arrow_opacity: 1
        property double arrow_size: 1

        property bool show_map: false

        property double map_opacity: 1
        property bool map_orientation: false
        property bool map_shape_circle: false

        property int map_zoom: 18

        property bool show_throttle: true
        property double throttle_opacity: 1
        property double throttle_scale: 1

        property bool show_control: false
        property double control_opacity: 1
        property double control_size: 1

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
        property double vibration_size: 1

        property bool show_vsi: true
        property double vsi_opacity: 1
        property int vsi_max: 20
        property double vsi_size: 1

        property bool show_wind: false
        property double wind_opacity: 1
        property bool wind_plane_copter: true
        property bool wind_arrow_circle: true
        //tumbler value had to be split into two values..
        property double wind_tumbler_decimal: 5
        property double wind_tumbler_tens: 13
        property double wind_max_quad_speed: wind_tumbler_tens+(wind_tumbler_decimal*.1)
        property double wind_size: 1

        property bool show_roll: true
        property bool roll_invert: false
        property bool roll_show_arc: true
        property bool roll_show_numbers: true
        property bool roll_sky_pointer: false
        property double roll_opacity: 1
        property double roll_size: 1

        property bool show_adsb: false
        property int adsb_distance_limit: 15000//meters. Bound box for api from map center (so x2)
        //property int adsb_marker_limit: 19
        property double adsb_opacity: 1
        property double adsb_size: 1

        property bool show_blackbox: false
        property double blackbox_opacity: 1
        property double blackbox_size: 1

        property bool show_example_widget: false

        property int stereo_mode: 0
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

    MarkerModel {
        id: markerModel
    }

    BlackBoxModel {
        id: blackBoxModel
    }

    Loader {
        anchors.fill: parent
        z: 1.0
        source: {
            if (EnableGStreamer && EnableMainVideo) {
                return "MainVideoGStreamer.qml";
            }
            if (IsAndroid && EnableVideoRender && EnableMainVideo) {
                return "MainVideoRender.qml";
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

    Connections {
        target: GroundStatusMicroservice
        function onStatusMessage(sysid, message, level, timestamp) {
            if (level >= settings.log_level) {
                hudOverlayGrid.messageHUD.pushMessage(message, level)
            }
        }
    }

    Connections {
        target: AirStatusMicroservice
        function onStatusMessage(sysid, message, level, timestamp) {
            if (level >= settings.log_level) {
                hudOverlayGrid.messageHUD.pushMessage(message, level)
            }
        }
    }


    // UI areas

    UpperOverlayBar {
        visible: settings.stereo_mode == 0
        id: upperOverlayBar
    }

    HUDOverlayGrid {
        id: hudOverlayGrid
        anchors.left: parent.left
        anchors.top: parent.top
        anchors.bottom: parent.bottom
        anchors.right: parent.right
        transform: Scale {
            origin.x: 0
            origin.y: hudOverlayGrid.height / 2
            xScale: settings.stereo_mode == 1 ? 0.5 : 1.0
            yScale: settings.stereo_mode == 1 ? 0.5 : 1.0
        }
        z: 3.0
        layer.enabled: true

        onSettingsButtonClicked: {
            settings_panel.openSettings();
        }
    }

    Rectangle {
        id: hudOverlayGridClone
        anchors.right: parent.right
        width: parent.width / 2
        height: parent.height / 2
        anchors.verticalCenter: settings.stereo_mode == 1 ? parent.verticalCenter : undefined
        visible: settings.stereo_mode != 0
        z: 3.0
        layer.enabled: true
        layer.effect: ShaderEffect {
            id: shader
            property variant cloneSource : hudOverlayGrid
            fragmentShader: "
                  varying highp vec2 qt_TexCoord0;
                  uniform highp sampler2D cloneSource;
                  void main(void) {
                       gl_FragColor =  texture2D(cloneSource, qt_TexCoord0);
                  }
            "
        }
    }

    LowerOverlayBar {
        visible: settings.stereo_mode == 0
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
