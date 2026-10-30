import "../MenuTypography.js" as MenuTypography
import QtQuick 2.12
import QtQuick.Controls 2.12
import QtQuick.Layouts 1.12
import ".."

AdvancedDialog {
    id: powerDialog
    objectName: "powerActionDialog"
    parent: Overlay.overlay
    anchors.centerIn: parent
    width: Math.min(480, parent ? parent.width - 32 : 480)
    title: qsTr("Confirm power change")
    closePolicy: powerRequestPending ? Popup.NoAutoClose : Popup.CloseOnEscape

    property bool powerRequestPending: false
    property bool pendingGround: false
    property bool pendingReboot: false

    function finish_power_action(result, reboot) {
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
        } else if (result === "busy") {
            message = qsTr("A Reboot/Shutdown request is already pending")
        } else {
            message = qsTr("Could not queue Reboot/Shutdown request; please try again")
        }
        _qopenhd.show_toast(message)
    }

    Connections {
        target: _ohdAction
        function onPowerActionFinished(ground, reboot, result) {
            if (!powerDialog.powerRequestPending || ground !== powerDialog.pendingGround
                    || reboot !== powerDialog.pendingReboot) return
            powerDialog.powerRequestPending = false
            powerDialog.finish_power_action(result, reboot)
        }
    }

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
        powerDialog.open()
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

    readonly property string actionLabel: {
                if (powerDialog.powerRequestPending) return qsTr("Sending...")
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

    contentItem: Text {
        objectName: "powerActionWarning"
        text: qsTr("Rebooting or shutting down during flight may cause a crash or trigger failsafe mode.")
        color: "#edf4fa"
        font.family: MenuTypography.family
        font.pixelSize: MenuTypography.body
        wrapMode: Text.WordWrap
    }
    footer: Item {
        implicitHeight: actions.implicitHeight + 32
        RowLayout {
            id: actions
            anchors.left: parent.left; anchors.right: parent.right
            anchors.margins: 20
            anchors.verticalCenter: parent.verticalCenter
            spacing: 12
            AdvancedDialogButton {
                objectName: "powerActionCancel"
                Layout.fillWidth: true
                Layout.preferredWidth: 1
                topInset: 0; bottomInset: 0
                font.capitalization: Font.MixedCase
                enabled: !powerDialog.powerRequestPending
                text: qsTr("Cancel")
                onClicked: powerDialog.reject()
            }
            AdvancedDialogButton {
                objectName: "powerActionConfirm"
                Layout.fillWidth: true
                Layout.preferredWidth: 1
                topInset: 0; bottomInset: 0
                font.capitalization: Font.MixedCase
                enabled: !powerDialog.powerRequestPending && !_ohdAction.powerActionBusy
                destructive: true
                text: powerDialog.actionLabel
                onClicked: {
                    var isGround = powerAction === PowerActionDialoque.PowerAction.RebootGround
                            || powerAction === PowerActionDialoque.PowerAction.ShutdownGround
                    var isAir = powerAction === PowerActionDialoque.PowerAction.RebootAir
                            || powerAction === PowerActionDialoque.PowerAction.ShutdownAir
                    var reboot = powerAction === PowerActionDialoque.PowerAction.RebootGround
                            || powerAction === PowerActionDialoque.PowerAction.RebootAir
                            || powerAction === PowerActionDialoque.PowerAction.RebootFC
                    var result
                    if (isGround || isAir) {
                        powerDialog.pendingGround = isGround
                        powerDialog.pendingReboot = reboot
                        result = _ohdAction.request_power_action(isGround, reboot)
                        if (result === "queued") {
                            powerDialog.powerRequestPending = true
                            return
                        }
                    } else {
                        result = _fcMavlinkAction.send_command_reboot(reboot) ? "accepted" : "unconfirmed"
                    }
                    powerDialog.finish_power_action(result, reboot)
                }

            }
        }
    }
}
