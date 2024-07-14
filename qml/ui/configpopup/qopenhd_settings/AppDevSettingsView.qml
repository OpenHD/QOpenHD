import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.12

import QtQuick.Controls.Material 2.12
import Qt.labs.settings 1.0

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
                m_short_description: "Enable advanced settings"
                Switch {
                    width: 32
                    height: elementHeight
                    anchors.rightMargin: Qt.inputMethod.visible ? 96 : 36

                    anchors.right: parent.right
                    anchors.verticalCenter: parent.verticalCenter
                    checked: settings.dev_show_whitelisted_params
                    onCheckedChanged: {
                        settings.dev_show_whitelisted_params = checked
                        settings.dev_show_advanced_button = checked
                    }
                }
            }
            SettingBaseElement{
                m_short_description:"Allow frequency change when armed"
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
                m_short_description:"Show all wifi channels"
                Switch {
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
                m_short_description:"Disable auto fetch"
                Switch {
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
                m_long_description: "Load a previosly backed up QOpenHD settings file (e.g. OSD layout,..) from your SD card. Only works from/to linux."

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
                m_short_description: "Improve Inav support"

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
                m_short_description: "Disable STBC warning"
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


