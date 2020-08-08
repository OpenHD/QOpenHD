import QtQuick 2.12
import QtQuick.Controls 2.12
import QtQuick.Dialogs 1.3
import QtQuick.Layouts 1.12
import QtQuick.Window 2.12
import Qt.labs.settings 1.0

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

    closeButton.onClicked: {
        visible = false
        if (IsRaspPi) {
            ManageSettings.savePiSettings();
        }
    }
}

