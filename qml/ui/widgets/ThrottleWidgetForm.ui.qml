import QtQuick 2.12
import QtQuick.Controls 2.12
import QtQuick.Layouts 1.12
import QtGraphicalEffects 1.12
import QtQuick.Shapes 1.0

import Qt.labs.settings 1.0

import OpenHD 1.0

BaseWidget {
    property alias gaugeAngle: throttleArc.sweepAngle

    id: throttleWidget
    width: 96
    height: 68

    visible: settings.show_throttle

    widgetIdentifier: "throttle_widget"

    defaultAlignment: 2
    defaultXOffset: 72
    defaultYOffset: 58
    defaultHCenter: false
    defaultVCenter: false

    hasWidgetDetail: true
    widgetDetailComponent: Column {
        Item {
            width: parent.width
            height: 32
            Text {
                id: opacityTitle
                text: "Transparency"
                color: "white"
                height: parent.height
                font.bold: true
                font.pixelSize: detailPanelFontPixels
                anchors.left: parent.left
                verticalAlignment: Text.AlignVCenter
            }
            Slider {
                id: throttle_opacity_Slider
                orientation: Qt.Horizontal
                from: .1
                value: settings.throttle_opacity
                to: 1
                stepSize: .1
                height: parent.height
                anchors.rightMargin: 0
                anchors.right: parent.right
                width: parent.width - 96

                onValueChanged: {
                    settings.throttle_opacity = throttle_opacity_Slider.value
                }
            }
        }
    }

    Glow {
        anchors.fill: widgetInner
        radius: 3
        samples: 17
        color: settings.color_glow
        opacity: settings.throttle_opacity
        source: widgetInner
    }

    Item {
        id: widgetInner
        anchors.fill: parent
        opacity: settings.throttle_opacity
        Text {
            id: throttle_percent
            y: 0
            width: 24
            height: 18
            color: settings.color_text
            text: OpenHD.throttle
            anchors.horizontalCenter: parent.horizontalCenter
            anchors.bottom: parent.bottom
            anchors.bottomMargin: 18
            verticalAlignment: Text.AlignVCenter
            horizontalAlignment: Text.AlignHCenter
            font.pixelSize: 18
        }

        Shape {
            id: throttleGauge
            anchors.fill: parent
            opacity: settings.throttle_opacity
            scale: 1.0

            ShapePath {
                id: throttleShape

                fillColor: "transparent"
                strokeColor: settings.color_shape
                strokeWidth: 9
                capStyle: ShapePath.RoundCap

                PathAngleArc {
                    id: throttleArc
                    centerX: 48
                    centerY: 48
                    radiusX: 32
                    radiusY: 32
                    startAngle: -180
                }
            }
        }

        Text {
            id: throttle_description
            y: 0
            width: parent.width
            height: 14
            color: settings.color_text
            opacity: settings.throttle_opacity
            text: qsTr("throttle")
            anchors.bottom: parent.bottom
            anchors.bottomMargin: 0
            verticalAlignment: Text.AlignBottom
            horizontalAlignment: Text.AlignHCenter
            font.pixelSize: 14
        }
    }
}
