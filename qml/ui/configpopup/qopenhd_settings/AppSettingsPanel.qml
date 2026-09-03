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

    property int currentPage: 0
    // Shared sizing contract used by the existing application-setting rows.
    property int rowHeight: 64
    property int elementHeight: 48

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
        ListElement { title: qsTr("SCREEN"); icon: "\uf108" }
        ListElement { title: qsTr("VIDEO"); icon: "\uf03d" }
        ListElement { title: qsTr("DEV"); icon: "\uf0ad" }
    }

    function focusTab(index) {
        var item = tabRepeater.itemAt(Math.max(0, Math.min(pageModel.count - 1, index)))
        if (item) {
            item.forceActiveFocus()
            tabScroller.ensureVisible(item)
        }
    }

    function gainFocus() { focusTab(currentPage) }

    function focusCurrentPage() {
        var page = settingsStack.itemAt(currentPage)
        if (page) page.gainFocus()
    }

    function moveTab(index, step) {
        var next = index + step
        if (next < 0) {
            settings_form.side_bar_regain_focus()
            return
        }
        if (next >= pageModel.count) {
            settings_form.frameworkActionButtons()[0].forceActiveFocus()
            return
        }
        currentPage = next
        focusTab(next)
    }

    function leaveContent() { focusTab(currentPage) }

    ColumnLayout {
        anchors.fill: parent
        anchors.leftMargin: settings_form.compactSidebar ? 14 : 24
        anchors.rightMargin: settings_form.compactSidebar ? 14 : 24
        spacing: 10

        Item { Layout.fillWidth: true; Layout.preferredHeight: 18 }

        RowLayout {
            Layout.fillWidth: true
            Layout.rightMargin: root.width > 420 ? 150 : 0
            spacing: 13
            Rectangle {
                width: 44; height: 44; radius: 11
                color: settings_form.darkMode ? "#173b61" : "#dcecff"
                Text {
                    anchors.centerIn: parent
                    text: "\uf108"
                    color: settings_form.accentColor
                    font.family: "Font Awesome 5 Free"
                    font.pixelSize: 21
                }
            }
            ColumnLayout {
                spacing: 1
                Text {
                    text: qsTr("OSD & APPLICATION")
                    color: settings_form.primaryText
                    font.pixelSize: Math.max(17, Math.min(22, root.width / 45))
                    font.bold: true
                }
                Text {
                    text: qsTr("Configure the application, display, widgets and vehicle presentation")
                    color: settings_form.secondaryText
                    font.pixelSize: 12
                    elide: Text.ElideRight
                    Layout.maximumWidth: Math.max(100, root.width - 250)
                }
            }
        }

        Flickable {
            id: tabScroller
            Layout.fillWidth: true
            Layout.preferredHeight: 36
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
                    model: pageModel
                    delegate: AdvancedTabButton {
                        id: tabButton
                        property bool selected: root.currentPage === index
                        checked: selected
                        width: implicitWidth
                        height: 34
                        text: model.title
                        iconText: model.icon
                        hoverEnabled: true
                        onClicked: root.currentPage = index
                        Keys.onPressed: function(event) {
                            if (event.key === Qt.Key_Left) {
                                root.moveTab(index, -1); event.accepted = true
                            } else if (event.key === Qt.Key_Right) {
                                root.moveTab(index, 1); event.accepted = true
                            } else if (event.key === Qt.Key_Down || event.key === Qt.Key_Return || event.key === Qt.Key_Enter) {
                                root.currentPage = index
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

                AppSettingsPageFrame { onBackRequested: root.leaveContent(); AppWidgetSettingsView { anchors.fill: parent } }
                AppSettingsPageFrame { onBackRequested: root.leaveContent(); AppWidgetStyleSettingsView { anchors.fill: parent } }
                AppSettingsPageFrame { onBackRequested: root.leaveContent(); AppGeneralSettingsView { anchors.fill: parent } }
                AppSettingsPageFrame { onBackRequested: root.leaveContent(); AppVehicleSettingsView { anchors.fill: parent } }
                AppSettingsPageFrame { onBackRequested: root.leaveContent(); AppScreenSettingsView { anchors.fill: parent } }
                AppSettingsPageFrame { onBackRequested: root.leaveContent(); AppVideoSettingsView { anchors.fill: parent } }
                AppSettingsPageFrame { onBackRequested: root.leaveContent(); AppDevSettingsView { anchors.fill: parent } }
            }
        }

        Item { Layout.fillWidth: true; Layout.preferredHeight: 0 }
    }
}
