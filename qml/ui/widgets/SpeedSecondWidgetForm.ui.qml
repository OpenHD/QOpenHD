import QtQuick 2.12
import QtQuick.Controls 2.12
import QtQuick.Layouts 1.12
import QtGraphicalEffects 1.12
import Qt.labs.settings 1.0

import OpenHD 1.0

BaseWidget {
    id: speedsecondWidget
    width: 40
    height: 25
    defaultAlignment: 3
    defaultHCenter: false
    defaultVCenter: false
    defaultXOffset: 12
    defaultYOffset: 128
    dragging: false

    visible: settings.show_speed_second

    widgetIdentifier: "speed_second_widget"

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
                id: speed_second_opacity_Slider
                orientation: Qt.Horizontal
                height: parent.height
                from: .1
                value: settings.speed_second_opacity
                to: 1
                stepSize: .1
                anchors.rightMargin: 0
                anchors.right: parent.right
                width: parent.width - 96


                onValueChanged: {
                    settings.speed_second_opacity = speed_second_opacity_Slider.value
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
                id: alt_second_size_Slider
                orientation: Qt.Horizontal
                from: .5
                value: settings.speed_second_size
                to: 3
                stepSize: .1
                height: parent.height
                anchors.rightMargin: 0
                anchors.right: parent.right
                width: parent.width - 96

                onValueChanged: {
                    settings.speed_second_size = alt_second_size_Slider.value
                }
            }
        }
        Item {
            width: parent.width
            height: 32
            Text {
                id: mslTitle
                text: qsTr("Airspeed / Groundspeed")
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
                checked: settings.speed_second_use_groundspeed
                onCheckedChanged: settings.speed_second_use_groundspeed = checked
            }
        }
    }

    Item {
        id: widgetInner
        anchors.fill: parent

        scale: settings.speed_second_size

        Text {
            id: second_alt_text
            color: settings.color_text
            opacity: settings.speed_second_opacity
            font.pixelSize: 14
            font.family: settings.font_text
            width: 40
            anchors.right: parent.right
            anchors.rightMargin: 0
            anchors.verticalCenter: widgetGlyph.verticalCenter
            text: Number(
                      settings.enable_imperial ?
                      (settings.speed_second_use_groundspeed ? OpenHD.speed * 0.621371 : OpenHD.airspeed * 0.621371) :
                      (settings.speed_second_use_groundspeed ? OpenHD.speed : OpenHD.airspeed)   ).toLocaleString(
                      Qt.locale(), 'f', 0)
            horizontalAlignment: Text.AlignRight
            verticalAlignment: Text.AlignVCenter
            style: Text.Outline
            styleColor: settings.color_glow
        }

        Text {
            id: widgetGlyph
            width: 40
            height: parent.height
            color: settings.color_shape
            opacity: settings.speed_second_opacity
            text: "\uf3fd"
            anchors.left: parent.left
            anchors.leftMargin: 0
            anchors.verticalCenter: parent.verticalCenter
            font.family: "Font Awesome 5 Free"
            font.pixelSize: 14
            verticalAlignment: Text.AlignVCenter
            style: Text.Outline
            styleColor: settings.color_glow
        }

        antialiasing: true
    }
}



