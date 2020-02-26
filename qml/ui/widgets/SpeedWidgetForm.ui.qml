import QtQuick 2.12
import QtQuick.Controls 2.12
import QtQuick.Layouts 1.12
import QtGraphicalEffects 1.12
import QtQuick.Shapes 1.0

import Qt.labs.settings 1.0

import OpenHD 1.0

BaseWidget {
    id: speedWidget
    width: 64
    height: 24

    visible: settings.show_speed

    defaultXOffset: 20
    defaultVCenter: true

    widgetIdentifier: "speed_widget"

    defaultHCenter: false

    hasWidgetDetail: true
    widgetDetailComponent: Column {
        Item {
            width: parent.width
            height: 24
            Text {
                text: "Airspeed or GPS"
                horizontalAlignment: Text.AlignRight
                color: "white"
                font.bold: true
                font.pixelSize: detailPanelFontPixels
                anchors.left: parent.left
            }
            Switch {
                width: 32
                height: parent.height
                anchors.rightMargin: 12
                anchors.right: parent.right
                checked: settings.speed_airspeed_gps
                onCheckedChanged: settings.speed_airspeed_gps = checked
            }
        }
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
                id: speed_opacity_Slider
                orientation: Qt.Horizontal
                from: .1
                value: settings.speed_opacity
                to: 1
                stepSize: .1

                onValueChanged: {
                    settings.speed_opacity = speed_opacity_Slider.value
                }
            }
        }
        Item {
            width: parent.width
            height: 24
            Text {
                text: "Size"
                color: "white"
                font.bold: true
                font.pixelSize: detailPanelFontPixels
                anchors.left: parent.left
            }
            Slider {
                id: speed_size_Slider
                orientation: Qt.Horizontal
                from: .7
                value: settings.speed_size
                to: 3
                stepSize: .1

                onValueChanged: {
                    settings.speed_size = speed_size_Slider.value
                }
            }
        }
    }

    Glow {
        anchors.fill: widgetInner
        radius: 3
        samples: 17
        color: settings.color_glow
        opacity: settings.speed_opacity
        source: widgetInner
    }

    Item {
        id: widgetInner
        anchors.fill: parent

        Text {
            anchors.fill: parent
            id: speed_text
            color: settings.color_text
            opacity: settings.speed_opacity
            transform: Scale { origin.x: 12; origin.y: 12; xScale: settings.speed_size ; yScale: settings.speed_size}
            text: Number(
                      settings.speed_airspeed_gps ? OpenHD.airspeed : OpenHD.speed).toLocaleString(
                      Qt.locale(), 'f', 0)
            horizontalAlignment: Text.AlignHCenter
            verticalAlignment: Text.AlignVCenter
        }

        Shape {
            id: outline
            anchors.fill: parent
            rotation: 180
            transform: Scale { origin.x: 12; origin.y: 12; xScale: settings.speed_size ; yScale: settings.speed_size}
            opacity: settings.speed_opacity
            ShapePath {
                strokeColor: settings.color_shape
                strokeWidth: 1
                strokeStyle: ShapePath.SolidLine
                fillColor: "transparent"
                startX: 0
                startY: 12
                PathLine {
                    x: 0
                    y: 12
                }
                PathLine {
                    x: 12
                    y: 0
                }
                PathLine {
                    x: 58
                    y: 0
                }
                PathLine {
                    x: 58
                    y: 24
                }
                PathLine {
                    x: 12
                    y: 24
                }
                PathLine {
                    x: 0
                    y: 12
                }
            }
        }
    }
}



