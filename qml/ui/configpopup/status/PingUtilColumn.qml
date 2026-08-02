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

    ColumnLayout {
        // 2 Rows
        anchors.left: parent.left
        anchors.leftMargin: 12

        RowLayout {
            id: actions_1
            width: parent.width
            ButtonIconInfo {
                onClicked: {
                    _messageBoxInstance.set_text_and_show(qsTr("Ping all systems, aka check if they respond to the mavlink ping command. Both OpenHD air and ground support this command, FC only ardupilot / px4 support this command. The command is lossy, aka you might need to use it more than once to get a response from all systems. No response after >10 tries is a hint that one of your systems is not functioning properly."))
                }
            }
            Button {
                text: qsTr("Ping all systems")
                onClicked: _mavlinkTelemetry.ping_all_systems()
            }
            Switch {
                text: qsTr("Auto-ping")
                onCheckedChanged: {
                    if (checked) {
                        autopingTimer.start()
                    } else {
                        autopingTimer.stop()
                    }
                }
            }
            Button {
                text: _ohdAction.formatAirSdCardBusy
                      ? qsTr("Storage operation running...")
                      : qsTr("Manage air storage")
                enabled: !_ohdAction.formatAirSdCardBusy && _ohdSystemAir.is_alive
                Material.accent: Material.Red
                onClicked: storageManagerDialog.open()
            }
            Label {
                visible: _ohdAction.formatAirSdCardStatus !== "Idle"
                text: _ohdAction.formatAirSdCardStatus
            }
            // Padding
            Item {
                // Padding
            }
        }
    }
}
