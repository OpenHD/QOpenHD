import QtQuick 2.12
import QtQuick.Controls 2.12
import QtQuick.Layouts 1.12

import OpenHD 1.0

Rectangle {
    id: root
    color: settings_form.pageBackground
    focus: false

    property int keyboardIndex: 0

    function voltage_as_string(voltage_mv) { return voltage_mv === 0 ? "N/A" : voltage_mv + " mV" }
    function current_as_string(current_ma) { return current_ma === 0 ? "N/A" : current_ma + " mA" }
    function open_power_action_dialoque(system, reboot) { powerDialog.open_dialoque(system, reboot) }

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
        anchors.leftMargin: settings_form.compactSidebar ? 13 : Math.max(16, Math.min(32, width * 0.025))
        anchors.rightMargin: settings_form.compactSidebar ? 13 : Math.max(16, Math.min(32, width * 0.025))
        clip: true
        contentWidth: width
        contentHeight: page.implicitHeight + 36
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

        ColumnLayout {
            id: page
            width: content.width
            spacing: 13

            Item { Layout.fillWidth: true; Layout.preferredHeight: 14 }
            RowLayout {
                id: pageHeader
                Layout.fillWidth: true
                Layout.rightMargin: content.width > 420 ? 150 : 0
                spacing: 13
                Text { text: "\uf21e"; color: "#67aaff"; font.family: "Font Awesome 5 Free"; font.pixelSize: 27 }
                ColumnLayout {
                    spacing: 2
                    Text { text: qsTr("SYSTEM STATUS"); color: settings_form.primaryText; font.pixelSize: Math.max(17, Math.min(22, content.width / 45)); font.bold: true }
                    Text { text: qsTr("Overview of all system components"); color: settings_form.secondaryText; font.pixelSize: 12 }
                }
            }
            StatusCardsColumn {
                id: statusCards
                Layout.fillWidth: true
            }
        }
    }

    PowerActionDialoque { id: powerDialog }
    DialoqueNotAlive { id: dialoqueNotAlive }
}
