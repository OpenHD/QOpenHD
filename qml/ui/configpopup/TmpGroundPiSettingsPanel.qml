import QtQuick 2.0

import QtQuick 2.12
import QtQuick.Controls 2.12
import QtQuick.Layouts 1.12
import QtQuick.Dialogs 1.0
import QtQuick.Controls.Material 2.12

import Qt.labs.settings 1.0

import OpenHD 1.0

import "../../ui" as Ui
import "../elements"

// Temporary dummy
Item {

    Layout.fillHeight: true
    Layout.fillWidth: true

    property int rowHeight: 64
    property int elementHeight: 48

    ScrollView {
        id: generalView
        width: parent.width
        height: parent.height
        contentHeight: 200
        visible: true

        clip: true

        Item {
            anchors.fill: parent

            Column {
                id: generalColumn
                spacing: 0
                anchors.left: parent.left
                anchors.right: parent.right


                Rectangle {
                    width: parent.width
                    height: rowHeight
                    visible: true

                    Text {
                        text: qsTr("Ping Result Air: ")+OpenHD.last_ping_result_openhd_air
                        font.weight: Font.Bold
                        font.pixelSize: 13
                        anchors.leftMargin: 8
                        verticalAlignment: Text.AlignVCenter
                        anchors.verticalCenter: parent.verticalCenter
                        width: 224
                        height: elementHeight
                        anchors.left: parent.left
                    }

                    Button {
                        width: 224
                        height: elementHeight
                        anchors.rightMargin: Qt.inputMethod.visible ? 96 : 36
                        anchors.right: parent.right
                        anchors.verticalCenter: parent.verticalCenter
                        text: qsTr("Ping Air")
                        onClicked: {
                            OpenHD.pingOpenHDUnit(true)
                        }
                    }
                }

                Rectangle {
                    width: parent.width
                    height: rowHeight
                    visible: true

                    Text {
                        text: qsTr("Ping Result Ground: ")+OpenHD.last_ping_result_openhd_ground
                        font.weight: Font.Bold
                        font.pixelSize: 13
                        anchors.leftMargin: 8
                        verticalAlignment: Text.AlignVCenter
                        anchors.verticalCenter: parent.verticalCenter
                        width: 224
                        height: elementHeight
                        anchors.left: parent.left
                    }

                    Button {
                        width: 224
                        height: elementHeight
                        anchors.rightMargin: Qt.inputMethod.visible ? 96 : 36
                        anchors.right: parent.right
                        anchors.verticalCenter: parent.verticalCenter
                        text: qsTr("Ping Ground")
                        onClicked: {
                            OpenHD.pingOpenHDUnit(false)
                        }
                    }
                }
            }
        }


    /*ListView {
        id: groundPiSettingsListView
        width: parent.width
        height: parent.height
        visible: true
        clip: true
        orientation: ListView.Vertical

        Item {
            anchors.fill: parent

            Column {
                id: manageColumnX
                spacing: 0
                anchors.left: parent.left
                anchors.right: parent.right

                Rectangle {
                    width: parent.width
                    height: 200
                    color: (Positioner.index % 2 == 0) ? "#8cbfd7f3" : "#00000000"
                    visible: true

                    Text {
                        text: qsTr("Ping Result Air: ")+OpenHD.last_ping_result_openhd_air
                        font.weight: Font.Bold
                        font.pixelSize: 13
                        anchors.leftMargin: 8
                        verticalAlignment: Text.AlignVCenter
                        anchors.verticalCenter: parent.verticalCenter
                        width: 224
                        height: 20
                        anchors.left: parent.left
                    }

                    Button {
                        width: 128
                        height: 60
                        anchors.rightMargin: Qt.inputMethod.visible ? 96 : 36

                        anchors.right: parent.right
                        anchors.verticalCenter: parent.verticalCenter
                        text: qsTr("Ping Air")
                        onClicked: {
                            OpenHD.pingOpenHDUnit(true)
                        }
                    }
                }
            }

            Column {
                id: manageColumnY
                spacing: 0
                anchors.left: parent.left
                anchors.right: parent.right

                Rectangle {
                    width: parent.width
                    height: 200
                    color: (Positioner.index % 2 == 0) ? "#8cbfd7f3" : "#00000000"
                    visible: true

                    Text {
                        text: qsTr("Ping Result Ground: ")+OpenHD.last_ping_result_openhd_ground
                        font.weight: Font.Bold
                        font.pixelSize: 13
                        anchors.leftMargin: 8
                        verticalAlignment: Text.AlignVCenter
                        anchors.verticalCenter: parent.verticalCenter
                        width: 224
                        height: 60
                        anchors.left: parent.left
                    }

                    Button {
                        width: 128
                        height: 40
                        anchors.rightMargin: Qt.inputMethod.visible ? 96 : 36

                        anchors.right: parent.right
                        anchors.verticalCenter: parent.verticalCenter
                        text: qsTr("Ping Ground")
                        onClicked: {
                            OpenHD.pingOpenHDUnit(true)
                        }
                    }
                }
            }
        }*/
    }
}
