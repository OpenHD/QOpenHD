import QtQuick 2.12
import QtQuick.Controls 2.12
import QtQuick.Layouts 1.12
import QtGraphicalEffects 1.12
import QtQuick.Shapes 1.0

import Qt.labs.settings 1.0

import OpenHD 1.0

BaseWidget {
    id: altitudeWidget
    width: 64
    height: 24
    // resize with right side (technically top right, but it doesn't matter because VCenter is set)
    defaultAlignment: 1
    defaultXOffset: 20
    defaultVCenter: true

    visible: settings.show_altitude

    widgetIdentifier: "altitude_widget"

    defaultHCenter: false

    hasWidgetDetail: true
    widgetDetailComponent: Column {
        Item {
            width: parent.width
            height: 24
            Text {
                text: "Relative Or MSL"
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
                checked: settings.altitude_rel_msl
                onCheckedChanged: settings.altitude_rel_msl = checked
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
                id: altitude_opacity_Slider
                orientation: Qt.Horizontal
                from: .1
                value: settings.altitude_opacity
                to: 1
                stepSize: .1

                onValueChanged: {
                    settings.altitude_opacity = altitude_opacity_Slider.value
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
                id: altitude_size_Slider
                orientation: Qt.Horizontal
                from: .7
                value: settings.altitude_size
                to: 3
                stepSize: .1

                onValueChanged: {
                    settings.altitude_size = altitude_size_Slider.value
                }
            }
        }
    }

    Glow {
        anchors.fill: widgetInner
        radius: 3
        samples: 17
        color: settings.color_glow
        opacity: settings.altitude_opacity
        source: widgetInner
    }

    Item {
        id: widgetInner
        anchors.fill: parent

        Text {
            id: alt_text
            color: settings.color_text
            opacity: settings.altitude_opacity
            transform: Scale { origin.x: 12; origin.y: 12; xScale: settings.altitude_size ; yScale: settings.altitude_size}
            text: Number(
                      settings.altitude_rel_msl ? OpenHD.alt_msl : OpenHD.alt_rel).toLocaleString(
                      Qt.locale(), 'f', 0)
            anchors.fill: parent
            horizontalAlignment: Text.AlignHCenter
            verticalAlignment: Text.AlignVCenter
        }

        Shape {
            id: outline
            anchors.fill: parent
            opacity: settings.altitude_opacity
            transform: Scale { origin.x: 12; origin.y: 12; xScale: settings.altitude_size ; yScale: settings.altitude_size}
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



