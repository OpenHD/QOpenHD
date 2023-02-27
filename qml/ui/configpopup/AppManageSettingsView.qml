import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.12
import QtQuick.Dialogs 1.0
import QtQuick.Controls.Material 2.12
import Qt.labs.settings 1.0
import Qt.labs.folderlistmodel 2.0
import Qt.labs.platform 1.0

import OpenHD 1.0

import "../../ui" as Ui
import "../elements"


ScrollView {
    id: appManageSettingsView
    width: parent.width
    height: parent.height
    contentHeight: manageColumn.height
    visible: appSettingsBar.currentIndex == 5

    clip: true

    Item {
        anchors.fill: parent

        Column {
            id: manageColumn
            spacing: 0
            anchors.left: parent.left
            anchors.right: parent.right
            //
            Rectangle {
                width: parent.width
                height: rowHeight
                color: (Positioner.index % 2 == 0) ? "#8cbfd7f3" : "#00000000"
                visible: true
                Text {
                    text: qsTr("DEV_SHOW_WHITELISTED_PARAMS")
                    font.weight: Font.Bold
                    font.pixelSize: 13
                    anchors.leftMargin: 8
                    verticalAlignment: Text.AlignVCenter
                    anchors.verticalCenter: parent.verticalCenter
                    width: 224
                    height: elementHeight
                    anchors.left: parent.left
                }
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
            Rectangle {
                width: parent.width
                height: rowHeight
                color: (Positioner.index % 2 == 0) ? "#8cbfd7f3" : "#00000000"
                visible: true
                Text {
                    text: qsTr("DEV_SHOW_ADVANCED_BUTTON")
                    font.weight: Font.Bold
                    font.pixelSize: 13
                    anchors.leftMargin: 8
                    verticalAlignment: Text.AlignVCenter
                    anchors.verticalCenter: parent.verticalCenter
                    width: 224
                    height: elementHeight
                    anchors.left: parent.left
                }
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
            Rectangle {
                width: parent.width
                height: rowHeight
                color: (Positioner.index % 2 == 0) ? "#8cbfd7f3" : "#00000000"
                visible: true
                Text {
                    text: qsTr("dev_allow_freq_change_when_armed")
                    font.weight: Font.Bold
                    font.pixelSize: 13
                    anchors.leftMargin: 8
                    verticalAlignment: Text.AlignVCenter
                    anchors.verticalCenter: parent.verticalCenter
                    width: 224
                    height: elementHeight
                    anchors.left: parent.left
                }
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
            Rectangle {
                width: parent.width
                height: rowHeight
                color: (Positioner.index % 2 == 0) ? "#8cbfd7f3" : "#00000000"
                visible: !IsRaspPi

                Text {
                    text: qsTr("Save settings to file")
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
                }
            }
            Rectangle {
                width: parent.width
                height: rowHeight
                color: (Positioner.index % 2 == 0) ? "#8cbfd7f3" : "#00000000"
                visible: !IsRaspPi

                Text {
                    text: qsTr("Load Settings from File")
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
                }
            }
            Rectangle {
                width: parent.width
                height: rowHeight
                color: (Positioner.index % 2 == 0) ? "#8cbfd7f3" : "#00000000"
                visible: !IsRaspPi

                Text {
                    text: qsTr("Reset ALL QOpenHD Settings")
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


