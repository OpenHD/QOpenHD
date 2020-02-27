import QtQuick 2.12
import QtQuick.Controls 2.12
import QtQuick.Layouts 1.12
import QtGraphicalEffects 1.12
import Qt.labs.settings 1.0

import OpenHD 1.0

BaseWidget {
    id: flightModeWidget
    width: 212
    height: 48

    visible: settings.show_flight_mode

    widgetIdentifier: "flight_mode_widget"

    defaultAlignment: 3
    defaultHCenter: true
    defaultVCenter: false

    hasWidgetDetail: true
    widgetDetailComponent: Column {
        Item {
            width: parent.width
            height: 32
            Text {
                id: opacityTitle
                text: "Opacity"
                color: "white"
                height: parent.height
                font.bold: true
                font.pixelSize: detailPanelFontPixels
                anchors.left: parent.left
                verticalAlignment: Text.AlignVCenter
            }
            Slider {
                id: flight_mode_opacity_Slider
                orientation: Qt.Horizontal
                from: .1
                value: settings.flight_mode_opacity
                to: 1
                stepSize: .1
                height: parent.height
                anchors.rightMargin: 0
                anchors.right: parent.right
                width: parent.width - 96

                onValueChanged: {
                    settings.flight_mode_opacity = flight_mode_opacity_Slider.value
                }
            }
        }
    }

    Item {
        id: widgetInner

        anchors.fill: parent

        Text {
            id: flight_mode_icon
            width: 24
            height: 48
            color: settings.color_shape
            opacity: settings.flight_mode_opacity
            text: "\uf072"
            anchors.right: flight_mode_text.left
            anchors.rightMargin: 6
            anchors.verticalCenter: parent.verticalCenter
            font.family: "Font Awesome 5 Free"
            horizontalAlignment: Text.AlignRight
            verticalAlignment: Text.AlignVCenter
            font.pixelSize: 20
        }

        Text {
            id: flight_mode_text

            height: 48
            color: settings.color_text
            opacity: settings.flight_mode_opacity
            text: OpenHD.flight_mode
            anchors.verticalCenter: parent.verticalCenter
            anchors.horizontalCenter: parent.horizontalCenter
            verticalAlignment: Text.AlignVCenter
            font.pixelSize: 24
            elide: Text.ElideRight
        }
    }
}
