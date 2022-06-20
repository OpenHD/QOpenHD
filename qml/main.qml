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
import "./ui/configpopup"


ApplicationWindow {
    id: applicationWindow
    visible: true
    width: 800
    height: 480
    minimumHeight: 320
    minimumWidth: 480
    title: qsTr("Open.HD")
    //color: EnableMainVideo ? "black" : "#00000000"
    //color: "transparent" //Consti10 transparent background
    color : "yellow" // make it yellow for testing, not green to avoid confusion with video renderer
    //flags: Qt.WindowStaysOnTopHint| Qt.FramelessWindowHint| Qt.X11BypassWindowManagerHint;
    visibility: UseFullscreen ? "FullScreen" : "AutomaticVisibility"

    property bool initialised: false

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
     * Local app settings. Uses the "user defaults" system on Mac/iOS, the Registry on Windows,
     * and equivalent settings systems on Linux and Android
     *
     */
    AppSettings {
        id: settings
        Component.onCompleted: {
            //
        }
    }

    // Loads the proper (platform-dependent) video widget for the main (primary) video
    Loader {
        anchors.fill: parent
        z: 1.0
        source: {
            if (EnableGStreamer && EnableMainVideo) {
                return "../video/MainVideoGStreamer.qml";
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
            if (level <= settings.log_level) {
                hudOverlayGrid.messageHUD.pushMessage(message, level)
            }
        }
    }

    Connections {
        target: LocalMessage
        function onMessageReceived(message, level) {
            if (level <= settings.log_level) {
                hudOverlayGrid.messageHUD.pushMessage(message, level)
            }
        }
    }


    // UI areas

    HUDOverlayGrid {
        id: hudOverlayGrid
        anchors.fill: parent
        z: 3.0
        onSettingsButtonClicked: {
            settings_panel.openSettings();
        }

        transform: Scale {
            origin.x: 0 + (settings.stereo_osd_left_x)
            origin.y: hudOverlayGrid.height / 2
            xScale: settings.stereo_enable ? 0.5*(settings.stereo_osd_size/100) : 1.0
            yScale: settings.stereo_enable ? 0.5*(settings.stereo_osd_size/100) : 1.0
        }

        layer.enabled: true
    }

    OSDCustomizer {
        id: osdCustomizer

        anchors.centerIn: parent
        visible: false
        z: 5.0
    }

    SettingsPopup {
        id: settings_panel
        visible: false
        onLocalMessage: {
            hudOverlayGrid.messageHUD.pushMessage(message, level)
        }

        onSettingsClosed: {
            if (settings.stereo_enable) {
                stereoHelpMessage.visible = true
                stereoHelpTimer.start()
            }
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
                    settings.stereo_enable = !settings.stereo_enable
                    if (settings.stereo_enable) {
                        stereoHelpMessage.visible = true
                        stereoHelpTimer.start()
                    }
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

    Text {
        id: stereoHelpMessage
        z: 2.0
        color: "#89ffffff"
        visible: false
        font.pixelSize: 18
        font.family: settings.font_text
        text: qsTr("Rapidly tap between widgets to enable/disable stereo")
        horizontalAlignment: Text.AlignHCenter
        height: 24
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.top: parent.top
        anchors.topMargin: 64
        style: Text.Outline
        styleColor: "black"
    }

    Timer {
        id: stereoHelpTimer
        running: false
        interval: 4000
        repeat: false

        onTriggered: {
            stereoHelpMessage.visible = false;
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
