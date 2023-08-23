import QtQuick 2.12
import QtQuick.Controls 2.12
import QtQuick.Layouts 1.12
import QtQuick.Controls.Material 2.12

import Qt.labs.settings 1.0

import OpenHD 1.0

import "../../../ui" as Ui
import "../../elements"

Rectangle {
    width: parent.width
    height: parent.height

    color: "#eaeaea"

    function voltage_as_string(voltage_mv){
        if(voltage_mv===0)return "N/A";
        return voltage_mv+" mV"
    }
    function current_as_string(current_ma){
        if(current_ma===0) return "N/A"
        return current_ma+" mA"
    }

    function open_power_action_dialoque(power_action_type){
        powerDialog.powerAction=power_action_type
        powerDialog.visible=true
    }

    PowerActionDialoque{
        id: powerDialog
    }

    QOpenHDVersionCard{
        id: qopenhdversioncard
        //anchors.top: airBox.bottom
    }

    RowLayout {
        id: mainItemsRowLayout
        anchors.right: parent.right
        anchors.rightMargin: 12
        anchors.top: qopenhdversioncard.bottom
        anchors.topMargin: 24
        anchors.left: parent.left
        anchors.leftMargin: 12
        spacing: 6
        height: 250

        Card {
            id: groundBox
            Layout.fillHeight: true
            Layout.fillWidth: true
            cardName: qsTr("OHD Ground station")

            m_style_error: !_ohdSystemGround.is_alive

            cardBody: StatusCardBodyOpenHD{
                m_is_ground: true
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
                        open_power_action_dialoque(PowerActionDialoque.PowerAction.RebootGround)
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
                        open_power_action_dialoque(PowerActionDialoque.PowerAction.ShutdownGround)
                    }
                }
            }
        }

        Card {
            id: airBox
            Layout.fillHeight: true
            Layout.fillWidth: true
            cardName: qsTr("OHD Air unit")
            m_style_error: !_ohdSystemAir.is_alive
            cardBody: StatusCardBodyOpenHD{
                m_is_ground: false
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
                        open_power_action_dialoque(PowerActionDialoque.PowerAction.RebootAir)
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
                        open_power_action_dialoque(PowerActionDialoque.PowerAction.ShutdownAir);
                    }
                }
            }
        }


        Card {
            id: fcBox
            visible: true
            enabled: _fcMavlinkSystem.is_alive
            Layout.fillHeight: true
            Layout.fillWidth: true
            cardName: qsTr("Flight Controller")
            m_style_error: !_fcMavlinkSystem.is_alive
            cardBody: StatusCardBodyFC{

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
                        open_power_action_dialoque(PowerActionDialoque.PowerAction.RebootFC)
                    }
                }
            }
        }
    }

    /*Item{
        width: parent.width
        height: 600
        ColumnLayout{
            width: parent.width
            height: parent.height
        }
    }*/

    RowLayout{
        id: actions_1
        width: parent.width
        //height: 30
        anchors.top: mainItemsRowLayout.bottom
        anchors.topMargin: 2
        RowLayout{
            IconInfoButon{
                onClicked: {
                    _messageBoxInstance.set_text_and_show("Ping all systems, aka check if they respond to the mavlink ping command. Both OpenHD air and ground support
 this command, FC only ardupilot / px4 support this command. The command is lossy, aka you might need to use it more than once to get a response from all systems.
 No response after >10 tries is a hint that one of your systems is not functioning properly.")
                }
            }
            Button{
                text: "Ping all systems"
                onClicked: _mavlinkTelemetry.ping_all_systems()
            }
        }
        RowLayout{
            IconInfoButon{
                onClicked: {
                    _messageBoxInstance.set_text_and_show("Request openhd air / ground station version. Lossy, might need a couple of tries.")
                }
            }
            Button{
                text: "Fetch version"
                onClicked: _mavlinkTelemetry.request_openhd_version()
            }
        }
    }

    RowLayout {
        id:actions_2
        width: parent.width
        anchors.top: actions_1.bottom
        anchors.topMargin: 2
        RowLayout{
            IconInfoButon{
                onClicked: {
                    _messageBoxInstance.set_text_and_show("Stops QOpenHD and disables the autostart service until the next reboot. Can be used to get into terminal on rpi.")
                }
            }
            Button{
                //font.pixelSize: 14
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
        }
        RowLayout{
            IconInfoButon{
                onClicked: {
                    _messageBoxInstance.set_text_and_show("Stops QOpenHD and lets the autostart service restart it (RPI)")
                }
            }
            Button {
                //font.pixelSize: 14
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


    }


}
