import QtQuick 2.0

import QtQuick 2.12
import QtQuick.Controls 2.12
import QtQuick.Layouts 1.12
import QtQuick.Dialogs 1.0
import QtQuick.Controls.Material 2.12

import Qt.labs.settings 1.0

import OpenHD 1.0
import MavlinkTelemetry 1.0

import "../../ui" as Ui
import "../elements"

// Temporary dummy
Item {

    Layout.fillHeight: true
    Layout.fillWidth: true

    //width: parent.width
    //height: 600

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
                        text: qsTr("Ping All")
                        onClicked: {
                            MavlinkTelemetry.pingAllSystems()
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

                    Text {
                        text: qsTr("Ping Result FC: ")+OpenHD.last_ping_result_flight_ctrl
                        font.weight: Font.Bold
                        font.pixelSize: 13
                        width: 224
                        height: elementHeight
                        anchors.rightMargin: Qt.inputMethod.visible ? 96 : 36
                        anchors.right: parent.right
                        anchors.verticalCenter: parent.verticalCenter
                    }
                }


                Rectangle {
                    width: parent.width
                    height: rowHeight
                    visible: true
                    color: Color.RED

                    Text {
                        text: qsTr("Test1: ")
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
                        text: qsTr("Test1B")
                        onClicked: {
                            MavlinkTelemetry.requestAllParameters()
                        }
                    }
                }
            }
        }
    }
}
