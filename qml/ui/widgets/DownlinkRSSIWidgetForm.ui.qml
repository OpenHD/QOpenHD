import QtQuick 2.13
import QtQuick.Controls 2.13
import QtQuick.Layouts 1.13
import QtGraphicalEffects 1.13
import Qt.labs.settings 1.0

import OpenHD 1.0

Item {    
    id: downlinkRSSIWidget
    width: 184
    height:24

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
        text: OpenHDTelemetry.downlink_rssi
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
