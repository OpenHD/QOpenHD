import QtQuick 2.12
import QtQuick.Layouts 1.12

import OpenHD 1.0

Rectangle {
    id: root
    color: settings_form.pageBackground
    focus: false

    function gainFocus() { connectionPane.gainFocus() }

    ColumnLayout {
        anchors.fill: parent
        anchors.leftMargin: settings_form.compactSidebar ? 13 : Math.max(16, Math.min(32, width * 0.025))
        anchors.rightMargin: settings_form.compactSidebar ? 13 : Math.max(16, Math.min(32, width * 0.025))
        spacing: 13

        Item { Layout.fillWidth: true; Layout.preferredHeight: 12 }

        PaneConnectionMode {
            id: connectionPane
            Layout.fillWidth: true
            Layout.fillHeight: true
        }
    }
}
