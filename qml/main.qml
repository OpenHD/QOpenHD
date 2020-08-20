import QtQuick 2.12
import QtQuick.Controls 2.12
import QtQuick.Controls.Styles 1.4
import QtQuick.Controls.Material 2.12
import QtQuick.Layouts 1.0
import QtGraphicalEffects 1.12
import Qt.labs.settings 1.0

import OpenHD 1.0

import "./ui"
import "./ui/widgets"
import "./ui/elements"


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

    // we call back into QML from ManagedSettings to ensure that the live settings take effect
    // immediately, QSettings doesn't seem capable of doing it from C++
    Connections {
        target: ManageSettings
        function onSettingUpdated(key, value) {
            settings.setValue(key, value);
        }

        function onNeedRestart() {
            settings_panel.visible = false;
            restartDialog.visible = true;
        }
    }

    ColorPicker {
        id: colorPicker
        height: 264
        width: 380
        z: 15.0
        anchors.centerIn: parent
    }

    RestartDialog {
        id: restartDialog
        height: 240
        width: 400
        z: 5.0
        anchors.centerIn: parent
    }

    /*
     * This is racing the QML Settings class, because it has a delay before it writes
     * out the merged default+saved settings when it first loads. The delay in Settings
     * has a purpose, but it makes it impossible to know when all of the settings have
     * actually made it into the settings system, which makes it impossible for QSettings
     * in c++ to read all of them.
     */
    Timer {
        id: piSettingsTimer
        running: false
        interval: 1000
        repeat: true

        property int retries: 10

        onTriggered: {
            if (!ManageSettings.savePiSettings()) {
                if (retries == 0) {
                    /*
                     * Exceeded the retry count, which means in a whole 10 seconds
                     * Qt did not manage to get all of the default+changed settings written to
                     * disk. This should never happen, that's a long time.
                     */
                    running = false;
                    return;
                }

                retries = retries - 1;
            }
            // success
            running = false;
        }
    }

    /*
     * Local app settings. Uses the "user defaults" system on Mac/iOS, the Registry on Windows,
     * and equivalent settings systems on Linux and Android
     *
     */
    AppSettings {
        id: settings
        Component.onCompleted: {
            if (IsRaspPi) {
                piSettingsTimer.start();
            }
        }
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
        visible: !settings.stereo_enable
        id: upperOverlayBar
    }

    HUDOverlayGrid {
        id: hudOverlayGrid
        anchors.fill: parent
        z: 3.0
        onSettingsButtonClicked: {
            settings_panel.openSettings();
        }
    }

    OSDCustomizer {
        id: osdCustomizer

        anchors.centerIn: parent
        visible: false
        z: 5.0
    }

    LowerOverlayBar {
        visible: !settings.stereo_enable
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

    Item {
        anchors.fill: parent
        z: settings.stereo_enable ? 10.0 : 1.0

        TapHandler {
            enabled: settings_panel.visible == false
            acceptedButtons: Qt.AllButtons
            onTapped: {
                if (tapCount == 3) {
                    settings.stereo_enable = false
                }
            }
            onLongPressed: {
                if (settings.stereo_enable ) {
                    return;
                }

                osdCustomizer.visible = true
            }

            grabPermissions: PointerHandler.CanTakeOverFromAnything
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
