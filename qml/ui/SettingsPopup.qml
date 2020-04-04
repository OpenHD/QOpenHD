import QtQuick 2.12
import QtQuick.Controls 2.12
import QtQuick.Dialogs 1.3
import QtQuick.Layouts 1.12
import QtQuick.Window 2.12
import Qt.labs.settings 1.0
import QtQuick.Dialogs 1.1

import OpenHD 1.0


SettingsPopupForm {
    id: settings_form
    signal localMessage(var message, var level)

    /*Connections {
        target: openHDRC
        onSelectedGamepadChanged: {
            console.log("onSelectedGamepadChanged %1".arg(selectedGamepad));
        }
        onSelectedGamepadNameChanged: {
            console.log("onSelectedGamepadNameChanged %1".arg(selectedGamepadName));
        }
    }*/

    function openSettings() {
        openHDSettings.fetchSettings();
        visible = true
    }

    rebootButton.onClicked: {
        visible = false
        rebootDialog.open()
    }

    closeButton.onClicked: {
        visible = false
    }

    Popup {
        id: rebootDialog

        parent: Overlay.overlay

        x: Math.round((parent.width - width) / 2)
        y: Math.round((parent.height - height) / 2)
        width: 400
        height: 200


        Text {
            id: titleTextArea
            text: qsTr("Reboot ground station?")
            anchors.top: parent.top
            anchors.left: parent.left
            font.pixelSize: 16
            font.bold: true
        }

        Text {
            id: imageArea
            enabled: false
            anchors.left: parent.left
            anchors.top: titleTextArea.bottom
            anchors.topMargin: 18
            width: 64
            height: 64
            text: "\uf071"
            font.family: "Font Awesome 5 Free"
            font.pixelSize: 36
            color: "orange"
        }

        Item {
            anchors.top: titleTextArea.bottom
            anchors.topMargin: 18
            anchors.right: parent.right
            anchors.left: imageArea.right
            anchors.bottom: parent.bottom

            Text {
                id: detailTextArea
                text: qsTr("If your drone is armed it may crash or enter failsafe mode.\n\nYou have been warned.")
                wrapMode: Text.WordWrap
                font.pixelSize: 14
                anchors.top: parent.top
                anchors.right: parent.right
                anchors.left: parent.left
                anchors.bottom: parent.bottom
                anchors.bottomMargin: 48
            }

            Item {
                anchors.top: detailTextArea.bottom
                anchors.right: parent.right
                anchors.left: parent.left
                anchors.bottom: parent.bottom

                height: 48

                Button {
                    id: cancelButton
                    text: qsTr("Cancel")
                    font.pixelSize: 12
                    width: 96
                    height: 48
                    anchors.left: parent.left
                    onPressed: {
                         rebootDialog.close()
                    }
                }

                Button {
                    id: confirmButton
                    text: qsTr("Reboot")
                    font.pixelSize: 12
                    width: 96
                    height: 48
                    highlighted: true
                    anchors.right: parent.right
                    anchors.rightMargin: 12
                    onPressed: {
                        openHDSettings.reboot();
                        localMessage("Rebooting...", 3);
                        rebootDialog.close()
                    }
                }
            }
        }

        Component.onCompleted: visible = false
    }
}

