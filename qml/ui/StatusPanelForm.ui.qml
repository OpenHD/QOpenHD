import QtQuick 2.12
import QtQuick.Controls 2.12
import QtQuick.Layouts 1.12

import Qt.labs.settings 1.0

import OpenHD 1.0

import "../ui" as Ui

Rectangle {
    id: element2
    width: 504
    height: 300

    Label {
        id: ohdLabel
        color: "black"
        text: "Last openhd telemetry: " + (openHDTelemetry.last_heartbeat !== undefined ? openHDTelemetry.last_heartbeat : "N/A")
        font.pixelSize: 12
        anchors.bottom: parent.bottom
        anchors.left: parent.left
        anchors.bottomMargin: 12
        anchors.leftMargin: 12

        z: 1.1
    }

    Label {
        id: mavLabel
        color: "black"
        text: "Last mavlink heartbeat: " + (mavlinkTelemetry.last_heartbeat !== undefined ? mavlinkTelemetry.last_heartbeat : "N/A")
        font.pixelSize: 12
        anchors.bottom: parent.bottom
        anchors.right: parent.right
        anchors.bottomMargin: 12
        anchors.rightMargin: 12

        z: 1.1
    }
}
