import QtQuick 2.12
import QtQuick.Controls 2.12
import QtQuick.Layouts 1.12
import QtQuick.Dialogs 1.1
import QtQuick.Controls.Material 2.12

import Qt.labs.settings 1.0

import OpenHD 1.0

import "../ui" as Ui
import "../ui/elements"

PowerPanelForm {

    property int powerAction: PowerPanel.PowerAction.RebootGround

    enum PowerAction {
        RebootAir,
        ShutdownAir,
        RebootGround,
        ShutdownGround
    }

    Card {
        id: powerDialog
        height: 240
        width: 400
        z: 5.0
        anchors.centerIn: parent
        cardNameColor: "black"
        hasHeaderImage: true

        Component.onCompleted: visible = false

        property bool stateVisible: visible

        states: [
            State {
                when: powerDialog.stateVisible;
                PropertyChanges {
                    target: powerDialog
                    opacity: 1.0
                }
            },
            State {
                when: !powerDialog.stateVisible;
                PropertyChanges {
                    target: powerDialog
                    opacity: 0.0
                }
            }
        ]
        transitions: [ Transition { NumberAnimation { property: "opacity"; duration: 250}} ]

        cardName: qsTr("Confirm Power Change")
        cardBody: Column {
            Text {
                text: qsTr("If your drone is in the air, rebooting or shutting down the ground or air pi may cause a crash or make it enter failsafe mode!")
                width: parent.width
                leftPadding: 12
                rightPadding: 12
                wrapMode: Text.WordWrap
            }
        }

        hasFooter: true
        cardFooter: Item {
            anchors.fill: parent
            Button {
                id: groundReboot
                width: 96
                height: 48
                text: qsTr("Cancel")
                anchors.left: parent.left
                anchors.leftMargin: 12
                anchors.bottom: parent.bottom
                anchors.bottomMargin: 6
                font.pixelSize: 14
                font.capitalization: Font.MixedCase

                onPressed: {
                    powerDialog.visible = false
                }
            }

            Button {
                id: groundShutdown
                width: 140
                height: 48
                anchors.right: parent.right
                anchors.rightMargin: 12
                anchors.bottom: parent.bottom
                anchors.bottomMargin: 6
                font.pixelSize: 14
                font.capitalization: Font.MixedCase
                Material.accent: Material.Red
                highlighted: true

                text:  {
                    if (powerAction == PowerPanel.PowerAction.RebootGround) {
                        return qsTr("Reboot Ground")
                    }
                    if (powerAction == PowerPanel.PowerAction.ShutdownGround) {
                        return qsTr("Shutdown Ground")
                    }
                    if (powerAction == PowerPanel.PowerAction.RebootAir) {
                        return qsTr("Reboot Air")
                    }
                    if (powerAction == PowerPanel.PowerAction.ShutdownAir) {
                        return qsTr("Shutdown Air")
                    }
                    return qsTr("Yes")
                }



                onPressed: {
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
                    powerDialog.visible = false
                    settings_panel.visible = false;
                }
            }
        }
    }
}
