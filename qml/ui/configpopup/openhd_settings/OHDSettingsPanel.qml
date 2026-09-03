import QtQuick 2.12
import QtQuick.Controls 2.12
import QtQuick.Layouts 1.12

import OpenHD 1.0
import ".."

Rectangle {
    id: root
    color: settings_form.pageBackground
    focus: false

    property int currentPage: 0
    property int rowHeight: 52
    property int elementHeight: 40
    property int elementComboBoxWidth: Math.max(220, Math.min(300, root.width * 0.36))

    ListModel {
        id: pageModel
        ListElement { title: qsTr("LINK / QUICK"); icon: "\uf1eb" }
        ListElement { title: qsTr("AIR CAM 1"); icon: "\uf030" }
        ListElement { title: qsTr("AIR CAM 2"); icon: "\uf030" }
        ListElement { title: qsTr("AIR"); icon: "\uf1d8" }
        ListElement { title: qsTr("GROUND"); icon: "\uf519" }
    }

    function tabIsAvailable(index) {
        if (index === 1)
            return true
        if (index === 2)
            return _airCameraSettingsModel2.has_params_fetched &&
                    (_airCameraSettingsModel2.param_int_exists("CAMERA_TYPE") ||
                     _airCameraSettingsModel2.param_string_exists("IP_CAM_PIPELINE"))
        return true
    }

    function tabTitle(index) {
        if (index === 0) return qsTr("LINK / QUICK")
        if (index === 1) return qsTr("AIR CAM 1")
        if (index === 2) return qsTr("AIR CAM 2")
        if (index === 3) return qsTr("AIR")
        if (index === 4) return qsTr("GROUND")
        return qsTr("mLRS")
    }

    function firstAvailableTab(from, step) {
        var index = from
        while (index >= 0 && index < 5) {
            if (tabIsAvailable(index)) return index
            index += step
        }
        return -1
    }

    function focusTab(index) {
        var item = tabRepeater.itemAt(index)
        if (item && item.visible) {
            item.forceActiveFocus()
            tabScroller.ensureVisible(item)
        }
    }

    function moveTab(index, step) {
        var next = firstAvailableTab(index + step, step)
        if (next >= 0) {
            currentPage = next
            focusTab(next)
        } else if (step < 0) {
            settings_form.side_bar_regain_focus()
        } else {
            settings_form.frameworkActionButtons()[0].forceActiveFocus()
        }
    }

    function gainFocus() {
        if (!tabIsAvailable(currentPage)) currentPage = firstAvailableTab(0, 1)
        focusTab(currentPage)
    }

    function focusCurrentPage() {
        if (currentPage === 0) quickPanel.gainFocus()
        else if (currentPage === 1) cameraOnePanel.gainFocus()
        else if (currentPage === 2) cameraTwoPanel.gainFocus()
        else if (currentPage === 3) airPanel.gainFocus()
        else if (currentPage === 4) groundPanel.gainFocus()
    }

    function user_quidance_animate_channel_scan() {
        currentPage = 0
        quickPanel.user_quidance_animate_channel_scan()
    }

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
                Layout.preferredWidth: 44
                Layout.preferredHeight: 44
                radius: 11
                color: settings_form.darkMode ? "#173b61" : "#dcecff"
                Text {
                    anchors.centerIn: parent
                    text: "\uf1eb"
                    color: settings_form.accentColor
                    font.family: "Font Awesome 5 Free"
                    font.pixelSize: 21
                }
            }
            ColumnLayout {
                spacing: 1
                Text {
                    text: qsTr("OPENHD")
                    color: settings_form.primaryText
                    font.pixelSize: Math.max(17, Math.min(22, root.width / 45))
                    font.bold: true
                }
                Text {
                    text: qsTr("Configure the video link, cameras and OpenHD systems")
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
                if (item.x < contentX) contentX = item.x
                else if (item.x + item.width > contentX + width)
                    contentX = item.x + item.width - width
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
                        visible: root.tabIsAvailable(index)
                        width: visible ? implicitWidth : 0
                        height: 34
                        text: model.title
                        iconText: model.icon
                        hoverEnabled: true
                        onClicked: root.currentPage = index
                        Keys.onPressed: function(event) {
                            if (event.key === Qt.Key_Left) {
                                root.moveTab(index, -1)
                                event.accepted = true
                            } else if (event.key === Qt.Key_Right) {
                                root.moveTab(index, 1)
                                event.accepted = true
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
                anchors.fill: parent
                anchors.margins: 1
                currentIndex: root.currentPage

                LinkQuickPanel { id: quickPanel; onBackRequested: root.focusTab(0) }
                CameraSettingsPanel {
                    id: cameraOnePanel
                    settingsModel: _airCameraSettingsModel
                    streamModel: _cameraStreamModelPrimary
                    secondary: false
                    onBackRequested: root.focusTab(1)
                }
                CameraSettingsPanel {
                    id: cameraTwoPanel
                    settingsModel: _airCameraSettingsModel2
                    streamModel: _cameraStreamModelSecondary
                    secondary: true
                    onBackRequested: root.focusTab(2)
                }
                MavlinkParamPanel {
                    id: airPanel
                    m_name: "AIR"
                    m_instanceMavlinkSettingsModel: _ohdSystemAirSettingsModel
                    m_instanceCheckIsAvlie: _ohdSystemAir
                    m_requires_alive_air: true
                    onBackRequested: root.focusTab(3)
                }
                MavlinkParamPanel {
                    id: groundPanel
                    m_name: "GROUND"
                    m_instanceMavlinkSettingsModel: _ohdSystemGroundSettings
                    m_instanceCheckIsAvlie: _ohdSystemGround
                    m_requires_alive_air: false
                    onBackRequested: root.focusTab(4)
                }
            }
        }

        Item { Layout.fillWidth: true; Layout.preferredHeight: 0 }
    }
}
