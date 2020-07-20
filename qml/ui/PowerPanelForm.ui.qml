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

    Rectangle {
        id: infoPanel
        anchors.left: parent.left
        anchors.leftMargin: 12
        anchors.right: parent.right
        anchors.rightMargin: 12
        anchors.top: parent.top
        anchors.topMargin: 12

        height: infoColumn.height + 12

        radius: 9
        color: "white"

        Column {
            id: infoColumn
            width: parent.width

            spacing: 12

            Text {
                text: qsTr("The buttons below provide direct control over the power of the air and ground stations, you can remotely reboot or safely shut down before removing power or to apply settings changes when it is difficult to cycle power manually.")
                wrapMode: Text.WordWrap
                width: parent.width
                leftPadding: 12
                rightPadding: 12
                topPadding: 12
                font.pixelSize: 14
            }

            Text {
                text: qsTr("If you have a power control board or sensors connected you may also see power supply information.")
                wrapMode: Text.WordWrap
                width: parent.width
                leftPadding: 12
                rightPadding: 12
                topPadding: 12
                font.pixelSize: 14
            }
        }
    }

    RowLayout {
        anchors.right: parent.right
        anchors.rightMargin: 12
        anchors.top: infoPanel.bottom
        anchors.topMargin: 24
        anchors.left: parent.left
        anchors.leftMargin: 12
        spacing: 6
        height: 192


        Rectangle {
            id: airBox
            color: "white"
            height: 224
            Layout.fillWidth: true

            radius: 9

            Item {
                id: airControlID
                width: parent.width
                height: 32
                anchors.left: parent.left
                anchors.leftMargin: 0
                anchors.right: parent.right
                anchors.rightMargin: 0
                anchors.top: parent.top
                anchors.topMargin: 0

                Text {
                    text: qsTr("Air")
                    width: parent.width
                    height: 24
                    color: "#33aaff"
                    font.bold: true
                    font.pixelSize: 16
                    verticalAlignment: Text.AlignVCenter
                    horizontalAlignment: Text.AlignLeft
                    anchors.top: parent.top
                    leftPadding: 12
                    topPadding: 3
                }
            }

            ColumnLayout {
                anchors.top: airControlID.bottom
                anchors.topMargin: 6

                width: parent.width

                RowLayout {
                    Layout.fillWidth: true

                    Text {
                        text: qsTr("Output Voltage:")
                        height: 24
                        Layout.fillWidth: true
                        font.pixelSize: 14
                        font.bold: true
                        verticalAlignment: Text.AlignVCenter
                        horizontalAlignment: Text.AlignLeft
                        leftPadding: 12
                    }

                    Text {
                        text: OpenHD.air_vout >= 0 ? (OpenHD.air_vout / 1000.0).toFixed(2) + "V" : "N/A"
                        height: 24
                        Layout.fillWidth: true
                        font.pixelSize: 14
                        verticalAlignment: Text.AlignVCenter
                        horizontalAlignment: Text.AlignRight
                        rightPadding: 12
                    }
                }

                RowLayout {
                    Layout.fillWidth: true

                    Text {
                        text: qsTr("Current:")
                        height: 24
                        Layout.fillWidth: true
                        font.pixelSize: 14
                        font.bold: true
                        verticalAlignment: Text.AlignVCenter
                        horizontalAlignment: Text.AlignLeft
                        leftPadding: 12
                    }

                    Text {
                        text: OpenHD.air_iout >= 0 ? OpenHD.air_iout + "mA" : "N/A"
                        height: 24
                        Layout.fillWidth: true
                        font.pixelSize: 14
                        verticalAlignment: Text.AlignVCenter
                        horizontalAlignment: Text.AlignRight
                        rightPadding: 12
                    }
                }
            }

            Rectangle {
                color: "#4c000000"
                width: parent.width
                height: 1

                anchors.left: parent.left
                anchors.leftMargin: 0
                anchors.right: parent.right
                anchors.rightMargin: 0
                anchors.bottom: button_background.top
                anchors.bottomMargin: 0
            }


            Rectangle {
                id: button_background
                width: parent.width
                height: 64
                color: "#f6f6f6"
                anchors.left: parent.left
                anchors.leftMargin: 0
                anchors.right: parent.right
                anchors.rightMargin: 0
                anchors.bottom: parent.bottom
                anchors.bottomMargin: 0

                Button {
                    id: airReboot
                    width: 96
                    height: 48
                    text: qsTr("Reboot")
                    anchors.left: parent.left
                    anchors.leftMargin: 12
                    anchors.bottom: parent.bottom
                    anchors.bottomMargin: 6
                    font.pixelSize: 14
                    font.capitalization: Font.MixedCase

                    onPressed: {
                        powerAction = PowerPanel.PowerAction.RebootAir
                        powerDialog.open()
                    }
                }

                Button {
                    id: airShutdown
                    width: 96
                    height: 48
                    anchors.right: parent.right
                    anchors.rightMargin: 12
                    anchors.bottom: parent.bottom
                    anchors.bottomMargin: 6
                    font.pixelSize: 14
                    font.capitalization: Font.MixedCase
                    Material.accent: Material.Red
                    highlighted: true

                    text: qsTr("Shutdown")

                    onPressed: {
                        powerAction = PowerPanel.PowerAction.ShutdownAir
                        powerDialog.open()
                    }
                }
            }
        }

        Rectangle {
            id: groundBox
            color: "white"
            height: 224
            Layout.fillWidth: true

            radius: 9

            Item {
                id: groundControlID
                width: parent.width
                height: 32

                anchors.left: parent.left
                anchors.leftMargin: 0
                anchors.right: parent.right
                anchors.rightMargin: 0
                anchors.top: parent.top
                anchors.topMargin: 0

                Text {
                    text: qsTr("Ground")
                    width: parent.width
                    height: 24
                    color: "#33aaff"
                    font.bold: true
                    font.pixelSize: 16
                    verticalAlignment: Text.AlignVCenter
                    horizontalAlignment: Text.AlignLeft
                    anchors.top: parent.top
                    leftPadding: 12
                    topPadding: 3
                }
            }

            ColumnLayout {
                anchors.top: groundControlID.bottom
                anchors.topMargin: 6

                width: parent.width

                RowLayout {
                    Layout.fillWidth: true

                    Text {
                        text: qsTr("Supply Voltage:")
                        height: 24
                        Layout.fillWidth: true
                        font.pixelSize: 14
                        font.bold: true
                        verticalAlignment: Text.AlignVCenter
                        horizontalAlignment: Text.AlignLeft
                        leftPadding: 12
                    }

                    Text {
                        text: OpenHD.ground_vin >= 0 ? (OpenHD.ground_vin / 1000.0).toFixed(2) + "V": "N/A"
                        height: 24
                        Layout.fillWidth: true
                        font.pixelSize: 14
                        verticalAlignment: Text.AlignVCenter
                        horizontalAlignment: Text.AlignRight
                        rightPadding: 12
                    }
                }

                RowLayout {
                    Layout.fillWidth: true

                    Text {
                        text: qsTr("Output Voltage:")
                        height: 24
                        Layout.fillWidth: true
                        font.pixelSize: 14
                        font.bold: true
                        verticalAlignment: Text.AlignVCenter
                        horizontalAlignment: Text.AlignLeft
                        leftPadding: 12
                    }

                    Text {
                        text: OpenHD.ground_vout >= 0 ? (OpenHD.ground_vout / 1000.0).toFixed(2)  + "V" : "N/A"
                        height: 24
                        Layout.fillWidth: true
                        font.pixelSize: 14
                        verticalAlignment: Text.AlignVCenter
                        horizontalAlignment: Text.AlignRight
                        rightPadding: 12
                    }
                }

                RowLayout {
                    Layout.fillWidth: true

                    Text {
                        text: qsTr("Output Current:")
                        height: 24
                        Layout.fillWidth: true
                        font.pixelSize: 14
                        font.bold: true
                        verticalAlignment: Text.AlignVCenter
                        horizontalAlignment: Text.AlignLeft
                        leftPadding: 12
                    }

                    Text {
                        text: OpenHD.ground_iout >= 0 ? OpenHD.ground_iout + "mA" : "N/A"
                        height: 24
                        Layout.fillWidth: true
                        font.pixelSize: 14
                        verticalAlignment: Text.AlignVCenter
                        horizontalAlignment: Text.AlignRight
                        rightPadding: 12
                    }
                }

                RowLayout {
                    Layout.fillWidth: true

                    Text {
                        text: qsTr("Battery Voltage:")
                        height: 24
                        Layout.fillWidth: true
                        font.pixelSize: 14
                        font.bold: true
                        verticalAlignment: Text.AlignVCenter
                        horizontalAlignment: Text.AlignLeft
                        leftPadding: 12
                    }

                    Text {
                        text: OpenHD.ground_vbat >= 0 ? (OpenHD.ground_vbat / 1000.0).toFixed(2) + "V" : "N/A"
                        height: 24
                        Layout.fillWidth: true
                        font.pixelSize: 14
                        verticalAlignment: Text.AlignVCenter
                        horizontalAlignment: Text.AlignRight
                        rightPadding: 12
                    }
                }
            }

            Rectangle {
                color: "#4c000000"
                width: parent.width
                height: 1

                anchors.left: parent.left
                anchors.leftMargin: 0
                anchors.right: parent.right
                anchors.rightMargin: 0
                anchors.bottom: button_background4.top
                anchors.bottomMargin: 0
            }

            Rectangle {
                id: button_background4
                width: parent.width
                height: 64
                color: "#f6f6f6"
                anchors.left: parent.left
                anchors.leftMargin: 0
                anchors.right: parent.right
                anchors.rightMargin: 0
                anchors.bottom: parent.bottom
                anchors.bottomMargin: 0

                Button {
                    id: groundReboot
                    width: 96
                    height: 48
                    text: qsTr("Reboot")
                    anchors.left: parent.left
                    anchors.leftMargin: 12
                    anchors.bottom: parent.bottom
                    anchors.bottomMargin: 6
                    font.pixelSize: 14
                    font.capitalization: Font.MixedCase

                    onPressed: {
                        powerAction = PowerPanel.PowerAction.RebootGround
                        powerDialog.open()
                    }
                }

                Button {
                    id: groundShutdown
                    width: 96
                    height: 48
                    anchors.right: parent.right
                    anchors.rightMargin: 12
                    anchors.bottom: parent.bottom
                    anchors.bottomMargin: 6
                    font.pixelSize: 14
                    font.capitalization: Font.MixedCase
                    Material.accent: Material.Red
                    highlighted: true

                    text: qsTr("Shutdown")

                    onPressed: {
                        powerAction = PowerPanel.PowerAction.ShutdownGround
                        powerDialog.open()
                    }
                }
            }
        }
    }

}
