import QtQuick 2.12
import QtQuick.Controls 2.12
import QtQuick.Layouts 1.12
import QtQuick.Dialogs 1.1

import Qt.labs.settings 1.0

import OpenHD 1.0

import "../ui" as Ui

PowerPanelForm {

    property int powerAction: PowerPanel.PowerAction.RebootGround

    enum PowerAction {
        RebootAir,
        ShutdownAir,
        RebootGround,
        ShutdownGround
    }

    MessageDialog {
        id: powerDialog
        title: qsTr("Are you sure?")
        text: qsTr("If your drone is in the air, rebooting or shutting down the ground or air pi may cause a crash or make it enter failsafe mode!")
        icon: StandardIcon.Warning
        standardButtons: StandardButton.Yes | StandardButton.Cancel
        onYes: {
            if (powerAction == PowerPanel.PowerAction.RebootGround) {
                localMessage("Rebooting ground station", 3);
                GroundPowerMicroservice.onReboot();
            }
            if (powerAction == PowerPanel.PowerAction.ShutdownGround) {
                localMessage("Shutting down ground station", 3);
                GroundPowerMicroservice.onShutdown();
            }
            if (powerAction == PowerPanel.PowerAction.RebootAir) {
                localMessage("Rebooting air pi", 3);
                AirPowerMicroservice.onReboot();
            }
            if (powerAction == PowerPanel.PowerAction.ShutdownAir) {
                localMessage("Shutting down air pi", 3);
                AirPowerMicroservice.onShutdown();
            }
            powerDialog.close()
            settings_panel.close()
        }
        onRejected: {
             powerDialog.close()
        }

        Component.onCompleted: visible = false
    }
}
