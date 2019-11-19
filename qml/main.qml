import QtQuick 2.12
import QtQuick.Controls 2.12
import QtQuick.Controls.Styles 1.4
import QtQuick.Layouts 1.0
import QtGraphicalEffects 1.12
import Qt.labs.settings 1.0

import OpenHD 1.0

import "./ui"
import "./ui/widgets"

import QGroundControl.QgcQtGStreamer 1.0

ApplicationWindow {
    id: applicationWindow
    visible: true
    width: 800
    height: 480
    minimumHeight: 320
    minimumWidth: 480
    title: qsTr("Open.HD")
    color: EnableVideo ? "black" : "#00000000"

    visibility: UseFullscreen ? "FullScreen" : "AutomaticVisibility"

    property bool initialised: false

    onAfterSynchronizing: {
        if (!initialised) {
            hudOverlayGrid.messageHUD.pushMessage("Initializing", 1)
            if (EnableRC) {
                OpenHDRC.initRC;
            }
            upperOverlayBar.configure();
            lowerOverlayBar.configure();
            hudOverlayGrid.configure();
            initialised = true;
            if (EnableVideo) {
                stream.startVideo();
            }
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

    QOpenHDLink {
        id: link
    }

    OpenHDTelemetry {
        id: openHDTelemetry
    }

    MavlinkTelemetry {
        id: mavlinkTelemetry
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


    VideoItem {
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.top: parent.top
        anchors.bottom: parent.bottom
        anchors.fill: parent
        id: videoBackground
        surface: stream.videoReceiver.videoSurface
        z: 1.0
        visible: EnableVideo
    }

    Connections {
        target: OpenHD
        onMessageReceived: {
            hudOverlayGrid.messageHUD.pushMessage(message, level)
        }
    }

    Connections {
        target: LocalMessage
        onMessageReceived: {
            hudOverlayGrid.messageHUD.pushMessage(message, level)
        }
    }

    OpenHDVideoStream {
        id: stream
        uri: {
            //if (OpenHDPi.is_raspberry_pi) {
            //    return "file:///root/videofifo1";
            //} else {
                var main_video_port = settings.value("main_video_port", 5600);
                return "udp://0.0.0.0:%1".arg(main_video_port);
            //}
        }
    }

    /*OpenHDVideoStream {
        id: pipVideoStream
        uri: {
            return "videotestsrc://";
            //if (OpenHDPi.is_raspberry_pi) {
            //    return "file:///root/videofifo1";
            //} else {
                var pip_video_port = settings.value("pip_video_port", 5601);
                return "udp://0.0.0.0:%1".arg(pip_video_port);
            //}
        }
    }*/
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
        onConfigure: {
            upperOverlayBar.configure();
            lowerOverlayBar.configure();
            hudOverlayGrid.configure();
            hudOverlayGrid.messageHUD.configure();
        }
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
