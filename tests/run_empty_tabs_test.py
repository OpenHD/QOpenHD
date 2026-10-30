"""Qt 5 regression for content-driven advanced-menu tabs."""
import argparse
import os
from pathlib import Path
import shutil
import subprocess
import tempfile

ROOT = Path(__file__).resolve().parents[1]
MENU = ROOT / "qml/ui/configpopup"
parser = argparse.ArgumentParser(description=__doc__)
parser.add_argument("--qt-bin", required=True, type=Path)
args = parser.parse_args()
with tempfile.TemporaryDirectory(prefix="qopenhd-empty-tabs-") as temp:
    folder = Path(temp)
    for name in ["AdvancedTabButton.qml", "AdvancedTabBar.qml", "MenuTypography.js", "AdvancedPage.qml", "AdvancedCard.qml"]:
        shutil.copy(MENU / name, folder / name)
    shutil.copy(MENU / "openhd_settings/AirSettingsLayout.js", folder)
    shutil.copy(MENU / "openhd_settings/CameraSettingsLayout.js", folder)
    (folder / "log").mkdir()
    shutil.copy(MENU / "log/LogMessagesView.qml", folder / "log")
    log_source = (MENU / "log/LogMessagesStatusView.qml").read_text(encoding="utf-8")
    log_source = log_source.replace("id: logTabs", 'id: logTabs; objectName: "sourceTabs"')
    (folder / "log/LogMessagesStatusView.qml").write_text(log_source, encoding="utf-8")
    for index, name in enumerate(["CameraSettingsPanel.qml", "CameraDualPanel.qml"]):
        source = (MENU / "openhd_settings" / name).read_text(encoding="utf-8")
        helpers = source[source.index("    ListModel {"):source.index("    function focusCategory(")]
        assert "visible: root.categoryAvailable(index)" in source
        (folder / ("CameraCategories%d.qml" % index)).write_text(
            'import QtQuick 2.12\nimport "CameraSettingsLayout.js" as CameraLayout\nItem { id: root; property var settingsModel; property int paramRevision: settingsModel.update_count; property string activeCategory: "VIDEO"; '
            + helpers + '\nonParamRevisionChanged: ensureActiveCategory()\nConnections { target: settings_form; function onShowAdvancedSettingsChanged() { root.ensureActiveCategory() } }\n}\n', encoding="utf-8")
    source = (MENU / "openhd_settings/OHDSettingsPanel.qml").read_text(encoding="utf-8")
    availability = source[source.index("    readonly property var availablePages:"):source.index("    function tabTitle(")]
    first = source[source.index("    function firstAvailableTab("):source.index("    function focusTab(")]
    (folder / "ParentTabs.qml").write_text('import QtQuick 2.12\nimport "AirSettingsLayout.js" as AirLayout\nimport "CameraSettingsLayout.js" as CameraLayout\nItem { id: root; property int currentPage: 0; QtObject { id: pageModel; property int count: 6 }\n' + availability + first + '\n}\n', encoding="utf-8")
    ground = (MENU / "openhd_settings/MavlinkParamPanel.qml").read_text(encoding="utf-8")
    modes = ground[ground.index("    readonly property bool isGroundPage:"):ground.index("    property bool m_ip_camera_settings_available:")]
    (folder / "GroundModes.qml").write_text('import QtQuick 2.12\nimport "AirSettingsLayout.js" as AirLayout\nItem {id:root;property var m_instanceMavlinkSettingsModel:_ohdSystemGroundSettings; property alias currentTab:groundTabs.currentIndex; QtObject {id:groundTabs;property int currentIndex:0}\n'+modes+'\n}\n',encoding="utf-8")
    extras = (MENU / "features/FeatureSettingsPanel.qml").read_text(encoding="utf-8")
    expression = extras.split("                hasContent: {", 1)[1].split("\n                }", 1)[0]
    (folder / "ExtrasAvailability.qml").write_text('import QtQuick 2.12\nItem { id: root; property int airRevision: _ohdSystemAirSettingsModel.update_count; property int groundRevision: _ohdSystemGroundSettings.update_count; readonly property bool dataLinkAvailable: {' + expression + '}\n}\n', encoding="utf-8")
    fixture = r'''import QtQuick 2.12
import QtQuick.Controls 2.12
import QtTest 1.2
import "log" as Logs
Item {
    width: 800; height: 600
    QtObject {
        id: settings_form
        property bool darkMode: true
        property bool compactSidebar: false
        property bool showAdvancedSettings: true
        property bool showDeveloperSettings: false
        property color pageBackground: "black"
        property color primaryText: "white"
        property color secondaryText: "gray"
        property color accentColor: "blue"
        property color panelBackground: "black"
        property color panelBackgroundRaised: "gray"
        property color lineColor: "gray"
    }
    QtObject { id: _qopenhd; property bool debugMenuPreview: false }
    QtObject {
        id: params
        property var ids: []
        property int cameraType: 0
        function get_cached_int(id) { return cameraType }
        property int update_count: 0
        function param_ids() { return ids }
        function get_ui_metadata(id) { return {hidden:id === "KEYFRAME_I"} }
        function param_int_exists(id) { return ids.indexOf(id) >= 0 }
        function param_string_exists(id) { return ids.indexOf(id) >= 0 }
    }
    property var _airCameraSettingsModel: params
    property var _airCameraSettingsModel2: params
    property var _ohdSystemAirSettingsModel: params
    property var _ohdSystemGroundSettings: params
    ListModel { id: _logGround }
    ListModel { id: _logOpenhdAir }
    ListModel { id: _logFC }
    property var _logQOpenHD: _logGround
    Logs.LogMessagesStatusView { id: logPage; width: 700; height: 500; y: 60 }
    ParentTabs { id: parentTabs }
    ExtrasAvailability { id: extras }
    GroundModes {id:groundModes}
    CameraCategories0 { id: single; settingsModel: params }
    CameraCategories1 { id: dual; settingsModel: params }
    AdvancedTabBar {
        id: tabs; width: 600
        AdvancedTabButton { id: one; text: "one" }
        AdvancedTabButton { id: two; text: "two" }
        AdvancedTabButton { id: three; text: "three" }
    }
    TestCase {
        name: "EmptyAdvancedTabs"; when: windowShown
        function init() {
            one.hasContent = two.hasContent = three.hasContent = true
            tabs.currentIndex = 0
            params.ids = []; params.update_count++
            settings_form.showAdvancedSettings = true
            _qopenhd.debugMenuPreview = false
        }
        function test_shared_bar_fallback_and_keyboard() {
            tabs.currentIndex = 1; two.forceActiveFocus()
            two.hasContent = false
            tryCompare(tabs, "currentIndex", 0)
            compare(two.visible, false); compare(two.width, 0)
            one.forceActiveFocus(); keyClick(Qt.Key_Right)
            compare(tabs.currentIndex, 2)
            keyClick(Qt.Key_Left); compare(tabs.currentIndex, 0)
            one.hasContent = three.hasContent = false
            tryCompare(tabs, "currentIndex", -1)
            three.hasContent = true
            tryCompare(tabs, "currentIndex", 2)
            tabs.visible = false
            compare(tabs.currentIndex, 2)
            tabs.visible = true
        }
        function test_camera_categories() {
            var panels = [single, dual]
            for (var i=0;i<panels.length;i++) {
                var panel = panels[i]
                params.ids = ["IP_CAM_ADDRESS", "CUSTOM_ENCODER"]; params.update_count++
                panel.activeCategory = "ADVANCED"
                settings_form.showAdvancedSettings = false
                compare(panel.activeCategory, "CONNECTION")
                compare(panel.categoryAvailable(panel.categoryIndex("ADVANCED")), false)
                compare(panel.categoryAvailable(panel.categoryIndex("IMAGE")), false)
                settings_form.showAdvancedSettings = true
                compare(panel.categoryAvailable(panel.categoryIndex("ADVANCED")), true)
                params.ids = ["KEYFRAME_I"]; params.update_count++
                settings_form.showAdvancedSettings = false
                compare(panel.categoryCount("VIDEO"),0)
                compare(panel.activeCategory, "")
                settings_form.showAdvancedSettings = true
                compare(panel.categoryCount("VIDEO"),1)
                params.ids = []; params.update_count++
                compare(panel.activeCategory, "")
                _qopenhd.debugMenuPreview = true
                compare(panel.categoryAvailable(panel.categoryIndex("IMAGE")), false)
                params.ids = ["BRIGHTNESS"]; params.update_count++
                compare(panel.activeCategory, "IMAGE")
                params.ids = ["BRIGHTNESS", "CONTRAST", "AWB_MODE", "AWB_MODE_LC", "WHITE_BALANCE"]; params.update_count++
                compare(panel.categoryCount("IMAGE"),5)
                compare(panel.categoryIndex("COLOR"),-1)
                params.ids = ["AWB_MODE"]; params.update_count++
                compare(panel.activeCategory,"IMAGE")
                compare(panel.categoryAvailable(panel.categoryIndex("IMAGE")),true)
                params.ids = ["CAMERA_TYPE","GX_AWB","GX_EXPOSURE","GX_SATURATION"]; params.cameraType=64; params.update_count++
                compare(panel.categoryCount("IMAGE"),3)
                params.cameraType=10;params.update_count++
                compare(panel.categoryCount("IMAGE"),0)
                settings_form.showAdvancedSettings=true
                compare(panel.categoryCount("IMAGE"),0)
                params.cameraType=64;params.update_count++
                compare(panel.categoryCount("IMAGE"),3)
                _qopenhd.debugMenuPreview = false
            }
        }
        function test_log_tabs_follow_rows() {
            var sources = findChild(logPage, "sourceTabs")
            _logGround.clear(); _logOpenhdAir.clear(); _logFC.clear()
            tryCompare(sources, "currentIndex", -1)
            logPage.focusLog()
            _logFC.append({tag:"FC",message:"test",severity_color:"white"})
            tryCompare(sources, "currentIndex", 2)
            compare(sources.itemAt(0).visible, false)
            compare(sources.itemAt(2).visible, true)
            _logOpenhdAir.append({tag:"Air",message:"test",severity_color:"white"})
            _logFC.clear()
            tryCompare(sources, "currentIndex", 1)
            _logOpenhdAir.clear()
            tryCompare(sources, "currentIndex", -1)
        }
        function test_unsupported_feature_tab() {
            compare(extras.dataLinkAvailable, false)
            params.ids = ["WB_UDP_ENABLE"]; params.update_count++
            compare(extras.dataLinkAvailable, true)
            params.ids = ["AUDIO_ENABLE"]; params.update_count++
            compare(extras.dataLinkAvailable, false)
        }
        function test_ground_ethernet_tabs_and_joystick_ownership(){
            params.ids=["ETHERNET","ETH_PASSIVE_F","SYS_DISP_MODE","ENABLE_JOY_RC"];params.update_count++
            settings_form.showAdvancedSettings=false;settings_form.showDeveloperSettings=false
            compare(groundModes.ethernetAvailable,false)
            verify(groundModes.hiddenDedicatedSetting("ETHERNET"))
            verify(groundModes.hiddenDedicatedSetting("ENABLE_JOY_RC"))
            settings_form.showAdvancedSettings=true;compare(groundModes.ethernetAvailable,true)
            verify(groundModes.hiddenDedicatedSetting("ETHERNET"))
            compare(groundModes.hiddenDedicatedSetting("SYS_DISP_MODE"),false)
            groundModes.currentTab=1
            compare(groundModes.hiddenDedicatedSetting("ETHERNET"),false)
            verify(groundModes.hiddenDedicatedSetting("SYS_DISP_MODE"))
            settings_form.showAdvancedSettings=false;compare(groundModes.currentTab,0)
            verify(groundModes.hiddenDedicatedSetting("ETHERNET"))
        }
        function test_parent_parameter_tabs() {
            compare(parentTabs.tabIsAvailable(1), false)
            compare(parentTabs.tabIsAvailable(3), false)
            compare(parentTabs.tabIsAvailable(4), false)
            params.ids = ["FC_UART_CONN"]; params.update_count++
            compare(parentTabs.tabIsAvailable(3), true)
            params.ids = ["FC_BATT_N_CELLS"]; params.update_count++
            compare(parentTabs.tabIsAvailable(3), true)
            parentTabs.currentPage = 3
            params.ids = []; params.update_count++
            compare(parentTabs.currentPage, 0)
            params.ids = ["CAMERA_TYPE"]; params.update_count++
            compare(parentTabs.tabIsAvailable(1), true)
            params.ids = ["SENSOR_MODE"]; params.update_count++
            settings_form.showAdvancedSettings = false
            compare(parentTabs.tabIsAvailable(1), false)
            params.ids = ["WB_RTX_TEST"]; params.update_count++
            compare(parentTabs.tabIsAvailable(3), false)
        }
    }
}
'''
    (folder / "tst_empty.qml").write_text(fixture, encoding="utf-8")
    env = dict(os.environ, QT_QPA_PLATFORM="offscreen", QT_QUICK_BACKEND="software", QT_FORCE_STDERR_LOGGING="1")
    raise SystemExit(subprocess.run([str(args.qt_bin / "qmltestrunner.exe"), "-input", str(folder)], env=env, timeout=60).returncode)
