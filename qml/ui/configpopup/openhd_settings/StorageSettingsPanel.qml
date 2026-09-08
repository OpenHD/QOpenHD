import QtQuick 2.12
import QtQuick.Controls 2.12
import QtQuick.Layouts 1.12
import QtQuick.Controls.Material 2.12

import OpenHD 1.0
import ".."

FocusScope {
    id: root
    signal backRequested()

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

    function gainFocus() {
        refreshButton.forceActiveFocus()
    }

    onVisibleChanged: {
        if (visible && _ohdSystemAir.is_alive && !_ohdAction.formatAirSdCardBusy)
            _ohdAction.refresh_air_storage()
    }

    Keys.onEscapePressed: backRequested()

    Material.theme: settings_form.darkMode ? Material.Dark : Material.Light
    Material.accent: settings_form.accentColor
    Material.foreground: settings_form.primaryText

    Flickable {
        anchors.fill: parent
        anchors.margins: 12
        contentWidth: width
        contentHeight: contentColumn.implicitHeight
        clip: true
        boundsBehavior: Flickable.StopAtBounds
        ScrollBar.vertical: ScrollBar { policy: ScrollBar.AsNeeded }

        ColumnLayout {
            id: contentColumn
            width: parent.width
            spacing: 12

            RowLayout {
                Layout.fillWidth: true
                spacing: 12

                Rectangle {
                    Layout.preferredWidth: 46
                    Layout.preferredHeight: 46
                    radius: 12
                    color: _ohdSystemAir.curr_space_left_mb >= 300
                           ? (settings_form.darkMode ? "#143c2c" : "#dff5e8")
                           : (settings_form.darkMode ? "#4a2025" : "#fde5e7")
                    Text {
                        anchors.centerIn: parent
                        text: "\uf51f"
                        color: _ohdSystemAir.curr_space_left_mb >= 300
                               ? Material.color(Material.Green) : settings_form.errorColor
                        font.family: "Font Awesome 5 Free"
                        font.pixelSize: 21
                    }
                }

                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 2
                    Text {
                        text: qsTr("AIR RECORDING STORAGE")
                        color: settings_form.primaryText
                        font.pixelSize: 18
                        font.bold: true
                    }
                    Text {
                        Layout.fillWidth: true
                        text: !_ohdSystemAir.is_alive
                              ? qsTr("Air unit is offline")
                              : (_ohdSystemAir.curr_space_left_mb >= 300
                                 ? qsTr("Ready - %1 available").arg(root.sizeText(_ohdSystemAir.curr_space_left_mb))
                                 : qsTr("Not ready - at least 300 MiB free is required"))
                        color: _ohdSystemAir.is_alive && _ohdSystemAir.curr_space_left_mb >= 300
                               ? Material.color(Material.Green) : settings_form.errorColor
                        font.pixelSize: 13
                    }
                }

                AdvancedActionButton {
                    id: refreshButton
                    text: qsTr("Refresh")
                    iconText: "\uf2f1"
                    enabled: _ohdSystemAir.is_alive && !_ohdAction.formatAirSdCardBusy
                    onClicked: _ohdAction.refresh_air_storage()
                }
            }

            AdvancedCard {
                Layout.fillWidth: true
                Layout.preferredHeight: 174
                color: settings_form.panelBackgroundRaised

                ColumnLayout {
                    anchors.fill: parent
                    spacing: 10

                    Text {
                        text: qsTr("Recording destination")
                        color: settings_form.primaryText
                        font.pixelSize: 15
                        font.bold: true
                    }
                    Text {
                        Layout.fillWidth: true
                        text: qsTr("Choose where new Air recordings are stored. OpenHD's system disk is protected and is never offered as a format target.")
                        color: settings_form.secondaryText
                        font.pixelSize: 12
                        wrapMode: Text.WordWrap
                    }
                    RowLayout {
                        Layout.fillWidth: true
                        ComboBox {
                            id: storageCombo
                            Layout.fillWidth: true
                            enabled: !_ohdAction.formatAirSdCardBusy
                            model: _ohdAction.airStorageDevices
                            textRole: "device"
                            valueRole: "id"
                        }
                        Text {
                            visible: root.selectedStorage && root.selectedStorage.mountedAtVideo
                            text: qsTr("ACTIVE")
                            color: Material.color(Material.Green)
                            font.pixelSize: 12
                            font.bold: true
                        }
                    }
                    Text {
                        Layout.fillWidth: true
                        text: {
                            var item = root.selectedStorage
                            if (!item)
                                return _ohdSystemAir.is_alive
                                        ? qsTr("No safe removable storage found")
                                        : qsTr("Connect to the Air unit to inspect storage")
                            if (item.kind === "disk")
                                return qsTr("Disk - %1 total - select Repartition to prepare it").arg(root.sizeText(item.totalMiB))
                            return qsTr("Partition - %1 total, %2 free").arg(root.sizeText(item.totalMiB)).arg(root.sizeText(item.freeMiB))
                        }
                        color: settings_form.secondaryText
                        font.pixelSize: 12
                        elide: Text.ElideRight
                    }
                }
            }

            AdvancedCard {
                Layout.fillWidth: true
                Layout.preferredHeight: 154
                color: settings_form.panelBackgroundRaised

                ColumnLayout {
                    anchors.fill: parent
                    spacing: 10
                    Text {
                        text: qsTr("Use selected storage")
                        color: settings_form.primaryText
                        font.pixelSize: 15
                        font.bold: true
                    }
                    Text {
                        Layout.fillWidth: true
                        text: qsTr("Record directly to the selected partition, or safely move existing media there and make it the new destination.")
                        color: settings_form.secondaryText
                        font.pixelSize: 12
                        wrapMode: Text.WordWrap
                    }
                    Flow {
                        Layout.fillWidth: true
                        spacing: 9
                        AdvancedActionButton {
                            id: recordHereButton
                            text: qsTr("Record here")
                            iconText: "\uf03d"
                            primary: true
                            enabled: root.selectedStorage && root.selectedStorage.canMount &&
                                     !root.selectedStorage.mountedAtVideo &&
                                     !_ohdAction.formatAirSdCardBusy
                            onClicked: confirmDialog.prepare("mount")
                        }
                        AdvancedActionButton {
                            text: qsTr("Move media here")
                            iconText: "\uf56f"
                            enabled: root.selectedStorage && root.selectedStorage.canMount &&
                                     !root.selectedStorage.mountedAtVideo &&
                                     !_ohdAction.formatAirSdCardBusy
                            onClicked: confirmDialog.prepare("migrate")
                        }
                    }
                }
            }

            AdvancedCard {
                Layout.fillWidth: true
                Layout.preferredHeight: 154
                color: settings_form.panelBackgroundRaised

                ColumnLayout {
                    anchors.fill: parent
                    spacing: 10
                    Text {
                        text: qsTr("Prepare storage")
                        color: settings_form.errorColor
                        font.pixelSize: 15
                        font.bold: true
                    }
                    Text {
                        Layout.fillWidth: true
                        text: qsTr("Formatting erases one partition. Repartitioning erases the entire disk and creates one FAT32 RECORDINGS partition.")
                        color: settings_form.secondaryText
                        font.pixelSize: 12
                        wrapMode: Text.WordWrap
                    }
                    Flow {
                        Layout.fillWidth: true
                        spacing: 9
                        AdvancedActionButton {
                            text: qsTr("Format partition")
                            iconText: "\uf2ed"
                            destructive: true
                            enabled: root.selectedStorage && root.selectedStorage.canFormat &&
                                     !_ohdAction.formatAirSdCardBusy
                            onClicked: confirmDialog.prepare("format")
                        }
                        AdvancedActionButton {
                            text: qsTr("Repartition disk")
                            iconText: "\uf7c2"
                            destructive: true
                            enabled: root.selectedStorage && root.selectedStorage.canRepartition &&
                                     !_ohdAction.formatAirSdCardBusy
                            onClicked: confirmDialog.prepare("repartition")
                        }
                    }
                }
            }

            RowLayout {
                Layout.fillWidth: true
                visible: _ohdAction.formatAirSdCardBusy || _ohdAction.formatAirSdCardStatus !== "Idle"
                BusyIndicator {
                    running: _ohdAction.formatAirSdCardBusy
                    visible: running
                    Layout.preferredWidth: 28
                    Layout.preferredHeight: 28
                }
                Text {
                    Layout.fillWidth: true
                    text: _ohdAction.formatAirSdCardStatus
                    color: _ohdAction.formatAirSdCardBusy
                           ? settings_form.accentColor : settings_form.secondaryText
                    font.pixelSize: 12
                    wrapMode: Text.WordWrap
                }
            }
        }
    }

    AdvancedDialog {
        id: confirmDialog
        parent: Overlay.overlay
        anchors.centerIn: parent
        modal: true
        width: Math.min(500, root.width - 30)
        title: action === "mount" ? qsTr("Change recording destination?")
               : action === "migrate" ? qsTr("Move Air recordings?")
                                      : qsTr("Confirm destructive operation")
        standardButtons: Dialog.Ok | Dialog.Cancel
        property string action: ""
        property int storageId: 0
        property string storageDevice: ""

        function prepare(requestedAction) {
            var item = root.selectedStorage
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
            else if (action === "migrate")
                _ohdAction.migrate_air_recordings(storageId)
        }
        contentItem: Label {
            width: confirmDialog.width - 48
            wrapMode: Text.WordWrap
            text: confirmDialog.action === "mount"
                  ? qsTr("Use %1 for all new Air recordings? Recording must be stopped while the destination changes.").arg(confirmDialog.storageDevice)
                  : confirmDialog.action === "migrate"
                    ? qsTr("Move existing Air recordings to %1? Recording must be stopped. Source files are removed only after they were copied successfully.").arg(confirmDialog.storageDevice)
                    : qsTr("This permanently deletes data on %1. Stop recording and verify the selected device carefully.").arg(confirmDialog.storageDevice)
        }
    }
}
