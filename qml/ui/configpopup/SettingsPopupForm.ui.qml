import QtQuick 2.12
import QtQuick.Controls 2.12
import QtQuick.Controls.Material 2.12
import QtQuick.Layouts 1.12
import QtQuick.Window 2.12

import Qt.labs.settings 1.0

import OpenHD 1.0


import "../../ui" as Ui
import "../elements"

// We use a stack layout here, but the row on the left (that selects the items inside the stack layout) is custom
// (Becasue of the immages I assume, TODO clean this up / use proper layouting)
Rectangle {
    property alias settings_popup: settings_popup
    property alias closeButton: closeButton
    property int eeInt : 0

    id: settings_popup

    anchors.fill: parent

    z: 4.0

    MouseArea {
        anchors.fill: parent
        propagateComposedEvents: false
    }

    // This is the settings row on the left. When an item is clicked, the stack layout index is changed which
    // means a different category is displayed.
    // NOTE: when changing the n of elements in the panel, remember to change the indices
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

            // QOpenHD Settings
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

                    text: qsTr("QOpenHD")
                    font.pixelSize: 15
                    horizontalAlignment: Text.AlignLeft
                    verticalAlignment: Text.AlignVCenter
                    color: mainStackLayout.currentIndex == 0 ? "#33aaff" : "#dde4ed"
                }
            }
            // OpenHD Settings
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

                    text: qsTr("OpenHD")
                    font.pixelSize: 15
                    horizontalAlignment: Text.AlignLeft
                    verticalAlignment: Text.AlignVCenter
                    color: mainStackLayout.currentIndex == 1 ? "#33aaff" : "#dde4ed"
                }
            }

            // Log
            Item {
                height: 48
                width: parent.width
                visible: true
                MouseArea {
                    id: logButtonMouseArea
                    anchors.fill: parent
                    onClicked: mainStackLayout.currentIndex = 2
                }

                Text {
                    id: logIcon
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
                    id: logButton
                    height: parent.height
                    anchors.left: logIcon.right
                    anchors.leftMargin: 6

                    text: qsTr("Log")
                    font.pixelSize: 15
                    horizontalAlignment: Text.AlignLeft
                    verticalAlignment: Text.AlignVCenter
                    color: mainStackLayout.currentIndex == 2 ? "#33aaff" : "#dde4ed"
                }
            }
            // Graphs
            /*Item {
                height: 48
                width: parent.width
                MouseArea {
                    id: graphButtonMouseArea
                    anchors.fill: parent
                    onClicked: mainStackLayout.currentIndex = 3
                }

                Text {
                    id: graphIcon
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
                    id: graphButton
                    height: parent.height
                    anchors.left: graphIcon.right
                    anchors.leftMargin: 6
                    text: qsTr("Graphs")
                    font.pixelSize: 15
                    horizontalAlignment: Text.AlignLeft
                    verticalAlignment: Text.AlignVCenter
                    color: mainStackLayout.currentIndex == 3 ? "#33aaff" : "#dde4ed"
                }
            }*/

            // Power
            Item {
                height: 48
                width: parent.width
                MouseArea {
                    id: powerButtonMouseArea
                    anchors.fill: parent
                    onClicked: mainStackLayout.currentIndex = 3
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
                    color: mainStackLayout.currentIndex == 3 ? "#33aaff" : "#dde4ed"
                }
            }



            // About
            Item {
                height: 48
                width: parent.width
                MouseArea {
                    id: aboutButtonMouseArea
                    anchors.fill: parent
                    onClicked: {
                        mainStackLayout.currentIndex = 4
                        if (eeInt > 8){
                            eeItem.visible = true
                            eeInt = 0
                        }
                        else{
                            eeItem.visible = false
                            eeInt = eeInt+1

                        }

                    }
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
                    color: mainStackLayout.currentIndex == 4 ? "#33aaff" : "#dde4ed"
                }
            }

            // Developer stats
            Item {
                height: 48
                width: parent.width
                MouseArea {
                    id: developerStatsButtonMouseArea
                    anchors.fill: parent
                    onClicked: mainStackLayout.currentIndex = 5
                }

                Text {
                    id: developerStatsIcon
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
                    id: developerStatsButton
                    height: parent.height
                    anchors.left: developerStatsIcon.right
                    anchors.leftMargin: 6

                    text: qsTr("DEV")
                    font.pixelSize: 15
                    horizontalAlignment: Text.AlignLeft
                    verticalAlignment: Text.AlignVCenter
                    color: mainStackLayout.currentIndex == 5 ? "#33aaff" : "#dde4ed"
                }
            }
            // RC
            Item {
                height: 48
                width: parent.width
                MouseArea {
                    id: rcButtonMouseArea
                    anchors.fill: parent
                    onClicked: mainStackLayout.currentIndex = 6
                }

                Text {
                    id: rcIcon
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
                    id: rcButton
                    height: parent.height
                    anchors.left: rcIcon.right
                    anchors.leftMargin: 6

                    text: qsTr("RC")
                    font.pixelSize: 15
                    horizontalAlignment: Text.AlignLeft
                    verticalAlignment: Text.AlignVCenter
                    color: mainStackLayout.currentIndex == 6 ? "#33aaff" : "#dde4ed"
                }
            }

            Item {
                id: eeItem
                visible: false
                height: 48
                width: parent.width
                MouseArea {
                    id: eeButtonMouseArea
                    anchors.fill: parent
                    onClicked: mainStackLayout.currentIndex = 7
                }

                Text {
                    id: eeIcon
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
                    id: eeButton
                    height: parent.height
                    anchors.left: eeIcon.right
                    anchors.leftMargin: 6

                    text: qsTr("EasterEgg")
                    font.pixelSize: 15
                    horizontalAlignment: Text.AlignLeft
                    verticalAlignment: Text.AlignVCenter
                    color: mainStackLayout.currentIndex == 7 ? "#33aaff" : "#dde4ed"
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

        LogMessagesStatusView{
            id: logMessagesStatusView
        }

        // In legacy for now
        //TelemetryGraphViewPanel{
        //    id: statusPanel
        //}

        PowerPanel {
            id: powerPanel
        }

        AboutPanel {
            id: aboutPanel
        }

        AppDeveloperStatsPanel {
            id: appDeveloperStatsPanel
        }

        RcInfoPanel2 {
            id: rcInfoPanel
        }
        EasterEggPanel {
            id: eePanel
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
