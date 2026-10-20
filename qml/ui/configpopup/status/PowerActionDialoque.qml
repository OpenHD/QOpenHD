import QtQuick 2.12
import QtQuick.Controls 2.12
import QtQuick.Layouts 1.12

import QtQuick.Controls.Material 2.12

import Qt.labs.settings 1.0

import OpenHD 1.0

import "../../../ui" as Ui
import "../../elements"


// Dialoque that does all the power commands (reboot / shutdown)
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

    function open_dialoque(system,reboot){
        var action=PowerActionDialoque.PowerAction.RebootGround
        if(system==0){
            // OHD GND
            action = reboot ? PowerActionDialoque.PowerAction.RebootGround : PowerActionDialoque.PowerAction.ShutdownGround
        }else if(system==1){
            action = reboot ? PowerActionDialoque.PowerAction.RebootAir : PowerActionDialoque.PowerAction.ShutdownAir
        }else{
            action = reboot ? PowerActionDialoque.PowerAction.RebootFC : PowerActionDialoque.PowerAction.ShutdownFC
        }
        powerDialog.powerAction=action
        powerDialog.visible=true
    }

    enum PowerAction {
        RebootAir,
        ShutdownAir,
        RebootGround,
        ShutdownGround,
        RebootFC,
        ShutdownFC
    }
    property int powerAction: PowerActionDialoque.PowerAction.RebootGround


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
        height: powerDialog.height
        width: powerDialog.width

        Text {
            text: qsTr("If your drone is in the air, rebooting or shutting down may cause a crash or make it enter failsafe mode!")
            width: parent.width
            leftPadding: 12
            rightPadding: 12
            wrapMode: Text.WordWrap
            color: settings_form.primaryText
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
                if (powerAction === PowerActionDialoque.PowerAction.RebootGround) {
                    return qsTr("Reboot Ground")
                }
                if (powerAction === PowerActionDialoque.PowerAction.ShutdownGround) {
                    return qsTr("Shutdown Ground")
                }
                if (powerAction === PowerActionDialoque.PowerAction.RebootAir) {
                    return qsTr("Reboot Air")
                }
                if (powerAction === PowerActionDialoque.PowerAction.ShutdownAir) {
                    return qsTr("Shutdown Air")
                }
                if (powerAction === PowerActionDialoque.PowerAction.RebootFC) {
                    return qsTr("Reboot FC")
                }
                if (powerAction === PowerActionDialoque.PowerAction.ShutdownFC) {
                    return qsTr("Shutdown FC")
                }
                return qsTr("Yes")
            }



            onPressed: {
                var isGround = powerAction === PowerActionDialoque.PowerAction.RebootGround
                        || powerAction === PowerActionDialoque.PowerAction.ShutdownGround
                var isAir = powerAction === PowerActionDialoque.PowerAction.RebootAir
                        || powerAction === PowerActionDialoque.PowerAction.ShutdownAir
                var reboot = powerAction === PowerActionDialoque.PowerAction.RebootGround
                        || powerAction === PowerActionDialoque.PowerAction.RebootAir
                        || powerAction === PowerActionDialoque.PowerAction.RebootFC
                var result
                if (isGround || isAir) {
                    result = _ohdAction.request_power_action(isGround, reboot)
                } else {
                    result = _fcMavlinkAction.send_command_reboot(reboot) ? "accepted" : "unconfirmed"
                }
                if (result === "accepted" || result === "unconfirmed") {
                    settings_panel.close_all()
                    powerDialog.visible = false
                }
                var message
                if (result === "accepted") {
                    message = reboot ? qsTr("Reboot request accepted") : qsTr("Shutdown request accepted")
                } else if (result === "unconfirmed") {
                    message = reboot ? qsTr("No confirmation received; the unit may already be rebooting")
                                     : qsTr("No confirmation received; the unit may already be shutting down")
                } else if (result === "denied") {
                    message = qsTr("Reboot/Shutdown request rejected by the unit")
                } else {
                    message = qsTr("Could not queue Reboot/Shutdown request; please try again")
                }
                _qopenhd.show_toast(message)
            }
        }
    }
}

