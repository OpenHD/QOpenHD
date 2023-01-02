import QtQuick 2.0

import QtQuick 2.12
import QtQuick.Window 2.0
import QtQuick.Controls 2.12
import QtQuick.Layouts 1.12
import QtQuick.Dialogs 1.0
import QtQuick.Controls.Material 2.12

import Qt.labs.settings 1.0

import OpenHD 1.0

import "../../ui" as Ui
import "../elements"


ScrollView {
    anchors.fill: parent
    clip:true
    ScrollBar.horizontal.policy: ScrollBar.AlwaysOff
    ScrollBar.vertical.policy: ScrollBar.AlwaysOff
    contentHeight: gridViewRaspberry.height+gridViewArducam.height+gridViewVeye.height+gridViewOther.height+250

    ColumnLayout {
        id: columnLayout
        x: 0
        y: 0
        width: parent.width
        height: maximumHeight
    }
    Card {
        id: infoBox
        y: 15
        height: 75
        anchors.left: parent.left
        anchors.leftMargin: 15
        anchors.right: parent.right
        anchors.rightMargin: 30
        Layout.fillWidth: true
        cardName: qsTr("  Camera Setup")
        cardBody:
                Text {
                    text: qsTr("     Here you can select the camera you want to use")
                    height: 24
                    font.pixelSize: 14
                }
    }
    Text {
        id: supplier1
        x: 15
        y: 115
        text: qsTr("Raspberry Cameras")
        font.pixelSize: 15
    }

    GridView {
        id: gridViewRaspberry
        x: 15
        y: supplier1.y+45
        width: columnLayout.width-15
        height: 150
        model: PiCameraConfigListOriginal {}
        highlight: Rectangle {
            color: "lightsteelblue"
            opacity: 0.7
            radius: 5
            focus:true
            clip: true
                }
                delegate: Column {
                    Image {
                        width: 120; height: 100
                        source: portrait; anchors.horizontalCenter: parent.horizontalCenter
                        MouseArea {
                        anchors.fill: parent
                            onClicked: {
                            console.log(aString)
                            }
                        }
                    }
                    property string aString: raspOverlay
                    Text { text: name; anchors.horizontalCenter: parent.horizontalCenter }
                }
                cellWidth: 130

    }

    Text {
        id: supplier2
        x: 15
        y: gridViewRaspberry.y+gridViewRaspberry.height
        text: qsTr("Arducam Cameras")
        font.pixelSize: 15
    }

    GridView {
        id: gridViewArducam
        x: 15
        y: gridViewRaspberry.y+gridViewRaspberry.height+30
        width: columnLayout.width
        height: 150
        model: PiCameraConfigListArducam {}
                delegate: Column {
                    Image {
                        width: 120; height: 100
                        source: portrait; anchors.horizontalCenter: parent.horizontalCenter
                        MouseArea {
                        anchors.fill: parent
                            onClicked: {
                            console.log(aString)
                            }
                        }
                    }
                    property string aString: raspOverlay
                    Text { text: name; anchors.horizontalCenter: parent.horizontalCenter }
                }
                cellWidth: 130
    }

    Text {
        id: supplier3
        x: 15
        y: gridViewArducam.y+gridViewArducam.height
        text: qsTr("Veye Imaging")
        font.pixelSize: 15
    }

    GridView {
        id: gridViewVeye
        x: 15
        y: gridViewArducam.y+gridViewArducam.height+30
        width: columnLayout.width-15
        height: 150
        model: PiCameraConfigListVeye {}
                delegate: Column {
                    Image {
                        width: 120; height: 100
                        source: portrait; anchors.horizontalCenter: parent.horizontalCenter
                        MouseArea {
                        anchors.fill: parent
                            onClicked: {
                            console.log(aString)
                            }
                        }
                    }
                    property string aString: raspOverlay
                    Text { text: name; anchors.horizontalCenter: parent.horizontalCenter }
                }
                cellWidth: 130
    }
    Text {
        id: supplier4
        x: 15
        y: gridViewVeye.y+gridViewVeye.height
        text: qsTr("Other Cameras")
        font.pixelSize: 15
    }
    GridView {
        id: gridViewOther
        x: 15
        y: gridViewVeye.y+gridViewVeye.height+30
        width: columnLayout.width-15
        height: 150
        model: PiCameraConfigListOther {}
                delegate: Column {
                    Image {
                        width: 120; height: 100
                        source: portrait; anchors.horizontalCenter: parent.horizontalCenter
                        MouseArea {
                        anchors.fill: parent
                            onClicked: {
                            console.log(aString)
                            }
                        }
                    }
                    property string aString: raspOverlay
                    Text { text: name; anchors.horizontalCenter: parent.horizontalCenter }
                }
                cellWidth: 130
    }

}
