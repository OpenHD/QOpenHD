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
            width: parent.width

            Text {
                text: qsTr("Reboot or safely shut down the air/ground before removing power, or to apply settings changes when it is difficult to cycle power manually. If you have a power control board or sensors connected you may also see power supply information.")
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

        Card {
            id: airBox
            height: 224
            Layout.fillWidth: true
            cardName: qsTr("Air")
            cardBody: ColumnLayout {
                height: parent.height

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
            hasFooter: true
            cardFooter: Item {
                anchors.fill: parent
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


        Card {
            id: groundBox
            height: 224
            Layout.fillWidth: true
            cardName: qsTr("Ground")
            cardBody: ColumnLayout {
                height: parent.height

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

            hasFooter: true
            cardFooter: Item {
                anchors.fill: parent
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
