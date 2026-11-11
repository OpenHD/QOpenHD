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
    for name in ("SideBarMain", "SideBarBasePanel", "SidebarStackButton", "ChoiceSelector"):
        source = (ROOT / "qml/ui/sidebar" / (name + ".qml")).read_text(encoding="utf-8")
        source = source.replace("import OpenHD 1.0", "").replace('import "../elements"', "")
        (folder / (name + ".qml")).write_text(source, encoding="utf-8")
    # Geometry uses the production shell; telemetry-heavy panel bodies are omitted.
    for name in ("Panel8FindAirUnit", "Panel1Link", "Panel2Video", "Panel3Camera",
                 "Panel4Recording", "Panel5RC", "Panel6Misc", "Panel7Status"):
        (folder / (name + ".qml")).write_text(
            'import QtQuick 2.12\nSideBarBasePanel { function takeover_control() {} }', encoding="utf-8")
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
    width: 800; height: 480
    QtObject {
        id: settings
        property bool show_sidebar: true
        function value(key, fallback) { return fallback }
        function setValue(key, value) {}
        function sync() {}
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
            verify((320 + 390/9 + 200) * sidebar.sidebarScale <= data.w)
            verify(sidebar.secondaryUiHeight * sidebar.sidebarScale <= data.h - 15)
            sidebar.close()
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
            verify(pos.y < 390/8)
            verify(pos.x > 320/2)
            compare(button.width,390/8)
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
