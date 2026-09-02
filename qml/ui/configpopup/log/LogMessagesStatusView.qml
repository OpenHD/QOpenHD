import QtQuick 2.12
import QtQuick.Controls 2.12
import QtQuick.Layouts 1.12
import ".."

AdvancedPage {
    id: root
    pageIcon: "\uf03a"
    pageTitle: qsTr("SYSTEM LOGS")
    pageSubtitle: qsTr("Live messages from Ground, Air and the flight controller")
    initialFocusItem: groundTab
    onBackRequested: settings_form.side_bar_regain_focus()

    function focusLog() { logStack.itemAt(logTabs.currentIndex).gainFocus() }

    ColumnLayout {
        anchors.fill: parent
        spacing: 10

        TabBar {
            id: logTabs
            Layout.fillWidth: true
            Layout.maximumWidth: 470
            spacing: 7
            background: Item {}
            AdvancedTabButton { id: groundTab; text: qsTr("GROUND") }
            AdvancedTabButton { text: qsTr("AIR") }
            AdvancedTabButton { text: qsTr("FLIGHT CONTROLLER") }

            Keys.onPressed: function(event) {
                if (event.key === Qt.Key_Down || event.key === Qt.Key_Enter || event.key === Qt.Key_Return) {
                    root.focusLog()
                    event.accepted = true
                } else if ((event.key === Qt.Key_Left && currentIndex === 0) || event.key === Qt.Key_Escape || event.key === Qt.Key_Up) {
                    settings_form.side_bar_regain_focus()
                    event.accepted = true
                }
            }
        }

        AdvancedCard {
            Layout.fillWidth: true
            Layout.fillHeight: true
            contentMargin: 1
            StackLayout {
                id: logStack
                anchors.fill: parent
                currentIndex: logTabs.currentIndex
                LogMessagesView { m_log_model: _logGround; onBackRequested: groundTab.forceActiveFocus() }
                LogMessagesView { m_log_model: _logOpenhdAir; onBackRequested: logTabs.itemAt(1).forceActiveFocus() }
                LogMessagesView { m_log_model: _logFC; onBackRequested: logTabs.itemAt(2).forceActiveFocus() }
            }
        }
    }
}
