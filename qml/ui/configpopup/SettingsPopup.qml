import QtQuick 2.12
import QtQuick.Controls 2.12
import QtQuick.Dialogs 1.3
import QtQuick.Layouts 1.12
import QtQuick.Window 2.12
import Qt.labs.settings 1.0

import OpenHD 1.0


//This is the main popup panel (Settings, Info and more) that is opened when you click the upper left icon.
SettingsPopupForm {
    id: settings_form
    signal localMessage(var message, var level)
    signal settingsClosed

    function openSettings() {
        visible = true
    }

    closeButton.onClicked: {
        visible = false
        settings_form.settingsClosed()
    }
}

