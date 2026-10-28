import QtQuick 2.12
import QtQuick.Controls 2.12
import QtQuick.Layouts 1.12

import OpenHD 1.0

Rectangle {
    id: root
    color: settings_form.pageBackground
    focus: false

    property int keyboardIndex: 0
    // A modal popup lives in the window overlay, outside this page's visual
    // hierarchy. Close it when navigating away so it cannot block the menu.
    onVisibleChanged: if (!visible) {
        groundDetails.close()
        unitDetails.close()
        craftDetails.close()
        powerDialog.close()
        dialoqueNotAlive.close()
    }

    function voltage_as_string(voltage_mv) { return voltage_mv === 0 ? "N/A" : voltage_mv + " mV" }
    function current_as_string(current_ma) { return current_ma === 0 ? "N/A" : current_ma + " mA" }
    function open_power_action_dialoque(system, reboot) {
        powerDialog.open("open_dialoque", [system, reboot])
    }
    function open_not_alive_dialog(system) {
        dialoqueNotAlive.open(system === 0 ? "open_ground" : "open_air", [])
    }

    function controls() {
        var all = settings_form.frameworkActionButtons().concat(statusCards.actionButtons())
        var available = []
        for (var i = 0; i < all.length; ++i) {
            if (all[i] && all[i].visible && all[i].enabled)
                available.push(all[i])
        }
        return available
    }
    function gainFocus() {
        var list = controls()
        if (list.length === 0) {
            root.forceActiveFocus()
            return
        }
        keyboardIndex = Math.max(0, Math.min(keyboardIndex, list.length - 1))
        list[keyboardIndex].forceActiveFocus()
        content.ensureVisible(list[keyboardIndex])
    }
    function syncFocus(control) {
        var list = controls()
        for (var i = 0; i < list.length; ++i) {
            if (list[i] === control) {
                keyboardIndex = i
                return
            }
        }
    }
    function moveFocus(step) {
        var list = controls()
        if (list.length === 0)
            return
        keyboardIndex = (keyboardIndex + step + list.length) % list.length
        list[keyboardIndex].forceActiveFocus()
        content.ensureVisible(list[keyboardIndex])
    }

    Keys.onPressed: function(event) {
        if (event.key === Qt.Key_Down || event.key === Qt.Key_Right) {
            moveFocus(1)
            event.accepted = true
        } else if (event.key === Qt.Key_Up) {
            moveFocus(-1)
            event.accepted = true
        } else if (event.key === Qt.Key_Left || event.key === Qt.Key_Escape) {
            settings_form.side_bar_regain_focus()
            event.accepted = true
        }
    }

    Flickable {
        id: content
        anchors.fill: parent
        anchors.topMargin: 12
        anchors.bottomMargin: 16
        anchors.leftMargin: root.width < 900 ? 13 : Math.min(54, root.width * 0.035)
        anchors.rightMargin: root.width < 900 ? 13 : Math.min(54, root.width * 0.035)
        clip: true
        contentWidth: width
        // Defer the extent update until the responsive grid has settled.
        // Qt 5 can re-enter a contentHeight binding while GridLayout relayouts.
        function updateExtent() {
            statusCards.y = Math.max(0, Math.round((height - statusCards.implicitHeight) / 2))
            contentHeight = Math.max(height, statusCards.implicitHeight + 24)
        }
        onHeightChanged: Qt.callLater(updateExtent)
        Component.onCompleted: Qt.callLater(updateExtent)
        boundsBehavior: Flickable.StopAtBounds
        flickableDirection: Flickable.VerticalFlick

        function ensureVisible(item) {
            var p = item.mapToItem(content.contentItem, 0, 0)
            if (p.y < contentY + 8)
                contentY = Math.max(0, p.y - 8)
            else if (p.y + item.height > contentY + height - 8)
                contentY = Math.max(0, Math.min(contentHeight - height, p.y + item.height - height + 8))
        }

        ScrollBar.vertical: ScrollBar { policy: ScrollBar.AlwaysOff }

        StatusCardsColumn {
            id: statusCards
            objectName: "statusOverviewCards"
            width: Math.min(content.width, 1600)
            x: Math.round((content.width - width) / 2)
            availableHeight: content.height
            onImplicitHeightChanged: Qt.callLater(content.updateExtent)
            onCraftDetailsRequested: craftDetails.open()
            onUnitDetailsRequested: function(systemType) {
                if (systemType === 0) groundDetails.open("open_dialoque", [0])
                else unitDetails.open("open_dialoque", [systemType])
            }
        }
    }

    DeferredStatusDialog { id: groundDetails; source: "GroundStationDetails.qml" }
    DeferredStatusDialog { id: unitDetails; source: "UnitDetailsDialog.qml" }
    DeferredStatusDialog { id: powerDialog; source: "PowerActionDialoque.qml" }
    Popup {
        id: craftDetails
        parent: root
        anchors.centerIn: parent
        width: Math.min(parent.width - 12, 1000)
        height: parent.height - 12
        modal: true
        dim: false
        focus: true
        padding: 0
        closePolicy: Popup.CloseOnEscape
        background: Rectangle { color: settings_form.pageBackground; radius: 14; border.color: settings_form.lineColor }
        contentItem: Loader {
            id: craftDetailsLoader
            active: craftDetails.visible
            asynchronous: true
            source: "CraftDetailsPanel.qml"
            onLoaded: if (craftDetails.opened) item.gainFocus()
            Connections {
                target: craftDetailsLoader.item
                function onCloseRequested() { craftDetails.close() }
            }
        }
        onOpened: if (craftDetailsLoader.item) craftDetailsLoader.item.gainFocus()
        onClosed: if (root.visible) root.gainFocus()
    }
    DeferredStatusDialog { id: dialoqueNotAlive; source: "DialoqueNotAlive.qml" }
}
