
import QtQuick 2.12
import QtQuick.Controls 2.12
import QtQuick.Controls.Material 2.12
import QtQuick.Layouts 1.0
import Qt.labs.settings 1.0
import QtPositioning 5.15

import OpenHD 1.0

import "./ui"
import "./ui/widgets"
import "./ui/elements"
import "./ui/configpopup"
import "./video"

Item {
    // rotation: settings.general_screen_rotation
    anchors.centerIn: parent
    width: (settings.general_screen_rotation == 90 || settings.general_screen_rotation == 270) ? parent.height : parent.width
    height: (settings.general_screen_rotation == 90 || settings.general_screen_rotation == 270) ? parent.width : parent.height

    // Loads the proper (platform-dependent) video widget for the main (primary) video
    // primary video is always full-screen and behind the HUD OSD Elements
    Loader {
        anchors.fill: parent
        z: 1.0
        source: {
            if(QOPENHD_ENABLE_VIDEO_VIA_ANDROID){
                return "../video/ExpMainVideoAndroid.qml"
            }
            // If we have avcodec at compile time, we prefer it over qmlglsink since it provides lower latency
            // (not really avcodec itself, but in this namespace we have 1) the preferred sw decode path and
            // 2) also the mmal rpi path )
            if(QOPENHD_ENABLE_VIDEO_VIA_AVCODEC){
                return "../video/MainVideoQSG.qml";
            }
            // Fallback / windows or similar
            if(QOPENHD_ENABLE_GSTREAMER_QMLGLSINK){
                return "../video/MainVideoGStreamer.qml";
            }
            console.warn("No primary video implementation")
            return ""
        }
    }

    HUDOverlayGrid {
        id: hudOverlayGrid
        anchors.fill: parent
        z: 3.0
        colorPicker: colorPicker
        //onSettingsButtonClicked: {
        //    settings_panel.openSettings();
        //}
        // Keep the debug overlay in a separate composited layer. Some video
        // renderers submit frames outside normal QML item stacking and can
        // otherwise cover widgets after their first frame arrives.
        // Avoid the extra layer during normal flight use.
        layer.enabled: settings.show_video_pipeline_debug_widget
    }

    // Keep the large advanced menu out of the boot path. Retain it after its
    // first use so closing/reopening settings preserves the selected page.
    Loader {
        id: settings_panel
        anchors.fill: parent
        z: 4
        visible: false
        property bool requested: false
        active: requested || !applicationWindow.bootSplashEnabled
        asynchronous: applicationWindow.bootSplashEnabled
        source: "ui/configpopup/ConfigPopup.qml"
        function openSettings() { visible = true }
        function close_all() {
            if (item) item.close_all()
            visible = false
            hudOverlayGrid.regain_focus()
        }
        onVisibleChanged: {
            if (visible) {
                requested = true
                if (status === Loader.Ready) item.openSettings()
            }
        }
        onLoaded: {
            if (visible) item.openSettings()
            else item.visible = false
        }
        Connections {
            target: settings_panel.item
            function onVisibleChanged() {
                settings_panel.visible = settings_panel.item.visible
            }
        }
    }

    Rectangle {
        id: loadingSettingsOverlay
        anchors.fill: parent
        z: 5
        color: "#091827"
        visible: settings_panel.visible && settings_panel.status !== Loader.Ready
        BusyIndicator {
            anchors.centerIn: parent
            running: parent.visible && settings_panel.status !== Loader.Error
        }
        Text {
            anchors.horizontalCenter: parent.horizontalCenter
            y: parent.height / 2 + 45
            color: "white"
            text: settings_panel.status === Loader.Error
                  ? qsTr("Unable to load settings") : qsTr("Loading settings…")
        }
        Shortcut {
            sequence: "Escape"
            enabled: loadingSettingsOverlay.visible
            onActivated: settings_panel.close_all()
        }
    }

    // TODO QT 6
    ColorPicker {
        id: colorPicker
        height: 264
        width: 380
        parent: Overlay.overlay
        z: 1000
        anchors.centerIn: parent
    }
    //ColorDialoque{
    //}

    WorkaroundMessageBox{
        id: workaroundmessagebox
    }
    ErrorMessageBox{
        id: errorMessageBox
    }
    CardToast{
        id: card_toast
        m_text: _qopenhd.toast_text
        visible: _qopenhd.toast_visible
    }

    // Used by settings that require a restart
    RestartQOpenHDMessageBox{
        id: restartQOpenHDMessageBox
    }

    // Allows closing QOpenHD via a keyboard shortcut
    // also stops the service, such that it is not restartet
    Shortcut {
        sequence: "Ctrl+F12"
        onActivated: {
            _qopenhd.disable_service_and_quit()
        }
    }
    AnyParamBusyIndicator{
        z: 10
    }

    Component.onCompleted: {
        console.log("Completed");
        hudOverlayGrid.regain_focus()
    }
}
