"""Exercise production map lifecycle with real Qt 5 Location plugins and a headless canvas.
Run: python tests/run_map_provider_test.py --qt-bin C:/Qt/5.15.19/mingw81_64/bin
No real access token or tile downloads are needed; rendering on a Pi is a separate check.
Use --render opengl to validate the circular GPU mask and save widget previews.
"""
import argparse
import os
from pathlib import Path
import subprocess
import tempfile
import shutil

ROOT = Path(__file__).resolve().parents[1]

BASE = '''import QtQuick 2.12
Item {
    property bool useDragHandle
    property bool disable_dragging
    property int defaultAlignment
    property int defaultXOffset
    property int defaultYOffset
    property string widgetIdentifier
    property bool hasWidgetDetail
    property bool dragging: false
    property int savedMoves: 0
    function _onPressAndHold(drag) { resetAnchors(); dragging = true; drag.target = this }
    function _onClicked(drag) { drag.target = null; dragging = false; savedMoves++ }
    function resetAnchors() {}
    function setAlignment() {}
    function loadAlignment() {}
}
'''
CANVAS = '''import QtQuick 2.12
import QtPositioning 5.15
Item {
    Rectangle {
        anchors.fill: parent
        color: "#9cb9ac"
        Repeater {
            model: 8
            Rectangle { x: index * 40; width: 1; height: parent.height; color: "#b9cfc4" }
        }
        Repeater {
            model: 8
            Rectangle { y: index * 40; height: 1; width: parent.width; color: "#b9cfc4" }
        }
        Rectangle { x: parent.width * 0.5; width: 8; height: parent.height; color: "#dfe2c6"; rotation: 28 }
    }
    signal expandRequested()
    property int centrePresses: 0
    MouseArea {
        anchors.fill: parent
        onPressed: parent.centrePresses++
    }
    property real bearing: 0
    property int error: 0
    property var plugin
    property bool demoFlight: false
    property bool compassMode: false
    property bool forceCustomMapType
    property var center: QtPositioning.coordinate(10, 20)
    property var gesture: QtObject { property bool enabled }
    property var supportedMapTypes: ["street", "satellite"]
    property real minimumZoomLevel: 0
    property real maximumZoomLevel: 20
    property real zoomLevel: 10
    property var activeMapType
    property var shownRegion
    function showOfflineRegion(region) { shownRegion = region }
}
'''
TEST = '''import QtQuick 2.12
import QtTest 1.2
Item {
    width: 800; height: 480
    property int rowHeight: 64
    property int elementHeight: 48
    QtObject {
        id: hudOverlayGrid
        readonly property alias mapSettingsTarget: widget
    }
    QtObject {
        id: settings_form
        function close_all() {}
        property bool darkMode: false
        property color accentColor: "#278cff"
        property color panelBackground: "white"
        property color errorColor: "red"
        property color panelBackgroundRaised: "#ffffff"
        property color lineColor: "#cccccc"
        property color primaryText: "#111111"
        property color secondaryText: "#555555"
    }
    QtObject {
        id: settings
        property bool show_map: false
        property int selected_map_provider: 0
        property int selected_map_variant: 99
        property string map_api_key: ""
        property real map_zoom: 8
        property real map_size: 1
        property bool map_round: false
        property real map_opacity_minimized: 1
        property real map_opacity_maximized: 1
        property bool map_orientation: false
        property bool map_drone_track: true
        property bool map_show_mission_waypoints: true
        property bool adsb_enable: false
        property int adsb_source: 0
        property int adsb_radius: 10000
    }
    QtObject {
        id: _offlineMapTiles
        property bool available: true
        property int packageCount: 1
        property var packages: [{name: "Remote field", south: 49, west: 7, north: 50, east: 8, minZoom: 0, maxZoom: 14}]
        property string baseUrl: "http://127.0.0.1:9/"
        property string osmBaseUrl: "http://127.0.0.1:9/osm/"
        function reload() {}
    }
    QtObject {
        id: _offlineMapBuilder
        function mapCacheDirectory(source) { return "CACHE_DIRECTORY/" + source }
    }
    Item {
        id: widgetPreview
        width: widget.width + 40
        height: widget.height + 40
        MapWidget { id: widget; x: 20; y: 20 }
    }
    AppMapSettingsView { id: mapSettings; anchors.fill: parent }
    TestCase {
        name: "MapProviderRecovery"; when: windowShown
        function test_z_stylePreview() {
            mapSettings.visible = false
            settings.selected_map_provider = 0
            settings.show_map = true
            settings.map_size = 1.2
            settings.map_round = false
            widget.configureSmallMap()
            tryVerify(function() { return widget.map !== null })
            wait(150)
            var saved = false
            verify(widgetPreview.grabToImage(function(image) { saved = image.saveToFile("SCREENSHOT_DIR/rectangle.png") }))
            tryVerify(function() { return saved })
            settings.map_round = true
            wait(150)
            saved = false
            verify(widgetPreview.grabToImage(function(image) { saved = image.saveToFile("SCREENSHOT_DIR/round.png") }))
            tryVerify(function() { return saved })
            settings.map_size = 0.25
            compare(widget.width, 184 * 0.7)
            verify(findChild(widget, "compactMapZoom").width <= widget.width)
        }
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
            compare(widget.map, null)
            settings.show_map = true
            tryVerify(function() { return widget.map !== null })
            verify(widget.map !== null)
            compare(widget.map.activeMapType, "satellite")
            var parameters = {}
            for (var i = 0; i < widget.mapPlugin.parameters.length; ++i)
                parameters[widget.mapPlugin.parameters[i].name] = widget.mapPlugin.parameters[i].value
            compare(parameters["osm.mapping.custom.host"], _offlineMapTiles.osmBaseUrl)
            compare(parameters["osm.useragent"], "OpenHD-OfflineMaps/1.0 (+https://openhd.org)")
            compare(parameters["osm.mapping.prefetching_style"], "NoPrefetching")
            widget.map.supportedMapTypes = []
            widget.setup_map_variant()
            compare(widget.activeMapTypeIndex, -1)
            settings.selected_map_provider = 1
            tryCompare(widget, "apiKeyMissing", true)
            verify(widget.apiKeyMissing)
            compare(widget.map, null)
            widget.configureSmallMap()
            settings.map_api_key = '  pk.test"\\\\token  '
            tryVerify(function() { return widget.map !== null })
            verify(widget.map !== null)
            compare(widget.mapPlugin.parameters[0].name, "mapboxgl.access_token")
            compare(widget.mapPlugin.parameters[0].value, settings.map_api_key.trim())
            var previous = widget.map
            settings.selected_map_provider = 0
            tryVerify(function() { return widget.map !== null && widget.map !== previous })
            verify(widget.map !== null && widget.map !== previous)
            compare(widget.apiKeyMissing, false)
            compare(widget.mapFailure, "")
            compare(widget.map.activeMapType, "satellite")
            settings.selected_map_variant = 1
            compare(widget.map.activeMapType, "satellite")
            settings.selected_map_provider = 2
            tryCompare(widget, "activeProviderName", "openhd_offline")
            compare(widget.map.activeMapType, "satellite")
            settings.selected_map_provider = -1
            tryCompare(settings, "selected_map_provider", 0)
            compare(settings.selected_map_provider, 0)
            verify(widget.map !== null)
            widget.createMap(widget.widgetInnerMap, "unavailable_test_provider")
            compare(widget.map, null)
            verify(widget.mapFailure.length > 0)
            widget.configure()
            verify(widget.map !== null)
            compare(widget.mapFailure, "")
            findChild(mapSettings, "jumpToOfflineMap").clicked()
            tryCompare(widget, "activeProviderName", "openhd_offline")
            tryVerify(function() { return widget.map.shownRegion !== undefined })
            compare(widget.map.shownRegion.west, 7)
            compare(widget.followDrone, false)
            verify(widget.map.gesture.enabled)
            var beforeZoom = widget.map.zoomLevel
            findChild(widget, "compactMapZoomIn").clicked()
            compare(widget.map.zoomLevel, beforeZoom + 1)
            verify(widget.disable_dragging)
            verify(!widget.useDragHandle)
            findChild(mapSettings, "toggleMapDemo").clicked()
            verify(widget.demoFlight)
            verify(widget.map.demoFlight)
            findChild(mapSettings, "toggleMapDemo").clicked()
            verify(!widget.demoFlight)
            verify(!widget.map.demoFlight)
            compare(mapSettings.mapTarget, widget)
            var provider = findChild(mapSettings, "mapProvider")
            verify(provider !== null)
            compare(provider.count, 3)
            provider.currentIndex = 1
            provider.activated(1)
            tryVerify(function() { return widget.mapPlugin && widget.mapPlugin.name === "mapboxgl" })
            compare(settings.selected_map_provider, 1)
            compare(widget.mapPlugin.parameters[0].name, "mapboxgl.access_token")
            var size = findChild(mapSettings, "mapSize")
            size.value = 2
            size.moved()
            compare(settings.map_size, 2)
            compare(widget.width, 400)
            compare(widget.height, 270)
            var shape = findChild(mapSettings, "mapShape")
            shape.currentIndex = 1
            shape.activated(1)
            verify(settings.map_round)
            compare(widget.width, 280)
            compare(widget.height, 280)
            var surface = findChild(widget, "mapSurface")
            compare(surface.width, surface.height)
            compare(surface.radius, surface.width / 2)
            verify(widget.map.compassMode)
            var north = findChild(widget, "mapCompassN")
            var south = findChild(widget, "mapCompassS")
            var east = findChild(widget, "mapCompassE")
            verify(north !== null && south !== null && east !== null)
            verify(north.y + north.height <= surface.y)
            verify(south.y >= surface.y + surface.height)
            widget.map.bearing = 90
            verify(north.x + north.width <= surface.x)
            verify(east.y + east.height <= surface.y + 0.01)
            widget.map.bearing = 0
            compare(findChild(widget, "mapControlDock"), null)
            verify(!findChild(widget, "mapAttribution").visible)
            verify(findChild(mapSettings, "mapMenuAttribution").visible)
            verify(findChild(mapSettings, "mapMenuAttribution").text.indexOf("openstreetmap.org/copyright") >= 0)
            compare(findChild(widget, "mapExpand"), null)
            var compactZoom = findChild(widget, "compactMapZoom")
            verify(compactZoom.visible)
            compare(findChild(widget, "compactMapZoomIn").width, 24)
            compare(findChild(widget, "compactMapZoomOut").height, 24)
            verify(!findChild(widget, "compactMapZoomIn").tooltipsEnabled)
            verify(!widget.isWidgetEdge(widget.width / 2, widget.height / 2))
            verify(widget.isWidgetEdge(5, widget.height / 2))
            verify(!widget.isWidgetEdge(0, 0))
            mapSettings.visible = false
            wait(30)
            var edge = findChild(widget, "mapEdgeDrag")
            var previousX = widget.x
            var savedMoves = widget.savedMoves
            var centrePresses = widget.map.centrePresses
            mouseClick(edge, edge.width / 2, edge.height / 2)
            compare(widget.map.centrePresses, centrePresses + 1)
            compare(widget.savedMoves, savedMoves)
            compare(widget.x, previousX)
            mousePress(edge, 5, edge.height / 2)
            mouseMove(edge, 25, edge.height / 2, 30)
            mouseMove(edge, 35, edge.height / 2, 30)
            mouseRelease(edge, 35, edge.height / 2)
            verify(widget.x > previousX)
            compare(widget.savedMoves, savedMoves + 1)
            verify(!widget.dragging)
            mapSettings.visible = true
            widget.map.expandRequested()
            verify(widget.mapExpanded)
            verify(findChild(widget, "mapAttribution").visible)
            verify(!widget.roundMap)
            verify(!widget.map.compassMode)
            widget.map.expandRequested()
            verify(!widget.mapExpanded)
            verify(!findChild(widget, "mapAttribution").visible)
            verify(widget.roundMap)
            shape.currentIndex = 0
            shape.activated(0)
            verify(!settings.map_round)
            compare(widget.height, 270)
            widget.configureLargeMap()
            settings.map_size = 3
            widget.configureSmallMap()
            compare(widget.width, 600)
            compare(widget.height, 405)
            var oldMap = widget.map
            findChild(mapSettings, "reloadMap").clicked()
            verify(widget.map !== oldMap)
        }
    }
}
'''


INTERACTION = '''import QtQuick 2.12
import QtLocation 5.15
import QtPositioning 5.15
import QtTest 1.2
Item {
    width: 800; height: 480
    property bool followDrone: true
    property var _fcMavlinkMissionItemsModel: []
    function setup_map_variant() {}
    QtObject {
        id: applicationWindow
        property bool fcPositionValid: false
        property bool referencePositionValid: true
        property real referenceLatitude: 50
        property real referenceLongitude: 8
    }
    QtObject {
        id: settings
        property real map_zoom: 10
        property bool map_orientation: false
        property bool map_drone_track: false
        property bool map_show_mission_waypoints: false
        property bool adsb_enable: false
        property int adsb_radius: 5000
    }
    QtObject {
        id: _fcMavlinkSystem
        property bool is_alive: true
        property real lat: 0
        property real lon: 0
        property int gps_fix_type: 0
        property real home_latitude: 0
        property real home_longitude: 0
        property real hdg: 0
        property real gps_hdop: 1
        property bool armed: false
    }
    QtObject {
        id: _offlineMapTiles
        property real latitude: 0
        property real longitude: 0
        function setPosition(lat, lon) { latitude = lat; longitude = lon }
    }
    Plugin {
        id: offline
        name: "osm"
        PluginParameter { name: "osm.mapping.providersrepository.disabled"; value: true }
        PluginParameter { name: "osm.mapping.custom.host"; value: "http://127.0.0.1:9/" }
    }
    property int expandRequests: 0
    RealMapComponent {
        id: map; anchors.fill: parent; plugin: offline
        onExpandRequested: expandRequests++
    }
    TestCase {
        name: "MapInteraction"; when: windowShown
        function test_panJumpAndFollow() {
            tryCompare(map, "mapReady", true)
            tryVerify(function() { return Math.abs(map.center.latitude - 50) < 0.01 })
            map.compassMode = true
            _fcMavlinkSystem.hdg = 90
            compare(map.bearing, 90)
            _fcMavlinkSystem.hdg = 180
            compare(map.bearing, 180)
            _fcMavlinkSystem.hdg = 359
            compare(map.bearing, 359)
            _fcMavlinkSystem.hdg = 1
            compare(map.bearing, 1)
            _fcMavlinkSystem.is_alive = false
            compare(map.bearing, 0)
            _fcMavlinkSystem.is_alive = true
            compare(map.bearing, 1)
            mouseDoubleClick(findChild(map, "mapDoubleClickArea"), 400, 200, Qt.LeftButton)
            compare(expandRequests, 1)
            mouseDrag(map, 400, 200, 100, 30, Qt.LeftButton)
            tryCompare(parent, "followDrone", false)
            compare(map.bearing, 0)
            verify(Math.abs(map.center.longitude - 8) > 0.001)
            tryCompare(map.gesture, "panActive", false, 10000)
            map.showOfflineRegion({south: 40, west: -75, north: 41, east: -74})
            wait(50)
            verify(map.center.latitude > 39 && map.center.latitude < 42)
            verify(map.center.longitude > -76 && map.center.longitude < -73)
            compare(_offlineMapTiles.latitude, 50)
            compare(_offlineMapTiles.longitude, 8)
            verify(!findChild(map, "droneMarker").visible)
            var zoom = map.zoomLevel
            map.zoomLevel = zoom + 1
            verify(map.zoomLevel > zoom)
            applicationWindow.referenceLatitude = 51
            wait(20)
            verify(map.center.latitude < 42)
            followDrone = true
            compare(map.bearing, 1)
            tryVerify(function() { return Math.abs(map.center.latitude - 51) < 0.01 })
            var actualLatitude = applicationWindow.referenceLatitude
            var actualHeading = _fcMavlinkSystem.hdg
            var beforeDemo = QtPositioning.coordinate(map.center.latitude, map.center.longitude)
            map.demoFlight = true
            verify(map.demoOrigin.distanceTo(beforeDemo) < 1)
            var firstPosition = map.demoCoordinate
            var firstHeading = map.craftHeading
            wait(250)
            verify(firstPosition.distanceTo(map.demoCoordinate) > 1)
            verify(map.craftHeading !== firstHeading)
            verify(Math.abs(map.demoOrigin.distanceTo(map.demoCoordinate) - 250) < 1)
            compare(map.bearing, map.craftHeading)
            compare(applicationWindow.referenceLatitude, actualLatitude)
            compare(_fcMavlinkSystem.hdg, actualHeading)
            followDrone = false
            mouseClick(findChild(map, "demoPlaneFollow"), 22, 22)
            verify(followDrone)
            map.demoFlight = false
            compare(map.bearing, actualHeading)
            compare(map.referenceCoordinate.latitude, actualLatitude)
            _fcMavlinkSystem.lat = actualLatitude
            _fcMavlinkSystem.lon = applicationWindow.referenceLongitude
            applicationWindow.fcPositionValid = true
            followDrone = false
            wait(30)
            mouseClick(findChild(map, "gpsPlaneFollow"), 22, 22)
            verify(followDrone)
            verify(findChild(map, "droneMarker").visible)
        }
    }
}
'''


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--qt-bin", required=True, type=Path)
    parser.add_argument("--render", choices=["software", "opengl"], default="software")
    parser.add_argument("--screenshots", type=Path, default=ROOT / "build-map-provider/style")
    args = parser.parse_args()
    args.screenshots.mkdir(parents=True, exist_ok=True)
    with tempfile.TemporaryDirectory(prefix="qopenhd-map-") as temp:
        folder = Path(temp)
        # Only replace the visual form/canvas; execute the production lifecycle unchanged.
        source = (ROOT / "qml/ui/widgets/map/MapWidget.qml").read_text(encoding="utf-8")
        (folder / "MapWidget.qml").write_text(source.replace('import "../../elements";', ''), encoding="utf-8")
        form = (ROOT / "qml/ui/widgets/map/MapWidgetForm.ui.qml").read_text(encoding="utf-8")
        for dependency in ['import "../";', 'import "../../elements";', 'import "../../configpopup"', 'import OpenHD 1.0']:
            form = form.replace(dependency, "")
        (folder / "MapWidgetForm.qml").write_text(form.replace("BaseWidget {", "MockBaseWidget {"), encoding="utf-8")
        (folder / "MockBaseWidget.qml").write_text(BASE, encoding="utf-8")
        shutil.copyfile(ROOT / "qml/ui/widgets/map/MapboxLogo.png", folder / "MapboxLogo.png")
        (folder / "MapControlButton.qml").write_text((ROOT / "qml/ui/widgets/map/MapControlButton.qml").read_text(encoding="utf-8"), encoding="utf-8")
        (folder / "MapComponent.qml").write_text(CANVAS, encoding="utf-8")
        shutil.copyfile(ROOT / "qml/ui/configpopup/MenuTypography.js", folder / "MenuTypography.js")
        (folder / "DarkComboBox.qml").write_text((ROOT / "qml/ui/elements/DarkComboBox.qml").read_text(encoding="utf-8").replace('../configpopup/MenuTypography.js', 'MenuTypography.js'), encoding="utf-8")
        view = (ROOT / "qml/ui/configpopup/qopenhd_settings/AppMapSettingsView.qml").read_text(encoding="utf-8")
        (folder / "AppMapSettingsView.qml").write_text(view.replace('import "../../elements"', '').replace('import ".."', '').replace('../MenuTypography.js', 'MenuTypography.js'), encoding="utf-8")
        (folder / "SettingBaseElement.qml").write_text(
            (ROOT / "qml/ui/elements/SettingBaseElement.qml").read_text(encoding="utf-8").replace('../configpopup/MenuTypography.js', 'MenuTypography.js'), encoding="utf-8")
        (folder / "AdvancedActionButton.qml").write_text((ROOT / "qml/ui/configpopup/AdvancedActionButton.qml").read_text(encoding="utf-8"), encoding="utf-8")
        real_canvas = (ROOT / "qml/ui/widgets/map/MapComponent.qml").read_text(encoding="utf-8")
        real_canvas = real_canvas.replace("import OpenHD 1.0", "").replace("AdsbVehicleManager.adsbVehicles", "[]")
        (folder / "RealMapComponent.qml").write_text(real_canvas, encoding="utf-8")
        shutil.copyfile(ROOT / "qml/ui/widgets/map/PlaneMapMarker.qml", folder / "PlaneMapMarker.qml")
        (folder / "tst_interaction.qml").write_text(INTERACTION, encoding="utf-8")
        (folder / "tst_map.qml").write_text(TEST.replace("CACHE_DIRECTORY", folder.as_posix()).replace("SCREENSHOT_DIR", args.screenshots.as_posix()), encoding="utf-8")
        fonts = folder / "fonts"
        fonts.mkdir()
        for name in ["segoeui.ttf", "segoeuib.ttf"]:
            font = Path(os.environ.get("WINDIR", "C:/Windows")) / "Fonts" / name
            if font.exists(): shutil.copyfile(font, fonts / name)
        env = os.environ.copy()
        env["QT_QPA_FONTDIR"] = str(fonts)
        env["PATH"] = str(args.qt_bin) + os.pathsep + env.get("PATH", "")
        env["QT_QPA_PLATFORM"] = "offscreen"
        if args.render == "software": env["QT_QUICK_BACKEND"] = "software"
        else:
            env.pop("QT_QUICK_BACKEND", None)
            env["QT_QPA_PLATFORM"] = "windows" if os.name == "nt" else "offscreen"
            env["QT_OPENGL"] = "software"
        env["QSG_RENDER_LOOP"] = "basic"
        log = folder / "results.txt"
        result = subprocess.run([str(args.qt_bin / ("qmltestrunner.exe" if os.name == "nt" else "qmltestrunner")), "-input", str(folder),
                                 "-o", str(log) + ",txt"], env=env, timeout=45)
        output = log.read_text(encoding="utf-8") if log.exists() else "No Qt test results produced"
        print(output)
        if args.render == "opengl" and result.returncode == 0:
            from PIL import Image
            rectangle = Image.open(args.screenshots / "rectangle.png").convert("RGBA")
            circle = Image.open(args.screenshots / "round.png").convert("RGBA")
            diameter = circle.width - 40
            assert circle.getpixel((25, 25))[3] == 0, "Circle corner was not masked"
            assert circle.getpixel((20 + diameter // 2, 20 + diameter // 2))[3] > 240, "Map disappeared inside circle"
            assert circle.getpixel((20 + diameter // 2, 22))[3] > 240, "Circle top disappeared"
            assert rectangle.getpixel((rectangle.width // 2, 50))[3] > 240, "Rectangular map disappeared"
            print("OpenGL previews verified: map visible, circle corners transparent")
        return result.returncode or (0 if "0 failed" in output else 1)


if __name__ == "__main__":
    raise SystemExit(main())
