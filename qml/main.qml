import QtQuick 2.12
import QtQuick.Controls 2.13
import QtQuick.Controls.Styles 1.4
import QtQuick.Layouts 1.0
import QtGraphicalEffects 1.12
import Qt.labs.settings 1.0

import QtQuick.Controls.Material 2.12

import OpenHD 1.0

import "./ui"


ApplicationWindow {
    id: applicationWindow
    visible: true
    width: 800
    height: 480
    minimumHeight: 480
    minimumWidth: 800
    title: qsTr("Open.HD")
    color: "#00000000"

    Material.theme: Material.Light
    Material.accent: Material.Blue
    visibility: UseFullscreen ? "FullScreen" : "AutomaticVisibility"

    property bool initialised: false

    onAfterSynchronizing: {
        if (!initialised) {
            messageHUD.pushMessage("Initializing", 1)
            if (EnableRC) {
                OpenHDRC.initRC;
            }
            upperOverlayBar.configure();
            lowerOverlayBar.configure();
            initialised = true;
        }
    }

    /*
     * Local app settings. Uses the "user defaults" system on Mac/iOS, the Registry on Windows,
     * and equivalent settings systems on Linux and Android
     *
     */
    Settings {
        id: settings
    }

    Loader {
        id: videoLoader
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.top: parent.top
        anchors.bottom: parent.bottom
        anchors.fill: parent
        source: EnableVideo ? "./ui/VideoPanel.qml" : ""
    }

    Connections {
        target: MavlinkTelemetry
        onMessageReceived: {
            messageHUD.pushMessage(message, level)
        }
    }

    Connections {
        target: LocalMessage
        onMessageReceived: {
            messageHUD.pushMessage(message, level)
        }
    }

    // UI areas

    MessageHUD {
        id: messageHUD
        anchors.bottom: lowerOverlayBar.top
        anchors.bottomMargin: 4
        anchors.left: parent.left
        anchors.leftMargin: 6
        anchors.right: parent.right
        anchors.rightMargin: 6

    }

    UpperOverlayBar {
        id: upperOverlayBar
        onSettingsButtonClicked: {
            settings_panel.openSettings();
        }
    }


    LowerOverlayBar {
        id: lowerOverlayBar
    }


    SettingsPopup {
        id: settings_panel
        onConfigure: {
            upperOverlayBar.configure();
            lowerOverlayBar.configure();
            messageHUD.configure();
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
