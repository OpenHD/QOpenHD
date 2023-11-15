import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.12
import QtQuick.Dialogs 1.0
import QtQuick.Controls.Material 2.12
import Qt.labs.settings 1.0
import Qt.labs.folderlistmodel 2.0
import Qt.labs.platform 1.0

import OpenHD 1.0

import "../../../ui" as Ui
import "../../elements"


ScrollView {
    id: appDevSettingsView
    width: parent.width
    height: parent.height
    contentHeight: manageColumn.height

    clip: true

    Item {
        anchors.fill: parent

        Column {
            id: manageColumn
            spacing: 0
            anchors.left: parent.left
            anchors.right: parent.right
            //
            SettingBaseElement{
                m_short_description: "DEV_SHOW_WHITELISTED_PARAMS"
                m_long_description: "Enabling this gives you full controll over the mavlink parameters set openhd exposes (both air and ground) BUT BE WARNED yu can easily break things!"
                Switch {
                    width: 32
                    height: elementHeight
                    anchors.rightMargin: Qt.inputMethod.visible ? 96 : 36

                    anchors.right: parent.right
                    anchors.verticalCenter: parent.verticalCenter
                    checked: settings.dev_show_whitelisted_params
                    onCheckedChanged: settings.dev_show_whitelisted_params = checked
                }
            }
            SettingBaseElement{
                m_short_description:"DEV_SHOW_ADVANCED_BUTTON"
                m_long_description: "Allows more customization of the mavlink parameters set than what openhd exposes, BE WARNED you can easily break things this way !"
                Switch {
                    width: 32
                    height: elementHeight
                    anchors.rightMargin: Qt.inputMethod.visible ? 96 : 36

                    anchors.right: parent.right
                    anchors.verticalCenter: parent.verticalCenter
                    checked: settings.dev_show_advanced_button
                    onCheckedChanged: settings.dev_show_advanced_button = checked
                }
            }
            SettingBaseElement{
                m_short_description:"dev_allow_freq_change_when_armed"
                m_long_description: "Allows changing the frequency and channel width while armed, THIS CAN BREAK YOUR LINK DURING FLIGHT !"
                Switch {
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
                m_short_description: "Save Settings to file"
                m_long_description: "Save your QOpenHD settings (e.g. OSD layout,..) to your SD card as a backup in between updates. Only works from/to linux."

                Button {
                    id:save
                    width: 128
                    height: elementHeight
                    anchors.rightMargin: Qt.inputMethod.visible ? 96 : 36

                    anchors.right: parent.right
                    anchors.verticalCenter: parent.verticalCenter
                    text: qsTr("Save")
                    onClicked: {
                        var res=_qopenhd.backup_settings_locally();
                        if (res) {
                            _messageBoxInstance.set_text_and_show("QOpenHD settings backed up to /boot/openhd/QOpenHD.conf")
                        }else{
                            _messageBoxInstance.set_text_and_show("Couldn't backup settings")
                        }
                    }
                    enabled: _qopenhd.is_linux()
                }
            }
            SettingBaseElement{
                m_short_description: "Load Settings from file"
                m_long_description: "Load a previosuly backed up QOpenHD settings file (e.g. OSD layout,..) from your SD card. Only works from/to linux."

                Button {
                    id:load
                    width: 128
                    height: elementHeight
                    anchors.rightMargin: Qt.inputMethod.visible ? 96 : 36

                    anchors.right: parent.right
                    anchors.verticalCenter: parent.verticalCenter
                    text: qsTr("Load")
                    onClicked: {
                        var res=_qopenhd.overwrite_settings_from_backup_file()
                        if (res) {
                            _restartqopenhdmessagebox.show_with_text("Settings file Loaded !");
                        }else{
                            _messageBoxInstance.set_text_and_show("Couldn't load settings - make sure \"/boot/openhd/QOpenHD.conf\" (a previous pbackup) exists on your SD card")
                        }
                    }
                    enabled: _qopenhd.is_linux()
                }
            }
            SettingBaseElement{
                m_short_description: "Reset all QOpenHD Settings"
                m_long_description: "Reset all QOpenHD Settings (e.g. OSD layout,...). Does not reset your openhd settings on the air or ground unit. Only works from/to linux."

                Button {
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
                m_short_description: "Enable audio playback"
                m_long_description: "Enable live audio playback in QOpenHD, NOTE: audio streaming is not supported in OpenHD yet. Requires restart of QOpenHD."

                Switch {
                    width: 32
                    height: elementHeight
                    anchors.rightMargin: Qt.inputMethod.visible ? 96 : 36

                    anchors.right: parent.right
                    anchors.verticalCenter: parent.verticalCenter
                    checked: settings.dev_enable_live_audio_playback
                    onCheckedChanged: settings.dev_enable_live_audio_playback = checked
                }
            }
            SettingBaseElement{
                m_short_description: "dirty_enable_inav_hacks"
                m_long_description: "NEVER ENABLE UNLESS YOU HAVE TO. INAV mavlink support is quirky in some ways to say the least."

                Switch {
                    width: 32
                    height: elementHeight
                    anchors.rightMargin: Qt.inputMethod.visible ? 96 : 36

                    anchors.right: parent.right
                    anchors.verticalCenter: parent.verticalCenter
                    checked: settings.dirty_enable_inav_hacks
                    onCheckedChanged: settings.dirty_enable_inav_hacks = checked
                }
            }
            SettingBaseElement{
                m_short_description: "dirty_enable_mavlink_fc_sys_id_check"
                 m_long_description: "Only accept FCs that explicitly expose themselves as autopilot - can fix issues with FC discovery in QOpenHD."

                Switch {
                    width: 32
                    height: elementHeight
                    anchors.rightMargin: Qt.inputMethod.visible ? 96 : 36

                    anchors.right: parent.right
                    anchors.verticalCenter: parent.verticalCenter
                    checked: settings.dirty_enable_mavlink_fc_sys_id_check
                    onCheckedChanged: settings.dirty_enable_mavlink_fc_sys_id_check = checked
                }
            }

            SettingBaseElement{
                m_short_description: "dev_mavlink_via_tcp"
                m_long_description: "Requires full restart. Connect via TCP instead of UDP. Requires matching server IP."
                Switch {
                    width: 32
                    height: elementHeight
                    anchors.rightMargin: Qt.inputMethod.visible ? 96 : 36
                    anchors.right: parent.right
                    anchors.verticalCenter: parent.verticalCenter
                    checked: settings.dev_mavlink_via_tcp
                    onCheckedChanged: settings.dev_mavlink_via_tcp = checked
                }
            }
            SettingBaseElement{
                m_short_description: "dev_mavlink_tcp_ip"
                m_long_description: "Requires full restart. IP of mavlink tcp server"
                TextInput{
                    id: ti_ip
                    height: elementHeight
                    anchors.rightMargin: Qt.inputMethod.visible ? 96 : 36
                    anchors.right: parent.right
                    anchors.verticalCenter: parent.verticalCenter

                    text: settings.dev_mavlink_tcp_ip
                    cursorVisible: true
                    inputMask: "999.999.999.999"
                    onTextEdited: settings.dev_mavlink_tcp_ip = ti_ip.text
                }
            }
            SettingBaseElement{
                m_short_description: "dev_wb_show_no_stbc_enabled_warning"
                m_long_description: "Do not show the STBC recommended enabled message"
                Switch {
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
            width: 360
            height: 340
            anchors.top: parent.top
            anchors.topMargin: 20
            anchors.left: parent.left
            anchors.leftMargin: mainStackLayout.width/2-180
            z: 5.0
            cardName: qsTr("WARNING")
            cardNameColor: "red"
            visible: false
            cardBody: Column {
                height: 200
                width: parent.width
                Text {
                    id: simplePopupHackText
                    text: "This will erase all your QOpenHD settings (Layout of OSD elements, ...) and is irreversible, continue only if you know what you're doing!"
                    width: parent.width-24
                    height:parent.height
                    leftPadding: 12
                    rightPadding: 12
                    font.pixelSize: 20
                    wrapMode: Text.WordWrap
                }
            }
            hasFooter: true
            cardFooter: Item {
                anchors.fill: parent
                Button {
                    width: 150
                    height: 48
                    anchors.left: parent.left
                    anchors.leftMargin: 12
                    anchors.bottom: parent.bottom
                    anchors.bottomMargin: 6
                    font.pixelSize: 14
                    font.capitalization: Font.MixedCase
                    Material.accent: Material.Red
                    highlighted: true
                    text:  qsTr("Continue")
                    onPressed: {
                        simplePopupHack.visible=false
                        var res=_qopenhd.reset_settings()
                        if (res) {
                             _restartqopenhdmessagebox.show_with_text("Settings reset to default,");
                        }
                        else{
                            _messageBoxInstance.set_text_and_show("couldn't reset the settings")
                        }
                    }
                }
                Button {
                    width: 150
                    height: 48
                    anchors.right: parent.right
                    anchors.rightMargin: 12
                    anchors.bottom: parent.bottom
                    anchors.bottomMargin: 6
                    font.pixelSize: 14
                    font.capitalization: Font.MixedCase
                    Material.accent: Material.Grey
                    highlighted: true
                    text:  qsTr("Cancel")
                    onPressed: {
                        simplePopupHack.visible=false
                    }
                }
            }
        }


    }
}


