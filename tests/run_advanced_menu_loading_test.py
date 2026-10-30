"""Check production menu dependency isolation and asynchronous navigation in Qt 5.

python tests/run_advanced_menu_loading_test.py --qt-bin C:/Qt/5.15.19/mingw81_64/bin
Unselected pages deliberately contain invalid QML: opening Status must not load
or compile them. Inline sourceComponents fail this check before instantiation.
"""
import argparse
import os
from pathlib import Path
import shutil
import subprocess
import tempfile


ROOT = Path(__file__).resolve().parents[1]


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--qt-bin", required=True, type=Path)
    args = parser.parse_args()
    menu_dir = ROOT / "qml/ui/configpopup"
    menu = (menu_dir / "ConfigPopup.qml").read_text(encoding="utf-8")
    # Support both old inline declarations and URL sources for regression checks.
    pages = {
        "status/PanelStatus.qml", "openhd_settings/OHDSettingsPanel.qml",
        "qopenhd_settings/AppSettingsPanel.qml", "qopenhd_settings/OsdSettingsPanel.qml", "log/LogMessagesStatusView.qml",
        "rc/RcInfoPanel.qml", "connect/ConnectPanel.qml", "credits/Credits.qml",
        "dev/MavlinkDebugPanel.qml", "dev/AppDeveloperStatsPanel.qml",
    }
    stub = '''import QtQuick 2.12
Item {
    property int focusCalls: 0
    property int guidanceCalls: 0
    property color inheritedColor: settings_form.pageBackground
    function gainFocus() { focusCalls++; forceActiveFocus() }
    function user_quidance_animate_channel_scan() { guidanceCalls++ }
    function syncFocus(control) {}
    function moveFocus(step) {}
}
'''
    test = '''import QtQuick 2.12
import QtTest 1.2
Item {
    width: 850; height: 480
    QtObject { id: _qopenhd; property string version_string: "test"; property bool launchedFromQtCreator: false; property bool debugMenuPreview: false; property int debugMenuPreviewLevel: 0; onDebugMenuPreviewLevelChanged: debugMenuPreview = debugMenuPreviewLevel > 0 }
    QtObject { id: _uiSimulator; property bool active: false; property var profile: ({accessMode:0}) }
    QtObject { id: hudOverlayGrid; function regain_focus() {} }
    Loader { id: menu; anchors.fill: parent; source: "ConfigPopup.qml" }
    TestCase {
        name: "AdvancedMenuLoading"; when: windowShown
        function test_creator_only_preview_button() {
            tryCompare(menu, "status", Loader.Ready)
            var button = findChild(menu.item, "debugMenuPreviewButton")
            verify(button !== null)
            compare(button.visible, false)
            _qopenhd.launchedFromQtCreator = true
            tryCompare(button, "visible", true)
            mouseClick(button)
            compare(_qopenhd.debugMenuPreview, true)
            compare(button.checked, true)
            compare(_qopenhd.debugMenuPreviewLevel, 1)
            compare(menu.item.showAdvancedSettings, false)
            mouseClick(button)
            compare(_qopenhd.debugMenuPreview, true)
            compare(_qopenhd.debugMenuPreviewLevel, 2)
            compare(menu.item.showAdvancedSettings, true)
            compare(menu.item.showDeveloperSettings, false)
            mouseClick(button)
            compare(_qopenhd.debugMenuPreview, false)
            compare(_qopenhd.debugMenuPreviewLevel, 0)
            compare(button.checked, false)
            _qopenhd.launchedFromQtCreator = false
            tryCompare(button, "visible", false)
        }
        function test_dependency_isolation_and_navigation() {
            tryCompare(menu, "status", Loader.Ready)
            var root = menu.item
            tryVerify(function() { return root.statusPanel !== null })
            compare(root.statusPanel.inheritedColor, root.pageBackground)
            compare(root.compactSidebar, true)
            compare(root.menuPageTitle, "SYSTEM STATUS")
            var headerTitle = findChild(root, "menuHeaderTitle")
            tryVerify(function() { return headerTitle !== null })
            compare(headerTitle.text, "SYSTEM STATUS")
            compare(root.ohdSettingsPanel, null)
            compare(root.appDeveloperStatsPanel, null)
            root.user_guidance_open_openhd_settings_find_air_unit_location()
            tryVerify(function() { return root.ohdSettingsPanel !== null })
            tryCompare(root.ohdSettingsPanel, "guidanceCalls", 1)
            compare(root.menuPageTitle, "OPENHD")
            compare(headerTitle.text, "OPENHD")
            verify(findChild(root,"statusSoundButton").visible)
            var cached = root.ohdSettingsPanel
            root.openDeveloperTools()
            compare(root.appDeveloperStatsPanel, null)
            compare(root.showDeveloperSettings, false)
            compare(root.menuPageTitle, "OPENHD")
            root.user_guidance_open_openhd_settings_find_air_unit_location()
            compare(root.ohdSettingsPanel, cached)
            compare(cached.guidanceCalls, 2)
            root.close_all()
            root.openSettings()
            compare(root.ohdSettingsPanel, cached)
        }
        function test_diagnostics_unlock_after_five_star_clicks() {
            tryCompare(menu, "status", Loader.Ready)
            var root = menu.item
            compare(root.diagnosticsUnlocked, false)
            compare(root.showDeveloperSettings, false)
            compare(root.navigationPageIds.indexOf(3), -1)
            compare(root.navigationPageIds.indexOf(7), -1)
            var navigation = findChild(root, "advancedNavigation")
            navigation.positionViewAtIndex(root.navigationPageIds.indexOf(6), ListView.Contain)
            wait(50)
            mouseClick(findChild(root, "navigationPage6"))
            compare(root.menuPageTitle, "CREDITS")
            compare(root.creditsStarClickCount, 1)
            var star = findChild(root, "creditsStarUnlockArea")
            for (var i = 0; i < 3; ++i) mouseClick(star)
            compare(root.diagnosticsUnlocked, false)
            mouseClick(star)
            tryCompare(root, "diagnosticsUnlocked", true)
            compare(root.showDeveloperSettings, true)
            verify(root.navigationPageIds.indexOf(3) >= 0)
            verify(root.navigationPageIds.indexOf(7) >= 0)
            compare(root.menuPageTitle, "CREDITS")
            wait(50)
            navigation.positionViewAtIndex(root.navigationPageIds.indexOf(3), ListView.Contain)
            mouseClick(findChild(root, "navigationPage3"))
            compare(root.menuPageTitle, "SYSTEM LOGS")
            root.openDeveloperTools()
            tryVerify(function() { return root.appDeveloperStatsPanel !== null })
            tryCompare(root.appDeveloperStatsPanel, "focusCalls", 1)
            compare(root.menuPageTitle, "DEVELOPER TOOLS")
        }
        function test_osd_and_application_are_separate() {
            var root = menu.item
            var navigation=findChild(root,"advancedNavigation")
            navigation.positionViewAtIndex(root.navigationPageIds.indexOf(2),ListView.Contain)
            wait(50);mouseClick(findChild(root,"navigationPage2"))
            compare(root.menuPageTitle,"OSD")
            navigation.positionViewAtIndex(root.navigationPageIds.indexOf(8),ListView.Contain)
            wait(50);mouseClick(findChild(root,"navigationPage8"))
            compare(root.menuPageTitle,"APPLICATION")
            compare(findChild(root,"menuHeaderTitle").text,"APPLICATION")
        }
        function test_simulator_access_modes() {
            var root = menu.item
            root.diagnosticsUnlocked = true
            _uiSimulator.profile = {accessMode:0}
            _uiSimulator.active = true
            compare(root.showAdvancedSettings, false)
            compare(root.showDeveloperSettings, false)
            compare(root.navigationPageIds.indexOf(3), -1)
            _uiSimulator.profile = {accessMode:1}
            compare(root.showAdvancedSettings, true)
            compare(root.showDeveloperSettings, false)
            _uiSimulator.profile = {accessMode:2}
            compare(root.showAdvancedSettings, true)
            compare(root.showDeveloperSettings, true)
            verify(root.navigationPageIds.indexOf(3) >= 0)
            _uiSimulator.active = false
            compare(root.showDeveloperSettings, true)
            compare(root.diagnosticsUnlocked, true)
        }
        function test_deferred_dialog_cancels_pending_request() {
            var component = Qt.createComponent("status/DeferredStatusDialog.qml")
            compare(component.status, Component.Ready)
            var dialog = component.createObject(menu.parent, {source: Qt.resolvedUrl("status/PowerActionDialoque.qml")})
            compare(dialog.item, null)
            dialog.open("open_dialoque", [0, true])
            dialog.close()
            tryCompare(dialog, "status", Loader.Ready)
            compare(dialog.item.visible, false)
            dialog.open("open_dialoque", [1, false])
            compare(dialog.item.receivedArguments, [1, false])
            compare(dialog.item.visible, true)
            dialog.close()
            dialog.destroy()
        }
        function test_loader_queues_and_cancels_focus() {
            var component = Qt.createComponent("AdvancedPageLoader.qml")
            compare(component.status, Component.Ready)
            var page = component.createObject(menu, {source: "Basic.qml"})
            page.selected = true
            page.gainFocus()
            tryCompare(page, "status", Loader.Ready)
            compare(page.item.focusCalls, 1)
            page.selected = false
            page.selected = true
            compare(page.item.focusCalls, 1)
            page.destroy()
            page = component.createObject(menu, {source: "Basic.qml"})
            page.selected = true
            page.gainFocus()
            page.selected = false
            compare(page.pendingMethod, "")
            page.selected = true
            tryCompare(page, "status", Loader.Ready)
            compare(page.item.focusCalls, 0)
            page.destroy()
        }
    }
}
'''
    env = os.environ.copy()
    env.update(QT_QPA_PLATFORM="offscreen", QT_QUICK_BACKEND="software",
               QT_FORCE_STDERR_LOGGING="1", QML_DISABLE_DISK_CACHE="1",
               QML2_IMPORT_PATH=str(args.qt_bin.parent / "qml"),
               QT_QPA_PLATFORM_PLUGIN_PATH=str(args.qt_bin.parent / "plugins/platforms"))
    with tempfile.TemporaryDirectory(prefix="qopenhd-menu-") as temp:
        folder = Path(temp)
        (folder / "OpenHD").mkdir()
        (folder / "OpenHD/qmldir").write_text("module OpenHD\nDummy 1.0 Dummy.qml\n", encoding="utf-8")
        (folder / "OpenHD/Dummy.qml").write_text("import QtQuick 2.12\nQtObject {}\n", encoding="utf-8")
        (folder / "Basic.qml").write_text(stub.replace("settings_form.pageBackground", '"black"'), encoding="utf-8")
        (folder / "features").mkdir()
        shutil.copy(menu_dir / "MenuTypography.js", folder)
        shutil.copy(menu_dir / "AdvancedActionButton.qml", folder)
        (folder / "ConfigPopup.qml").write_text(menu, encoding="utf-8")
        shutil.copy(menu_dir / "AdvancedPageLoader.qml", folder)
        for name in pages:
            path = folder / name
            path.parent.mkdir(exist_ok=True)
            valid = name.startswith("status/") or name.endswith(("OHDSettingsPanel.qml", "AppDeveloperStatsPanel.qml"))
            path.write_text(stub if valid else "import QtQuick 2.12\nDeliberatelyMissingType {}\n", encoding="utf-8")
        shutil.copy(menu_dir / "status/StatusOverviewHeader.qml", folder / "status/StatusOverviewHeader.qml")
        (folder / "tst_menu.qml").write_text(test, encoding="utf-8")
        command = [str(args.qt_bin / "qmltestrunner.exe"), "-import", str(folder), "-input", str(folder)]
        start = test.index("        function test_deferred_dialog_cancels_pending_request()")
        end = test.index("        function test_loader_queues_and_cancels_focus()", start)
        (folder / "tst_menu.qml").write_text(test[:start] + test[end:], encoding="utf-8")
        result = subprocess.run(command, env=env, timeout=60).returncode
        if result:
            return result
        # Exercise the actual Status page as well: a closed FC inspector must
        # not instantiate its live models while the menu is being created.
        status = (menu_dir / "status/PanelStatus.qml").read_text(encoding="utf-8")
        status = status.replace("id: root", "id: root; readonly property color inheritedColor: settings_form.pageBackground", 1)
        status = status.replace("id: powerDialog;", 'id: powerDialog; objectName: "testPowerDialog";')
        status = status.replace("id: dialoqueNotAlive;", 'id: dialoqueNotAlive; objectName: "testWarningDialog";')
        status = status.replace('objectName: "flightControllerDetailsPopup"', 'objectName: "testCraftPopup"')
        status = status.replace("id: craftDetailsLoader\n", 'id: craftDetailsLoader; objectName: "testCraftLoader"\n')
        (folder / "status/PanelStatus.qml").write_text(status, encoding="utf-8")
        (folder / "status/StatusCardsColumn.qml").write_text('''import QtQuick 2.12
Item { property real availableHeight: 0; signal craftDetailsRequested(); signal unitDetailsRequested(int systemType); function actionButtons() { return [] } }
''', encoding="utf-8")
        shutil.copy(menu_dir / "status/DeferredStatusDialog.qml", folder / "status/DeferredStatusDialog.qml")
        for name in ("PowerActionDialoque", "DialoqueNotAlive"):
            (folder / ("status/" + name + ".qml")).write_text('import QtQuick 2.12\nItem { visible: false; property var receivedArguments: []; function open_dialoque(system, reboot) { receivedArguments = [system, reboot]; visible = true } function open_ground() { receivedArguments = [0]; visible = true } function open_air() { receivedArguments = [1]; visible = true } }\n', encoding="utf-8")
        (folder / "status/CraftDetailsPanel.qml").write_text(stub.replace("    property int focusCalls", "    signal closeRequested()\n    property int focusCalls"), encoding="utf-8")
        popup_test = '''
        function test_status_defers_closed_craft_inspector() {
            var component = Qt.createComponent("ConfigPopup.qml")
            compare(component.status, Component.Ready)
            var root = component.createObject(menu.parent)
            tryVerify(function() { return root.statusPanel !== null })
            var popup = findChild(root.statusPanel, "testCraftPopup")
            var loader = findChild(root.statusPanel, "testCraftLoader")
            verify(popup !== null)
            verify(loader !== null)
            compare(loader.item, null)
            var power = findChild(root.statusPanel, "testPowerDialog")
            var warning = findChild(root.statusPanel, "testWarningDialog")
            compare(power.item, null)
            compare(warning.item, null)
            root.statusPanel.open_power_action_dialoque(1, true)
            tryCompare(power, "status", Loader.Ready)
            compare(power.item.receivedArguments, [1, true])
            compare(power.item.visible, true)
            var cachedPower = power.item
            root.close_all()
            compare(power.item.visible, false)
            root.openSettings()
            root.statusPanel.open_power_action_dialoque(0, false)
            compare(power.item, cachedPower)
            compare(power.item.receivedArguments, [0, false])
            root.statusPanel.open_not_alive_dialog(1)
            tryCompare(warning, "status", Loader.Ready)
            compare(warning.item.receivedArguments, [1])
            warning.close()
            root.statusPanel.open_not_alive_dialog(0)
            compare(warning.item.receivedArguments, [0])
            popup.open()
            tryCompare(loader, "status", Loader.Ready)
            tryCompare(popup, "opened", true)
            tryCompare(loader.item, "focusCalls", 1)
            loader.item.closeRequested()
            tryCompare(popup, "visible", false)
            tryCompare(loader, "item", null)
            root.destroy()
        }
'''
        test = test.replace("        function test_loader_queues", popup_test + "        function test_loader_queues")
        (folder / "tst_menu.qml").write_text(test, encoding="utf-8")
        result = subprocess.run(command, env=env, timeout=60).returncode
        if result:
            return result
        # Exercise the production HUD loader, including cached reopening.
        hud = (ROOT / "qml/HudContent.qml").read_text(encoding="utf-8")
        loader = hud[hud.index("    Loader {\n        id: settings_panel"):]
        loader = loader[:loader.index("\n    Rectangle {")]
        loader = loader.replace('"ui/configpopup/ConfigPopup.qml"', '"ConfigPopup.qml"')
        hud_test = '''import QtQuick 2.12
import QtTest 1.2
Item {
    id: applicationWindow; width: 850; height: 480
    property bool bootSplashEnabled: true
    QtObject { id: hudOverlayGrid; function regain_focus() {} }
    QtObject {
        id: _qopenhd
        property string version_string: "test"
    }
LOADER
    TestCase {
        name: "AdvancedMenuHudLoading"; when: windowShown
        function test_actual_hud_loading_and_reopen() {
            compare(settings_panel.item, null)
            settings_panel.openSettings()
            tryCompare(settings_panel, "status", Loader.Ready)
            tryVerify(function() { return settings_panel.item.currentPageReady })
            var cached = settings_panel.item
            settings_panel.close_all()
            settings_panel.openSettings()
            compare(settings_panel.item, cached)
            settings_panel.close_all()
        }
    }
}
'''.replace("LOADER", loader)
        (folder / "tst_menu.qml").write_text(hud_test, encoding="utf-8")
        return subprocess.run(command, env=env, timeout=60).returncode


if __name__ == "__main__":
    raise SystemExit(main())
