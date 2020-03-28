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


    MessageDialog {
        id: rebootDialog
        title: qsTr("Reboot ground station?")
        text: qsTr("This will immediately reboot the ground station!\n\nIf your drone is armed it may crash or enter failsafe mode.\n\nYou have been warned.")
        icon: StandardIcon.Warning
        standardButtons: StandardButton.Yes | StandardButton.Cancel
        onYes: {
            openHDSettings.reboot();
            localMessage("Rebooting...", 3);
            rebootDialog.close()
        }
        onRejected: {
             rebootDialog.close()
        }

        Component.onCompleted: visible = false
    }
}

