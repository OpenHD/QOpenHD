import QtQuick 2.12
import QtQuick.Controls 2.12
import QtQuick.Layouts 1.12
import QtGraphicalEffects 1.12
import Qt.labs.settings 1.0

import OpenHD 1.0

BaseWidget {
    id: flightTimerWidget
    width: 96
    height: 24

    visible: settings.show_flight_timer

    widgetIdentifier: "flight_timer_widget"

    defaultAlignment: 2
    defaultXOffset: 0
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
                id: flight_timer_opacity_Slider
                orientation: Qt.Horizontal
                from: .1
                value: settings.flight_timer_opacity
                to: 1
                stepSize: .1
                height: parent.height
                anchors.rightMargin: 0
                anchors.right: parent.right
                width: parent.width - 96

                onValueChanged: {
                    settings.flight_timer_opacity = flight_timer_opacity_Slider.value
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
                id: flight_timer_size_Slider
                orientation: Qt.Horizontal
                from: .5
                value: settings.flight_timer_size
                to: 3
                stepSize: .1
                height: parent.height
                anchors.rightMargin: 0
                anchors.right: parent.right
                width: parent.width - 96

                onValueChanged: {
                    settings.flight_timer_size = flight_timer_size_Slider.value
                }
            }
        }
    }

    Item {
        id: widgetInner

        anchors.fill: parent
        scale: settings.flight_timer_size

        Text {
            id: flight_timer_text
            y: 0
            width: 64
            height: 24
            color: settings.color_text
            opacity: settings.flight_timer_opacity
            text: OpenHD.flight_time
            elide: Text.ElideRight
            anchors.right: parent.right
            anchors.rightMargin: 8
            verticalAlignment: Text.AlignVCenter
            font.pixelSize: 16
            horizontalAlignment: Text.AlignLeft
            style: Text.Outline
            styleColor: settings.color_glow
        }

        Text {
            id: time_icon
            x: 0
            y: 0
            width: 24
            height: 24
            color: settings.color_shape
            opacity: settings.flight_timer_opacity
            text: "\uf017"
            font.family: "Font Awesome 5 Free"
            anchors.right: flight_timer_text.left
            horizontalAlignment: Text.AlignRight
            verticalAlignment: Text.AlignVCenter
            anchors.rightMargin: 6
            font.pixelSize: 14
            style: Text.Outline
            styleColor: settings.color_glow
        }
    }
}
