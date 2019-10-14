import QtQuick 2.13
import QtQuick.Controls 2.13
import QtQuick.Layouts 1.13
import QtGraphicalEffects 1.13
import Qt.labs.settings 1.0

import OpenHD 1.0

Item {    
    id: bitrateWidget
    width: 104
    height: 24

    Text {
        id: kbitrate
        y: 0
        width: 84
        height: 24
        color: "#ffffff"
        text: OpenHDTelemetry.kbitrate
        anchors.verticalCenterOffset: 0
        anchors.left: camera_icon.right
        anchors.leftMargin: 6
        anchors.verticalCenter: parent.verticalCenter
        verticalAlignment: Text.AlignTop
        elide: Text.ElideRight
        wrapMode: Text.NoWrap
        clip: false
        horizontalAlignment: Text.AlignLeft
        font.pixelSize: 14
    }

    Text {
        id: camera_icon
        y: 0
        width: 24
        height: 24
        color: "#ffffff"
        text: "\uf03d"
        anchors.left: parent.left
        anchors.leftMargin: 0
        verticalAlignment: Text.AlignTop
        font.family: "Font Awesome 5 Free"
        styleColor: "#f7f7f7"
        font.pixelSize: 16
        horizontalAlignment: Text.AlignRight
    }
}
