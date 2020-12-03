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

    id: settings_popup

    anchors.fill: parent

    z: 4.0

    MouseArea {
        anchors.fill: parent
        propagateComposedEvents: false
    }

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
        color: "#333c4c"
        radius: 0
        border.width: 1
        border.color: "#4c000000"

        clip: true

        Column {
            width: parent.width
            anchors.top: parent.top

            Item {
                height: 48
                width: parent.width

                MouseArea {
                    id: appButtonMouseArea
                    anchors.fill: parent
                    onClicked: mainStackLayout.currentIndex = 0
                }

                Text {
                    id: appIcon
                    text: "\uf013"
                    horizontalAlignment: Text.AlignHCenter
                    verticalAlignment: Text.AlignVCenter
                    font.family: "Font Awesome 5 Free"
                    font.pixelSize: 18
                    height: parent.height
                    width: 24
                    anchors.left: parent.left
                    anchors.leftMargin: 12

                    color: "#dde4ed"

                }

                Text {
                    id: appButton
                    height: parent.height
                    anchors.left: appIcon.right
                    anchors.leftMargin: 6

                    text: qsTr("App")
                    font.pixelSize: 15
                    horizontalAlignment: Text.AlignLeft
                    verticalAlignment: Text.AlignVCenter
                    color: mainStackLayout.currentIndex == 0 ? "#33aaff" : "#dde4ed"
                }
            }

            Item {
                height: 48
                width: parent.width
                MouseArea {
                    id: groundButtonMouseArea
                    anchors.fill: parent
                    onClicked: mainStackLayout.currentIndex = 1
                }

                Text {
                    id: groundIcon
                    text: "\uf085"
                    horizontalAlignment: Text.AlignHCenter
                    verticalAlignment: Text.AlignVCenter
                    font.family: "Font Awesome 5 Free"
                    font.pixelSize: 18
                    height: parent.height
                    width: 24
                    anchors.left: parent.left
                    anchors.leftMargin: 12

                    color: "#dde4ed"

                }

                Text {
                    id: groundButton
                    height: parent.height
                    anchors.left: groundIcon.right
                    anchors.leftMargin: 6

                    text: qsTr("Ground")
                    font.pixelSize: 15
                    horizontalAlignment: Text.AlignLeft
                    verticalAlignment: Text.AlignVCenter
                    color: mainStackLayout.currentIndex == 1 ? "#33aaff" : "#dde4ed"
                }
            }

            Item {
                height: 48
                width: parent.width
                MouseArea {
                    id: statusButtonMouseArea
                    anchors.fill: parent
                    onClicked: mainStackLayout.currentIndex = 2
                }

                Text {
                    id: statusIcon
                    text: "\uf0c9"
                    horizontalAlignment: Text.AlignHCenter
                    verticalAlignment: Text.AlignVCenter
                    font.family: "Font Awesome 5 Free"
                    font.pixelSize: 18
                    height: parent.height
                    width: 24
                    anchors.left: parent.left
                    anchors.leftMargin: 12

                    color: "#dde4ed"

                }

                Text {
                    id: statusButton
                    height: parent.height
                    anchors.left: statusIcon.right
                    anchors.leftMargin: 6

                    text: qsTr("Status")
                    font.pixelSize: 15
                    horizontalAlignment: Text.AlignLeft
                    verticalAlignment: Text.AlignVCenter
                    color: mainStackLayout.currentIndex == 2 ? "#33aaff" : "#dde4ed"
                }
            }

            Item {
                height: 48
                width: parent.width
                visible: false
                MouseArea {
                    id: chartsButtonMouseArea
                    anchors.fill: parent
                    onClicked: mainStackLayout.currentIndex = 3
                }

                Text {
                    id: chartsIcon
                    text: "\uf201"
                    horizontalAlignment: Text.AlignHCenter
                    verticalAlignment: Text.AlignVCenter
                    font.family: "Font Awesome 5 Free"
                    font.pixelSize: 18
                    height: parent.height
                    width: 24
                    anchors.left: parent.left
                    anchors.leftMargin: 12

                    color: "#dde4ed"

                }

                Text {
                    id: chartsButton
                    height: parent.height
                    anchors.left: chartsIcon.right
                    anchors.leftMargin: 6

                    text: qsTr("Charts")
                    font.pixelSize: 15
                    horizontalAlignment: Text.AlignLeft
                    verticalAlignment: Text.AlignVCenter
                    color: mainStackLayout.currentIndex == 3 ? "#33aaff" : "#dde4ed"
                }
            }

            Item {
                height: 48
                width: parent.width
                MouseArea {
                    id: powerButtonMouseArea
                    anchors.fill: parent
                    onClicked: mainStackLayout.currentIndex = 4
                }

                Text {
                    id: powerIcon
                    text: "\uf011"
                    horizontalAlignment: Text.AlignHCenter
                    verticalAlignment: Text.AlignVCenter
                    font.family: "Font Awesome 5 Free"
                    font.pixelSize: 18
                    height: parent.height
                    width: 24
                    anchors.left: parent.left
                    anchors.leftMargin: 12

                    color: "#dde4ed"

                }

                Text {
                    id: powerButton
                    height: parent.height
                    anchors.left: powerIcon.right
                    anchors.leftMargin: 6

                    text: qsTr("Power")
                    font.pixelSize: 15
                    horizontalAlignment: Text.AlignLeft
                    verticalAlignment: Text.AlignVCenter
                    color: mainStackLayout.currentIndex == 4 ? "#33aaff" : "#dde4ed"
                }
            }


            Item {
                height: 48
                width: parent.width
                visible: false
                MouseArea {
                    id: sensorsButtonMouseArea
                    anchors.fill: parent
                    onClicked: mainStackLayout.currentIndex = 5
                }

                Text {
                    id: sensorsIcon
                    text: "\uf2c9"
                    horizontalAlignment: Text.AlignHCenter
                    verticalAlignment: Text.AlignVCenter
                    font.family: "Font Awesome 5 Free"
                    font.pixelSize: 18
                    height: parent.height
                    width: 24
                    anchors.left: parent.left
                    anchors.leftMargin: 12

                    color: "#dde4ed"

                }

                Text {
                    id: sensorsButton
                    height: parent.height
                    anchors.left: sensorsIcon.right
                    anchors.leftMargin: 6

                    text: qsTr("Sensors")
                    font.pixelSize: 15
                    horizontalAlignment: Text.AlignLeft
                    verticalAlignment: Text.AlignVCenter
                    color: mainStackLayout.currentIndex == 5 ? "#33aaff" : "#dde4ed"
                }
            }

            Item {
                height: 48
                width: parent.width
                MouseArea {
                    id: aboutButtonMouseArea
                    anchors.fill: parent
                    onClicked: mainStackLayout.currentIndex = 6
                }

                Text {
                    id: aboutIcon
                    text: "\uf05a"
                    horizontalAlignment: Text.AlignHCenter
                    verticalAlignment: Text.AlignVCenter
                    font.family: "Font Awesome 5 Free"
                    font.pixelSize: 18
                    height: parent.height
                    width: 24
                    anchors.left: parent.left
                    anchors.leftMargin: 12

                    color: "#dde4ed"

                }

                Text {
                    id: aboutButton
                    height: parent.height
                    anchors.left: aboutIcon.right
                    anchors.leftMargin: 6

                    text: qsTr("About")
                    font.pixelSize: 15
                    horizontalAlignment: Text.AlignLeft
                    verticalAlignment: Text.AlignVCenter
                    color: mainStackLayout.currentIndex == 6 ? "#33aaff" : "#dde4ed"
                }
            }
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

        PowerPanel {
            id: powerPanel
        }

        SensorPanel {
            id: sensorPanel
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
