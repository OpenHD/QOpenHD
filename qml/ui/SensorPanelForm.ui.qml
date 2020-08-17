import QtQuick 2.12
import QtQuick.Controls 2.12
import QtQuick.Layouts 1.12
import QtQuick.Controls.Material 2.12

import Qt.labs.settings 1.0

import OpenHD 1.0

import "../ui" as Ui

import "../ui/elements"

Rectangle {
    Layout.fillHeight: true
    Layout.fillWidth: true

    color: "#eaeaea"

    Card {
        id: infoPanel
        anchors.left: parent.left
        anchors.leftMargin: 12
        anchors.right: parent.right
        anchors.rightMargin: 12
        anchors.top: parent.top
        anchors.topMargin: 12

        hasHeader: false
        height: infoColumn.height + 24

        cardBody: Column {
            id: infoColumn
            spacing: 12
            width: infoPanel.width

            Text {
                text: qsTr("If you have temperature or IMU sensors connected you may see and/or calibrate them below.")
                wrapMode: Text.WordWrap
                width: parent.width
                leftPadding: 12
                rightPadding: 12
                topPadding: 12
                font.pixelSize: 14
            }
        }
    }
}
