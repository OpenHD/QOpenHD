"""Run production sidebar geometry and image-reset sequencing in Qt Quick."""
import argparse
import os
from pathlib import Path
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
        source = source.replace("import OpenHD 1.0", "").replace('import "../elements"', "")
        (folder / (name + ".qml")).write_text(source, encoding="utf-8")
    # Geometry uses the production shell; telemetry-heavy panel bodies are omitted.
    for name in ("Panel1Link", "Panel2Video", "Panel3Camera",
                 "Panel4Recording", "Panel6Misc"):
        (folder / (name + ".qml")).write_text(
            'import QtQuick 2.12\nSideBarBasePanel { function takeover_control() {} }', encoding="utf-8")
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
    (folder / "tst_sidebar.qml").write_text(r'''import QtQuick 2.12
import QtQuick.Controls 2.12
import QtTest 1.2
Item {
    id: hudOverlayGrid
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
    QtObject {
        id: settings
        property bool show_sidebar: true
        property bool scan_passive_nexmon: false
        property int scan_channel_width_mhz: 20
        function value(key, fallback) { return fallback }
        function setValue(key, value) {}
        function sync() {}
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
''', encoding="utf-8")
    env = dict(os.environ, QT_QUICK_BACKEND="software", QT_QUICK_CONTROLS_STYLE="Material",
               QT_SCALE_FACTOR="1", QT_FORCE_STDERR_LOGGING="1")
    env["PATH"] = str(args.qt_bin) + os.pathsep + env.get("PATH", "")
    raise SystemExit(subprocess.run([str(args.qt_bin / "qmltestrunner.exe"), "-input", str(folder)],
                                   env=env, timeout=60).returncode)
