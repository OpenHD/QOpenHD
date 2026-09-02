import QtQuick 2.12
import QtQuick.Controls 2.12
import QtQuick.Layouts 1.12
import Qt.labs.settings 1.0

import OpenHD 1.0

import "connect"
import "credits"
import "dev"
import "log"
import "qopenhd_settings"
import "openhd_settings"
import "rc"
import "status"

// Shared framework for the advanced menu. Pages remain in the StackLayout;
// responsive navigation and keyboard ownership live here.
Rectangle {
    id: settings_form
    anchors.fill: parent
    z: 4
    color: pageBackground
    focus: visible

    property bool darkMode: advancedThemeSettings.darkMode
    property color pageBackground: darkMode ? "#091827" : "#eef4fa"
    property color panelBackground: darkMode ? "#102235" : "#ffffff"
    property color panelBackgroundRaised: darkMode ? "#15283b" : "#f7faff"
    property color lineColor: darkMode ? "#26394c" : "#d7e1eb"
    property color primaryText: darkMode ? "#f2f6fb" : "#132235"
    property color secondaryText: darkMode ? "#aebdcb" : "#405d78"
    property color accentColor: darkMode ? "#278cff" : "#1477d4"
    property color goodColor: darkMode ? "#35dc72" : "#087f3f"
    property color errorColor: darkMode ? "#ff4e5d" : "#c6283d"
    // Compact rail keeps the complete status overview on portrait/embedded
    // displays while retaining the labelled sidebar on desktop.
    property bool compactSidebar: width < 1050
    property int sidebarWidth: compactSidebar ? 72 : Math.max(160, Math.min(210, width * 0.17))

    Settings {
        id: advancedThemeSettings
        category: "AdvancedMenu"
        property bool darkMode: true
    }

    function openSettings() {
        visible = true
        focus = true
        navigation.forceActiveFocus()
    }
    function close_all() {
        visible = false
        focus = false
        hudOverlayGrid.regain_focus()
    }
    function side_bar_regain_focus() { navigation.forceActiveFocus() }
    function user_quidance_open_connect_screen() {
        openSettings()
        mainStackLayout.currentIndex = 5
        navigation.currentIndex = 5
    }
    function openDeveloperTools() {
        openSettings()
        mainStackLayout.currentIndex = 8
        navigation.currentIndex = -1
        appDeveloperStatsPanel.gainFocus()
    }
    function user_guidance_open_openhd_settings_find_air_unit_location() {
        openSettings()
        mainStackLayout.currentIndex = 1
        navigation.currentIndex = 1
        ohdSettingsPanel.user_quidance_animate_channel_scan()
    }
    function gain_focus() { navigation.forceActiveFocus() }
    function frameworkActionButtons() { return [refreshButton, themeButton] }
    function runHeaderRefresh() {
        if (mainStackLayout.currentIndex === 0) {
            _mavlinkTelemetry.ping_all_systems()
            return
        }

        // Outside Status, refresh every currently reachable settings source.
        if (_ohdSystemGround.is_alive)
            _ohdSystemGroundSettings.try_refetch_all_parameters_async(false)
        if (_ohdSystemAir.is_alive) {
            _ohdSystemAirSettingsModel.try_refetch_all_parameters_async(false)
            _airCameraSettingsModel.try_refetch_all_parameters_async(false)
            _airCameraSettingsModel2.try_refetch_all_parameters_async(false)
        }
        _mlrsController.refresh()
    }

    Keys.onEscapePressed: close_all()

    ListModel {
        id: navigationModel
        ListElement { title: qsTr("Status"); icon: "\uf21e" }
        ListElement { title: qsTr("OpenHD"); icon: "\uf085" }
        ListElement { title: qsTr("OSD"); icon: "\uf108" }
        ListElement { title: qsTr("Log"); icon: "\uf03a" }
        ListElement { title: qsTr("RC"); icon: "\uf11b" }
        ListElement { title: qsTr("Connect"); icon: "\uf6ff" }
        ListElement { title: qsTr("Credits"); icon: "\uf005" }
        ListElement { title: qsTr("MAV Debug"); icon: "\uf188" }
    }

    Rectangle {
        id: sidebar
        anchors.top: parent.top
        anchors.bottom: parent.bottom
        anchors.left: parent.left
        width: settings_form.sidebarWidth
        color: darkMode ? "#0b1b2b" : "#ffffff"
        border.color: lineColor
        border.width: 1

        Column {
            id: brand
            anchors.top: parent.top
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.margins: settings_form.compactSidebar ? 10 : 20
            spacing: 3
            Row {
                visible: !settings_form.compactSidebar
                spacing: 8
                Text {
                    text: "QOpenHD"
                    color: primaryText
                    font.pixelSize: Math.max(16, Math.min(19, sidebar.width / 10))
                    font.bold: true
                }
                Rectangle {
                    visible: !settings_form.compactSidebar
                    anchors.verticalCenter: parent.verticalCenter
                    width: 43; height: 25; radius: 5; color: "#12579d"
                    Text { anchors.centerIn: parent; text: "EVO"; color: "#5eb3ff"; font.pixelSize: 13; font.bold: true }
                }
            }
            Text { visible: !settings_form.compactSidebar; text: qsTr("ADVANCED MENU"); color: secondaryText; font.pixelSize: 10; font.letterSpacing: 1.4 }
            Button {
                id: compactBackButton
                visible: settings_form.compactSidebar
                width: 52
                height: 52
                x: Math.round((brand.width - width) / 2)
                hoverEnabled: true
                activeFocusOnTab: true
                padding: 5
                onClicked: settings_form.close_all()
                background: Item { }
                contentItem: Canvas {
                    id: openHdMark
                    property bool inverted: compactBackButton.hovered || compactBackButton.activeFocus || compactBackButton.down
                    antialiasing: true
                    renderTarget: Canvas.FramebufferObject
                    onInvertedChanged: requestPaint()
                    onPaint: {
                        var ctx = getContext("2d")
                        var side = Math.min(width, height)
                        var scale = side / 42
                        var center = side / 2
                        var primaryMarkColor = settings_form.darkMode ? "#f3f7fb" : "#163d62"
                        var accentMarkColor = "#08a5df"
                        ctx.setTransform(1, 0, 0, 1, 0, 0)
                        ctx.clearRect(0, 0, width, height)
                        ctx.translate((width - side) / 2, (height - side) / 2)
                        ctx.lineWidth = 3.2 * scale
                        ctx.lineCap = "round"

                        ctx.strokeStyle = inverted ? accentMarkColor : primaryMarkColor
                        for (var upper = 0; upper < 3; ++upper) {
                            ctx.beginPath()
                            ctx.arc(center, center, (7 + upper * 5) * scale, Math.PI, Math.PI * 1.5, false)
                            ctx.stroke()
                        }

                        ctx.strokeStyle = inverted ? primaryMarkColor : accentMarkColor
                        for (var lower = 0; lower < 3; ++lower) {
                            ctx.beginPath()
                            ctx.arc(center, center, (7 + lower * 5) * scale, 0, Math.PI * 0.5, false)
                            ctx.stroke()
                        }
                    }
                    onWidthChanged: requestPaint()
                    onHeightChanged: requestPaint()
                    Connections {
                        target: settings_form
                        onDarkModeChanged: openHdMark.requestPaint()
                    }
                }
            }
        }

        ListView {
            id: navigation
            anchors.top: brand.bottom
            anchors.topMargin: 18
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.bottom: versionBadge.top
            anchors.bottomMargin: 16
            anchors.leftMargin: 12
            anchors.rightMargin: 12
            clip: true
            spacing: 4
            model: navigationModel
            currentIndex: mainStackLayout.currentIndex
            keyNavigationWraps: true
            highlightMoveDuration: 120
            focus: true
            ScrollBar.vertical: ScrollBar { policy: ScrollBar.AlwaysOff }

            delegate: ItemDelegate {
                id: navDelegate
                width: navigation.width
                height: 43
                leftPadding: 0
                rightPadding: 0
                hoverEnabled: true
                highlighted: ListView.isCurrentItem
                contentItem: Item {
                    Text {
                        width: 25
                        anchors.verticalCenter: parent.verticalCenter
                        x: settings_form.compactSidebar ? Math.round((parent.width - width) / 2) : 14
                        text: model.icon
                        color: navDelegate.highlighted ? "#ffffff" : settings_form.primaryText
                        font.family: "Font Awesome 5 Free"
                        font.pixelSize: 16
                        horizontalAlignment: Text.AlignHCenter
                    }
                    Text {
                        visible: !settings_form.compactSidebar
                        anchors.left: parent.left
                        anchors.leftMargin: 50
                        anchors.verticalCenter: parent.verticalCenter
                        text: model.title
                        color: navDelegate.highlighted ? "#ffffff" : settings_form.primaryText
                        font.pixelSize: 14
                        font.bold: navDelegate.highlighted
                    }
                }
                background: Rectangle {
                    radius: 9
                    color: navDelegate.highlighted ? "#174d82" : (navDelegate.hovered ? (settings_form.darkMode ? "#142f48" : "#e3edf7") : "transparent")
                    border.color: navDelegate.activeFocus ? "#58a9ff" : "transparent"
                    border.width: 2
                    Rectangle {
                        width: 3; height: parent.height - 8
                        anchors.left: parent.left; anchors.verticalCenter: parent.verticalCenter
                        radius: 2; color: settings_form.accentColor; visible: navDelegate.highlighted
                    }
                }
                onClicked: {
                    navigation.currentIndex = index
                    mainStackLayout.currentIndex = index
                    navigation.forceActiveFocus()
                }
            }

            Keys.onPressed: function(event) {
                if (event.key === Qt.Key_Enter || event.key === Qt.Key_Return || event.key === Qt.Key_Space) {
                    mainStackLayout.currentIndex = currentIndex
                    event.accepted = true
                } else if (event.key === Qt.Key_Right) {
                    if (currentIndex === 0)
                        statusPanel.gainFocus()
                    else if (currentIndex === 1)
                        ohdSettingsPanel.gainFocus()
                    else if (currentIndex === 2)
                        appSettingsPanel.gainFocus()
                    else {
                        var page = mainStackLayout.itemAt(currentIndex)
                        if (page && page.gainFocus)
                            page.gainFocus()
                        else if (page)
                            page.forceActiveFocus()
                    }
                    event.accepted = true
                } else if (event.key === Qt.Key_Left || event.key === Qt.Key_Escape) {
                    close_all()
                    event.accepted = true
                }
            }
            onCurrentIndexChanged: {
                if (activeFocus && currentIndex >= 0)
                    mainStackLayout.currentIndex = currentIndex
            }
        }

        Rectangle {
            id: versionBadge
            anchors.left: parent.left; anchors.right: parent.right; anchors.bottom: parent.bottom
            anchors.margins: settings_form.compactSidebar ? 10 : 18
            height: 42; radius: 8
            color: versionHit.containsMouse ? settings_form.panelBackgroundRaised : "transparent"
            border.color: lineColor
            Row {
                anchors.centerIn: parent; spacing: 10
                Rectangle { width: 10; height: 10; radius: 5; color: goodColor }
                Text { visible: !settings_form.compactSidebar; anchors.verticalCenter: parent.verticalCenter; text: _qopenhd.version_string; color: secondaryText; font.pixelSize: 11 }
            }
            MouseArea {
                id: versionHit
                property bool longPressTriggered: false
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onPressed: longPressTriggered = false
                onPressAndHold: {
                    longPressTriggered = true
                    settings_form.openDeveloperTools()
                }
                onClicked: {
                    if (!longPressTriggered)
                        settings_form.user_quidance_open_connect_screen()
                }
            }
        }
    }

    Item {
        id: contentFrame
        anchors.top: parent.top; anchors.bottom: parent.bottom
        anchors.left: sidebar.right; anchors.right: parent.right

        Button {
            id: refreshButton
            z: 10
            anchors.top: parent.top; anchors.right: themeButton.left
            anchors.topMargin: 20; anchors.rightMargin: 9
            width: 62; height: 40
            text: "\uf2f1"
            font.family: "Font Awesome 5 Free"; font.pixelSize: 15
            onClicked: settings_form.runHeaderRefresh()
            onActiveFocusChanged: if (activeFocus && mainStackLayout.currentIndex === 0) statusPanel.syncFocus(refreshButton)
            Keys.onPressed: function(event) {
                if (event.key === Qt.Key_Down || event.key === Qt.Key_Right) {
                    if (mainStackLayout.currentIndex === 0)
                        statusPanel.moveFocus(1)
                    else
                        themeButton.forceActiveFocus()
                    event.accepted = true
                } else if (event.key === Qt.Key_Up) {
                    if (mainStackLayout.currentIndex === 0)
                        statusPanel.moveFocus(-1)
                    else
                        themeButton.forceActiveFocus()
                    event.accepted = true
                } else if (event.key === Qt.Key_Left || event.key === Qt.Key_Escape) {
                    settings_form.side_bar_regain_focus()
                    event.accepted = true
                }
            }
            background: Rectangle { radius: 20; color: panelBackground; border.color: refreshButton.activeFocus ? accentColor : lineColor; border.width: refreshButton.activeFocus ? 2 : 1 }
            contentItem: Text { text: refreshButton.text; font: refreshButton.font; color: primaryText; horizontalAlignment: Text.AlignHCenter; verticalAlignment: Text.AlignVCenter }
        }

        Button {
            id: themeButton
            z: 10
            anchors.top: parent.top; anchors.right: parent.right
            anchors.topMargin: 20; anchors.rightMargin: 20
            width: 62; height: 40
            text: darkMode ? "\uf185" : "\uf186"
            font.family: "Font Awesome 5 Free"; font.pixelSize: 15
            onClicked: {
                darkMode = !darkMode
                advancedThemeSettings.darkMode = darkMode
            }
            onActiveFocusChanged: if (activeFocus && mainStackLayout.currentIndex === 0) statusPanel.syncFocus(themeButton)
            Keys.onPressed: function(event) {
                if (event.key === Qt.Key_Down || event.key === Qt.Key_Right) {
                    if (mainStackLayout.currentIndex === 0)
                        statusPanel.moveFocus(1)
                    else
                        refreshButton.forceActiveFocus()
                    event.accepted = true
                } else if (event.key === Qt.Key_Up) {
                    if (mainStackLayout.currentIndex === 0)
                        statusPanel.moveFocus(-1)
                    else
                        refreshButton.forceActiveFocus()
                    event.accepted = true
                } else if (event.key === Qt.Key_Left || event.key === Qt.Key_Escape) {
                    settings_form.side_bar_regain_focus()
                    event.accepted = true
                }
            }
            background: Rectangle { radius: 20; color: panelBackground; border.color: themeButton.activeFocus ? accentColor : lineColor; border.width: themeButton.activeFocus ? 2 : 1 }
            contentItem: Text { text: themeButton.text; font: themeButton.font; color: primaryText; horizontalAlignment: Text.AlignHCenter; verticalAlignment: Text.AlignVCenter }
        }

        StackLayout {
            id: mainStackLayout
            anchors.fill: parent
            currentIndex: 0
            PanelStatus { id: statusPanel }
            OHDSettingsPanel { id: ohdSettingsPanel }
            AppSettingsPanel { id: appSettingsPanel }
            LogMessagesStatusView { id: logMessagesStatusView }
            RcInfoPanel { id: rcInfoPanel }
            ConnectPanel { id: connectPanel }
            Credits { id: creditspanel }
            MavlinkDebugPanel { id: mavlinkDebugPanel }
            AppDeveloperStatsPanel { id: appDeveloperStatsPanel }
        }
    }
}
