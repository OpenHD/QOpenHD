import QtQuick 2.13
import QtQuick.Controls 2.13
import QtQuick.Layouts 1.13
import QtGraphicalEffects 1.13
import Qt.labs.settings 1.0

import OpenHD 1.0

Rectangle {
    id: horizonWidget
    width: 200
    height:1
    anchors.centerIn: parent
    transformOrigin: Item.Center
    color: "white"
    rotation: MavlinkTelemetry.roll_raw
    antialiasing: true

    Rectangle {
        width: 1
        height: 12
        anchors.left: parent.right
        anchors.verticalCenter: parent.verticalCenter
    }

    Rectangle {
        width: 1
        height: 12
        anchors.right: parent.left
        anchors.verticalCenter: parent.verticalCenter
    }
}
