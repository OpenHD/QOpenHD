import QtQuick 2.13
import QtQuick.Controls 2.13
import QtQuick.Controls.Material 2.13
import QtQuick.Layouts 1.13
import QtQuick.Window 2.13

import Qt.labs.settings 1.0

import OpenHD 1.0


import "../ui" as Ui

Popup {
    property alias save: groundPiSettingsPanel.save
    property alias settings_popup: settings_popup
    property alias closeButton: closeButton
    property alias rebootButton: rebootButton

    id: settings_popup
    parent: Overlay.overlay

    x: Math.round((Overlay.overlay.width - width) / 2)
    y: Math.round((Overlay.overlay.height - height) / 2)

    width: applicationWindow.width
    height: applicationWindow.height


    padding: 0
    rightPadding: 0
    bottomPadding: 0
    leftPadding: 0
    topPadding: 0
    margins: 0
    rightMargin: 0
    bottomMargin: 0
    leftMargin: 0
    topMargin: 0
    modal: true
    clip: true

    Rectangle {
        id: sidebar
        width: 132
        visible: true
        anchors.left: parent.left
        anchors.leftMargin: -1
        anchors.bottom: parent.bottom
        anchors.bottomMargin: -1
        anchors.top: parent.top
        anchors.topMargin: -1
        color: "#f6f6f6"
        radius: 0
        border.width: 1
        border.color: "#4c000000"

        clip: true

        Text {
            id: appButton
            y: 0
            width: parent.width
            height: 48
            anchors.top: parent.top
            leftPadding: 12
            MouseArea {
                id: appButtonMouseArea
                anchors.fill: parent
                onClicked: mainStackLayout.currentIndex = 0
            }
            text: "App"
            anchors.topMargin: 0
            anchors.right: parent.right
            anchors.rightMargin: 0
            anchors.left: parent.left
            anchors.leftMargin: 0
            font.pixelSize: 13
            horizontalAlignment: Text.AlignLeft
            verticalAlignment: Text.AlignVCenter
            color: mainStackLayout.currentIndex == 0 ? "#33aaff" : "#333333"
        }

        Text {
            id: groundPiSettingsButton
            y: 0
            width: parent.width
            height: 48
            anchors.top: appButton.bottom
            leftPadding: 12
            MouseArea {
                id: groundPiSettingsButtonMouseArea
                anchors.fill: parent
                onClicked: mainStackLayout.currentIndex = 1
            }
            text: "Ground Pi"
            anchors.topMargin: 0
            anchors.right: parent.right
            anchors.rightMargin: 0
            anchors.left: parent.left
            anchors.leftMargin: 0
            font.pixelSize: 13
            horizontalAlignment: Text.AlignLeft
            verticalAlignment: Text.AlignVCenter
            color: mainStackLayout.currentIndex == 1 ? "#33aaff" : "#333333"
        }

        Text {
            id: aboutButton
            y: 0
            width: parent.width
            height: 48
            anchors.top: groundPiSettingsButton.bottom
            leftPadding: 12
            MouseArea {
                id: aboutButtonMouseArea
                anchors.fill: parent
                onClicked: mainStackLayout.currentIndex = 2
            }
            text: "About"
            anchors.topMargin: 0
            anchors.right: parent.right
            anchors.rightMargin: 0
            anchors.left: parent.left
            anchors.leftMargin: 0
            font.pixelSize: 13
            horizontalAlignment: Text.AlignLeft
            verticalAlignment: Text.AlignVCenter
            color: mainStackLayout.currentIndex == 2 ? "#33aaff" : "#333333"
        }

        /*Text {
            id: statusButton
            y: 0
            width: parent.width
            height: 48
            anchors.top: aboutButton.bottom
            leftPadding: 12
            MouseArea {
                id: settingsButtonMouseArea
                anchors.fill: parent
                onClicked: mainStackLayout.currentIndex = 3
            }
            text: "Status"
            anchors.right: parent.right
            anchors.rightMargin: 0
            anchors.left: parent.left
            anchors.leftMargin: 0
            font.pixelSize: 13
            horizontalAlignment: Text.AlignLeft
            verticalAlignment: Text.AlignVCenter
            color: mainStackLayout.currentIndex == 3 ? "#33aaff" : "#333333"
        }*/

        Button {
            id: rebootButton
            y: 0
            height: 48
            leftPadding: 6
            text: qsTr("Reboot")
            anchors.bottom: closeButton.top
            anchors.bottomMargin: 6
            anchors.right: parent.right
            anchors.rightMargin: 12
            anchors.left: parent.left
            anchors.leftMargin: 12
            font.pixelSize: 13
            enabled: !openHDSettings.busy
            visible: OpenHDPi.is_raspberry_pi
        }

        Button {
            id: closeButton
            y: 0
            height: 48
            leftPadding: 6
            text: qsTr("Close")
            anchors.bottom: parent.bottom
            anchors.bottomMargin: 6
            anchors.right: parent.right
            anchors.rightMargin: 12
            anchors.left: parent.left
            anchors.leftMargin: 12
            font.pixelSize: 13
            enabled: !openHDSettings.busy
        }
    }


    StackLayout {
        id: mainStackLayout
        anchors.bottom: parent.bottom
        anchors.bottomMargin: 0
        anchors.right: parent.right
        anchors.rightMargin: 0
        anchors.left: sidebar.right
        anchors.leftMargin: 0
        anchors.top: parent.top
        anchors.topMargin: 0

        /*StatusPanel {
            id: statusPanel
        }*/

        AppSettingsPanel {
            id: appSettingsPanel
        }

        GroundPiSettingsPanel {
            id: groundPiSettingsPanel
        }

        AboutPanel {
            id: aboutPanel
        }
    }
}

/*##^##
Designer {
    D{i:2;anchors_height:480;anchors_width:376;anchors_x:0}D{i:3;anchors_x:0}D{i:4;anchors_height:360;anchors_width:99}
D{i:5;anchors_width:99}D{i:1;anchors_height:200;anchors_width:200}D{i:7;anchors_width:0}
D{i:8;anchors_width:400}D{i:9;anchors_width:0}D{i:6;anchors_height:360;anchors_width:400}
}
##^##*/
