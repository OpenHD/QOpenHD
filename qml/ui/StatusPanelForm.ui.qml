import QtQuick 2.12
import QtQuick.Controls 2.12
import QtQuick.Layouts 1.12

import Qt.labs.settings 1.0

import OpenHD 1.0

import "../ui" as Ui

import "../ui/elements"

Item {
    id: element2
    Layout.fillHeight: true
    Layout.fillWidth: true

    Text {
        text: qsTr("OpenHD Status Log")
        font.pixelSize: 16
        font.bold: true
        color: "#515151"

        anchors.top: parent.top
        anchors.topMargin: 12
        anchors.left: parent.left
        anchors.leftMargin: 24
    }

    Rectangle {
        color: "#ff2a2a2a"
        border.width: 1
        border.color: "white"
        clip: true

        anchors.top: parent.top
        anchors.topMargin: 48
        anchors.left: parent.left
        anchors.leftMargin: 24
        anchors.right: parent.right
        anchors.rightMargin: 24
        anchors.bottom: parent.bottom
        anchors.bottomMargin: 36

        StatusView {
            anchors.fill: parent
        }
    }

    Label {
        id: ohdLabel
        color: "black"
        text: qsTr("Last openhd heartbeat: ") + (OpenHD.last_openhd_heartbeat >= 0 && OpenHD.last_openhd_heartbeat <= 300000 ? OpenHD.last_openhd_heartbeat + "ms" : "N/A")
        font.pixelSize: 12
        anchors.bottom: parent.bottom
        anchors.left: parent.left
        anchors.bottomMargin: 12
        anchors.leftMargin: 24

        z: 1.1
    }

    Label {
        id: mavLabel
        color: "black"
        text: qsTr("Last telemetry heartbeat: ") + (OpenHD.last_telemetry_heartbeat >= 0 && OpenHD.last_telemetry_heartbeat <= 300000 ? OpenHD.last_telemetry_heartbeat  + "ms": "N/A")
        font.pixelSize: 12
        anchors.bottom: parent.bottom
        anchors.right: parent.right
        anchors.bottomMargin: 12
        anchors.rightMargin: 142

        z: 1.1
    }
}
