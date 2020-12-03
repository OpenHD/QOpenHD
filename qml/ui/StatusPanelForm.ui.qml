import QtQuick 2.12
import QtQuick.Controls 2.12
import QtQuick.Layouts 1.12
import QtGraphicalEffects 1.12

import Qt.labs.settings 1.0

import OpenHD 1.0

import "../ui" as Ui

import "../ui/elements"

Rectangle {
    Layout.fillHeight: true
    Layout.fillWidth: true
    color: "#eaeaea"


    Rectangle {
        id: statusLog
        color: "#2a2a2a"

        anchors.top: parent.top
        anchors.topMargin: 12
        anchors.left: parent.left
        anchors.leftMargin: 12
        anchors.right: parent.right
        anchors.rightMargin: 12
        anchors.bottom: parent.bottom
        anchors.bottomMargin: 36

        StatusView {
            anchors.fill: parent
            clip: true
        }
    }

    Label {
        id: ohdLabel
        color: "black"
        text: qsTr("Last RSSI: ") + (OpenHD.last_openhd_heartbeat >= 0 && OpenHD.last_openhd_heartbeat <= 300000 ? OpenHD.last_openhd_heartbeat + "ms" : "N/A")
        font.pixelSize: 12
        anchors.bottom: parent.bottom
        anchors.left: parent.left
        anchors.bottomMargin: 12
        anchors.leftMargin: 24

        z: 1.1
    }

    Row {
        anchors.bottom: parent.bottom
        anchors.right: parent.right
        anchors.bottomMargin: 12
        anchors.rightMargin: 12
        spacing: 0

        Label {
            color: "black"
            text: qsTr("  HB: ") + (OpenHD.last_telemetry_heartbeat >= 0 && OpenHD.last_telemetry_heartbeat <= 300000 ? OpenHD.last_telemetry_heartbeat: "N/A")
            font.pixelSize: 12
            font.family: "monospace"
            width: 64
            z: 1.1
        }

        Label {
            color: "black"
            text: qsTr(" | ATT: ") + (OpenHD.last_telemetry_attitude >= 0 && OpenHD.last_telemetry_attitude <= 300000 ? OpenHD.last_telemetry_attitude: "N/A")
            font.pixelSize: 12
            font.family: "monospace"
            width: 64
            z: 1.1
        }

        Label {
            color: "black"
            text: qsTr(" | BAT: ") + (OpenHD.last_telemetry_battery >= 0 && OpenHD.last_telemetry_battery <= 300000 ? OpenHD.last_telemetry_battery: "N/A")
            font.pixelSize: 12
            font.family: "monospace"
            width: 64
            z: 1.1
        }

        Label {
            color: "black"
            text: qsTr(" | GPS: ") + (OpenHD.last_telemetry_gps >= 0 && OpenHD.last_telemetry_gps <= 300000 ? OpenHD.last_telemetry_gps: "N/A")
            font.pixelSize: 12
            font.family: "monospace"
            width: 64
            z: 1.1
        }

        Label {
            color: "black"
            text: qsTr(" | VFR: ") + (OpenHD.last_telemetry_vfr >= 0 && OpenHD.last_telemetry_vfr <= 300000 ? OpenHD.last_telemetry_vfr: "N/A")
            font.pixelSize: 12
            font.family: "monospace"
            width: 64
            z: 1.1
        }
    }
}
