import QtQuick 2.12
import QtQuick.Controls 2.12
import QtQuick.Layouts 1.12
import QtGraphicalEffects 1.12
import Qt.labs.settings 1.0

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
    widgetDetailComponent: Column {
        Item {
            width: parent.width
            height: 24
            Text { text: "Lost:";  color: "white"; font.bold: true; font.pixelSize: detailPanelFontPixels; anchors.left: parent.left }
            Text {
                text: Number(OpenHD.lost_packet_cnt).toLocaleString(Qt.locale(), 'f', 0) + qsTr(" (%L1%)").arg(OpenHD.lost_packet_percent);
                color: "white";
                font.bold: true;
                font.pixelSize: detailPanelFontPixels;
                anchors.right: parent.right
            }
        }
        Item {
            width: parent.width
            height: 24
            Text { text: "Damaged:";  color: "white"; font.bold: true; font.pixelSize: detailPanelFontPixels; anchors.left: parent.left }
            Text {
                text: Number(OpenHD.damaged_block_cnt).toLocaleString(Qt.locale(), 'f', 0) + qsTr(" (%L1%)").arg(OpenHD.damaged_block_percent);
                color: "white";
                font.bold: true;
                font.pixelSize: detailPanelFontPixels;
                anchors.right: parent.right
            }
        }
        Item {
            width: parent.width
            height: 24
            Text { text: "CTS:";  color: "white"; font.bold: true; font.pixelSize: detailPanelFontPixels; anchors.left: parent.left }
            Text { text: OpenHD.cts; color: "white"; font.bold: true; font.pixelSize: detailPanelFontPixels; anchors.right: parent.right }
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
            color: "#ffffff"
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
            color: "#ffffff"
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
            color: "#ffffff"
            text: OpenHD.downlink_rssi
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
