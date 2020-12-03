import QtQuick 2.12
import QtQuick.Controls 2.12
import QtQuick.Layouts 1.12
import QtGraphicalEffects 1.12
import Qt.labs.settings 1.0

import OpenHD 1.0

BaseWidget {
    id: uplinkRSSIWidget
    width: 112
    height:24

    visible: settings.show_uplink_rssi

    widgetIdentifier: "uplink_rssi_widget"

    defaultAlignment: 1
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
                id: uplink_rssi_opacity_Slider
                orientation: Qt.Horizontal
                from: .1
                value: settings.uplink_rssi_opacity
                to: 1
                stepSize: .1
                height: parent.height
                anchors.rightMargin: 0
                anchors.right: parent.right
                width: parent.width - 96

                onValueChanged: {
                    settings.uplink_rssi_opacity = uplink_rssi_opacity_Slider.value
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
                id: uplink_rssi_size_Slider
                orientation: Qt.Horizontal
                from: .5
                value: settings.uplink_rssi_size
                to: 3
                stepSize: .1
                height: parent.height
                anchors.rightMargin: 0
                anchors.right: parent.right
                width: parent.width - 96

                onValueChanged: {
                    settings.uplink_rssi_size = uplink_rssi_size_Slider.value
                }
            }
        }
    }

    Item {
        id: widgetInner

        anchors.fill: parent
        opacity: settings.uplink_rssi_opacity
        scale: settings.uplink_rssi_size

        Text {
            id: uplink_icon
            width: 24
            height: 24
            color: settings.color_shape
            text: "\uf382"
            anchors.left: parent.left
            anchors.leftMargin: 0
            anchors.top: parent.top
            anchors.topMargin: 0
            font.family: "Font Awesome 5 Free"
            font.pixelSize: 18
            verticalAlignment: Text.AlignVCenter           
            horizontalAlignment: Text.AlignRight
            style: Text.Outline
            styleColor: settings.color_glow
        }

        Text {
            id: uplink_rssi            
            height: 24
            color: settings.color_text

            text: OpenHD.current_signal_joystick_uplink == -127 ? qsTr("N/A") : OpenHD.current_signal_joystick_uplink
            anchors.left: uplink_icon.right
            anchors.leftMargin: 3
            anchors.top: parent.top
            horizontalAlignment: Text.AlignRight
            font.pixelSize: 18
            font.family: settings.font_text
            verticalAlignment: Text.AlignVCenter
            wrapMode: Text.NoWrap
            elide: Text.ElideNone
            clip: false
            style: Text.Outline
            styleColor: settings.color_glow
        }


        Text {
            id: uplink_dbm
            width: 32
            height: 24
            color: settings.color_text
            text: qsTr("dBm")
            anchors.left: uplink_rssi.right
            anchors.leftMargin: 2
            anchors.top: parent.top
            anchors.topMargin: 2
            horizontalAlignment: Text.AlignLeft
            font.pixelSize: 12
            font.family: settings.font_text
            verticalAlignment: Text.AlignTop
            wrapMode: Text.NoWrap
            elide: Text.ElideNone
            clip: false
            style: Text.Outline
            styleColor: settings.color_glow
        }

        Text {
            id: uplink_lost_packet_cnt_rc
            width: 64
            height: 24
            color: settings.color_text
            opacity: settings.uplink_rssi_opacity
            text: OpenHD.lost_packet_cnt_rc
            anchors.bottom: parent.bottom
            anchors.bottomMargin: 0
            anchors.right: uplink_lost_packet_cnt_telemetry_up.left
            anchors.rightMargin: 10
            verticalAlignment: Text.AlignVCenter
            font.pixelSize: 14
            font.family: settings.font_text
            horizontalAlignment: Text.AlignRight
            wrapMode: Text.NoWrap
            elide: Text.ElideNone
            clip: false
            visible: false
            style: Text.Outline
            styleColor: settings.color_glow
        }

        Text {
            id: uplink_lost_packet_cnt_telemetry_up
            width: 64
            height: 24
            color: settings.color_text
            opacity: settings.uplink_rssi_opacity
            text: OpenHD.lost_packet_cnt_telemetry_up
            anchors.bottom: parent.bottom
            anchors.bottomMargin: 0
            anchors.right: parent.right
            anchors.rightMargin: 8
            horizontalAlignment: Text.AlignLeft
            font.pixelSize: 14
            font.family: settings.font_text
            verticalAlignment: Text.AlignVCenter
            wrapMode: Text.NoWrap
            elide: Text.ElideRight
            clip: false
            visible: false
            style: Text.Outline
            styleColor: settings.color_glow
        }
    }
}
