import QtQuick 2.12
import QtQuick.Controls 2.12
import QtQuick.Layouts 1.12
import QtGraphicalEffects 1.12
import Qt.labs.settings 1.0

import OpenHD 1.0

import org.freedesktop.gstreamer.GLVideoItem 1.0

BaseWidget {
    width: 252
    height: 192

    visible: settings.show_pip_video && isRunning

    widgetIdentifier: "pip_video_widget"

    defaultAlignment: 0
    defaultXOffset: 12
    defaultYOffset: 64
    defaultHCenter: false
    defaultVCenter: false

    hasWidgetDetail: true
    widgetDetailComponent: Column {
        Item {
            width: parent.width
            height: 24
            Text {
                text: "Opacity"
                color: "white"
                font.bold: true
                font.pixelSize: detailPanelFontPixels
                anchors.left: parent.left
            }
            Slider {
                id: pip_video_opacity_Slider
                orientation: Qt.Horizontal
                from: .1
                value: settings.pip_video_opacity
                to: 1
                stepSize: .1

                onValueChanged: {
                    settings.pip_video_opacity = pip_video_opacity_Slider.value
                }
            }
        }
    }

    Rectangle {
        id: widgetInner

        color: settings.color_text
        opacity: settings.pip_video_opacity
        anchors.left: parent.left
        anchors.leftMargin: 6

        anchors.right: parent.right
        anchors.rightMargin: 6

        anchors.top: parent.top
        anchors.topMargin: 6

        anchors.bottom: parent.bottom
        anchors.bottomMargin: 6

        GstGLVideoItem {
            id: videoElement
            objectName: "pipVideoItem"
            anchors.fill: parent
        }
    }
}
