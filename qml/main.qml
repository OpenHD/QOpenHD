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

    // this is not used but must stay right here, it forces qmlglsink to completely
    // initialize the rendering system early. Without this, the next GstGLVideoItem
    // to be initialized, depending on the order they appear in the QML, will simply
    // not work on desktop linux.
    Loader {
        source: (EnableGStreamer && EnableMainVideo && EnablePiP)  ? "DummyVideoItem.qml" : ""
    }

    /*
     * Local app settings. Uses the "user defaults" system on Mac/iOS, the Registry on Windows,
     * and equivalent settings systems on Linux and Android
     *
     */
    Settings {
        id: settings
        property int main_video_port: 5600
        property int pip_video_port: 5601
        property int lte_video_port: 8000
        property int battery_cells: 3

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

        property double ground_power_opacity: 1
        
        property int log_level: 3

        property bool show_downlink_rssi: true
        property double downlink_rssi_opacity: 1

        property bool show_uplink_rssi: true
        property double uplink_rssi_opacity: 1

        property bool show_bitrate: true
        property double bitrate_opacity: 1

        property bool show_air_battery: true
        property double air_battery_opacity: 1

        property bool show_gps: true
        property double gps_opacity: 1

        property bool show_home_distance: true
        property double home_distance_opacity: 1

        property bool show_flight_timer: true
        property double flight_timer_opacity: 1

        property bool show_flight_mode: true
        property double flight_mode_opacity: 1

        property bool show_ground_status: true
        property double ground_status_opacity: 1

        property bool show_air_status: true
        property double air_status_opacity: 1

        property bool show_message_hud: true
        property double message_hud_opacity: 1

        property bool show_horizon: true
        property bool horizon_invert_pitch: false
        property bool horizon_invert_roll: false
        property int horizon_size: 250
        property double horizon_opacity: 1

        property bool show_fpv: true
        property int fpv_sensitivity: 5
        property double fpv_opacity: 1

        property bool show_speed: true
        property bool speed_airspeed_gps: false
        property double speed_opacity: 1

        property bool show_heading: true
        property bool heading_inav: false
        property double heading_opacity: 1

        property bool show_altitude: true
        property bool altitude_rel_msl: false
        property double altitude_opacity: 1

        property bool show_altitude_second: true
        property bool altitude_second_msl_rel: false
        property double altitude_second_opacity: 1

        property bool show_arrow: true
        property bool arrow_invert: false
        property double arrow_opacity: 1

        property bool show_map: false
        property int map_small_zoom: 18

        property bool show_throttle: true
        property double throttle_opacity: 1

        property bool show_gpio: false
    }

    OpenHDRC {
        id: openHDRC
    }

    QOpenHDLink {
        id: link
    }

    OpenHDSettings {
        id: openHDSettings
    }

    Connections {
        target: openHDSettings
        onGroundStationIPUpdated: {
            link.setGroundIP(address)
            openHDRC.setGroundIP(address)
            MavlinkTelemetry.setGroundIP(address)
            AirGPIOMicroservice.setGroundIP(address)
            GroundPowerMicroservice.setGroundIP(address)
        }
    }

    //FrSkyTelemetry {
    //    id: frskyTelemetry
    //}

    //MSPTelemetry {
    //    id: mspTelemetry
    //}

    //LTMTelemetry {
    //    id: ltmTelemetry
    //}

    Loader {
        anchors.fill: parent
        z: 1.1
        source: {
            if (EnableGStreamer && EnableMainVideo) {
                return "MainVideoItem.qml";
            }
            return ""
        }
    }

    Connections {
        target: OpenHD
        onMessageReceived: {
            if (level >= settings.log_level) {
                hudOverlayGrid.messageHUD.pushMessage(message, level)
            }
        }
    }

    Connections {
        target: LocalMessage
        onMessageReceived: {
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
        onLocalMessage: {
            hudOverlayGrid.messageHUD.pushMessage(message, level)
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
