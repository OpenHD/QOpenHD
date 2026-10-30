import "MenuTypography.js" as MenuTypography
import QtQuick 2.12
import QtQuick.Controls 2.12
import QtQuick.Layouts 1.12
import Qt.labs.settings 1.0

import OpenHD 1.0

// Shared framework for the advanced menu. Pages are created on first selection;
// responsive navigation and keyboard ownership live here.
Rectangle {
    id: settings_form
    anchors.fill: parent
    z: 4
    color: pageBackground
    focus: visible

    readonly property var statusPanel: statusPage.item
    readonly property var ohdSettingsPanel: openhdPage.item
    readonly property var appDeveloperStatsPanel: developerPage.item
    readonly property bool currentPageReady: {
        var page = mainStackLayout.children[mainStackLayout.currentIndex]
        return !!page && page.status === Loader.Ready
    }

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
    property bool compactSidebar: true
    readonly property bool simulatorActive: typeof _uiSimulator !== "undefined" && _uiSimulator.active
    readonly property int simulatorAccessMode: simulatorActive ? Number(_uiSimulator.profile.accessMode || 0) : 0
    readonly property bool showDeveloperSettings: simulatorActive ? simulatorAccessMode === 2 : diagnosticsUnlocked
    readonly property bool showAdvancedSettings: simulatorActive ? simulatorAccessMode >= 1 : _qopenhd.debugMenuPreviewLevel === 2 ||
        (!_qopenhd.debugMenuPreview && typeof settings !== "undefined" && settings.dev_show_advanced_button === true)
    function openBackupRestore() {
        backupDialog.active = true
        if (backupDialog.item) backupDialog.item.open()
    }
    Loader {
        id:backupDialog
        active:false
        source:"backup/BackupRestorePopup.qml"
        onLoaded:item.open()
    }
    function openSimulator() {
        if (!diagnosticsUnlocked || typeof _uiSimulator === "undefined") return
        _uiSimulator.developerUnlocked = true
        simulationDialog.active = true
        if(simulationDialog.item)simulationDialog.item.open()
    }
    Loader {
        id:simulationDialog
        active:false
        source: "dev/SimulationPopup.qml"
        onLoaded:item.open()
    }
    Shortcut { sequence:"Ctrl+Shift+S"; enabled:settings_form.visible && settings_form.diagnosticsUnlocked; onActivated:settings_form.openSimulator() }
    Rectangle {
        z: 100
        anchors.bottom: parent.bottom; anchors.horizontalCenter: parent.horizontalCenter
        width: simulationRow.implicitWidth + 24; height: 34; radius: 8
        visible: typeof _uiSimulator !== "undefined" && _uiSimulator.active
        color: "#663f0c"; border.color: "#eaa33d"
        Row {
            id: simulationRow;anchors.centerIn:parent;spacing:12
            Text { text:qsTr("SIMULATION - no device writes");color:"#fff0d6";font.pixelSize: MenuTypography.body;anchors.verticalCenter:parent.verticalCenter }
            AdvancedActionButton { text:qsTr("Configure / Stop");height:MenuTypography.controlHeight;onClicked:settings_form.openSimulator() }
        }
    }
    property bool diagnosticsUnlocked: false
    property int creditsStarClickCount: 0
    property bool updatingNavigation: false
    readonly property var navigationPageIds: showDeveloperSettings ? [0, 1, 2, 8, 3, 5, 6, 7] : [0, 1, 2, 8, 5, 6]
    onShowDeveloperSettingsChanged: {
        if (!showDeveloperSettings && (mainStackLayout.currentIndex === 3 || mainStackLayout.currentIndex === 7 || mainStackLayout.currentIndex === 9)) {
            mainStackLayout.currentIndex = 0
            navigation.currentIndex = navigationPageIds.indexOf(0)
        }
    }
    function creditsStarClicked() {
        if (mainStackLayout.currentIndex !== 6 || diagnosticsUnlocked) return
        creditsStarClickCount++
        if (creditsStarClickCount < 5) return
        updatingNavigation = true
        diagnosticsUnlocked = true
        navigation.currentIndex = navigationPageIds.indexOf(6)
        Qt.callLater(function() {
            navigation.currentIndex = navigationPageIds.indexOf(mainStackLayout.currentIndex)
            updatingNavigation = false
        })
    }
    onMenuPageTitleChanged: if (mainStackLayout.currentIndex !== 6) creditsStarClickCount = 0
    property int sidebarWidth: compactSidebar ? 72 : Math.max(160, Math.min(210, width * 0.17))

    readonly property string menuPageTitle: [qsTr("SYSTEM STATUS"), qsTr("OPENHD"), qsTr("OSD"), qsTr("SYSTEM LOGS"), "", qsTr("CONNECT"), qsTr("CREDITS"), qsTr("DEBUG"), qsTr("APPLICATION"), qsTr("DEVELOPER TOOLS")][mainStackLayout.currentIndex]
    readonly property string menuPageSubtitle: [qsTr("Overview of all system components"), qsTr("Link, cameras and unit settings"), qsTr("Widgets, style and map"), qsTr("Live system messages"), "", qsTr("Connect to your OpenHD system"), qsTr("The OpenHD community"), qsTr("MAVLink and hardware diagnostics"), qsTr("General, vehicle and video settings"), qsTr("Diagnostics and system information")][mainStackLayout.currentIndex]
    readonly property string menuPageIcon: ["\uf21e", "\uf085", "\uf108", "\uf03a", "\uf11b", "\uf6ff", "\uf005", "\uf188", "\uf013", "\uf0ad"][mainStackLayout.currentIndex]

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
        navigation.currentIndex = navigationPageIds.indexOf(5)
    }
    function openDeveloperTools() {
        if (!diagnosticsUnlocked) return
        openSettings()
        mainStackLayout.currentIndex = 9
        navigation.currentIndex = -1
        developerPage.gainFocus()
    }
    function user_guidance_open_openhd_settings_find_air_unit_location() {
        openSettings()
        mainStackLayout.currentIndex = 1
        navigation.currentIndex = navigationPageIds.indexOf(1)
        openhdPage.invokeWhenReady("user_quidance_animate_channel_scan")
    }
    function gain_focus() { navigation.forceActiveFocus() }
    function frameworkActionButtons() { return debugPreviewButton.visible ? [debugPreviewButton, refreshButton, themeButton] : [refreshButton, themeButton] }
    function runHeaderRefresh() {
        if (_qopenhd.debugMenuPreview) return;
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
        ListElement { title: ""; icon: "" } // Reserved page ID; RC moved to Extras.
        ListElement { title: qsTr("Connect"); icon: "\uf6ff" }
        ListElement { title: qsTr("Credits"); icon: "\uf005" }
        ListElement { title: qsTr("Debug"); icon: "\uf188" }
        ListElement { title: qsTr("Application"); icon: "\uf013" }
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
            AdvancedActionButton { font.family: MenuTypography.family; font.pixelSize: MenuTypography.body;
                id: logoBackButton
                width: 52
                height: MenuTypography.controlHeight
                x: Math.round((brand.width - width) / 2)
                hoverEnabled: true
                activeFocusOnTab: true
                padding: 5
                onClicked: settings_form.close_all()
                background: Item { }
                contentItem: Canvas {
                    id: openHdMark
                    property bool inverted: logoBackButton.hovered || logoBackButton.activeFocus || logoBackButton.down
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
            objectName: "advancedNavigation"
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
            model: settings_form.navigationPageIds
            currentIndex: settings_form.navigationPageIds.indexOf(mainStackLayout.currentIndex)
            keyNavigationWraps: true
            highlightMoveDuration: 120
            focus: true
            ScrollBar.vertical: ScrollBar { policy: ScrollBar.AlwaysOff }

            delegate: ItemDelegate {
                id: navDelegate
                objectName: "navigationPage" + modelData
                width: navigation.width
                height: 43
                leftPadding: 0
                rightPadding: 0
                hoverEnabled: true
                highlighted: mainStackLayout.currentIndex === modelData
                contentItem: Item {
                    Text {
                        width: 25
                        anchors.verticalCenter: parent.verticalCenter
                        x: settings_form.compactSidebar ? Math.round((parent.width - width) / 2) : 14
                        text: navigationModel.get(modelData).icon
                        color: navDelegate.highlighted ? "#ffffff" : settings_form.primaryText
                        font.family: "Font Awesome 5 Free"
                        font.pixelSize: MenuTypography.rowIcon
                        horizontalAlignment: Text.AlignHCenter
                    }
                    Text {
                        visible: !settings_form.compactSidebar
                        anchors.left: parent.left
                        anchors.leftMargin: 50
                        anchors.verticalCenter: parent.verticalCenter
                        text: navigationModel.get(modelData).title
                        color: navDelegate.highlighted ? "#ffffff" : settings_form.primaryText
                        font.pixelSize: MenuTypography.body; font.family: MenuTypography.family
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
                    mainStackLayout.currentIndex = modelData
                    if (modelData === 6) settings_form.creditsStarClicked()
                    navigation.forceActiveFocus()
                }
            }

            Keys.onPressed: function(event) {
                if (event.key === Qt.Key_Enter || event.key === Qt.Key_Return || event.key === Qt.Key_Space) {
                    mainStackLayout.currentIndex = settings_form.navigationPageIds[currentIndex]
                    event.accepted = true
                } else if (event.key === Qt.Key_Right) {
                    var page = mainStackLayout.children[settings_form.navigationPageIds[currentIndex]]
                    if (page) page.gainFocus()
                    event.accepted = true
                } else if (event.key === Qt.Key_Left || event.key === Qt.Key_Escape) {
                    close_all()
                    event.accepted = true
                }
            }
            onCurrentIndexChanged: {
                if (activeFocus && currentIndex >= 0 && !settings_form.updatingNavigation)
                    mainStackLayout.currentIndex = settings_form.navigationPageIds[currentIndex]
            }
        }

        Rectangle {
            id: versionBadge
            objectName:"settingsBackupButton"
            activeFocusOnTab:true
            Accessible.role:Accessible.Button
            Accessible.name:qsTr("Backup and restore settings")
            Keys.onReturnPressed:settings_form.openBackupRestore()
            Keys.onSpacePressed:settings_form.openBackupRestore()
            anchors.left: parent.left; anchors.right: parent.right; anchors.bottom: parent.bottom
            anchors.margins: settings_form.compactSidebar ? 10 : 18
            height: 42; radius: 8
            color: versionHit.containsMouse ? settings_form.panelBackgroundRaised : "transparent"
            border.color: lineColor
            Row {
                anchors.centerIn: parent; spacing: 10
                Text {text:"\uf0c7";color:accentColor;font.family:"Font Awesome 5 Free";font.pixelSize:MenuTypography.sidebarIcon}
                Text { visible: !settings_form.compactSidebar; anchors.verticalCenter: parent.verticalCenter; text: qsTr("Backup & Restore"); color: secondaryText; font.pixelSize: MenuTypography.body; font.family: MenuTypography.family }
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
                        settings_form.openBackupRestore()
                }
            }
        }
    }

    Item {
        id: contentFrame
        readonly property real statusHeaderInset: statusHeader.item ? Math.ceil(24 + statusHeader.item.contentHeight) : 76
        readonly property real toolbarScale: statusHeader.item ? statusHeader.item.headerScale : 1
        anchors.top: parent.top; anchors.bottom: parent.bottom
        anchors.left: sidebar.right; anchors.right: parent.right

        Rectangle {
            visible: true
            anchors.left: parent.left; anchors.right: parent.right
            y: contentFrame.statusHeaderInset - 1
            height: 1
            color: "#153447"
        }

        Loader {
            id: statusHeader
            anchors.left: parent.left; anchors.right: parent.right
            anchors.leftMargin: settings_form.compactSidebar ? 13 : Math.max(16, Math.min(32, contentFrame.width * 0.025))
            anchors.rightMargin: anchors.leftMargin
            anchors.top: parent.top
            anchors.topMargin: 16
            height: 64
            active: true
            visible: true
            source: "status/StatusOverviewHeader.qml"
        }

        AdvancedActionButton {
            id: debugPreviewButton
            objectName: "debugMenuPreviewButton"
            hoverEnabled: true
            z: 10
            anchors.top: parent.top; anchors.right: refreshButton.left
            anchors.topMargin: 16; anchors.rightMargin: 10 * contentFrame.toolbarScale
            width: 90 * contentFrame.toolbarScale; height: MenuTypography.controlHeight * contentFrame.toolbarScale
            visible: _qopenhd.launchedFromQtCreator === true
            checked: _qopenhd.debugMenuPreview === true
            text: "\uf188"
            font.family: "Font Awesome 5 Free"; font.pixelSize: MenuTypography.sectionIcon * contentFrame.toolbarScale
            Accessible.name: qsTr("Debug view: normal, all basic settings, all settings")
            onClicked: {
                if(typeof _uiSimulator !== "undefined" && _uiSimulator.active)settings_form.openSimulator()
                else _qopenhd.debugMenuPreviewLevel = (_qopenhd.debugMenuPreviewLevel + 1) % 3
            }
            onPressAndHold: settings_form.openSimulator()
            KeyNavigation.right: refreshButton
            Keys.onEscapePressed: settings_form.side_bar_regain_focus()
            onActiveFocusChanged: if (activeFocus && mainStackLayout.currentIndex === 0 && statusPanel) statusPanel.syncFocus(debugPreviewButton)
            background: Rectangle {
                radius: 20
                color: _qopenhd.debugMenuPreviewLevel === 2 ? "#713b85" : debugPreviewButton.checked ? "#805c20" : panelBackground
                border.color: debugPreviewButton.activeFocus ? accentColor : lineColor
                border.width: debugPreviewButton.activeFocus ? 2 : 1
            }
            contentItem: Text { text: debugPreviewButton.text; font: debugPreviewButton.font; color: primaryText; horizontalAlignment: Text.AlignHCenter; verticalAlignment: Text.AlignVCenter }
        }

        AdvancedActionButton {
            id: refreshButton
            z: 10
            anchors.top: parent.top; anchors.right: themeButton.left
            anchors.topMargin: 16; anchors.rightMargin: 10 * contentFrame.toolbarScale
            width: 90 * contentFrame.toolbarScale; height: MenuTypography.controlHeight * contentFrame.toolbarScale
            text: "\uf2f1"
            font.family: "Font Awesome 5 Free"; font.pixelSize: MenuTypography.sectionIcon * contentFrame.toolbarScale
            onClicked: settings_form.runHeaderRefresh()
            onActiveFocusChanged: if (activeFocus && mainStackLayout.currentIndex === 0 && statusPanel) statusPanel.syncFocus(refreshButton)
            Keys.onPressed: function(event) {
                if (event.key === Qt.Key_Down || event.key === Qt.Key_Right) {
                    if (mainStackLayout.currentIndex === 0 && statusPanel)
                        statusPanel.moveFocus(1)
                    else
                        themeButton.forceActiveFocus()
                    event.accepted = true
                } else if (event.key === Qt.Key_Up) {
                    if (mainStackLayout.currentIndex === 0 && statusPanel)
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

        AdvancedActionButton {
            id: themeButton
            z: 10
            anchors.top: parent.top; anchors.right: parent.right
            anchors.topMargin: 16; anchors.rightMargin: statusHeader.anchors.rightMargin
            width: 90 * contentFrame.toolbarScale; height: MenuTypography.controlHeight * contentFrame.toolbarScale
            text: darkMode ? "\uf185" : "\uf186"
            font.family: "Font Awesome 5 Free"; font.pixelSize: MenuTypography.sectionIcon * contentFrame.toolbarScale
            onClicked: {
                darkMode = !darkMode
                advancedThemeSettings.darkMode = darkMode
            }
            onActiveFocusChanged: if (activeFocus && mainStackLayout.currentIndex === 0 && statusPanel) statusPanel.syncFocus(themeButton)
            Keys.onPressed: function(event) {
                if (event.key === Qt.Key_Down || event.key === Qt.Key_Right) {
                    if (mainStackLayout.currentIndex === 0 && statusPanel)
                        statusPanel.moveFocus(1)
                    else
                        refreshButton.forceActiveFocus()
                    event.accepted = true
                } else if (event.key === Qt.Key_Up) {
                    if (mainStackLayout.currentIndex === 0 && statusPanel)
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

        BusyIndicator {
            anchors.centerIn: parent
            z: 1
            running: visible
            visible: mainStackLayout.children[mainStackLayout.currentIndex].status === Loader.Loading
        }

        StackLayout {
            id: mainStackLayout
            anchors.fill: parent
            // Keep the Status heading, telemetry and toolbar clear of the cards.
            anchors.topMargin: contentFrame.statusHeaderInset
            currentIndex: 0
            onCurrentIndexChanged: if (currentIndex === 4) currentIndex = 0
            // URL sources defer parsing/compiling each page's dependency tree.
            // Inline sourceComponents still resolve every page when this menu loads.
            AdvancedPageLoader { id: statusPage; selected: mainStackLayout.currentIndex === 0; source: "status/PanelStatus.qml" }
            AdvancedPageLoader { id: openhdPage; selected: mainStackLayout.currentIndex === 1; source: "openhd_settings/OHDSettingsPanel.qml" }
            AdvancedPageLoader { id: osdPage; selected: mainStackLayout.currentIndex === 2; source: "qopenhd_settings/OsdSettingsPanel.qml" }
            AdvancedPageLoader { id: logPage; selected: mainStackLayout.currentIndex === 3; source: "log/LogMessagesStatusView.qml" }
            Item { property int status: Loader.Ready } // Retired RC page; preserve other page IDs.
            AdvancedPageLoader { id: connectPage; selected: mainStackLayout.currentIndex === 5; source: "connect/ConnectPanel.qml" }
            AdvancedPageLoader { id: creditsPage; selected: mainStackLayout.currentIndex === 6; source: "credits/Credits.qml" }
            AdvancedPageLoader { id: mavDebugPage; selected: mainStackLayout.currentIndex === 7; source: "dev/MavlinkDebugPanel.qml" }
            AdvancedPageLoader { id: applicationPage; selected: mainStackLayout.currentIndex === 8; source: "qopenhd_settings/AppSettingsPanel.qml" }
            AdvancedPageLoader { id: developerPage; selected: mainStackLayout.currentIndex === 9; source: "dev/AppDeveloperStatsPanel.qml" }
        }
    }
}
