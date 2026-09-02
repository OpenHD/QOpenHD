import QtQuick 2.12
import QtQuick.Controls 2.12
import QtQuick.Layouts 1.12
import ".."

AdvancedPage {
    id: root
    pageIcon: "\uf11b"
    pageTitle: qsTr("RC CONTROL")
    pageSubtitle: qsTr("Configure and monitor RC over OpenHD")
    initialFocusItem: aboutTab
    onBackRequested: settings_form.side_bar_regain_focus()

    function focusPage() { rcStack.itemAt(rcTabs.currentIndex).gainFocus() }

    ColumnLayout {
        anchors.fill: parent
        spacing: 10
        TabBar {
            id: rcTabs
            Layout.fillWidth: true
            Layout.maximumWidth: 500
            spacing: 7
            background: Item {}
            AdvancedTabButton { id: aboutTab; text: qsTr("OVERVIEW") }
            AdvancedTabButton { text: qsTr("OPENHD RC") }
            AdvancedTabButton { text: qsTr("FC CHANNELS") }
            Keys.onPressed: function(event) {
                if (event.key === Qt.Key_Down || event.key === Qt.Key_Enter || event.key === Qt.Key_Return) {
                    root.focusPage(); event.accepted = true
                } else if ((event.key === Qt.Key_Left && currentIndex === 0) || event.key === Qt.Key_Escape || event.key === Qt.Key_Up) {
                    settings_form.side_bar_regain_focus(); event.accepted = true
                }
            }
        }
        StackLayout {
            id: rcStack
            Layout.fillWidth: true
            Layout.fillHeight: true
            currentIndex: rcTabs.currentIndex
            RcInfoScreen { onBackRequested: aboutTab.forceActiveFocus() }
            RcDebugScreenOpenHD { onBackRequested: rcTabs.itemAt(1).forceActiveFocus() }
            RcDebugScreenFC { onBackRequested: rcTabs.itemAt(2).forceActiveFocus() }
        }
    }
}
