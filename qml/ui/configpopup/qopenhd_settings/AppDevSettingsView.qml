import "../MenuTypography.js" as MenuTypography
import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.12

import QtQuick.Controls.Material 2.12
import Qt.labs.settings 1.0

import OpenHD 1.0

import "../../../ui" as Ui
import "../../elements"
import ".."


ScrollView {
    id: appDevSettingsView
    width: parent.width
    height: parent.height
    contentHeight: manageColumn.height

    clip: true
    ScrollBar.horizontal.policy: ScrollBar.AlwaysOff
    ScrollBar.vertical.policy: ScrollBar.AlwaysOff

    Item {
        anchors.fill: parent

        Column {
            id: manageColumn
            spacing: 5
            anchors.left: parent.left
            anchors.right: parent.right
            AppGeneralDeveloperSettings {width:parent.width;height:implicitHeight}
            AdvancedActionButton {
                objectName:"openSimulatorButton"
                text:qsTr("Simulate Air / Ground...")
                iconText:"\uf1b2"
                onClicked:settings_form.openSimulator()
            }

            //
            SettingBaseElement{
                m_short_description: qsTr("Allow frequency change when armed")
                Switch { font.family: MenuTypography.family; font.pixelSize: MenuTypography.body;
                    width: 32
                    height: elementHeight
                    anchors.rightMargin: Qt.inputMethod.visible ? 96 : 36

                    anchors.right: parent.right
                    anchors.verticalCenter: parent.verticalCenter
                    checked: settings.dev_allow_freq_change_when_armed
                    onCheckedChanged: settings.dev_allow_freq_change_when_armed = checked
                }
            }
            SettingBaseElement{
                m_short_description: qsTr("Show all wifi channels")
                Switch { font.family: MenuTypography.family; font.pixelSize: MenuTypography.body;
                    width: 32
                    height: elementHeight
                    anchors.rightMargin: Qt.inputMethod.visible ? 96 : 36

                    anchors.right: parent.right
                    anchors.verticalCenter: parent.verticalCenter
                    checked: settings.dev_show_5180mhz_lowband
                    onCheckedChanged: settings.dev_show_5180mhz_lowband = checked
                }
            }
            SettingBaseElement{
                m_short_description: qsTr("Disable auto fetch")
                Switch { font.family: MenuTypography.family; font.pixelSize: MenuTypography.body;
                    width: 32
                    height: elementHeight
                    anchors.rightMargin: Qt.inputMethod.visible ? 96 : 36

                    anchors.right: parent.right
                    anchors.verticalCenter: parent.verticalCenter
                    checked: settings.dev_disable_autofetch
                    onCheckedChanged: settings.dev_disable_autofetch = checked
                }
            }
            SettingBaseElement{
                m_short_description: qsTr("Show link routing")
                m_long_description: qsTr("Show the Link routing selector in the OpenHD Link panel.")
                Switch { font.family: MenuTypography.family; font.pixelSize: MenuTypography.body;
                    width: 32
                    height: elementHeight
                    anchors.rightMargin: Qt.inputMethod.visible ? 96 : 36

                    anchors.right: parent.right
                    anchors.verticalCenter: parent.verticalCenter
                    checked: settings.dev_show_link_routing
                    onCheckedChanged: settings.dev_show_link_routing = checked
                }
            }
            SettingBaseElement{
                m_short_description: qsTr("Show link usage")
                m_long_description: qsTr("Show Total Link Usage meter in the OpenHD Link panel.")
                Switch { font.family: MenuTypography.family; font.pixelSize: MenuTypography.body;
                    width: 32
                    height: elementHeight
                    anchors.rightMargin: Qt.inputMethod.visible ? 96 : 36

                    anchors.right: parent.right
                    anchors.verticalCenter: parent.verticalCenter
                    checked: settings.dev_show_link_usage
                    onCheckedChanged: settings.dev_show_link_usage = checked
                }
            }
            SettingBaseElement{
                m_short_description: qsTr("Simulate Ethernet link")
                m_long_description: qsTr("UI debugging only. Does not create or change any real connection.")
                Switch { font.family: MenuTypography.family; font.pixelSize: MenuTypography.body;
                    width: 32
                    height: elementHeight
                    anchors.rightMargin: Qt.inputMethod.visible ? 96 : 36

                    anchors.right: parent.right
                    anchors.verticalCenter: parent.verticalCenter
                    checked: settings.dev_simulate_ethernet_link
                    onCheckedChanged: settings.dev_simulate_ethernet_link = checked
                }
            }
            SettingBaseElement{
                m_short_description: qsTr("Simulate WiFiBroadcast link")
                m_long_description: qsTr("UI debugging only. Shows populated radio data in the Link tab.")
                Switch { font.family: MenuTypography.family; font.pixelSize: MenuTypography.body;
                    width: 32
                    height: elementHeight
                    anchors.rightMargin: Qt.inputMethod.visible ? 96 : 36

                    anchors.right: parent.right
                    anchors.verticalCenter: parent.verticalCenter
                    checked: settings.dev_simulate_wifibroadcast_link
                    onCheckedChanged: settings.dev_simulate_wifibroadcast_link = checked
                }
            }
            SettingBaseElement{
                m_short_description: qsTr("Simulate UART link")
                m_long_description: qsTr("UI debugging only. Does not create or change any real connection.")
                Switch { font.family: MenuTypography.family; font.pixelSize: MenuTypography.body;
                    width: 32
                    height: elementHeight
                    anchors.rightMargin: Qt.inputMethod.visible ? 96 : 36

                    anchors.right: parent.right
                    anchors.verticalCenter: parent.verticalCenter
                    checked: settings.dev_simulate_uart_link
                    onCheckedChanged: settings.dev_simulate_uart_link = checked
                }
            }
            SettingBaseElement {
                m_short_description: qsTr("Backup & Restore")
                m_long_description: qsTr("Export or import settings using a file on your chosen storage device.")
                AdvancedActionButton {
                    anchors.right:parent.right;anchors.verticalCenter:parent.verticalCenter
                    text:qsTr("Open");onClicked:settings_form.openBackupRestore()
                }
            }
            SettingBaseElement{
                m_short_description: qsTr("Reset all QOpenHD Settings")

                AdvancedActionButton { font.family: MenuTypography.family; font.pixelSize: MenuTypography.body;
                    id:reset
                    width: 128
                    height: elementHeight
                    anchors.rightMargin: Qt.inputMethod.visible ? 96 : 36

                    anchors.right: parent.right
                    anchors.verticalCenter: parent.verticalCenter
                    text: qsTr("Reset")
                    onClicked: {
                        simplePopupHack.visible=true;
                    }
                    //enabled: _qopenhd.is_linux()
                }
            }
            SettingBaseElement{
                m_short_description: qsTr("Disable STBC warning")
                Switch { font.family: MenuTypography.family; font.pixelSize: MenuTypography.body;
                    width: 32
                    height: elementHeight
                    anchors.rightMargin: Qt.inputMethod.visible ? 96 : 36
                    anchors.right: parent.right
                    anchors.verticalCenter: parent.verticalCenter
                    checked: settings.dev_wb_show_no_stbc_enabled_warning
                    onCheckedChanged: settings.dev_wb_show_no_stbc_enabled_warning = checked
                }
            }
        }
        Card {
            id: simplePopupHack
            width: Math.min(430, appDevSettingsView.width - 28)
            height: 220
            anchors.centerIn: parent
            z: 5.0
            cardName: qsTr("WARNING")
            cardNameColor: "red"
            visible: false
            cardBody: Column {
                height: 200
                width: parent.width
                StyledText {
                    id: simplePopupHackText
                    text: qsTr("Do you really want to erase all your QOpenHD settings?")
                    width: parent.width-24
                    height: parent.height
                    leftPadding: 12
                    rightPadding: 12
                    font.pixelSize: MenuTypography.body; font.family: MenuTypography.family
                    color: settings_form.primaryText
                    wrapMode: Text.WordWrap
                }
            }
            hasFooter: true
            cardFooter: Item {
                anchors.fill: parent
                AdvancedActionButton { font.family: MenuTypography.family; font.pixelSize: MenuTypography.body;
                    width: 160
                    height: 40
                    anchors.left: parent.left
                    anchors.leftMargin: 12
                    anchors.bottom: parent.bottom
                    anchors.bottomMargin: 6
                    destructive: true
                    iconText: "\uf071"
                    text:  qsTr("Continue")
                    onPressed: {
                        simplePopupHack.visible=false
                        var res=_qopenhd.reset_settings()
                        if (res) {
                             _restartqopenhdmessagebox.show_with_text("Settings reset to default,");
                        }
                        else{
                            _messageBoxInstance.set_text_and_show(qsTr("Couldn't reset the settings"))
                        }
                    }
                }
                AdvancedActionButton { font.family: MenuTypography.family; font.pixelSize: MenuTypography.body;
                    width: 130
                    height: 40
                    anchors.right: parent.right
                    anchors.rightMargin: 12
                    anchors.bottom: parent.bottom
                    anchors.bottomMargin: 6
                    iconText: "\uf00d"
                    text:  qsTr("Cancel")
                    onPressed: {
                        simplePopupHack.visible=false
                    }
                }
            }
        }


    }
}


