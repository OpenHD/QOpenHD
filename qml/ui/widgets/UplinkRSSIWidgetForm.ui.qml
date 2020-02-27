import QtQuick 2.12
import QtQuick.Controls 2.12
import QtQuick.Layouts 1.12
import QtGraphicalEffects 1.12
import Qt.labs.settings 1.0

import OpenHD 1.0

BaseWidget {
    id: uplinkRSSIWidget
    width: 92
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
            height: 24
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
    }

    Item {
        id: widgetInner

        anchors.fill: parent

        Text {
            id: uplink_icon
            y: 0
            width: 24
            height: 24
            color: settings.color_shape
            opacity: settings.uplink_rssi_opacity
            text: "\uf382"
            anchors.right: uplink_rssi.left
            anchors.rightMargin: 0
            font.family: "Font Awesome 5 Free"
            font.pixelSize: 14
            anchors.top: parent.top
            styleColor: "#f7f7f7"
            verticalAlignment: Text.AlignVCenter
            z: 2.2
            anchors.topMargin: 0
            horizontalAlignment: Text.AlignRight
        }

        Text {
            id: uplink_dbm
            x: 568
            y: 0
            width: 32
            height: 24
            color: settings.color_text
            opacity: settings.uplink_rssi_opacity
            text: "dBm"
            anchors.right: parent.right
            anchors.rightMargin: 0
            anchors.top: parent.top
            anchors.topMargin: 0
            horizontalAlignment: Text.AlignLeft
            font.pixelSize: 10
            verticalAlignment: Text.AlignTop
            wrapMode: Text.NoWrap
            elide: Text.ElideRight
            clip: false
        }

        Text {
            id: uplink_rssi
            x: 820
            y: 0
            width: 34
            height: 24
            color: settings.color_text
            opacity: settings.uplink_rssi_opacity
            text: OpenHD.current_signal_joystick_uplink == -127 ? qsTr("N/A") : OpenHD.current_signal_joystick_uplink
            anchors.right: uplink_dbm.left
            anchors.rightMargin: 2
            anchors.top: parent.top
            anchors.topMargin: 0
            horizontalAlignment: Text.AlignRight
            font.pixelSize: 14
            verticalAlignment: Text.AlignVCenter
            wrapMode: Text.NoWrap
            elide: Text.ElideRight
            clip: false
        }

        Text {
            id: uplink_lost_packet_cnt_rc
            x: 0
            y: 0
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
            horizontalAlignment: Text.AlignRight
            wrapMode: Text.NoWrap
            elide: Text.ElideRight
            clip: false
            visible: false
        }

        Text {
            id: uplink_lost_packet_cnt_telemetry_up
            x: 0
            y: 0
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
            verticalAlignment: Text.AlignVCenter
            wrapMode: Text.NoWrap
            elide: Text.ElideRight
            clip: false
            visible: false
        }
    }
}
