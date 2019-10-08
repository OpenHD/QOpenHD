import QtQuick 2.13
import QtQuick.Controls 2.13
import QtQuick.Layouts 1.13

import Qt.labs.settings 1.0

import OpenHD 1.0

import "../ui" as Ui

GridLayout {
    width: 900
    height: 300
        columnSpacing: 8
        rows: 8
        columns: 8
        enabled: true


        Rectangle {
            id: openHDHeartbeatRow
            height: 32
            Layout.leftMargin: 0
            width: parent.width

            Layout.fillWidth: true
            Layout.rowSpan: 1
            Layout.columnSpan: 8

            Text {
                id: openHDHeartbeatText
                width: 192
                height: parent.height
                font.bold: true
                text: qsTr("Last OpenHD heartbeat:")
                anchors.left: parent.left
                anchors.leftMargin: 12
                verticalAlignment: Text.AlignVCenter
            }

            Text {
                id: openHDHeartbeatValue
                width: 128
                height: parent.height
                text: OpenHDTelemetry.last_heartbeat !== undefined ? OpenHDTelemetry.last_heartbeat : "N/A"
                horizontalAlignment: Text.AlignRight
                anchors.rightMargin: 12
                anchors.right: parent.right
                elide: Text.ElideRight
                verticalAlignment: Text.AlignVCenter
            }
        }

        Rectangle {
            id: mavlinkHeartbeatRow
            height: 32
            Layout.leftMargin: 0
            width: parent.width

            Layout.fillWidth: true
            Layout.rowSpan: 1
            Layout.columnSpan: 8

            Text {
                id: mavlinkHeartbeatText
                width: 192
                height: parent.height
                font.bold: true
                text: qsTr("Last Mavlink heartbeat:")
                anchors.left: parent.left
                anchors.leftMargin: 12
                verticalAlignment: Text.AlignVCenter
            }

            Text {
                id: mavlinkHeartbeatValue
                width: 128
                height: parent.height
                text: MavlinkTelemetry.last_heartbeat !== undefined ? MavlinkTelemetry.last_heartbeat : "N/A"
                horizontalAlignment: Text.AlignRight
                anchors.rightMargin: 12
                anchors.right: parent.right
                elide: Text.ElideRight
                verticalAlignment: Text.AlignVCenter
            }
        }

        Rectangle {
            id: gamepadRow
            height: 32
            Layout.leftMargin: 0
            width: parent.width

            Layout.fillWidth: true
            Layout.rowSpan: 1
            Layout.columnSpan: 8

            Text {
                id: gamepadText
                width: 192
                height: parent.height
                font.bold: true
                text: qsTr("Connected gamepad:")
                anchors.left: parent.left
                anchors.leftMargin: 12
                verticalAlignment: Text.AlignVCenter
            }

            Text {
                id: gamepadValue
                width: 128
                height: parent.height
                text: OpenHDRC.selectedGamepadName !== undefined ? OpenHDRC.selectedGamepadName : "N/A"
                horizontalAlignment: Text.AlignRight
                anchors.rightMargin: 12
                anchors.right: parent.right
                elide: Text.ElideRight
                verticalAlignment: Text.AlignVCenter
            }
        }
    }
