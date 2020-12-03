import QtQuick 2.12
import QtQuick.Controls 2.12
import QtQuick.Layouts 1.12
import QtGraphicalEffects 1.12
import QtQuick.Shapes 1.0

import Qt.labs.settings 1.0

import OpenHD 1.0

BaseWidget {
    property alias gaugeAngle: throttleArc.sweepAngle

    property alias gaugeAngleGlow: throttleArcGlow.sweepAngle

    id: throttleWidget
    width: 96
    height: 68

    visible: settings.show_throttle

    widgetIdentifier: "throttle_widget"

    defaultAlignment: 2
    defaultXOffset: 96
    defaultYOffset: 72
    defaultHCenter: false
    defaultVCenter: false

    hasWidgetDetail: true
    widgetDetailComponent: Column {
        Item {
            width: parent.width
            height: 32
            Text {
                id: opacityTitle
                text: qsTr("Transparency")
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
        Item {
            width: parent.width
            height: 32
            Text {
                text: qsTr("Size")
                color: "white"
                height: parent.height
                font.bold: true
                font.pixelSize: detailPanelFontPixels
                anchors.left: parent.left
                verticalAlignment: Text.AlignVCenter
            }
            Slider {
                id: throttle_size_Slider
                orientation: Qt.Horizontal
                from: .5
                value: settings.throttle_scale
                to: 3
                stepSize: .1
                height: parent.height
                anchors.rightMargin: 0
                anchors.right: parent.right
                width: parent.width - 96

                onValueChanged: {
                    settings.throttle_scale = throttle_size_Slider.value
                }
            }
        }
    }

    Item {
        id: widgetInner
        anchors.fill: parent
        opacity: settings.throttle_opacity

        Item {
            anchors.fill: parent
            anchors.centerIn: parent
            transform: Scale { origin.x: 48; origin.y: 34; xScale: settings.throttle_scale ; yScale: settings.throttle_scale}


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
                font.family: settings.font_text
                style: Text.Outline
                styleColor: settings.color_glow
            }

            Shape {
                id: throttleGauge
                anchors.fill: parent
                scale: 1.0

                ShapePath {
                    id: throttleShapeGlow

                    fillColor: "transparent"
                    strokeColor: settings.color_glow
                    strokeWidth: 11
                    capStyle: ShapePath.RoundCap

                    PathAngleArc {
                        id: throttleArcGlow
                        centerX: 48
                        centerY: 48
                        radiusX: 32
                        radiusY: 32
                        startAngle: -180
                    }
                }

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
                text: qsTr("throttle")
                anchors.bottom: parent.bottom
                anchors.bottomMargin: 0
                verticalAlignment: Text.AlignBottom
                horizontalAlignment: Text.AlignHCenter
                font.pixelSize: 14
                font.family: settings.font_text
                style: Text.Outline
                styleColor: settings.color_glow
            }
        }
    }
}
