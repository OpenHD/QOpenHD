import QtQuick 2.13
import QtQuick.Controls 2.13
import QtQuick.Layouts 1.13

import Qt.labs.settings 1.0

import OpenHD 1.0

import "../ui" as Ui

Rectangle {
    id: element2
    width: 504
    height: 300

    GroupBox {
        title: qsTr("OpenHD Telemetry")
        id: openhd_box

        width: (parent.width / 2) - 48

        anchors.top: parent.top
        anchors.topMargin: 24
        anchors.left: parent.left
        anchors.leftMargin: 24

        background: Rectangle {
            y: openhd_box.topPadding - openhd_box.bottomPadding
            width: parent.width
            height: parent.height - openhd_box.topPadding + openhd_box.bottomPadding
            color: "transparent"
            border.color: "black"
            radius: 2
        }

        label: Label {
            x: openhd_box.leftPadding
            width: openhd_box.availableWidth
            text: openhd_box.title
            color: "black"
            elide: Text.ElideRight
            font.pixelSize: 12
        }

        Label {
            color: "black"
            text: "last heartbeat: " + (OpenHDTelemetry.last_heartbeat !== undefined ? OpenHDTelemetry.last_heartbeat : "N/A")
            font.pixelSize: 12
        }
    }


    GroupBox {
        title: qsTr("Mavlink")
        id: mavlink_box

        width: (parent.width / 2) - 48

        anchors.top: parent.top
        anchors.topMargin: 24
        anchors.left: openhd_box.right
        anchors.leftMargin: 24

        background: Rectangle {
            y: mavlink_box.topPadding - mavlink_box.bottomPadding
            width: parent.width
            height: parent.height - mavlink_box.topPadding + mavlink_box.bottomPadding
            color: "transparent"
            border.color: "black"
            radius: 2
        }

        label: Label {
            x: mavlink_box.leftPadding
            width: mavlink_box.availableWidth
            text: mavlink_box.title
            color: "black"
            elide: Text.ElideRight
            font.pixelSize: 12
        }

        Label {
            color: "black"
            text: "last heartbeat: " + (MavlinkTelemetry.last_heartbeat !== undefined ? MavlinkTelemetry.last_heartbeat : "N/A")
            font.pixelSize: 12
        }
    }


    /*
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
        }*/
}
