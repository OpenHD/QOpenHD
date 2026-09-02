import QtQuick 2.12
import QtQuick.Controls 2.12
import QtQuick.Layouts 1.12
import ".."

FocusScope {
    id: root
    property string title: ""
    property string description: ""
    property var channelModel
    signal backRequested()
    function gainFocus() { channels.forceActiveFocus() }

    AdvancedCard {
        anchors.fill: parent
        contentMargin: 12
        ColumnLayout {
            anchors.fill: parent
            spacing: 8
            RowLayout {
                Layout.fillWidth: true
                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 2
                    Text { text: root.title; color: settings_form.primaryText; font.pixelSize: 15; font.bold: true }
                    Text { text: root.description; color: settings_form.secondaryText; font.pixelSize: 11; elide: Text.ElideRight; Layout.fillWidth: true }
                }
                Text { text: qsTr("PWM 1000–2000"); color: settings_form.secondaryText; font.pixelSize: 11 }
            }
            ListView {
                id: channels
                Layout.fillWidth: true
                Layout.fillHeight: true
                model: root.channelModel
                spacing: 4
                clip: true
                focus: true
                keyNavigationWraps: false
                ScrollBar.vertical: ScrollBar { policy: ScrollBar.AlwaysOff }
                delegate: Rectangle {
                    width: channels.width
                    height: 38
                    radius: 6
                    color: ListView.isCurrentItem ? (settings_form.darkMode ? "#193d60" : "#e1effd")
                                                   : (index % 2 ? settings_form.panelBackgroundRaised : "transparent")
                    border.width: ListView.isCurrentItem && channels.activeFocus ? 1 : 0
                    border.color: settings_form.accentColor
                    RowLayout {
                        anchors.fill: parent
                        anchors.leftMargin: 10
                        anchors.rightMargin: 10
                        spacing: 12
                        Text { text: qsTr("CH %1").arg(index + 1); color: settings_form.secondaryText; font.pixelSize: 11; font.bold: true; Layout.preferredWidth: 52 }
                        ProgressBar { Layout.fillWidth: true; from: 1000; to: 2000; value: model.curr_value }
                        Text { text: model.curr_value; color: settings_form.primaryText; font.pixelSize: 12; font.bold: true; horizontalAlignment: Text.AlignRight; Layout.preferredWidth: 48 }
                    }
                    MouseArea { anchors.fill: parent; onClicked: { channels.currentIndex = index; channels.forceActiveFocus() } }
                }
                Keys.onPressed: function(event) {
                    if (event.key === Qt.Key_Left || event.key === Qt.Key_Escape) {
                        root.backRequested(); event.accepted = true
                    }
                }
            }
        }
    }
}
