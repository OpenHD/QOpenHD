import "../MenuTypography.js" as MenuTypography
import QtQuick 2.12
import QtQuick.Controls 2.12
import QtQuick.Layouts 1.12
import QtQuick.Controls.Material 2.12
import OpenHD 1.0
import ".."

Rectangle {
    id: root
    color: settings_form.pageBackground
    focus: false

    property bool osdMenu: false
    property int currentPage: osdMenu ? 0 : 2
    readonly property var availablePageIds: osdMenu ? [0,1,5] : (settings_form.showDeveloperSettings ? [2,4,6] : [2,4])
    readonly property int availableTabCount: availablePageIds.length
    onAvailablePageIdsChanged: if (availablePageIds.indexOf(currentPage)<0) currentPage=availablePageIds[0]
    onCurrentPageChanged: if (!osdMenu && currentPage === 3) currentPage=2
    // Shared sizing contract used by the existing application-setting rows.
    property int rowHeight: MenuTypography.rowHeight
    property int elementHeight: MenuTypography.controlHeight

    Material.theme: settings_form.darkMode ? Material.Dark : Material.Light
    Material.accent: settings_form.accentColor
    Material.foreground: settings_form.primaryText
    Material.background: settings_form.panelBackgroundRaised

    ListModel {
        id: pageModel
        ListElement { title: qsTr("WIDGETS"); icon: "\uf009" }
        ListElement { title: qsTr("STYLE"); icon: "\uf53f" }
        ListElement { title: qsTr("GENERAL"); icon: "\uf013" }
        ListElement { title: qsTr("VEHICLE"); icon: "\uf1b9" }
        ListElement { title: qsTr("VIDEO"); icon: "\uf03d" }
        ListElement { title: qsTr("MAP"); icon: "\uf279" }
        ListElement { title: qsTr("DEV"); icon: "\uf0ad" }
    }

    function focusTab(index) {
        var item = tabRepeater.itemAt(availablePageIds.indexOf(index))
        if (item) {
            item.forceActiveFocus()
            tabScroller.ensureVisible(item)
        }
    }

    function gainFocus() { focusTab(currentPage) }

    function focusCurrentPage() {
        var page = settingsStack.children[currentPage]
        if (page) page.gainFocus()
    }

    function moveTab(index, step) {
        var next = availablePageIds.indexOf(index) + step
        if (next < 0) {
            settings_form.side_bar_regain_focus()
            return
        }
        if (next >= availableTabCount) {
            settings_form.frameworkActionButtons()[0].forceActiveFocus()
            return
        }
        currentPage = availablePageIds[next]
        focusTab(currentPage)
    }

    function leaveContent() { focusTab(currentPage) }

    ColumnLayout {
        anchors.fill: parent
        anchors.leftMargin: settings_form.compactSidebar ? 14 : 24
        anchors.rightMargin: settings_form.compactSidebar ? 14 : 24
        spacing: 10

        Item { Layout.fillWidth: true; Layout.preferredHeight: 12 }

        Flickable {
            id: tabScroller
            Layout.fillWidth: true
            Layout.preferredHeight: MenuTypography.controlHeight
            contentWidth: tabRow.width
            contentHeight: height
            flickableDirection: Flickable.HorizontalFlick
            boundsBehavior: Flickable.StopAtBounds
            clip: true
            ScrollBar.horizontal: ScrollBar { policy: ScrollBar.AlwaysOff }

            function ensureVisible(item) {
                if (!item) return
                var left = item.x
                var right = item.x + item.width
                if (left < contentX) contentX = left
                else if (right > contentX + width) contentX = right - width
            }

            Row {
                id: tabRow
                height: parent.height
                spacing: 7
                Repeater {
                    id: tabRepeater
                    model: root.availablePageIds
                    delegate: AdvancedTabButton {
                        id: tabButton
                        objectName: "settingsTab"+modelData
                        property bool selected: root.currentPage === modelData
                        checked: selected
                        width: visible ? implicitWidth : 0
                        height: 34
                        text: pageModel.get(modelData).title
                        iconText: pageModel.get(modelData).icon
                        hoverEnabled: true
                        onClicked: root.currentPage = modelData
                        Keys.onPressed: function(event) {
                            if (event.key === Qt.Key_Left) {
                                root.moveTab(modelData, -1); event.accepted = true
                            } else if (event.key === Qt.Key_Right) {
                                root.moveTab(modelData, 1); event.accepted = true
                            } else if (event.key === Qt.Key_Down || event.key === Qt.Key_Return || event.key === Qt.Key_Enter) {
                                root.currentPage = modelData
                                root.focusCurrentPage()
                                event.accepted = true
                            } else if (event.key === Qt.Key_Up || event.key === Qt.Key_Escape) {
                                settings_form.side_bar_regain_focus()
                                event.accepted = true
                            }
                        }
                    }
                }
            }
        }

        Rectangle {
            Layout.fillWidth: true
            Layout.fillHeight: true
            radius: 12
            color: settings_form.panelBackground
            border.color: settings_form.lineColor
            clip: true

            StackLayout {
                id: settingsStack
                anchors.fill: parent
                anchors.margins: 1
                currentIndex: root.currentPage

                AdvancedPageLoader { selected: root.currentPage === 0; sourceComponent: AppSettingsPageFrame { onBackRequested: root.leaveContent(); AppWidgetSettingsView { anchors.fill: parent } } }
                AdvancedPageLoader { selected: root.currentPage === 1; sourceComponent: AppSettingsPageFrame { onBackRequested: root.leaveContent(); AppWidgetStyleSettingsView { anchors.fill: parent } } }
                AdvancedPageLoader { selected: root.currentPage === 2; sourceComponent: AppSettingsPageFrame { onBackRequested: root.leaveContent(); AppGeneralSettingsView { anchors.fill: parent } } }
                AdvancedPageLoader { selected: false; // Vehicle is intentionally unavailable; preserve the reserved page ID.
                     sourceComponent: AppSettingsPageFrame { onBackRequested: root.leaveContent(); AppVehicleSettingsView { anchors.fill: parent } } }
                AdvancedPageLoader { selected: root.currentPage === 4; sourceComponent: AppSettingsPageFrame { onBackRequested: root.leaveContent(); AppVideoSettingsView { anchors.fill: parent } } }
                AdvancedPageLoader { selected: root.currentPage === 5; sourceComponent: AppSettingsPageFrame { onBackRequested: root.leaveContent(); AppMapSettingsView { anchors.fill: parent } } }
                AdvancedPageLoader { selected: root.currentPage === 6 && settings_form.showDeveloperSettings; sourceComponent: AppSettingsPageFrame { onBackRequested: root.leaveContent(); AppDevSettingsView { anchors.fill: parent } } }
            }
        }

        Item { Layout.fillWidth: true; Layout.preferredHeight: 0 }
    }
}
