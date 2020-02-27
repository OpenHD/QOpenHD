import QtQuick 2.12
import QtQuick.Controls 2.12
import QtQuick.Layouts 1.12
import QtGraphicalEffects 1.12
import Qt.labs.settings 1.0
import QtQuick.Shapes 1.0

import OpenHD 1.0

BaseWidget {
    id: downlinkRSSIWidget
    width: 92
    height:24

    visible: settings.show_downlink_rssi

    widgetIdentifier: "downlink_rssi_widget"

    defaultAlignment: 0
    defaultXOffset: 60
    defaultYOffset: 0
    defaultHCenter: false
    defaultVCenter: false


    hasWidgetDetail: true
    widgetDetailWidth: 256
    widgetDetailHeight: 320

    widgetDetailComponent: Column {
        Connections {
            target: OpenHD
            onWifi_adapter0_changed: {
                card0text.text = Number(wifi_adapter.current_signal_dbm).toLocaleString(Qt.locale(), 'f', 0) + qsTr(" dBm");
                card0.visible = true;
            }
            onWifi_adapter1_changed: {
                card1text.text = Number(wifi_adapter.current_signal_dbm).toLocaleString(Qt.locale(), 'f', 0) + qsTr(" dBm");
                card1.visible = true;
            }
            onWifi_adapter2_changed: {
                card2text.text = Number(wifi_adapter.current_signal_dbm).toLocaleString(Qt.locale(), 'f', 0) + qsTr(" dBm");
                card2.visible = true;
            }
            onWifi_adapter3_changed: {
                card3text.text = Number(wifi_adapter.current_signal_dbm).toLocaleString(Qt.locale(), 'f', 0) + qsTr(" dBm");
                card3.visible = true;
            }
            onWifi_adapter4_changed: {
                card4text.text = Number(wifi_adapter.current_signal_dbm).toLocaleString(Qt.locale(), 'f', 0) + qsTr(" dBm");
                card4.visible = true;
            }
            onWifi_adapter5_changed: {
                card5text.text = Number(wifi_adapter.current_signal_dbm).toLocaleString(Qt.locale(), 'f', 0) + qsTr(" dBm");
                card5.visible = true;
            }
        }
        Item {
            id: card0
            visible: false
            width: parent.width
            height: 32
            Text {
                text: "Card 1:"
                color: "white"
                font.bold: true
                height: parent.height
                font.pixelSize: detailPanelFontPixels
                anchors.left: parent.left
                verticalAlignment: Text.AlignVCenter
            }
            Text {
                id: card0text
                color: "white";
                font.bold: true;
                height: parent.height
                font.pixelSize: detailPanelFontPixels;
                anchors.right: parent.right
                verticalAlignment: Text.AlignVCenter
            }
        }
        Item {
            id: card1
            visible: false
            width: parent.width
            height: 32
            Text {
                text: "Card 2:"
                color: "white"
                font.bold: true
                height: parent.height;
                font.pixelSize: detailPanelFontPixels
                anchors.left: parent.left
                verticalAlignment: Text.AlignVCenter
            }
            Text {
                id: card1text
                color: "white";
                font.bold: true;
                height: parent.height
                font.pixelSize: detailPanelFontPixels;
                anchors.right: parent.right
                verticalAlignment: Text.AlignVCenter
            }
        }

        Item {
            id: card2
            visible: false
            width: parent.width
            height: 24
            Text {
                text: "Card 3:"
                color: "white"
                font.bold: true
                height: parent.height;
                font.pixelSize: detailPanelFontPixels
                anchors.left: parent.left
                verticalAlignment: Text.AlignVCenter
            }
            Text {
                id: card2text
                color: "white";
                font.bold: true;
                height: parent.height;
                font.pixelSize: detailPanelFontPixels;
                anchors.right: parent.right
                verticalAlignment: Text.AlignVCenter
            }
        }

        Item {
            id: card3
            visible: false
            width: parent.width
            height: 24
            Text {
                text: "Card 4:"
                color: "white"
                font.bold: true
                height: parent.height
                font.pixelSize: detailPanelFontPixels
                anchors.left: parent.left
                verticalAlignment: Text.AlignVCenter
            }
            Text {
                id: card3text
                color: "white";
                font.bold: true;
                height: parent.height;
                font.pixelSize: detailPanelFontPixels;
                anchors.right: parent.right
                verticalAlignment: Text.AlignVCenter
            }
        }

        Item {
            id: card4
            visible: false
            width: parent.width
            height: 24
            Text {
                text: "Card 5:"
                color: "white"
                font.bold: true
                height: parent.height
                font.pixelSize: detailPanelFontPixels
                anchors.left: parent.left
                verticalAlignment: Text.AlignVCenter
            }
            Text {
                id: card4text
                color: "white";
                font.bold: true;
                height: parent.height;
                font.pixelSize: detailPanelFontPixels;
                anchors.right: parent.right
                verticalAlignment: Text.AlignVCenter
            }
        }

        Item {
            id: card5
            visible: false
            width: parent.width
            height: 24
            Text {
                text: "Card 6:"
                color: "white"
                font.bold: true
                height: parent.height
                font.pixelSize: detailPanelFontPixels
                anchors.left: parent.left
                verticalAlignment: Text.AlignVCenter
            }
            Text {
                id: card5text
                color: "white";
                font.bold: true;
                height: parent.height
                font.pixelSize: detailPanelFontPixels;
                anchors.right: parent.right
                verticalAlignment: Text.AlignVCenter
            }
        }


        Shape {
            id: line
            height: 32
            width: parent.width

            ShapePath {
                strokeColor: "white"
                strokeWidth: 2
                strokeStyle: ShapePath.SolidLine
                fillColor: "transparent"
                startX: 0
                startY: line.height / 2
                PathLine { x: 0;          y: line.height / 2 }
                PathLine { x: line.width; y: line.height / 2 }
            }
        }

        Item {
            width: parent.width
            height: 32
            Text {
                text: "Lost:"
                color: "white"
                font.bold: true
                height: parent.height
                font.pixelSize: detailPanelFontPixels
                anchors.left: parent.left
                verticalAlignment: Text.AlignVCenter
            }
            Text {
                text: Number(OpenHD.lost_packet_cnt).toLocaleString(Qt.locale(), 'f', 0) + qsTr(" (%L1%)").arg(OpenHD.lost_packet_percent);
                color: "white";
                font.bold: true;
                height: parent.height
                font.pixelSize: detailPanelFontPixels;
                anchors.right: parent.right
                verticalAlignment: Text.AlignVCenter
            }
        }
        Item {
            width: parent.width
            height: 32
            Text {
                text: "Damaged:"
                color: "white"
                font.bold: true
                height: parent.height
                font.pixelSize: detailPanelFontPixels
                anchors.left: parent.left
                verticalAlignment: Text.AlignVCenter
            }
            Text {
                text: Number(OpenHD.damaged_block_cnt).toLocaleString(Qt.locale(), 'f', 0) + qsTr(" (%L1%)").arg(OpenHD.damaged_block_percent);
                color: "white";
                font.bold: true;
                height: parent.height
                font.pixelSize: detailPanelFontPixels;
                anchors.right: parent.right
                verticalAlignment: Text.AlignVCenter
            }
        }
        Item {
            width: parent.width
            height: 32
            Text {
                text: "CTS:"
                color: "white"
                font.bold: true
                height: parent.height
                font.pixelSize: detailPanelFontPixels
                anchors.left: parent.left
                verticalAlignment: Text.AlignVCenter
            }
            Text {
                text: OpenHD.cts
                color: "white"
                font.bold: true
                height: parent.height
                font.pixelSize: detailPanelFontPixels
                anchors.right: parent.right
                verticalAlignment: Text.AlignVCenter
            }
        }

        Shape {
            id: line2
            height: 32
            width: parent.width

            ShapePath {
                strokeColor: "white"
                strokeWidth: 2
                strokeStyle: ShapePath.SolidLine
                fillColor: "transparent"
                startX: 0
                startY: line2.height / 2
                PathLine { x: 0;           y: line2.height / 2 }
                PathLine { x: line2.width; y: line2.height / 2 }
            }
        }
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
                id: downlink_rssi_opacity_Slider
                orientation: Qt.Horizontal
                from: .1
                value: settings.downlink_rssi_opacity
                to: 1
                stepSize: .1
                height: parent.height
                anchors.rightMargin: 0
                anchors.right: parent.right
                width: parent.width - 96

                onValueChanged: {
                    settings.downlink_rssi_opacity = downlink_rssi_opacity_Slider.value
                }
            }
        }
    }

    Item {
        id: widgetInner

        anchors.fill: parent

        Text {
            id: downlink_icon
            y: 0
            width: 24
            height: 24
            color: settings.color_shape
            opacity: settings.downlink_rssi_opacity
            text: "\uf381"
            anchors.left: parent.left
            anchors.leftMargin: 0
            anchors.top: parent.top
            anchors.topMargin: 0
            verticalAlignment: Text.AlignVCenter
            font.family: "Font Awesome 5 Free"
            styleColor: "#f7f7f7"
            font.pixelSize: 14
            horizontalAlignment: Text.AlignRight
        }

        Text {
            id: primary_radio_dbm
            width: 32
            height: 24
            color: settings.color_text
            opacity: settings.downlink_rssi_opacity
            text: "dBm"
            anchors.left: downlink_rssi.right
            anchors.leftMargin: 2
            anchors.top: parent.top
            anchors.topMargin: 0
            verticalAlignment: Text.AlignTop
            font.pixelSize: 10
            horizontalAlignment: Text.AlignLeft
            wrapMode: Text.NoWrap
            elide: Text.ElideRight
            clip: false
        }

        Text {
            id: downlink_rssi
            width: 34
            height: 24
            color: settings.color_text
            opacity: settings.downlink_rssi_opacity
            text: OpenHD.downlink_rssi == -127 ? qsTr("N/A") : OpenHD.downlink_rssi
            anchors.left: downlink_icon.right
            anchors.leftMargin: 0
            anchors.top: parent.top
            anchors.topMargin: 0
            verticalAlignment: Text.AlignVCenter
            font.pixelSize: 14
            horizontalAlignment: Text.AlignRight
            wrapMode: Text.NoWrap
            elide: Text.ElideRight
            clip: true
        }
    }
}
