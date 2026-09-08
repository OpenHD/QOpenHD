import QtQuick 2.12
import QtQuick.Controls 2.12
import QtQuick.Layouts 1.12
import QtQuick.Controls.Material 2.12

import OpenHD 1.0
import ".."

FocusScope {
    id: root
    signal backRequested()

    readonly property bool canOperate: _ohdSystemAir.is_alive && !_ohdAction.formatAirSdCardBusy
    readonly property var devices: _ohdAction.airStorageDevices

    function sizeText(mib) {
        var value = Number(mib)
        if (!isFinite(value) || value <= 0) return "0 MiB"
        if (value >= 1024) return (value / 1024).toFixed(value >= 10240 ? 0 : 1) + " GiB"
        return value.toFixed(0) + " MiB"
    }

    function parentDevice(device) {
        var value = String(device || "")
        if (/p[0-9]+$/.test(value)) return value.replace(/p[0-9]+$/, "")
        return value.replace(/[0-9]+$/, "")
    }

    function disks() {
        var result = []
        for (var i = 0; i < devices.length; ++i)
            if (devices[i].kind === "disk") result.push(devices[i])
        return result
    }

    function partitionsFor(disk) {
        var result = []
        for (var i = 0; i < devices.length; ++i) {
            var item = devices[i]
            var userCanUse = item.mountedAtVideo || item.canMount || item.canFormat
            if (item.kind === "partition" &&
                    parentDevice(item.device) === disk.device && userCanUse)
                result.push(item)
        }
        return result
    }

    function orphanPartitions() {
        var result = []
        for (var i = 0; i < devices.length; ++i) {
            var item = devices[i]
            if (item.kind !== "partition") continue
            if (!item.mountedAtVideo && !item.canMount && !item.canFormat) continue
            var found = false
            for (var j = 0; j < devices.length; ++j) {
                if (devices[j].kind === "disk" && devices[j].device === parentDevice(item.device)) {
                    found = true
                    break
                }
            }
            if (!found) result.push(item)
        }
        return result
    }

    function activePartition() {
        for (var i = 0; i < devices.length; ++i)
            if (devices[i].mountedAtVideo) return devices[i]
        return null
    }

    function friendlyDiskName(item) {
        if (item.internal) return qsTr("Internal storage")
        if (String(item.device).indexOf("/dev/sd") === 0) return qsTr("USB storage")
        return qsTr("Removable storage")
    }

    function friendlyPartitionName(item, position) {
        if (item.mountedAtVideo) return qsTr("Recording partition")
        return qsTr("Partition %1").arg(position + 1)
    }

    function usage(item) {
        var total = Math.max(0, Number(item.totalMiB))
        var free = Math.max(0, Number(item.freeMiB))
        return total > 0 ? Math.max(0, Math.min(1, (total - free) / total)) : 0
    }

    function gainFocus() {
        if (refreshButton.enabled) refreshButton.forceActiveFocus()
        else root.forceActiveFocus()
    }

    onVisibleChanged: if (visible && canOperate) _ohdAction.refresh_air_storage()
    Keys.onEscapePressed: backRequested()

    Material.theme: settings_form.darkMode ? Material.Dark : Material.Light
    Material.accent: settings_form.accentColor
    Material.foreground: settings_form.primaryText

    Component {
        id: partitionRow
        Rectangle {
            id: partition
            property var storageItem
            property int position: 0
            width: parent ? parent.width : 0
            height: 112
            radius: 9
            color: settings_form.darkMode ? "#102438" : "#f3f7fb"
            border.width: storageItem && storageItem.mountedAtVideo ? 2 : 1
            border.color: storageItem && storageItem.mountedAtVideo ? settings_form.accentColor : settings_form.lineColor

            ColumnLayout {
                anchors.fill: parent
                anchors.margins: 12
                spacing: 7

                RowLayout {
                    Layout.fillWidth: true
                    spacing: 8
                    Text {
                        text: storageItem ? root.friendlyPartitionName(storageItem, position) : ""
                        color: settings_form.primaryText
                        font.pixelSize: 14
                        font.bold: true
                    }
                    Rectangle {
                        visible: storageItem && storageItem.mountedAtVideo
                        implicitWidth: activeText.implicitWidth + 14
                        implicitHeight: 22
                        radius: 11
                        color: settings_form.darkMode ? "#174733" : "#dff5e8"
                        Text {
                            id: activeText
                            anchors.centerIn: parent
                            text: qsTr("IN USE")
                            color: settings_form.darkMode ? "#62d99b" : "#16744a"
                            font.pixelSize: 10
                            font.bold: true
                        }
                    }
                    Item { Layout.fillWidth: true }
                    Text {
                        text: storageItem ? qsTr("%1 free of %2").arg(root.sizeText(storageItem.freeMiB)).arg(root.sizeText(storageItem.totalMiB)) : ""
                        color: settings_form.secondaryText
                        font.pixelSize: 12
                    }
                }

                Rectangle {
                    Layout.fillWidth: true
                    Layout.preferredHeight: 8
                    radius: 4
                    color: settings_form.darkMode ? "#263b4e" : "#dce5ed"
                    Rectangle {
                        width: storageItem ? parent.width * root.usage(storageItem) : 0
                        height: parent.height
                        radius: 4
                        color: storageItem && root.usage(storageItem) > 0.9
                               ? (settings_form.darkMode ? "#f4b844" : "#c47b00")
                               : settings_form.accentColor
                    }
                }

                RowLayout {
                    Layout.fillWidth: true
                    spacing: 8
                    Text {
                        Layout.fillWidth: true
                        text: storageItem && storageItem.mountedAtVideo && Number(storageItem.freeMiB) < 300
                              ? qsTr("Storage is full")
                              : (storageItem && storageItem.formatted
                                 ? qsTr("Ready to store recordings")
                                 : qsTr("Needs to be prepared"))
                        color: settings_form.secondaryText
                        font.pixelSize: 11
                    }
                    AdvancedActionButton {
                        visible: storageItem && !storageItem.mountedAtVideo && storageItem.canMount
                        text: qsTr("Use for recordings")
                        iconText: "\uf03d"
                        primary: true
                        enabled: root.canOperate
                        onClicked: confirmDialog.prepare("mount", storageItem)
                    }
                    AdvancedActionButton {
                        visible: storageItem && !storageItem.formatted && storageItem.canFormat
                        text: qsTr("Prepare")
                        iconText: "\uf0ad"
                        primary: true
                        enabled: root.canOperate
                        onClicked: confirmDialog.prepare("format", storageItem)
                    }
                    AdvancedActionButton {
                        visible: storageItem && storageItem.formatted && storageItem.canFormat
                        text: qsTr("Erase")
                        iconText: "\uf2ed"
                        destructive: true
                        enabled: root.canOperate
                        onClicked: confirmDialog.prepare("format", storageItem)
                    }
                }
            }
        }
    }

    Flickable {
        anchors.fill: parent
        anchors.margins: 16
        contentWidth: width
        contentHeight: contentColumn.implicitHeight
        clip: true
        boundsBehavior: Flickable.StopAtBounds
        ScrollBar.vertical: ScrollBar { policy: ScrollBar.AsNeeded }

        ColumnLayout {
            id: contentColumn
            width: parent.width
            spacing: 14

            RowLayout {
                Layout.fillWidth: true
                spacing: 13
                Rectangle {
                    Layout.preferredWidth: 48
                    Layout.preferredHeight: 48
                    radius: 13
                    color: root.activePartition() ? (settings_form.darkMode ? "#173b61" : "#dcecff") : (settings_form.darkMode ? "#3d3020" : "#fff1d6")
                    Text {
                        anchors.centerIn: parent
                        text: "\uf51f"
                        color: root.activePartition() ? settings_form.accentColor : "#e6a52e"
                        font.family: "Font Awesome 5 Free"
                        font.pixelSize: 21
                    }
                }
                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 2
                    Text {
                        text: qsTr("Recording storage")
                        color: settings_form.primaryText
                        font.pixelSize: 20
                        font.bold: true
                    }
                    Text {
                        Layout.fillWidth: true
                        text: !_ohdSystemAir.is_alive
                              ? qsTr("Connect to the Air unit to see its storage")
                              : (root.activePartition() && Number(root.activePartition().freeMiB) < 300
                                 ? qsTr("Storage is full · free up space to record")
                                 : (root.activePartition()
                                    ? qsTr("Ready · %1 available").arg(root.sizeText(root.activePartition().freeMiB))
                                    : qsTr("Choose where Air recordings should be saved")))
                        color: root.activePartition() && Number(root.activePartition().freeMiB) < 300
                               ? (settings_form.darkMode ? "#f4b844" : "#9a6200")
                               : (root.activePartition() ? settings_form.secondaryText : "#e6a52e")
                        font.pixelSize: 12
                    }
                }
                AdvancedActionButton {
                    id: refreshButton
                    text: qsTr("Refresh")
                    iconText: "\uf2f1"
                    enabled: root.canOperate
                    onClicked: _ohdAction.refresh_air_storage()
                }
            }

            ColumnLayout {
                Layout.fillWidth: true
                visible: root.devices.length > 0
                spacing: 3
                Text {
                    text: qsTr("Available storage")
                    color: settings_form.primaryText
                    font.pixelSize: 15
                    font.bold: true
                }
                Text {
                    text: qsTr("USB drives appear automatically when you plug them into the Air unit.")
                    color: settings_form.secondaryText
                    font.pixelSize: 12
                }
            }

            Repeater {
                model: root.disks()
                delegate: AdvancedCard {
                    id: diskCard
                    property var diskItem: modelData
                    property var diskPartitions: root.partitionsFor(diskItem)
                    Layout.fillWidth: true
                    Layout.preferredHeight: diskContents.implicitHeight + 32
                    color: settings_form.panelBackgroundRaised

                    ColumnLayout {
                        id: diskContents
                        anchors.fill: parent
                        spacing: 10
                        RowLayout {
                            Layout.fillWidth: true
                            spacing: 11
                            Rectangle {
                                Layout.preferredWidth: 40
                                Layout.preferredHeight: 40
                                radius: 10
                                color: settings_form.darkMode ? "#1a344b" : "#e5f0fa"
                                Text {
                                    anchors.centerIn: parent
                                    text: diskCard.diskItem.internal ? "\uf0a0" : "\uf8e9"
                                    color: settings_form.accentColor
                                    font.family: "Font Awesome 5 Free"
                                    font.pixelSize: 18
                                }
                            }
                            ColumnLayout {
                                Layout.fillWidth: true
                                spacing: 1
                                Text {
                                    text: root.friendlyDiskName(diskCard.diskItem)
                                    color: settings_form.primaryText
                                    font.pixelSize: 15
                                    font.bold: true
                                }
                                Text {
                                    text: qsTr("%1 total").arg(root.sizeText(diskCard.diskItem.totalMiB))
                                    color: settings_form.secondaryText
                                    font.pixelSize: 12
                                }
                            }
                            Rectangle {
                                implicitWidth: typeText.implicitWidth + 16
                                implicitHeight: 24
                                radius: 12
                                color: settings_form.darkMode ? "#20384e" : "#e8f0f7"
                                Text {
                                    id: typeText
                                    anchors.centerIn: parent
                                    text: diskCard.diskItem.internal ? qsTr("INTERNAL") : qsTr("REMOVABLE")
                                    color: settings_form.secondaryText
                                    font.pixelSize: 10
                                    font.bold: true
                                }
                            }
                        }

                        Repeater {
                            model: diskCard.diskPartitions
                            delegate: Loader {
                                Layout.fillWidth: true
                                Layout.preferredHeight: 112
                                sourceComponent: partitionRow
                                onLoaded: { item.storageItem = modelData; item.position = index }
                            }
                        }

                        Rectangle {
                            Layout.fillWidth: true
                            Layout.preferredHeight: 58
                            visible: diskCard.diskPartitions.length > 0 &&
                                     Number(diskCard.diskItem.freeMiB) >= 1024
                            radius: 9
                            color: settings_form.darkMode ? "#142c2a" : "#eaf7f1"
                            RowLayout {
                                anchors.fill: parent
                                anchors.margins: 10
                                spacing: 9
                                Text {
                                    text: "\uf067"
                                    color: "#46c889"
                                    font.family: "Font Awesome 5 Free"
                                    font.pixelSize: 14
                                }
                                Text {
                                    Layout.fillWidth: true
                                    text: qsTr("%1 unallocated space").arg(root.sizeText(diskCard.diskItem.freeMiB))
                                    color: settings_form.primaryText
                                    font.pixelSize: 12
                                }
                                AdvancedActionButton {
                                    text: qsTr("Add recording partition")
                                    iconText: "\uf067"
                                    primary: true
                                    enabled: root.canOperate && diskCard.diskItem.canCreatePartition
                                    onClicked: confirmDialog.prepare("create", diskCard.diskItem)
                                }
                            }
                        }

                        RowLayout {
                            Layout.fillWidth: true
                            visible: diskCard.diskPartitions.length === 0 || diskCard.diskItem.canResizePartition
                            spacing: 8
                            Text {
                                Layout.fillWidth: true
                                visible: diskCard.diskPartitions.length === 0
                                text: qsTr("No recording partition yet")
                                color: settings_form.secondaryText
                                font.pixelSize: 12
                            }
                            AdvancedActionButton {
                                visible: diskCard.diskPartitions.length === 0 && diskCard.diskItem.canRepartition
                                text: qsTr("Set up storage")
                                iconText: "\uf0ad"
                                primary: true
                                enabled: root.canOperate
                                onClicked: confirmDialog.prepare("repartition", diskCard.diskItem)
                            }
                            AdvancedActionButton {
                                visible: diskCard.diskItem.canResizePartition
                                text: qsTr("Make space for recordings")
                                iconText: "\uf065"
                                primary: true
                                enabled: root.canOperate
                                onClicked: confirmDialog.prepare("resize", diskCard.diskItem)
                            }
                        }
                    }
                }
            }

            Repeater {
                model: root.orphanPartitions()
                delegate: Loader {
                    Layout.fillWidth: true
                    Layout.preferredHeight: 112
                    sourceComponent: partitionRow
                    onLoaded: { item.storageItem = modelData; item.position = index }
                }
            }

            AdvancedCard {
                Layout.fillWidth: true
                Layout.preferredHeight: 132
                visible: _ohdSystemAir.is_alive && root.devices.length === 0 && !_ohdAction.formatAirSdCardBusy
                color: settings_form.panelBackgroundRaised
                ColumnLayout {
                    anchors.centerIn: parent
                    width: parent.width
                    spacing: 8
                    Text {
                        Layout.alignment: Qt.AlignHCenter
                        text: "\uf287"
                        color: settings_form.secondaryText
                        font.family: "Font Awesome 5 Free"
                        font.pixelSize: 25
                    }
                    Text {
                        Layout.alignment: Qt.AlignHCenter
                        text: qsTr("No storage was detected")
                        color: settings_form.primaryText
                        font.pixelSize: 14
                        font.bold: true
                    }
                    Text {
                        Layout.alignment: Qt.AlignHCenter
                        text: qsTr("Insert a USB drive, then press Refresh")
                        color: settings_form.secondaryText
                        font.pixelSize: 12
                    }
                }
            }

            RowLayout {
                Layout.fillWidth: true
                visible: _ohdAction.formatAirSdCardBusy || (_ohdAction.formatAirSdCardStatus !== "Idle" && _ohdAction.formatAirSdCardStatus !== "Storage operation complete")
                spacing: 9
                BusyIndicator {
                    running: _ohdAction.formatAirSdCardBusy
                    visible: running
                    Layout.preferredWidth: 26
                    Layout.preferredHeight: 26
                }
                Text {
                    Layout.fillWidth: true
                    text: _ohdAction.formatAirSdCardStatus
                    color: _ohdAction.formatAirSdCardBusy ? settings_form.accentColor : settings_form.secondaryText
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
        property string action: ""
        property int storageId: 0

        title: action === "mount" ? qsTr("Use this for recordings?") : action === "format" ? qsTr("Prepare this partition?") : action === "create" ? qsTr("Add recording space?") : action === "resize" ? qsTr("Make room for recordings?") : qsTr("Set up this storage?")
        standardButtons: Dialog.Ok | Dialog.Cancel

        function prepare(requestedAction, item) {
            action = requestedAction
            storageId = item.id
            open()
        }

        onAccepted: {
            if (action === "format") _ohdAction.format_air_storage(storageId)
            else if (action === "repartition") _ohdAction.repartition_air_storage(storageId)
            else if (action === "create") _ohdAction.create_air_storage_partition(storageId)
            else if (action === "resize") _ohdAction.resize_air_storage_partition(storageId)
            else if (action === "mount") _ohdAction.mount_air_storage_for_recording(storageId)
        }

        contentItem: Label {
            width: confirmDialog.width - 48
            wrapMode: Text.WordWrap
            text: confirmDialog.action === "mount" ? qsTr("New Air recordings will be saved on this partition. Existing recordings stay where they are.") : confirmDialog.action === "format" ? qsTr("This partition will be erased and prepared automatically for OpenHD recordings.") : confirmDialog.action === "create" ? qsTr("OpenHD will use the available unallocated space to create a recording partition. Existing partitions are left unchanged.") : confirmDialog.action === "resize" ? qsTr("OpenHD will reduce the main partition and create dedicated recording space. Back up important data before continuing.") : qsTr("This USB drive will be erased and prepared automatically for OpenHD recordings.")
        }
    }
}
