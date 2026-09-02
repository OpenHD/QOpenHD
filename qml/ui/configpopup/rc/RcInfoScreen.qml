import QtQuick 2.12
import QtQuick.Controls 2.12
import QtQuick.Layouts 1.12
import ".."

FocusScope {
    id: root
    signal backRequested()
    function gainFocus() { instructions.forceActiveFocus() }

    Flickable {
        id: view
        anchors.fill: parent
        contentWidth: width
        contentHeight: cards.implicitHeight
        clip: true
        boundsBehavior: Flickable.StopAtBounds
        ScrollBar.vertical: ScrollBar { policy: ScrollBar.AlwaysOff }
        ColumnLayout {
            id: cards
            width: view.width
            spacing: 10
            AdvancedCard {
                id: instructions
                Layout.fillWidth: true
                Layout.preferredHeight: 200
                activeFocusOnTab: true
                border.color: activeFocus ? settings_form.accentColor : settings_form.lineColor
                border.width: activeFocus ? 2 : 1
                Column {
                    anchors.fill: parent
                    spacing: 10
                    Text { text: qsTr("GETTING STARTED"); color: settings_form.accentColor; font.pixelSize: 12; font.bold: true }
                    Text {
                        width: parent.width
                        text: qsTr("1. Enable ENABLE_JOY_RC in the OpenHD Ground settings.\n2. Connect a USB joystick to the ground station.\n3. Reboot when requested, then verify the live channels in the OpenHD RC tab.")
                        color: settings_form.primaryText
                        font.pixelSize: 14
                        lineHeight: 1.35
                        wrapMode: Text.WordWrap
                    }
                    Text {
                        width: parent.width
                        text: qsTr("A dedicated RC link such as ExpressLRS is recommended for primary flight control.")
                        color: settings_form.secondaryText
                        font.pixelSize: 12
                        wrapMode: Text.WordWrap
                    }
                }
                Keys.onPressed: function(event) {
                    if (event.key === Qt.Key_Left || event.key === Qt.Key_Escape || event.key === Qt.Key_Up) {
                        root.backRequested(); event.accepted = true
                    }
                }
            }
            AdvancedCard {
                Layout.fillWidth: true
                Layout.preferredHeight: 130
                Column {
                    anchors.fill: parent
                    spacing: 9
                    Text { text: qsTr("CHANNEL MAPPING"); color: settings_form.accentColor; font.pixelSize: 12; font.bold: true }
                    Text {
                        width: parent.width
                        text: qsTr("Use the live channel screens to validate assignments and their 1000–2000 PWM range. Advanced transmitters can perform channel mapping before the joystick data reaches QOpenHD.")
                        color: settings_form.primaryText
                        font.pixelSize: 13
                        wrapMode: Text.WordWrap
                    }
                }
            }
        }
    }
}
