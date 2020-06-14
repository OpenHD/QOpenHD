import QtQuick 2.12
import QtQuick.Controls 2.12
import QtQuick.Controls.Material 2.12
import QtQuick.Layouts 1.12
import QtQuick.Window 2.12

import Qt.labs.settings 1.0

import OpenHD 1.0


import "../ui" as Ui

Rectangle {
    property alias settings_popup: settings_popup
    property alias closeButton: closeButton
    property alias rebootButton: rebootButton

    id: settings_popup

    anchors.fill: parent

    z: 4.0

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

        Column {
            width: parent.width
            anchors.top: parent.top

            Text {
                id: appButton
                width: parent.width
                height: 48
                leftPadding: 12
                MouseArea {
                    id: appButtonMouseArea
                    anchors.fill: parent
                    onClicked: mainStackLayout.currentIndex = 0
                }
                text: qsTr("App")
                font.pixelSize: 15
                horizontalAlignment: Text.AlignLeft
                verticalAlignment: Text.AlignVCenter
                color: mainStackLayout.currentIndex == 0 ? "#33aaff" : "#333333"
            }

            Text {
                id: groundPiSettingsButton
                width: parent.width
                height: 48
                leftPadding: 12
                MouseArea {
                    id: groundPiSettingsButtonMouseArea
                    anchors.fill: parent
                    onClicked: mainStackLayout.currentIndex = 1
                }
                text: qsTr("Ground Pi")
                font.pixelSize: 15
                horizontalAlignment: Text.AlignLeft
                verticalAlignment: Text.AlignVCenter
                color: mainStackLayout.currentIndex == 1 ? "#33aaff" : "#333333"
            }

            Text {
                id: statusButton
                width: parent.width
                height: 48
                leftPadding: 12
                MouseArea {
                    id: statusSettingsButtonMouseArea
                    anchors.fill: parent
                    onClicked: mainStackLayout.currentIndex = 2
                }
                text: qsTr("Status")
                font.pixelSize: 15
                horizontalAlignment: Text.AlignLeft
                verticalAlignment: Text.AlignVCenter
                color: mainStackLayout.currentIndex == 2 ? "#33aaff" : "#333333"
            }

            Text {
                id: chartsButton
                visible: EnableCharts
                width: parent.width
                height: 48
                leftPadding: 12
                MouseArea {
                    id: chartsSettingsButtonMouseArea
                    anchors.fill: parent
                    onClicked: mainStackLayout.currentIndex = 3
                }
                text: qsTr("Charts")
                font.pixelSize: 15
                horizontalAlignment: Text.AlignLeft
                verticalAlignment: Text.AlignVCenter
                color: mainStackLayout.currentIndex == 3 ? "#33aaff" : "#333333"
            }

            Text {
                id: aboutButton
                width: parent.width
                height: 48
                leftPadding: 12
                MouseArea {
                    id: aboutButtonMouseArea
                    anchors.fill: parent
                    onClicked: mainStackLayout.currentIndex = 4
                }
                text: qsTr("About")
                font.pixelSize: 15
                horizontalAlignment: Text.AlignLeft
                verticalAlignment: Text.AlignVCenter
                color: mainStackLayout.currentIndex == 4 ? "#33aaff" : "#333333"
            }
        }



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
            enabled: !OpenHD.armed && !openHDSettings.saving
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


        AppSettingsPanel {
            id: appSettingsPanel
        }

        GroundPiSettingsPanel {
            id: groundPiSettingsPanel
        }

        StatusPanel {
            id: statusPanel
        }

        ChartsPanel {
            id: chartsPanel
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
