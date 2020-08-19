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
    widgetDetailHeight: 224
    widgetDetailWidth: 264

    widgetDetailComponent: Column {
        id: speedSettingsColumn
        spacing: 0

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
                id: speed_opacity_Slider
                orientation: Qt.Horizontal
                from: .1
                value: settings.speed_opacity
                to: 1
                stepSize: .1
                height: parent.height
                anchors.rightMargin: 0
                anchors.right: parent.right
                width: parent.width - 96

                onValueChanged: {
                    settings.speed_opacity = speed_opacity_Slider.value
                }
            }
        }
        Item {
            width: parent.width
            height: 32
            Text {
                id: sizeTitle
                text: qsTr("Size")
                color: "white"
                height: parent.height
                font.bold: true
                font.pixelSize: detailPanelFontPixels
                anchors.left: parent.left
                verticalAlignment: Text.AlignVCenter
            }
            Slider {
                id: speed_size_Slider
                orientation: Qt.Horizontal
                from: .7
                value: settings.speed_size
                to: 3
                stepSize: .1
                height: parent.height
                anchors.rightMargin: 0
                anchors.right: parent.right
                width: parent.width - 96

                onValueChanged: {
                    settings.speed_size = speed_size_Slider.value
                }
            }
        }
        Item {
            width: parent.width
            height: 32
            Text {
                text: qsTr("Airspeed / Groundspeed")
                horizontalAlignment: Text.AlignRight
                color: "white"
                height: parent.height
                font.bold: true
                font.pixelSize: detailPanelFontPixels
                anchors.left: parent.left
                verticalAlignment: Text.AlignVCenter
            }
            Switch {
                width: 32
                height: parent.height
                anchors.rightMargin: 6
                anchors.right: parent.right
                checked: settings.speed_use_groundspeed
                onCheckedChanged: settings.speed_use_groundspeed = checked
            }
        }
        Item {
            width: parent.width
            height: 32
            Text {
                text: qsTr("Show ladder")
                color: "white"
                height: parent.height
                font.bold: true
                font.pixelSize: detailPanelFontPixels
                anchors.left: parent.left
                verticalAlignment: Text.AlignVCenter
            }
            Switch {
                width: 32
                height: parent.height
                anchors.rightMargin: 6
                anchors.right: parent.right
                checked: settings.show_speed_ladder
                onCheckedChanged: settings.show_speed_ladder = checked
            }
        }
        Item {
            width: parent.width
            height: 32
            Text {
                text: qsTr("Range")
                color: "white"
                height: parent.height
                font.bold: true
                font.pixelSize: detailPanelFontPixels
                anchors.left: parent.left
                verticalAlignment: Text.AlignVCenter
            }
            Slider {
                id: speed_range_Slider
                orientation: Qt.Horizontal
                from: 40
                value: settings.speed_range
                to: 150
                stepSize: 10
                height: parent.height
                anchors.rightMargin: 0
                anchors.right: parent.right
                width: parent.width - 96

                onValueChanged: { // @disable-check M223
                    settings.speed_range = speed_range_Slider.value;
                }
            }
        }
        Item {
            width: parent.width
            height: 32
            Text {
                text: qsTr("Minimum")
                color: "white"
                height: parent.height
                font.bold: true
                font.pixelSize: detailPanelFontPixels
                anchors.left: parent.left
                verticalAlignment: Text.AlignVCenter
            }
            Slider {
                id: speed_minimum_Slider
                orientation: Qt.Horizontal
                from: 0
                value: settings.speed_minimum
                to: 50
                stepSize: 10
                height: parent.height
                anchors.rightMargin: 0
                anchors.right: parent.right
                width: parent.width - 96

                onValueChanged: { // @disable-check M223
                    settings.speed_minimum = speed_minimum_Slider.value
                }
            }
        }
    }

    Item {
        id: widgetInner
        anchors.fill: parent
        opacity: settings.speed_opacity

        //-----------------------ladder start---------------
        Item {
            id: speedLadder

            anchors.right: parent.right
            anchors.rightMargin: 20 //tweak ladder left or right

            visible: settings.show_speed_ladder

            transform: Scale { origin.x: -33; origin.y: 12; xScale: settings.speed_size ; yScale: settings.speed_size}

            SpeedLadder {
                id: speedLadderC
                anchors.centerIn: parent
                width: 50
                height: 300
                clip: false
                color: settings.color_shape
                glow: settings.color_glow
                useGroundspeed: settings.speed_use_groundspeed
                imperial: settings.enable_imperial
                speedMinimum: settings.speed_minimum
                speedRange: settings.speed_range
                speed: OpenHD.speed
                airspeed: OpenHD.airspeed
                fontFamily: settings.font_text
            }
        }
        //-----------------------ladder end---------------



        Text {
            anchors.fill: parent
            id: speed_text
            color: settings.color_text           
            font.pixelSize: 14
            font.family: settings.font_text
            transform: Scale { origin.x: 12; origin.y: 12; xScale: settings.speed_size ; yScale: settings.speed_size}
            text: Number(
                      settings.enable_imperial ?
                      (settings.speed_use_groundspeed ? OpenHD.speed * 0.621371 : OpenHD.airspeed * 0.621371) :
                      (settings.speed_use_groundspeed ? OpenHD.speed : OpenHD.airspeed)   ).toLocaleString(
                      Qt.locale(), 'f', 0)
            horizontalAlignment: Text.AlignHCenter
            verticalAlignment: Text.AlignVCenter
            style: Text.Outline
            styleColor: settings.color_glow
        }
        Shape {
            id: outlineGlow
            anchors.fill: parent
            rotation: 180
            transform: Scale { origin.x: 12; origin.y: 12; xScale: settings.speed_size ; yScale: settings.speed_size}
            ShapePath {
                strokeColor: settings.color_glow
                strokeWidth: 3
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
        Shape {
            id: outline
            anchors.fill: parent
            rotation: 180
            transform: Scale { origin.x: 12; origin.y: 12; xScale: settings.speed_size ; yScale: settings.speed_size}
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



