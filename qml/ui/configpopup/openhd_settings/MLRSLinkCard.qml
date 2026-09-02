import QtQuick 2.12
import QtQuick.Controls 2.12
import QtQuick.Layouts 1.12

Rectangle {
    id: root
    property var host
    property int cardIndex: -1
    property bool keyboardSelected: false
    radius: 10; color: settings_form.panelBackgroundRaised
    border.color: keyboardSelected ? settings_form.accentColor : settings_form.lineColor
    border.width: keyboardSelected ? 2 : 1
    function gainFocus() { panel.gainFocus() }
    ColumnLayout {
        anchors.fill: parent; anchors.margins: 8; spacing: 5
        RowLayout { Layout.fillWidth: true; Layout.preferredHeight: 36; spacing: 8
            Text { text: "\uf519"; color: "#b06cff"; font.family: "Font Awesome 5 Free"; font.pixelSize: 17 }
            Text { text: qsTr("mLRS Link"); color: settings_form.primaryText; font.pixelSize: 12; font.bold: true; Layout.fillWidth: true }
            Rectangle { width: activeText.implicitWidth + 14; height: 21; radius: 7; color: Qt.rgba(0.1,0.8,0.35,0.12)
                Text { id: activeText; anchors.centerIn: parent; text: qsTr("ACTIVE"); color: settings_form.goodColor; font.pixelSize: 8; font.bold: true }
            }
        }
        MLRSSettingsPanel {
            id: panel; Layout.fillWidth: true; Layout.fillHeight: true
            onBackRequested: if (root.host) root.host.collapseCard(root.cardIndex)
            onFocusItemRequested: if (root.host) root.host.ensureItemVisible(item)
        }
    }
}
