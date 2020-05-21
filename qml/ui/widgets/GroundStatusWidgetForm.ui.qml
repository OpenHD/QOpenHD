import QtQuick 2.12
import QtQuick.Controls 2.12
import QtQuick.Layouts 1.12
import QtGraphicalEffects 1.12
import Qt.labs.settings 1.0

import OpenHD 1.0

BaseWidget {
    id: groundStatusWidget
    width: 112
    height: 24

    visible: settings.show_ground_status

    widgetIdentifier: "ground_status_widget"

    defaultAlignment: 1
    defaultXOffset: 128
    defaultYOffset: 24
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
                id: ground_status_opacity_Slider
                orientation: Qt.Horizontal
                from: .1
                value: settings.ground_status_opacity
                to: 1
                stepSize: .1
                height: parent.height
                anchors.rightMargin: 0
                anchors.right: parent.right
                width: parent.width - 96

                onValueChanged: {
                    settings.ground_status_opacity = ground_status_opacity_Slider.value
                }
            }
        }
    }

    Item {
        id: widgetInner

        anchors.fill: parent

        Text {
            id: chip_gnd
            y: 0
            width: 24
            height: 24
            color: settings.color_shape
            opacity: settings.ground_status_opacity
            text: "\uF2DA"
            anchors.right: cpuload_gnd.left
            anchors.rightMargin: 2
            anchors.verticalCenter: parent.verticalCenter
            font.family: "Font Awesome 5 Free"
            verticalAlignment: Text.AlignVCenter
            font.pixelSize: 14
            horizontalAlignment: Text.AlignRight
            elide: Text.ElideRight
        }

        Text {
            id: cpuload_gnd
            x: 0
            y: 0
            width: 36
            height: 24
            color: settings.color_text
            opacity: settings.ground_status_opacity
            text: Number(OpenHD.cpuload_gnd).toLocaleString(Qt.locale(), 'f', 0) + "%";
            anchors.verticalCenter: parent.verticalCenter
            anchors.right: temp_gnd.left
            anchors.rightMargin: 2
            verticalAlignment: Text.AlignVCenter
            font.pixelSize: 14
            horizontalAlignment: Text.AlignRight
            elide: Text.ElideRight
        }

        Text {
            id: temp_gnd
            x: 0
            y: 0
            width: 36
            height: 24
            color: settings.color_text
            opacity: settings.ground_status_opacity
            text: Number(OpenHD.temp_gnd).toLocaleString(Qt.locale(), 'f', 0) + "°";
            anchors.verticalCenter: parent.verticalCenter
            anchors.right: parent.right
            anchors.rightMargin: 0
            verticalAlignment: Text.AlignVCenter
            font.pixelSize: 14
            horizontalAlignment: Text.AlignRight
            elide: Text.ElideRight
        }
    }
}
