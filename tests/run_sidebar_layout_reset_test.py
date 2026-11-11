"""Run production sidebar geometry and image-reset sequencing in Qt Quick."""
import argparse
import os
from pathlib import Path
import shutil
import subprocess
import tempfile

ROOT = Path(__file__).resolve().parents[1]
parser = argparse.ArgumentParser()
parser.add_argument("--qt-bin", type=Path, required=True)
args = parser.parse_args()
with tempfile.TemporaryDirectory(prefix="qopenhd-sidebar-") as temp:
    folder = Path(temp)
    for name in ("SideBarMain", "SideBarBasePanel", "SidebarStackButton", "ChoiceSelector",
                 "Panel8FindAirUnit", "BaseJoyEditElement2"):
        source = (ROOT / "qml/ui/sidebar" / (name + ".qml")).read_text(encoding="utf-8")
        source = (source.replace("import OpenHD 1.0", "")
                  .replace('import "../elements"', "").replace('import "../widgets"', "")
                  .replace('import "../configpopup"', ""))
        (folder / (name + ".qml")).write_text(source, encoding="utf-8")
    for path in ("elements/Card.qml", "elements/ColorPicker.qml", "elements/DarkComboBox.qml",
                 "elements/FontSelect.qml", "elements/OSDCustomizer.qml", "elements/SidebarSizeControls.qml",
                 "widgets/BaseWidgetDefaultUiControlElements.qml", "configpopup/AdvancedActionButton.qml",
                 "configpopup/MenuTypography.js"):
        source = ((ROOT / "qml/ui" / path).read_text(encoding="utf-8").replace('import "../elements"', "")
                  .replace('import "../configpopup"', "").replace('../configpopup/MenuTypography.js', 'MenuTypography.js'))
        (folder / Path(path).name).write_text(source, encoding="utf-8")
    shutil.copytree(ROOT / "qml/ui/elements/colorwheel", folder / "colorwheel")
    # Geometry uses the production shell; telemetry-heavy panel bodies are omitted.
    for name in ("Panel2Video", "Panel4Recording", "Panel6Misc"):
        (folder / (name + ".qml")).write_text(
            'import QtQuick 2.12\nSideBarBasePanel { function takeover_control() {} }', encoding="utf-8")
    (folder / "Panel1Link.qml").write_text('''import QtQuick 2.12
import QtQuick.Controls 2.12
SideBarBasePanel {
    objectName: "fixtureLinkPanel"
    function takeover_control() {}
    Item {
        width: parent.width
        height: Math.max(40, hudOverlayGrid.fixtureContentHeight)
        Slider { objectName: "fixtureSidebarSlider"; width: 240; height: 40; value: 0.5 }
    }
}''', encoding="utf-8")
    (folder / "SystemHealth.js").write_bytes(
        (ROOT / "qml/ui/configpopup/status/SystemHealth.js").read_bytes())
    (folder / "Panel7Status.qml").write_text(
        (ROOT / "qml/ui/sidebar/Panel7Status.qml").read_text(encoding="utf-8")
        .replace("../configpopup/status/SystemHealth.js", "SystemHealth.js"), encoding="utf-8")
    (folder / "CameraImageReset.qml").write_text(
        (ROOT / "qml/ui/elements/CameraImageReset.qml").read_text(encoding="utf-8"), encoding="utf-8")
    camera_source = (ROOT / "qml/ui/sidebar/Panel3Camera.qml").read_text(encoding="utf-8")
    (folder / "Panel3Camera.qml").write_text(
        camera_source.replace("import OpenHD 1.0", "").replace('import "../elements"', ""), encoding="utf-8")
    (folder / "MavlinkChoiceElement2.qml").write_text('''import QtQuick 2.12
Item {
    property string m_title
    property string m_param_id
    property var m_settings_model
    signal goto_previous()
    signal goto_next()
    function takeover_control() { forceActiveFocus() }
    width: 320; height: 40
}''', encoding="utf-8")
    fixture_source = r'''import QtQuick 2.12
import QtQuick.Controls 2.12
import Qt.labs.settings 1.0
import QtTest 1.2
Item {
    id: hudOverlayGrid
    property int fixtureContentHeight: 0
    property bool openedSystemStatus: false
    function open_config_popup(showSystemStatus) { openedSystemStatus = showSystemStatus }
    QtObject {
        id: _ohdSystemAir
        property bool is_alive: true
        property int curr_soc_temp_degree: 73
        property int curr_cpuload_perc: 31
    }
    QtObject {
        id: _ohdSystemGround
        property bool is_alive: true
        property int wb_gnd_operating_mode: 0
        property int curr_soc_temp_degree: 46
        property int curr_cpuload_perc: 21
        property int current_rx_rssi: -58
        property int curr_rx_packet_loss_perc: 2
    }
    QtObject { id: _fcMavlinkSystem; property bool is_alive: true }
    width: 800; height: 480
    Settings {
        id: settings
        fileName: "SETTINGS_PATH"
        property bool show_sidebar: true
        property real sidebar_popup_scale: 1.2
        property real sidebar_show_icon_scale: 1.0
        property bool scan_passive_nexmon: false
        property int scan_channel_width_mhz: 20
        property color color_shape: "white"
        property color color_glow: "black"
        property color color_text: "white"
        property string font_text: "Sans Serif"
    }
    QtObject {
        id: _wbLinkSettingsHelper
        property bool ground_supports_10mhz: true
        property int scan_progress_perc: 0
        property string scanning_text_for_ui: ""
        property var lastRequest: []
        property bool acceptRequest: true
        function start_scan_channels(band, widthMhz, passive) {
            lastRequest = [band, widthMhz, passive]
            return acceptRequest
        }
    }
    QtObject { id: _qopenhd; property string toast: ""; function show_toast(value) { toast = value } }
    property var _airCameraSettingsModel: backend
    property var _airCameraSettingsModel2: backend
    property var _ohdSystemAirSettingsModel: backend
    property var _ohdSystemGroundSettings: backend
    QtObject { id: _cameraStreamModelPrimary; property int camera_type: 64 }
    QtObject {
        id: backend
        property int update_count: 0
        property bool has_params_fetched: true
        property bool ui_is_busy: false
        property var values: ({ISP_AE_MODE:1, ISP_WB_AUTO:0, ISP_GAIN:400, BRIGHTNESS:150, RESOLUTION_FPS:720})
        property var writes: []
        property bool reject: false
        signal backupParameterFinished(string id, bool success)
        function system_is_alive() { return true }
        function param_int_exists(id) { return values[id] !== undefined }
        function get_cached_int(id) { return values[id] }
        function ensure_parameters_available() {}
        function try_set_param_int_async(id, value, log) {
            if (ui_is_busy) fail("Overlapping parameter writes")
            ui_is_busy = true
            writes.push([id, value])
            ack.idToAck = id; ack.newValue = value; ack.start()
        }
    }
    Timer {
        id: ack; interval: 5
        property string idToAck
        property int newValue
        onTriggered: {
            backend.ui_is_busy = false
            if (!backend.reject) backend.values[idToAck] = newValue
            backend.backupParameterFinished(idToAck, !backend.reject)
        }
    }
    SideBarMain { id: sidebar }
    ColorPicker { id: colorPicker }
    OSDCustomizer { id: quickStyle; anchors.centerIn: parent; visible: false }
    CameraImageReset { id: reset; settingsModel: backend; x: 500 }
    TestCase {
        name: "SidebarLayoutAndReset"
        when: windowShown
        function test_geometry_data() {
            return [{tag:"desktop",w:1280,h:720}, {tag:"short",w:800,h:280},
                    {tag:"phone",w:915,h:360}, {tag:"portrait",w:360,h:800},
                    {tag:"scaled-small",w:400,h:240}]
        }
        function test_geometry(data) {
            hudOverlayGrid.width=data.w; hudOverlayGrid.height=data.h
            sidebar.open_category(3)
            wait(20)
            var panels = findChild(sidebar, "sidebarPanels")
            verify(panels !== null)
            var top = panels.mapToItem(hudOverlayGrid, 0, 0)
            var bottom = panels.mapToItem(hudOverlayGrid, panels.width, panels.height)
            verify(top.y >= 7)
            verify(bottom.y <= data.h - 7)
            verify(bottom.x <= data.w)
            if (data.h < 390) verify(sidebar.sidebarScale < 1)
            // The complete panel + choice column must fit in logical viewport space.
            verify((556 + 68 + 200) * sidebar.sidebarScale <= data.w)
            verify(sidebar.secondaryUiHeight * sidebar.sidebarScale <= data.h - 15)
            sidebar.close()
        }
        function test_customization() {
            hudOverlayGrid.width = 800; hudOverlayGrid.height = 480
            sidebar.open_category(0)
            var popup = findChild(sidebar, "sidebarCustomizePopup")
            var start = findChild(sidebar, "scanStart")
            mousePress(start)
            wait(900)
            verify(!popup.visible)
            mouseRelease(start)

            var header = findChild(sidebar, "sidebarEmptyHeader")
            mouseClick(header, 12, 20)
            verify(!popup.visible)
            mousePress(header, 12, 20)
            tryCompare(popup, "opened", true)
            mouseRelease(header, 12, 20)
            compare(sidebar.bw_current_scale, 1.2)
            fuzzyCompare(sidebar.sidebarScale, sidebar.automaticScale * 1.2, 0.0001)
            compare(sidebar.secondaryUiOpacity, 0.94)
            compare(sidebar.secondaryUiColor, "#121e2a")
            var passiveCard = findChild(sidebar, "scanPassiveCard")
            compare(passiveCard.color, "#203448")
            compare(start.background.color, "#285879")

            var sizeSlider = findChild(popup.contentItem, "sidebar_popup_scale")
            var opacitySlider = findChild(popup.contentItem, "widgetTransparencySlider")
            mouseClick(sizeSlider, sizeSlider.width * 0.75, sizeSlider.height / 2)
            mouseClick(opacitySlider, opacitySlider.width / 2, opacitySlider.height / 2)
            verify(sidebar.bw_current_scale > 1)
            verify(sidebar.secondaryUiOpacity < 0.94)
            compare(settings.sidebar_popup_scale, sidebar.bw_current_scale)
            compare(settings.value("sidebar_popup_opacity"), sidebar.secondaryUiOpacity)

            var swatch = findChild(popup.contentItem, "widgetBackgroundColorSwatch")
            var picker = findChild(popup.contentItem, "sidebarColorPicker")
            mouseClick(swatch)
            verify(picker.visible)
            compare(picker.color, "#ff121e2a")
            var wheel = findChild(picker, "colorWheelSurface")
            tryVerify(function() {
                var context = wheel.getContext("2d")
                return context && context.getImageData(18, 75, 1, 1).data[0] > 230
            })
            mouseClick(wheel, 18, 75)
            verify(!Qt.colorEqual(sidebar.secondaryUiColor, "#121e2a"))
            keyClick(Qt.Key_Escape)
            tryCompare(popup, "visible", false)
            compare(sidebar.secondaryUiColor, "#121e2a")

            sidebar.openCustomization()
            tryCompare(popup, "opened", true)
            mouseClick(findChild(popup.contentItem, "sidebarTextColorSwatch"))
            compare(picker.color, "#ffedf6ff")
            picker.color = "#ffffcc66"
            mouseClick(findChild(picker, "colorPickerSelect"))
            compare(start.contentItem.color, "#ffcc66")
            mouseClick(findChild(popup.contentItem, "sidebarHighlightColorSwatch"))
            compare(picker.color, "#ff71d4ff")
            picker.color = "#ff74cc8a"
            mouseClick(findChild(picker, "colorPickerSelect"))
            mouseClick(findChild(popup.contentItem, "sidebarControlColorSwatch"))
            compare(picker.color, "#ff285879")
            picker.color = "#ff8f4532"
            mouseClick(findChild(picker, "colorPickerSelect"))
            mouseMove(hudOverlayGrid, hudOverlayGrid.width - 5, 5)
            compare(passiveCard.color, Qt.lighter("#8f4532", 0.72))
            compare(start.background.color, "#8f4532")
            popup.close()
            tryCompare(popup, "visible", false)
            start.forceActiveFocus()
            compare(start.background.border.color, "#74cc8a")
            compare(settings.value("sidebar_popup_text_color"), "#ffcc66")
            compare(settings.value("sidebar_popup_highlight_color"), "#74cc8a")
            compare(settings.value("sidebar_popup_control_color"), "#8f4532")
            mouseClick(findChild(sidebar, "scanBand"))
            tryVerify(function() { return findChild(sidebar, "sidebarChoiceText") !== null })
            compare(findChild(sidebar, "sidebarChoiceText").color, "#ffcc66")
            compare(findChild(sidebar, "sidebarChoiceHighlight").border.color, "#74cc8a")
            keyClick(Qt.Key_Left)

            sidebar.open_category(1)
            var page = findChild(sidebar, "fixtureLinkPanel")
            var panelSlider = findChild(page, "fixtureSidebarSlider")
            mousePress(panelSlider, panelSlider.width / 2, panelSlider.height / 2)
            wait(900)
            verify(!popup.visible)
            mouseMove(panelSlider, panelSlider.width * 0.8, panelSlider.height / 2)
            mouseRelease(panelSlider, panelSlider.width * 0.8, panelSlider.height / 2)
            verify(panelSlider.value > 0.5)
            var blank = findChild(page, "sidebarEmptyBody")
            var touch = touchEvent(blank)
            touch.press(0, blank, blank.width / 2, blank.height / 2).commit()
            tryCompare(popup, "opened", true)
            touch.release(0, blank, blank.width / 2, blank.height / 2).commit()
            mouseClick(findChild(popup.contentItem, "sidebarCustomizeReset"))
            compare(sidebar.bw_current_scale, 1.2)
            compare(sidebar.secondaryUiOpacity, 0.94)
            compare(sidebar.secondaryUiColor, "#121e2a")
            compare(sidebar.popupTextColor, "#edf6ff")
            compare(sidebar.popupHighlightColor, "#71d4ff")
            compare(sidebar.popupControlColor, "#285879")
            popup.close()
            tryCompare(popup, "visible", false)
            sidebar.close()
        }
        function test_customized_geometry() {
            sidebar.open_category(1)
            sidebar.bw_set_current_scale(3)
            for (var size of test_geometry_data()) {
                hudOverlayGrid.width = size.w; hudOverlayGrid.height = size.h
                var panels = findChild(sidebar, "sidebarPanels")
                var bottom = panels.mapToItem(hudOverlayGrid, panels.width, panels.height)
                verify(sidebar.sidebarScale > sidebar.automaticScale)
                verify(bottom.x + 200 * sidebar.sidebarScale <= size.w - 11)
                verify(bottom.y <= size.h - 13)
                compare(sidebar.scale, sidebar.sidebarScale)
            }
            var blank = findChild(findChild(sidebar, "fixtureLinkPanel"), "sidebarEmptyBody")
            verify(blank.height > 0)
            hudOverlayGrid.fixtureContentHeight = 640
            tryCompare(blank, "height", 0)
            var scroll = findChild(findChild(sidebar, "fixtureLinkPanel"), "sidebarBodyScroll")
            tryCompare(scroll, "contentHeight", 640)
            verify(scroll.contentHeight > scroll.height)
            hudOverlayGrid.fixtureContentHeight = 0
            sidebar.bw_set_current_scale(0.5)
            compare(sidebar.sidebarScale, 0.5 * sidebar.automaticScale)
            sidebar.close()
            compare(sidebar.scale, 2 * sidebar.automaticScale)
            sidebar.bw_set_current_scale(1.2)
        }
        function test_appearance_on_startup() {
            compare(sidebar.bw_current_scale, EXPECT_RESTORED ? 1.7 : 1.2)
            compare(sidebar.secondaryUiOpacity, EXPECT_RESTORED ? 0.6 : 0.94)
            compare(sidebar.secondaryUiColor, EXPECT_RESTORED ? "#285080" : "#121e2a")
            compare(sidebar.popupTextColor, EXPECT_RESTORED ? "#ffcc66" : "#edf6ff")
            compare(sidebar.popupHighlightColor, EXPECT_RESTORED ? "#74cc8a" : "#71d4ff")
            compare(sidebar.popupControlColor, EXPECT_RESTORED ? "#8f4532" : "#285879")
            compare(sidebar.m_sidebar_icon_scale, EXPECT_RESTORED ? 1.5 : 1)
        }
        function test_sidebar_sizes_and_launcher() {
            hudOverlayGrid.width = 800; hudOverlayGrid.height = 480
            var launcher = findChild(sidebar, "sidebarLauncher")
            compare(launcher.background, null)
            sidebar.open_category(0)
            sidebar.openCustomization()
            var popup = findChild(sidebar, "sidebarCustomizePopup")
            tryCompare(popup, "opened", true)
            var buttonSize = findChild(popup.contentItem, "sidebar_show_icon_scale")
            var popupSize = findChild(popup.contentItem, "sidebar_popup_scale")
            buttonSize.value = 1.6
            buttonSize.moved()
            compare(launcher.width, Math.round(32 * 1.6))
            popupSize.value = 1.8
            popupSize.moved()
            fuzzyCompare(sidebar.sidebarScale, sidebar.automaticScale * 1.8, 0.0001)
            popup.close()
            tryCompare(popup, "visible", false)
            sidebar.close()
            var iconPopup = findChild(sidebar, "sidebarIconResizePopup")
            mousePress(launcher)
            tryCompare(iconPopup, "opened", true)
            mouseRelease(launcher)
            verify(!sidebar.m_extra_is_visible)
            iconPopup.close()
            tryCompare(iconPopup, "visible", false)
            mouseClick(launcher)
            verify(sidebar.m_extra_is_visible)
            sidebar.close()
            settings.sidebar_popup_scale = 1.2
            settings.sidebar_show_icon_scale = 1
        }
        function test_quick_style_has_no_sidebar_sizes() {
            hudOverlayGrid.width = 400; hudOverlayGrid.height = 280
            quickStyle.visible = true
            verify(quickStyle.height <= hudOverlayGrid.height - 24)
            compare(findChild(quickStyle, "sidebar_popup_scale"), null)
            compare(findChild(quickStyle, "sidebar_show_icon_scale"), null)
            quickStyle.visible = false
        }
        function test_zz_save_customization() {
            sidebar.bw_set_current_scale(1.7)
            sidebar.bw_set_current_opacity(0.6)
            sidebar.bw_current_background_color = "#285080"
            sidebar.popupTextColor = "#ffcc66"
            sidebar.popupHighlightColor = "#74cc8a"
            sidebar.popupControlColor = "#8f4532"
            settings.sidebar_show_icon_scale = 1.5
        }
        function test_scan_sends_displayed_bandwidth() {
            sidebar.open_and_take_control(true)
            _qopenhd.toast = ""
            keyClick(Qt.Key_Right)
            keyClick(Qt.Key_Down)
            keyClick(Qt.Key_Right)
            keyClick(Qt.Key_Up)
            keyClick(Qt.Key_Return)
            var bandwidth = findChild(sidebar, "scanBandwidth")
            compare(bandwidth.m_displayed_value, "10 MHz")

            var start = findChild(sidebar, "scanStart")
            mouseClick(start)
            compare(_wbLinkSettingsHelper.lastRequest, [0, 10, false])

            // The settings menu can update the shared width while the HUD is alive.
            settings.scan_channel_width_mhz = 40
            compare(bandwidth.m_displayed_value, "40 MHz")
            mouseClick(start)
            compare(_wbLinkSettingsHelper.lastRequest, [0, 40, false])

            settings.scan_channel_width_mhz = 10
            settings.scan_passive_nexmon = true
            compare(bandwidth.m_displayed_value, "20 MHz")
            mouseClick(start)
            compare(_wbLinkSettingsHelper.lastRequest, [0, 20, true])
            settings.scan_passive_nexmon = false
            compare(bandwidth.m_displayed_value, "10 MHz")
            compare(_qopenhd.toast, "")

            _wbLinkSettingsHelper.acceptRequest = false
            mouseClick(start)
            var feedback = findChild(sidebar, "sidebarScanFeedback")
            verify(feedback.text.indexOf("Scan could not start") === 0)
            compare(_qopenhd.toast, "")
            _wbLinkSettingsHelper.acceptRequest = true
            mouseClick(start)
            verify(feedback.text.indexOf("Scan could not start") === -1)

            _ohdSystemGround.wb_gnd_operating_mode = 1
            verify(!start.enabled)
            _ohdSystemGround.wb_gnd_operating_mode = 0
            sidebar.close()
        }
        function test_sidebar_status_navigation() {
            hudOverlayGrid.width = 800; hudOverlayGrid.height = 480
            sidebar.open_and_take_control(true)
            verify(findChild(sidebar, "sidebarCategory_rc") === null)
            for (var i = 0; i < 6; ++i) keyClick(Qt.Key_Down)
            var statusTab = findChild(sidebar, "sidebarCategory_status")
            verify(statusTab.activeFocus)
            keyClick(Qt.Key_Down)
            verify(findChild(sidebar, "sidebarCategory_scan").activeFocus)
            for (var j = 0; j < 6; ++j) keyClick(Qt.Key_Down)
            keyClick(Qt.Key_Up)
            verify(findChild(sidebar, "sidebarCategory_misc").activeFocus)
            keyClick(Qt.Key_Down)
            keyClick(Qt.Key_Right)
            var details = findChild(sidebar, "sidebarStatusDetails")
            verify(details.activeFocus)
            function showsText(item, expected) {
                if (!item.visible) return false
                if (item.text === expected) return true
                for (var k = 0; k < item.children.length; ++k) {
                    if (showsText(item.children[k], expected)) return true
                }
                return false
            }
            verify(showsText(sidebar, "Warning"))
            verify(showsText(sidebar, "-58 dBm"))
            _ohdSystemGround.is_alive = false
            verify(showsText(sidebar, "Offline"))
            verify(!showsText(sidebar, "-58 dBm"))
            _ohdSystemGround.is_alive = true
            _ohdSystemGround.current_rx_rssi = -62
            verify(showsText(sidebar, "-62 dBm"))
            keyClick(Qt.Key_Left)
            verify(statusTab.activeFocus)
            keyClick(Qt.Key_Right)
            keyClick(Qt.Key_Return)
            verify(hudOverlayGrid.openedSystemStatus)
            verify(!sidebar.m_extra_is_visible)
        }
        function test_reset_ack_sequence() {
            backend.reject=false; backend.writes=[]
            reset.startReset()
            tryCompare(reset, "resetting", false)
            compare(backend.values.ISP_AE_MODE,0)
            compare(backend.values.ISP_WB_AUTO,1)
            compare(backend.values.ISP_GAIN,100)
            compare(backend.values.BRIGHTNESS,100)
            compare(backend.values.RESOLUTION_FPS,720)
            compare(backend.writes.length,4)
            verify(reset.resultText.indexOf("restored") >= 0)
        }
        function test_reset_failure_stops() {
            backend.values.ISP_GAIN=500; backend.values.BRIGHTNESS=180
            backend.reject=true; backend.writes=[]
            reset.startReset()
            tryCompare(reset, "resetting", false)
            compare(backend.writes.length,1)
            verify(reset.resultText.indexOf("incomplete") >= 0)
            compare(backend.values.BRIGHTNESS,180)
        }
        function test_gx_header_reset() {
            backend.reject=false; backend.writes=[]
            backend.values=({GX_EXPOSURE:0, GX_WB_MODE:0, GX_CONTRAST:80, RESOLUTION_FPS:720})
            backend.update_count++
            sidebar.open_category(3)
            wait(20)
            var panels=findChild(sidebar, "sidebarPanels")
            var button=null
            function findReset(item) {
                if (item.iconOnly === true) return item
                for (var i=0; i<item.children.length; ++i) {
                    var found=findReset(item.children[i])
                    if (found) return found
                }
                return null
            }
            button=findReset(panels)
            verify(button !== null)
            verify(button.visible)
            var pos=button.mapToItem(panels,0,0)
            verify(pos.y < 78)
            verify(pos.x > 320/2)
            compare(button.width,78)
            button.startReset()
            tryCompare(button,"resetting",false)
            compare(backend.values.GX_EXPOSURE,2)
            compare(backend.values.GX_WB_MODE,2)
            compare(backend.values.GX_CONTRAST,50)
            compare(backend.values.RESOLUTION_FPS,720)
            compare(backend.writes.length,3)
            sidebar.close()
            backend.values=({ISP_AE_MODE:1, ISP_WB_AUTO:0, ISP_GAIN:400, BRIGHTNESS:150, RESOLUTION_FPS:720})
            backend.update_count++
        }
    }
}
'''.replace("SETTINGS_PATH", (folder / "settings.ini").as_posix())
    env = dict(os.environ, QT_QUICK_BACKEND="software", QT_QUICK_CONTROLS_STYLE="Material",
               QT_SCALE_FACTOR="1", QT_FORCE_STDERR_LOGGING="1")
    env["PATH"] = str(args.qt_bin) + os.pathsep + env.get("PATH", "")
    command = [str(args.qt_bin / "qmltestrunner.exe"), "-input", str(folder)]
    fixture = folder / "tst_sidebar.qml"
    fixture.write_text(fixture_source.replace("EXPECT_RESTORED", "false"), encoding="utf-8")
    subprocess.run(command, env=env, timeout=60, check=True)
    fixture.write_text(fixture_source.replace("EXPECT_RESTORED", "true"), encoding="utf-8")
    subprocess.run(command + ["SidebarLayoutAndReset::test_appearance_on_startup"], env=env, timeout=60, check=True)
