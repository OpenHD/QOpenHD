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

        Item { Layout.fillWidth: true; Layout.preferredHeight: 14 }
        RowLayout {
            Layout.fillWidth: true
            Layout.rightMargin: root.width > 420 ? 150 : 0
            spacing: 13
            Text {
                text: "\uf6ff"
                color: settings_form.accentColor
                font.family: "Font Awesome 5 Free"
                font.pixelSize: 27
            }
            ColumnLayout {
                spacing: 1
                Text { text: qsTr("CONNECT"); color: settings_form.primaryText; font.pixelSize: Math.max(17, Math.min(22, root.width / 45)); font.bold: true }
                Text { text: qsTr("Choose how QOpenHD reaches your OpenHD system"); color: settings_form.secondaryText; font.pixelSize: 12 }
            }
        }
        PaneConnectionMode {
            id: connectionPane
            Layout.fillWidth: true
            Layout.fillHeight: true
        }
    }
}
