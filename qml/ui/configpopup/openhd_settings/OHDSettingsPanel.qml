import "../MenuTypography.js" as MenuTypography
import QtQuick 2.12
import QtQuick.Controls 2.12
import QtQuick.Layouts 1.12

import OpenHD 1.0
import ".."
import "../features"
import "AirSettingsLayout.js" as AirLayout
import "CameraSettingsLayout.js" as CameraLayout

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
        ListElement { title: qsTr("LINK"); icon: "\uf1eb" }
        ListElement { title: qsTr("CAMERA"); icon: "\uf030" }
        ListElement { title: qsTr("STORAGE"); icon: "\uf51f" }
        ListElement { title: qsTr("AIR"); icon: "\uf1d8" }
        ListElement { title: qsTr("GROUND"); icon: "\uf519" }
        ListElement { title: qsTr("EXTRAS"); icon: "\uf067" }
    }

    readonly property var availablePages: {
        _airCameraSettingsModel.update_count
        _airCameraSettingsModel2.update_count
        _ohdSystemAirSettingsModel.update_count
        _ohdSystemGroundSettings.update_count
        var cameraIds = CameraLayout.availableParameterIds(_airCameraSettingsModel, settings_form.showAdvancedSettings)
            .concat(CameraLayout.availableParameterIds(_airCameraSettingsModel2, settings_form.showAdvancedSettings))
        var airIds = AirLayout.availableParameterIds(_ohdSystemAirSettingsModel,
            settings_form.showAdvancedSettings, settings_form.showDeveloperSettings === true,
            _qopenhd.debugMenuPreview)
        // Link, Storage and Extras include local actions/status. Camera, Air
        // and Ground need actual parameters, including preview fixture data.
        return [true, cameraIds.length > 0, true, airIds.length > 0,
                _ohdSystemGroundSettings.param_ids().length > 0, true]
    }
    function tabIsAvailable(index) {
        return index >= 0 && index < availablePages.length && availablePages[index]
    }
    function ensureAvailablePage() {
        if (!tabIsAvailable(currentPage)) currentPage = firstAvailableTab(0, 1)
    }
    onAvailablePagesChanged: ensureAvailablePage()
    Component.onCompleted: ensureAvailablePage()

    function tabTitle(index) {
        if (index === 0) return qsTr("LINK")
        if (index === 1) return qsTr("CAMERA")
        if (index === 2) return qsTr("STORAGE")
        if (index === 3) return qsTr("AIR")
        if (index === 4) return qsTr("GROUND")
        return qsTr("EXTRAS")
    }

    function firstAvailableTab(from, step) {
        var index = from
        while (index >= 0 && index < pageModel.count) {
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
        var page = settingsStack.children[currentPage]
        if (page) page.gainFocus()
    }

    function user_quidance_animate_channel_scan() {
        currentPage = 0
        linkPage.invokeWhenReady("user_quidance_animate_channel_scan")
    }

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
                        onClicked: if (root.tabIsAvailable(index)) root.currentPage = index
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
                id: settingsStack
                anchors.fill: parent
                anchors.margins: 1
                currentIndex: root.currentPage

                AdvancedPageLoader { id: linkPage; selected: root.currentPage === 0; sourceComponent:
                    LinkQuickPanel { id: quickPanel; onBackRequested: root.focusTab(0) }
                }
                AdvancedPageLoader { selected: root.currentPage === 1; sourceComponent:
                    CameraDualPanel {
                        id: cameraDualPanel
                        onBackRequested: root.focusTab(1)
                    }
                }
                AdvancedPageLoader { selected: root.currentPage === 2; sourceComponent:
                    StorageSettingsPanel { id: storagePanel; onBackRequested: root.focusTab(2) }
                }
                AdvancedPageLoader { selected: root.currentPage === 3; sourceComponent:
                    AirSettingsPanel {
                        id: airPanel
                        onBackRequested: root.focusTab(3)
                    }
                }
                AdvancedPageLoader { selected: root.currentPage === 4; sourceComponent:
                    MavlinkParamPanel {
                        id: groundPanel
                        m_name: "GROUND"
                        m_instanceMavlinkSettingsModel: _ohdSystemGroundSettings
                        m_instanceCheckIsAvlie: _ohdSystemGround
                        m_requires_alive_air: false
                        onBackRequested: root.focusTab(4)
                    }
                }
                AdvancedPageLoader { selected: root.currentPage === 5; sourceComponent:
                    FeatureSettingsPanel {
                        id: extrasPanel
                        onBackRequested: root.focusTab(5)
                    }
                }
            }
        }

        Item { Layout.fillWidth: true; Layout.preferredHeight: 0 }
    }
}
