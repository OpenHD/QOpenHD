import QtQuick 2.12
import QtQuick.Controls 2.12
import QtQuick.Layouts 1.12
import QtGraphicalEffects 1.12
import Qt.labs.settings 1.0

import OpenHD 1.0

BaseWidget {
    id: flightMahWidget
    width: 96
    height: 24

    visible: settings.show_flight_mah

    widgetIdentifier: "flight_mah_widget"


    defaultAlignment: 3
    defaultXOffset: 110
    defaultYOffset: 0
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
                id: mah_opacity_Slider
                orientation: Qt.Horizontal
                from: .1
                value: settings.mah_opacity
                to: 1
                stepSize: .1
                height: parent.height
                anchors.rightMargin: 0
                anchors.right: parent.right
                width: parent.width - 96

                onValueChanged: {
                    settings.mah_opacity = mah_opacity_Slider.value
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
                id: mah_size_Slider
                orientation: Qt.Horizontal
                from: .5
                value: settings.mah_size
                to: 3
                stepSize: .1
                height: parent.height
                anchors.rightMargin: 0
                anchors.right: parent.right
                width: parent.width - 96

                onValueChanged: {
                    settings.mah_size = mah_size_Slider.value
                }
            }
        }
        Item {
            width: parent.width
            height: 32
            Text {
                text: qsTr("Use telemetry data")
                color: "white"
                height: parent.height
                font.bold: true
                font.pixelSize: detailPanelFontPixels;
                anchors.left: parent.left
                verticalAlignment: Text.AlignVCenter
            }
            Switch {
                width: 32
                height: parent.height
                anchors.rightMargin: 6
                anchors.right: parent.right
                checked: settings.flight_mah_use_telemetry
                onCheckedChanged: settings.flight_mah_use_telemetry = checked
            }
        }
    }

    Item {
        id: widgetInner

        anchors.fill: parent
        scale: settings.mah_size

        Text {
            id: home_icon
            x: 0

            width: 24
            height: 24
            clip: true
            color: settings.color_shape
            opacity: settings.mah_opacity
            text: "\uf0e7"
            anchors.right: flight_mah_text.left
            anchors.rightMargin: 6
            verticalAlignment: Text.AlignVCenter
            font.family: "Font Awesome 5 Free"
            font.pixelSize: 15
            horizontalAlignment: Text.AlignRight
            style: Text.Outline
            styleColor: settings.color_glow
        }

        Text {
            id: flight_mah_text
            width: 68
            height: 24
            clip: true
            color: settings.color_text
            opacity: settings.mah_opacity
            text: settings.flight_mah_use_telemetry ? OpenHD.flight_mah + "mAh" : OpenHD.app_mah + "mAh"
            anchors.right: parent.right
            anchors.rightMargin: 0
            verticalAlignment: Text.AlignVCenter
            font.pixelSize: 16
            font.family: settings.font_text
            horizontalAlignment: Text.AlignLeft
            style: Text.Outline
            styleColor: settings.color_glow
        }
    }
}
