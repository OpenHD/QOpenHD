import QtQuick 2.12
import QtQuick.Controls 2.12
import QtQuick.Layouts 1.12
import QtGraphicalEffects 1.12
import Qt.labs.settings 1.0

import OpenHD 1.0

BaseWidget {
    id: altitudesecondWidget
    width: 40
    height: 25
    defaultAlignment: 2
    defaultHCenter: false
    defaultVCenter: false
    defaultXOffset: 12
    defaultYOffset: 64
    dragging: false

    visible: settings.show_altitude_second

    widgetIdentifier: "altitude_second_widget"

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
                id: altitude_second_opacity_Slider
                orientation: Qt.Horizontal
                height: parent.height
                from: .1
                value: settings.altitude_second_opacity
                to: 1
                stepSize: .1
                anchors.rightMargin: 0
                anchors.right: parent.right
                width: parent.width - 96


                onValueChanged: {
                    settings.altitude_second_opacity = altitude_second_opacity_Slider.value
                }
            }
        }
        Item {
            width: parent.width
            height: 32
            Text {
                id: mslTitle
                text: qsTr("Relative / MSL")
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
                checked: settings.altitude_second_msl_rel
                onCheckedChanged: settings.altitude_second_msl_rel = checked
            }
        }
    }

    Glow {
        anchors.fill: widgetInner
        radius: 3
        samples: 17
        color: settings.color_glow
        opacity: settings.altitude_second_opacity
        source: widgetInner
    }

    Item {
        id: widgetInner
        anchors.fill: parent

        Text {
            id: second_alt_text
            color: settings.color_text
            opacity: settings.altitude_second_opacity
            font.pixelSize: 14
            width: 40
            anchors.right: parent.right
            anchors.rightMargin: 0
            anchors.verticalCenter: widgetGlyph.verticalCenter
            text: Number(settings.enable_imperial ? (settings.altitude_second_msl_rel ? (OpenHD.alt_msl*3.28) : (OpenHD.alt_rel*3.28)) :
                      (settings.altitude_second_msl_rel ? OpenHD.alt_msl : OpenHD.alt_rel)
                      ).toLocaleString(
                      Qt.locale(), 'f', 0)
            horizontalAlignment: Text.AlignRight
            verticalAlignment: Text.AlignVCenter
        }

        Text {
            id: widgetGlyph
            width: 40
            height: parent.height
            color: settings.color_shape
            opacity: settings.altitude_second_opacity
            text: "\uf338"
            anchors.left: parent.left
            anchors.leftMargin: 0
            anchors.verticalCenter: parent.verticalCenter
            font.family: "Font Awesome 5 Free"
            font.pixelSize: 14
            verticalAlignment: Text.AlignVCenter
        }

        antialiasing: true
    }
}



