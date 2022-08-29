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
    //color: "transparent" //Consti10 transparent background
    //color : "#2C3E50" // reduce KREBS
    color: settings.app_background_transparent ? "transparent" : "#2C3E50"
    //flags: Qt.WindowStaysOnTopHint| Qt.FramelessWindowHint| Qt.X11BypassWindowManagerHint;
    visibility: UseFullscreen ? "FullScreen" : "AutomaticVisibility"

    property bool initialised: false


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
    /*Loader {
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
    }*/
    Squircle {
        SequentialAnimation on t {
            NumberAnimation { to: 1; duration: 2500; easing.type: Easing.InQuad }
            NumberAnimation { to: 0; duration: 2500; easing.type: Easing.OutQuad }
            loops: Animation.Infinite
            running: true
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
    }

    // We need this one to display popup messages to the user on platforms that don't support
    // QMessageBox (e.g. eglfs) since QMessageBox wants to open a new window
    // TODO make me less dirty / hacky
    Card {
        id: workaroundMessageBox
        height: 200
        width: 320
        z: 5.0
        anchors.centerIn: parent
        cardName: qsTr("QOpenHD")
        cardNameColor: "black"
        visible: _messageBoxInstance.show_to_user
        cardBody: Column {
            height: 200
            width: 320
            Text {
                id: workaroundMessageBox_text
                text: _messageBoxInstance.text
                width: parent.width-24
                height:parent.height
                leftPadding: 12
                rightPadding: 12
                wrapMode: Text.WordWrap
            }
        }
        hasFooter: true
        cardFooter: Item {
            anchors.fill: parent
            Button {
                width: 140
                height: 48
                anchors.right: parent.right
                anchors.rightMargin: 12
                anchors.bottom: parent.bottom
                anchors.bottomMargin: 6
                font.pixelSize: 14
                font.capitalization: Font.MixedCase
                Material.accent: Material.Green
                highlighted: true
                text:  qsTr("Okay")
                onPressed: {
                    _messageBoxInstance.okay_button_clicked()
                }
            }
        }
    }

    Shortcut {
        sequence: "Ctrl+F12"
        onActivated: {
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
            }
            onLongPressed: {
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
