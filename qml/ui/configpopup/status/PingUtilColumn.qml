import QtQuick 2.12
import QtQuick.Controls 2.12
import QtQuick.Layouts 1.12
import QtQuick.Controls.Material 2.12

import Qt.labs.settings 1.0

import OpenHD 1.0

import "../../../ui" as Ui
import "../../elements"

Item {
    id: root

    implicitHeight: (width < 650 ? 118 : 75) + (_ohdAction.formatAirSdCardStatus !== "Idle" ? 20 : 0)

    function actionButtons() { return [pingButton, autoPingSwitch, storageButton] }

    Dialog {
        id: storageManagerDialog
        parent: Overlay.overlay
        anchors.centerIn: parent
        width: 620
        height: 390
        modal: true
        title: qsTr("Air recording storage")
        standardButtons: Dialog.Close
        onOpened: _ohdAction.refresh_air_storage()

        property var selectedStorage:
            storageCombo.currentIndex >= 0 &&
            storageCombo.currentIndex < _ohdAction.airStorageDevices.length
                ? _ohdAction.airStorageDevices[storageCombo.currentIndex]
                : null

        function sizeText(mib) {
            if (mib >= 1024)
                return (mib / 1024).toFixed(1) + " GiB"
            return Number(mib).toFixed(0) + " MiB"
        }

        contentItem: ColumnLayout {
            spacing: 12

            Label {
                Layout.fillWidth: true
                wrapMode: Text.WordWrap
                text: qsTr("Only removable/non-root storage is shown. The disk containing the OpenHD root filesystem is excluded by sysutils.")
            }
            RowLayout {
                Layout.fillWidth: true
                ComboBox {
                    id: storageCombo
                    Layout.fillWidth: true
                    model: _ohdAction.airStorageDevices
                    textRole: "device"
                    valueRole: "id"
                }
                Button {
                    text: qsTr("Refresh")
                    enabled: !_ohdAction.formatAirSdCardBusy
                    onClicked: _ohdAction.refresh_air_storage()
                }
            }
            Label {
                Layout.fillWidth: true
                text: {
                    var item = storageManagerDialog.selectedStorage
                    if (!item)
                        return qsTr("No safe storage devices found")
                    var kind = item.kind === "disk" ? qsTr("Disk") : qsTr("Partition")
                    var mounted = item.mountedAtVideo ? qsTr(" — mounted at /Video") : ""
                    if (item.kind === "disk")
                        return kind + " — " +
                               storageManagerDialog.sizeText(item.totalMiB) +
                               " total"
                    return kind + " — " +
                           storageManagerDialog.sizeText(item.totalMiB) +
                           " total, " +
                           storageManagerDialog.sizeText(item.freeMiB) +
                           " free" + mounted
                }
            }
            Label {
                Layout.fillWidth: true
                wrapMode: Text.WordWrap
                color: Material.color(Material.Red)
                text: qsTr("Formatting deletes one partition. Repartitioning deletes the entire selected disk and creates one FAT32 RECORDINGS partition.")
            }
            RowLayout {
                Layout.fillWidth: true
                Button {
                    text: qsTr("Format partition")
                    enabled: {
                        var item = storageManagerDialog.selectedStorage
                        return item && item.canFormat &&
                               !_ohdAction.formatAirSdCardBusy
                    }
                    onClicked: storageConfirmDialog.prepare("format")
                }
                Button {
                    text: qsTr("Repartition disk")
                    Material.accent: Material.Red
                    enabled: {
                        var item = storageManagerDialog.selectedStorage
                        return item && item.canRepartition &&
                               !_ohdAction.formatAirSdCardBusy
                    }
                    onClicked: storageConfirmDialog.prepare("repartition")
                }
                Button {
                    text: qsTr("Use for recording")
                    enabled: {
                        var item = storageManagerDialog.selectedStorage
                        return item && item.canMount &&
                               !item.mountedAtVideo &&
                               !_ohdAction.formatAirSdCardBusy
                    }
                    onClicked: storageConfirmDialog.prepare("mount")
                }
            }
            BusyIndicator {
                running: _ohdAction.formatAirSdCardBusy
                visible: running
            }
            Label {
                Layout.fillWidth: true
                text: _ohdAction.formatAirSdCardStatus
            }
        }
    }

    Dialog {
        id: storageConfirmDialog
        parent: Overlay.overlay
        anchors.centerIn: parent
        modal: true
        width: 480
        title: action === "mount" ? qsTr("Change recording storage?")
                                     : qsTr("Confirm destructive operation")
        standardButtons: Dialog.Ok | Dialog.Cancel
        property string action: ""
        property int storageId: 0
        property string storageDevice: ""

        function prepare(requestedAction) {
            var item = storageManagerDialog.selectedStorage
            if (!item)
                return
            action = requestedAction
            storageId = item.id
            storageDevice = item.device
            open()
        }
        onAccepted: {
            if (action === "format")
                _ohdAction.format_air_storage(storageId)
            else if (action === "repartition")
                _ohdAction.repartition_air_storage(storageId)
            else if (action === "mount")
                _ohdAction.mount_air_storage_for_recording(storageId)
        }
        contentItem: Label {
            width: 430
            wrapMode: Text.WordWrap
            text: storageConfirmDialog.action === "mount"
                  ? qsTr("Unmount the current recording partition and mount %1 at /Video? Stop recording first.").arg(storageConfirmDialog.storageDevice)
                  : qsTr("This permanently deletes data on %1. Stop recording and verify the selected device carefully.").arg(storageConfirmDialog.storageDevice)
        }
    }

    Timer {
        id: autopingTimer
        running: false
        interval: 1000
        repeat: true
        onTriggered: {
            _mavlinkTelemetry.ping_all_systems()
        }
    }

    Rectangle {
        anchors.fill: parent
        radius: 17
        color: settings_form.panelBackground
        border.color: settings_form.lineColor
        border.width: 1
    }

    Flow {
        id: actionFlow
        anchors.left: parent.left; anchors.right: parent.right; anchors.top: parent.top
        anchors.margins: 16
        spacing: 10
        height: childrenRect.height

        Button {
            id: pingButton
            width: Math.min(176, Math.max(150, actionFlow.width * 0.25)); height: 43
            text: "\uf140  " + qsTr("PING ALL SYSTEMS")
            font.family: "Font Awesome 5 Free"; font.pixelSize: 11
            onClicked: _mavlinkTelemetry.ping_all_systems()
            background: Rectangle { radius: 10; color: parent.hovered ? "#20384f" : settings_form.panelBackgroundRaised; border.color: parent.activeFocus ? settings_form.accentColor : settings_form.lineColor; border.width: parent.activeFocus ? 2 : 1 }
            contentItem: Text { text: parent.text; font: parent.font; color: settings_form.primaryText; horizontalAlignment: Text.AlignHCenter; verticalAlignment: Text.AlignVCenter }
        }
        Switch {
            id: autoPingSwitch
            width: 132; height: 43
            text: qsTr("Auto-ping")
            onToggled: autopingTimer.running = checked
            contentItem: Text { leftPadding: autoPingSwitch.indicator.width + autoPingSwitch.spacing; text: autoPingSwitch.text; color: settings_form.secondaryText; font.pixelSize: 11; verticalAlignment: Text.AlignVCenter }
        }
        Button {
            id: storageButton
            width: Math.min(212, Math.max(180, actionFlow.width * 0.27)); height: 43
            text: "\uf51f  " + (_ohdAction.formatAirSdCardBusy ? qsTr("STORAGE BUSY...") : qsTr("MANAGE AIR STORAGE"))
            enabled: !_ohdAction.formatAirSdCardBusy && _ohdSystemAir.is_alive
            font.family: "Font Awesome 5 Free"; font.pixelSize: 11
            onClicked: storageManagerDialog.open()
            background: Rectangle { radius: 10; color: parent.hovered ? "#20384f" : settings_form.panelBackgroundRaised; opacity: parent.enabled ? 1 : 0.45; border.color: parent.activeFocus ? settings_form.accentColor : settings_form.lineColor; border.width: parent.activeFocus ? 2 : 1 }
            contentItem: Text { text: parent.text; font: parent.font; color: settings_form.primaryText; opacity: parent.enabled ? 1 : 0.45; horizontalAlignment: Text.AlignHCenter; verticalAlignment: Text.AlignVCenter; elide: Text.ElideRight }
        }
        Text {
            width: actionFlow.width
            height: visible ? 20 : 0
            visible: _ohdAction.formatAirSdCardStatus !== "Idle"
            text: _ohdAction.formatAirSdCardStatus
            color: settings_form.secondaryText
            font.pixelSize: 11
            elide: Text.ElideRight
        }
    }
}
