import QtQuick 2.12
import QtQuick.Controls 2.12
import QtQuick.Layouts 1.12
import QtQuick.Controls.Material 2.12

import Qt.labs.settings 1.0

import OpenHD 1.0

import "../../ui" as Ui
import "../elements"

Rectangle {
    Layout.fillHeight: true
    Layout.fillWidth: true

    color: "#eaeaea"

    function voltage_as_string(voltage_mv){
        if(voltage_mv===0)return "N/A";
        return voltage_mv+" mV"
    }
    function current_as_string(current_ma){
        if(current_ma===0) return "N/A"
        return current_ma+" mA"
    }

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

                RowLayout {
                    Layout.fillWidth: true

                    Text {
                        text: qsTr("INA219 Voltage:")
                        height: 24
                        Layout.fillWidth: true
                        font.pixelSize: 14
                        font.bold: true
                        verticalAlignment: Text.AlignVCenter
                        horizontalAlignment: Text.AlignLeft
                        leftPadding: 12
                    }

                    Text {
                        text: voltage_as_string(_ohdSystemAir.ina219_voltage_millivolt)
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
                        text: qsTr("INA219 Current:")
                        height: 24
                        Layout.fillWidth: true
                        font.pixelSize: 14
                        font.bold: true
                        verticalAlignment: Text.AlignVCenter
                        horizontalAlignment: Text.AlignLeft
                        leftPadding: 12
                    }

                    Text {
                        text: current_as_string(_ohdSystemAir.ina219_current_milliamps)
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
                    enabled: _ohdSystemAir.is_alive

                    onPressed: {
                        powerAction = PowerPanel.PowerAction.RebootAir
                        powerDialog.visible = true
                    }
                }

                Button {
                    id: airShutdown
                    width: 96
                    height: 48
                    text: qsTr("Shutdown")
                    anchors.right: parent.right
                    anchors.rightMargin: 12
                    anchors.bottom: parent.bottom
                    anchors.bottomMargin: 6
                    font.pixelSize: 14
                    font.capitalization: Font.MixedCase
                    Material.accent: Material.Red
                    highlighted: true
                    enabled: _ohdSystemAir.is_alive

                    onPressed: {
                        powerAction = PowerPanel.PowerAction.ShutdownAir
                        powerDialog.visible = true
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

                RowLayout {
                    Layout.fillWidth: true

                    Text {
                        text: qsTr("INA219 Voltage:")
                        height: 24
                        Layout.fillWidth: true
                        font.pixelSize: 14
                        font.bold: true
                        verticalAlignment: Text.AlignVCenter
                        horizontalAlignment: Text.AlignLeft
                        leftPadding: 12
                    }

                    Text {
                        text: voltage_as_string(_ohdSystemGround.ina219_voltage_millivolt)
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
                        text: qsTr("INA219 Current:")
                        height: 24
                        Layout.fillWidth: true
                        font.pixelSize: 14
                        font.bold: true
                        verticalAlignment: Text.AlignVCenter
                        horizontalAlignment: Text.AlignLeft
                        leftPadding: 12
                    }

                    Text {
                        text: current_as_string(_ohdSystemGround.ina219_current_milliamps)
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
                    enabled: _ohdSystemGround.is_alive

                    onPressed: {
                        powerAction = PowerPanel.PowerAction.RebootGround
                        powerDialog.visible = true
                    }
                }

                Button {
                    id: groundShutdown
                    width: 96
                    height: 48
                    text: qsTr("Shutdown")
                    anchors.right: parent.right
                    anchors.rightMargin: 12
                    anchors.bottom: parent.bottom
                    anchors.bottomMargin: 6
                    font.pixelSize: 14
                    font.capitalization: Font.MixedCase
                    Material.accent: Material.Red
                    highlighted: true
                    enabled: _ohdSystemGround.is_alive

                    onPressed: {
                        powerAction = PowerPanel.PowerAction.ShutdownGround
                        powerDialog.visible = true
                    }
                }
            }
        }


        Card {
            id: fcBox
            visible: _fcMavlinkSystem.supports_basic_commands
            enabled: _fcMavlinkSystem.is_alive
            height: 224
            Layout.fillWidth: true
            cardName: qsTr("Flight Controller")
            cardBody: ColumnLayout {
                //empty..
            }

            hasFooter: true
            cardFooter: Item {
                anchors.fill: parent
                Button {
                    id: fcReboot
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
                        powerAction = PowerPanel.PowerAction.RebootFC
                        powerDialog.visible = true
                    }
                }
/* needs testing on actual FC. Shutdown is not accepted by SITL
                Button {
                    id: fcShutdown
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
                        powerAction = PowerPanel.PowerAction.ShutdownFC
                        powerDialog.visible = true
                    }
                }
                */
            }
        }
    }
    Button {
        id: devCancelQOpenHD
        anchors.right: parent.right
        anchors.rightMargin: 12
        anchors.bottom: parent.bottom
        anchors.bottomMargin: 6
        font.pixelSize: 14
        font.capitalization: Font.MixedCase
        Material.accent: Material.Red
        highlighted: true

        text: qsTr("DEV! Cancel QOpenHD")

        onPressed: {
            // disables the service (such that qopenhd doesn't get restarted), then quits qopenhd
            // NOTE: only works on images where the QT auto restart service is active
            _qopenhd.disable_service_and_quit()
        }
    }
    Button {
        id: devRestartQOpenHD
        anchors.right: parent.right
        anchors.rightMargin: 12
        anchors.bottom: devCancelQOpenHD.top
        anchors.bottomMargin: 6
        font.pixelSize: 14
        font.capitalization: Font.MixedCase
        Material.accent: Material.Orange
        highlighted: true

        text: qsTr("DEV! Restart QOpenHD")

        onPressed: {
              // Will be restarted by the service
             _qopenhd.quit_qopenhd()
        }
    }


}
