import QtQuick 2.13
import QtQuick.Controls 2.13
import QtQuick.Layouts 1.13
import QtGraphicalEffects 1.13
import Qt.labs.settings 1.0

import OpenHD 1.0

Item {
    id: flightModeWidget
    width: 184
    height: 48

    Text {
        id: flight_mode_icon
        width: 48
        height: 48
        color: "#ffffff"
        text: "\uf072"
        anchors.left: parent.left
        anchors.leftMargin: 0
        anchors.verticalCenter: parent.verticalCenter
        font.family: "Font Awesome 5 Free"
        horizontalAlignment: Text.AlignRight
        verticalAlignment: Text.AlignVCenter
        font.pixelSize: 20
    }

    Text {
        id: flight_mode_text

        width: 184
        height: 48
        color: "#ffffff"
        text: MavlinkTelemetry.flight_mode
        anchors.verticalCenter: parent.verticalCenter
        anchors.left: flight_mode_icon.right
        anchors.leftMargin: 8
        verticalAlignment: Text.AlignVCenter
        horizontalAlignment: Text.AlignLeft
        font.pixelSize: 24
        elide: Text.ElideMiddle
    }
}
