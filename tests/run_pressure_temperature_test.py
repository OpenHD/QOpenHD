"""Exercise the production pressure-temperature widget with Qt 5 offscreen.

python tests/run_pressure_temperature_test.py --qt-bin C:/Qt/5.15.19/mingw81_64/bin
Only the HUD base/layout and incoming telemetry are stubbed; the full widget,
source selector, warning bindings and persisted source declaration are production.
"""
import argparse
import os
from pathlib import Path
import re
import subprocess
import tempfile

ROOT = Path(__file__).resolve().parents[1]


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--qt-bin", required=True, type=Path)
    parser.add_argument("--screenshot", type=Path)
    args = parser.parse_args()
    source = (ROOT / "qml/ui/widgets/PressTempWidget.qml").read_text(encoding="utf-8")
    declaration = re.search(r"    property int press_temp_source: .*", (
        ROOT / "qml/ui/elements/AppSettings.qml").read_text(encoding="utf-8")).group(0)
    env = os.environ.copy()
    env["PATH"] = str(args.qt_bin) + os.pathsep + env["PATH"]
    env.update(QT_QPA_PLATFORM="offscreen", QT_QUICK_BACKEND="software",
               QT_FORCE_STDERR_LOGGING="1", QT_QPA_FONTDIR=str(Path(os.environ.get("WINDIR", "C:/Windows")) / "Fonts"),
               QML2_IMPORT_PATH=str(args.qt_bin.parent / "qml"),
               QT_QPA_PLATFORM_PLUGIN_PATH=str(args.qt_bin.parent / "plugins/platforms"))
    with tempfile.TemporaryDirectory(prefix="qopenhd-pressure-temperature-") as temp:
        folder = Path(temp)
        (folder / "PressTempWidget.qml").write_text(
            source.replace("import OpenHD 1.0", ""), encoding="utf-8")
        (folder / "BaseWidget.qml").write_text("""import QtQuick 2.12
Item {
    property string widgetIdentifier; property string bw_verbose_name
    property int defaultAlignment; property int defaultXOffset; property int defaultYOffset
    property bool defaultHCenter; property bool defaultVCenter; property bool hasWidgetDetail
    property Component widgetDetailComponent
    property real bw_current_scale: 1; property real bw_current_opacity: 1
    property int detailPanelFontPixels: 14
}""")
        (folder / "BaseWidgetDefaultUiControlElements.qml").write_text(
            "import QtQuick 2.12\nColumn { width: 270; spacing: 0 }")
        screenshot = args.screenshot.resolve().as_posix() if args.screenshot else ""
        fixture = """import QtQuick 2.12
import QtQuick.Controls 2.12
import QtTest 1.2
import Qt.labs.settings 1.0
Rectangle {
    id: root; width: 340; height: 330; color: "#20252b"
    FontLoader { source: "file:///C:/Windows/Fonts/arial.ttf" }
    Settings {
        id: settings; fileName: "SETTINGS_FILE"; category: "PressureTemperature"
        SOURCE_DECLARATION
        property bool show_press_temp: true; property bool show_widgets: true
        property bool press_temp_declutter: false
        property real press_temp_warn: 75; property real press_temp_caution: 60
        property color color_warn: "red"; property color color_caution: "yellow"
        property color color_shape: "white"; property color color_text: "white"
        property color color_glow: "black"; property string font_text: "Arial"
    }
    QtObject {
        id: _fcMavlinkSystem
        property int preasure_sensor_temperature_degree: 35
        property int preasure_sensor2_temperature_degree: 65
        property int preasure_sensor3_temperature_degree: 85
        property bool armed: false
    }
    PressTempWidget { id: widget; x: 30; y: 20; width: 80 }
    Loader { id: panel; x: 30; y: 70; width: 280; height: 250
        sourceComponent: widget.widgetDetailComponent }
    Component { id: persistedSettings
        Settings { fileName: "SETTINGS_FILE"; category: "PressureTemperature"
            SOURCE_DECLARATION
        }
    }
    TestCase {
        name: "PressureTemperatureSource"; when: windowShown
        function init() {
            settings.press_temp_source = 0; settings.press_temp_declutter = false
            _fcMavlinkSystem.armed = false
            _fcMavlinkSystem.preasure_sensor_temperature_degree = 35
            _fcMavlinkSystem.preasure_sensor2_temperature_degree = 65
            _fcMavlinkSystem.preasure_sensor3_temperature_degree = 85
        }
        function value() { return findChild(widget, "pressureTemperatureValue") }
        function test_source_and_warnings_data() {
            return [{tag:"primary",source:0,temp:35,color:"#ffffff"},
                    {tag:"secondary",source:1,temp:65,color:"#ffff00"},
                    {tag:"tertiary",source:2,temp:85,color:"#ff0000"}]
        }
        function test_source_and_warnings(data) {
            settings.press_temp_source=data.source
            compare(widget.selectedTemperature,data.temp)
            compare(value().text,data.temp + String.fromCharCode(176))
            compare(value().color.toString(),data.color)
            var glyph=findChild(widget,"pressureTemperatureGlyph")
            compare(glyph.color.toString(),data.color)
            settings.press_temp_declutter=true; _fcMavlinkSystem.armed=true
            compare(value().parent.visible,data.source !== 0)
        }
        function test_selected_stream_updates_and_missing() {
            settings.press_temp_source=1
            _fcMavlinkSystem.preasure_sensor_temperature_degree=99
            compare(widget.selectedTemperature,65)
            _fcMavlinkSystem.preasure_sensor2_temperature_degree=-12
            compare(value().text,"-12" + String.fromCharCode(176))
            _fcMavlinkSystem.preasure_sensor2_temperature_degree=0
            compare(value().text,"N/A")
            compare(value().color.toString(),"#ffffff")
        }
        function test_selector_and_persistence() {
            var selector=findChild(panel.item,"pressureTemperatureSource")
            verify(selector !== null); compare(selector.count,3)
            compare(selector.currentIndex,0)
            selector.forceActiveFocus(); keyClick(Qt.Key_Down)
            compare(selector.currentIndex,1); compare(settings.press_temp_source,1)
            compare(value().text,"65" + String.fromCharCode(176))
            keyClick(Qt.Key_Down)
            compare(settings.press_temp_source,2); compare(value().text,"85" + String.fromCharCode(176))
            wait(600) // Qt.labs.settings batches property writes.
            settings.sync()
            var restored=persistedSettings.createObject(root)
            compare(restored.press_temp_source,2); restored.destroy()
        }
        function test_invalid_setting_falls_back() {
            settings.press_temp_source=99
            compare(widget.selectedTemperature,35)
            compare(findChild(panel.item,"pressureTemperatureSource").currentIndex,0)
        }
        function test_screenshot() {
            if ("SCREENSHOT_FILE" === "") return
            settings.press_temp_source=1
            wait(100)
            var done=false
            root.grabToImage(function(result) {
                verify(result.saveToFile("SCREENSHOT_FILE")); done=true
            })
            tryVerify(function() { return done })
        }
    }
}
"""
        fixture = fixture.replace("SETTINGS_FILE", (folder / "settings.ini").as_posix())
        fixture = fixture.replace("SOURCE_DECLARATION", declaration)
        fixture = fixture.replace("SCREENSHOT_FILE", screenshot)
        (folder / "tst_pressure_temperature.qml").write_text(fixture, encoding="utf-8")
        result = subprocess.run([str(args.qt_bin / "qmltestrunner.exe"), "-input", str(folder)],
                                env=env, capture_output=True, text=True, timeout=60)
        print(result.stdout + result.stderr)
        return result.returncode


if __name__ == "__main__":
    raise SystemExit(main())
