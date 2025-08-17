import QtQuick
import QtQuick.Controls
import QtQuick.Controls.Material
import QtQuick.Layouts
import Qt.labs.settings
import QtQuick.Window

import OpenHD
import "./ui"
import "./ui/widgets"
import "./ui/elements"
import "./ui/configpopup"
import "./video"

ApplicationWindow {
    id: applicationWindow
    visible: true
    property bool QOPENHD_ENABLE_VIDEO_VIA_ANDROID: true

    // To prevent the screen from turning off (new for Qt 6)
    keepScreenOn: true

    //Allow drawing under system bars / notch
    flags: Qt.ExpandedClientAreaHint | Qt.NoTitleBarBackgroundHint

    // Window sizing
    property int m_window_width: 850
    property int m_window_height: 480

    width: (settings.general_screen_rotation == 90 || settings.general_screen_rotation == 270) ? m_window_height : m_window_width
    height: (settings.general_screen_rotation == 90 || settings.general_screen_rotation == 270) ? m_window_width : m_window_height

    // === SAFE HELPERS (avoid ReferenceError on undefined globals) ===
    readonly property bool _isMobile: (typeof QOPENHD_IS_MOBILE !== "undefined") ? QOPENHD_IS_MOBILE : true
    readonly property bool _vidAndroid: (typeof QOPENHD_ENABLE_VIDEO_VIA_ANDROID !== "undefined") ? QOPENHD_ENABLE_VIDEO_VIA_ANDROID : false
    readonly property bool _vidAvcodec: (typeof QOPENHD_ENABLE_VIDEO_VIA_AVCODEC !== "undefined") ? QOPENHD_ENABLE_VIDEO_VIA_AVCODEC : false
    readonly property bool _vidGstQml: (typeof QOPENHD_ENABLE_GSTREAMER_QMLGLSINK !== "undefined") ? QOPENHD_ENABLE_GSTREAMER_QMLGLSINK : false

    // Guard calls into C++ singletons that may not be set up yet
    onWidthChanged: {
        if (typeof _qrenderstats !== "undefined" && _qrenderstats.set_window_width)
            _qrenderstats.set_window_width(width)
    }
    onHeightChanged: {
        if (typeof _qrenderstats !== "undefined" && _qrenderstats.set_window_height)
            _qrenderstats.set_window_height(height)
    }

    contentOrientation: settings.general_screen_rotation===0 ? Qt.PortraitOrientation : Qt.LandscapeOrientation
    contentItem.rotation: settings.general_screen_rotation

    title: qsTr("QOpenHD EVO")
    color: settings.app_background_transparent ? "transparent" : "#2C3E50"

    // Set full-screen visibility (new for Qt 6)
    visibility: (settings.dev_force_show_full_screen || _isMobile) ? Window.FullScreen : Window.AutomaticVisibility

    // Local app settings
    AppSettings {
        id: settings
    }

    // Simple debug HUD so we can see QML is alive and what it chose
    Rectangle {
        id: debugHud
        anchors.left: parent.left
        anchors.top: parent.top
        anchors.margins: 100
        radius: 6
        color: "#66000000"
        z: 10000
        visible: true    // set to false later when you’re done
        border.width: 1
        border.color: "#33FFFFFF"
        Column {
            padding: 6
            spacing: 2
            Text { text: "QML OK  •  " + Qt.formatTime(new Date(), "hh:mm:ss"); color: "white"; font.pixelSize: 14 }
            Text { text: "Size: " + applicationWindow.width + "x" + applicationWindow.height; color: "white"; font.pixelSize: 12 }
            Text { text: "API: " + GraphicsInfo.api; color: "white"; font.pixelSize: 12 }
            Text { text: "Video path: " + videoLoader.source; color: "white"; font.pixelSize: 12; elide: Text.ElideRight; width: 320 }
            Text { text: "Flags A/AVC/GST: " + _vidAndroid + "/" + _vidAvcodec + "/" + _vidGstQml; color: "white"; font.pixelSize: 12 }
        }
        MouseArea { anchors.fill: parent; onClicked: debugHud.visible = false }
    }

    Item{
        anchors.centerIn: parent
        width: (settings.general_screen_rotation == 90 || settings.general_screen_rotation == 270) ? parent.height : parent.width
        height: (settings.general_screen_rotation == 90 || settings.general_screen_rotation == 270) ? parent.width : parent.height

        // Primary video Loader (now with logging + fallback plate)
        Loader {
            id: videoLoader
            anchors.fill: parent
            z: 1.0
            source: {
                if (_vidAndroid) {
                    console.log("QML: selecting ExpMainVideoAndroid.qml")
                    return "../video/ExpMainVideoAndroid.qml"
                }
                if (_vidAvcodec) {
                    console.log("QML: selecting MainVideoQSG.qml")
                    return "../video/MainVideoQSG.qml"
                }
                if (_vidGstQml) {
                    console.log("QML: selecting MainVideoGStreamer.qml")
                    return "../video/MainVideoGStreamer.qml"
                }
                console.warn("QML: No primary video implementation flags set; leaving source empty")
                return ""
            }
            onStatusChanged: {
                // 1=Loading 2=Ready 3=Error
                console.log("QML: videoLoader status=", status, "item=", item, "source=", source)
                if (status === Loader.Error) {
                    console.error("QML: videoLoader ERROR for", source)
                }
            }
        }

        // fallback plate if videoLoader didn’t load anything
        Rectangle {
            anchors.fill: parent
            z: 1.0
            visible: videoLoader.status !== Loader.Ready
            color: "#20252b"
            border.color: "#40464f"
            Text {
                anchors.horizontalCenter: parent.horizontalCenter
                y: (parent.height * 2 / 3) - height / 2
                text: (videoLoader.source==="" ? "No video source selected" : "Loading video…")
                color: "white"
                font.pixelSize: 20
            }
        }

        HUDOverlayGrid {
            id: hudOverlayGrid
            anchors.fill: parent
            z: 3.0
            layer.enabled: false
        }

        ConfigPopup { id: settings_panel; visible: false }

        ColorPicker { id: colorPicker; height: 264; width: 380; z: 15.0; anchors.centerIn: parent }

        WorkaroundMessageBox{ id: workaroundmessagebox }
        ErrorMessageBox{ id: errorMessageBox }
        CardToast{ id: card_toast; m_text: _qopenhd ? _qopenhd.toast_text : ""; visible: _qopenhd ? _qopenhd.toast_visible : false }

        RestartQOpenHDMessageBox{ id: restartQOpenHDMessageBox }

        Shortcut {
            sequence: "Ctrl+F12"
            onActivated: {
                if (typeof _qopenhd !== "undefined" && _qopenhd.disable_service_and_quit)
                    _qopenhd.disable_service_and_quit()
            }
        }
        AnyParamBusyIndicator{ z: 10 }

        Component.onCompleted: {
            console.log("QML: main ApplicationWindow completed")
            if (hudOverlayGrid && hudOverlayGrid.regain_focus)
                hudOverlayGrid.regain_focus()
        }
    }
}
