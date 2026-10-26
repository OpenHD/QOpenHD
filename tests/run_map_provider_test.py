"""Exercise production map lifecycle with real Qt 5 Location plugins and a headless canvas.
Run: python tests/run_map_provider_test.py --qt-bin C:/Qt/5.15.19/mingw81_64/bin
No real access token or tile downloads are needed; rendering on a Pi is a separate check.
"""
import argparse
import os
from pathlib import Path
import subprocess
import tempfile

ROOT = Path(__file__).resolve().parents[1]

FORM = '''import QtQuick 2.12
import QtQuick.Controls 2.12
Item {
    property bool useDragHandle
    property bool hasWidgetDetail
    property alias widgetDetail: popup
    Popup { id: popup }
    property alias pluginModel: providers
    ListModel { id: providers
        ListElement { name: "osm" }
        ListElement { name: "mapboxgl" }
        ListElement { name: "openhd_offline" }
    }
    property alias widgetInnerMap: canvas
    Item { id: canvas; anchors.fill: parent }
    property alias mini_zoomSlider: zoom
    Slider { id: zoom }
    property alias mini_sizeSlider: size
    Slider { id: size }
    property alias openclose_button: button
    Button { id: button }
    property alias sidebar_wrapper: sidebar
    Item { id: sidebar }
    property alias variantDropdown: variants
    ComboBox { id: variants }
    property alias providerDropdown: provider
    ComboBox { id: provider }
    function resetAnchors() {}
    function setAlignment() {}
    function loadAlignment() {}
}
'''
CANVAS = '''import QtQuick 2.12
import QtPositioning 5.15
Item {
    property var plugin
    property bool forceCustomMapType
    property var center: QtPositioning.coordinate(10, 20)
    property var gesture: QtObject { property bool enabled }
    property var supportedMapTypes: ["street", "satellite"]
    property var activeMapType
}
'''
TEST = '''import QtQuick 2.12
import QtTest 1.2
Item {
    width: 800; height: 480
    QtObject {
        id: settings
        property bool show_map: false
        property int selected_map_provider: 0
        property int selected_map_variant: 99
        property string map_api_key: ""
        property real map_zoom: 8
        property real map_size: 1
    }
    QtObject {
        id: _offlineMapTiles
        property bool available: true
        property string baseUrl: "http://127.0.0.1:9/"
        property string mapboxBaseUrl: "http://127.0.0.1:9/"
        property string mapboxCacheDirectory: "CACHE_DIRECTORY"
        function setMapboxKey(key) {}
        function reload() {}
    }
    MapWidget { id: widget }
    TestCase {
        name: "MapProviderRecovery"; when: windowShown
        function test_late_settings_restore() {
            compare(widget.map, null)
            // Match Qt.labs.settings: show_map arrives before provider/key.
            settings.show_map = true
            settings.selected_map_provider = 1
            settings.map_api_key = "pk.test-restored"
            tryVerify(function() { return widget.map !== null })
            compare(widget.mapPlugin.name, "mapboxgl")
            compare(widget.mapPlugin.parameters[0].value, "pk.test-restored")
            settings.show_map = false
            tryCompare(widget, "map", null)
            settings.selected_map_provider = 0
            settings.map_api_key = ""
        }
        function test_recovery() {
            settings.show_map = true
            widget.configure()
            verify(widget.map !== null)
            compare(widget.map.activeMapType, "satellite")
            widget.map.supportedMapTypes = []
            widget.setup_map_variant()
            compare(widget.variantDropdown.currentIndex, -1)
            settings.selected_map_provider = 1
            widget.configure()
            verify(widget.apiKeyMissing)
            compare(widget.map, null)
            widget.configureSmallMap()
            settings.map_api_key = '  pk.test"\\\\token  '
            tryVerify(function() { return widget.map !== null })
            compare(widget.mapPlugin.parameters[0].name, "mapboxgl.access_token")
            compare(widget.mapPlugin.parameters[0].value, settings.map_api_key.trim())
            var previous = widget.map
            settings.selected_map_provider = 0
            widget.configure()
            verify(widget.map !== null && widget.map !== previous)
            compare(widget.apiKeyMissing, false)
            compare(widget.mapFailure, "")
            compare(widget.map.activeMapType, "satellite")
            settings.selected_map_provider = 2
            widget.configure()
            compare(widget.map.activeMapType, "satellite")
            settings.selected_map_provider = -1
            widget.configure()
            compare(settings.selected_map_provider, 0)
            verify(widget.map !== null)
            widget.createMap(widget.widgetInnerMap, "unavailable_test_provider")
            compare(widget.map, null)
            verify(widget.mapFailure.length > 0)
            widget.configure()
            verify(widget.map !== null)
            compare(widget.mapFailure, "")
        }
    }
}
'''


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--qt-bin", required=True, type=Path)
    args = parser.parse_args()
    with tempfile.TemporaryDirectory(prefix="qopenhd-map-") as temp:
        folder = Path(temp)
        # Only replace the visual form/canvas; execute the production lifecycle unchanged.
        source = (ROOT / "qml/ui/widgets/map/MapWidget.qml").read_text(encoding="utf-8")
        (folder / "MapWidget.qml").write_text(source.replace('import "../../elements";', ''), encoding="utf-8")
        (folder / "MapWidgetForm.qml").write_text(FORM, encoding="utf-8")
        (folder / "MapComponent.qml").write_text(CANVAS, encoding="utf-8")
        (folder / "tst_map.qml").write_text(TEST, encoding="utf-8")
        env = os.environ.copy()
        env["PATH"] = str(args.qt_bin) + os.pathsep + env.get("PATH", "")
        env["QT_QPA_PLATFORM"] = "offscreen"
        env["QT_QUICK_BACKEND"] = "software"
        log = folder / "results.txt"
        result = subprocess.run([str(args.qt_bin / ("qmltestrunner.exe" if os.name == "nt" else "qmltestrunner")), "-input", str(folder),
                                 "-o", str(log) + ",txt"], env=env, timeout=45)
        output = log.read_text(encoding="utf-8") if log.exists() else "No Qt test results produced"
        print(output)
        return result.returncode or (0 if "0 failed" in output else 1)


if __name__ == "__main__":
    raise SystemExit(main())
