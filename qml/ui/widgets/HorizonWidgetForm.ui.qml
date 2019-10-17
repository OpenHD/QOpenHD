import QtQuick 2.13
import QtQuick.Controls 2.13
import QtQuick.Layouts 1.13
import QtGraphicalEffects 1.13
import Qt.labs.settings 1.0

import OpenHD 1.0

Rectangle {
    id: horizonWidget
    width: 0
    height: 0
    anchors.centerIn: parent
    transformOrigin: Item.Center
    rotation: MavlinkTelemetry.roll_raw
    transform: Translate {
        x: Item.Center
        y: MavlinkTelemetry.pitch_raw
    }
    antialiasing: true

    Rectangle {
        width: 100
        height: 2
        anchors.left: parent.left
        anchors.verticalCenter: parent.verticalCenter
        color: "white"
        anchors.leftMargin: 25
    }

    Rectangle {
        width: 100
        height: 2
        anchors.right: parent.right
        anchors.verticalCenter: parent.verticalCenter
        color: "white"
        anchors.rightMargin: 25
    }
}
