"""Test production map/ADS-B positioning with a local HTTP geolocation fixture."""
import argparse
from http.server import BaseHTTPRequestHandler, ThreadingHTTPServer
import os
from pathlib import Path
import subprocess
import tempfile
from threading import Thread

ROOT = Path(__file__).resolve().parents[1]


class LocationHandler(BaseHTTPRequestHandler):
    def do_GET(self):
        self.send_response(200)
        self.send_header("Content-Type", "application/json")
        self.end_headers()
        self.wfile.write(b'{"success":true,"latitude":null,"longitude":8}'
                         if self.path == "/invalid" else
                         b'{"success":true,"latitude":50,"longitude":8}')

    def log_message(self, *_args):
        pass


TEST = '''import QtQuick 2.12
import QtPositioning 5.15
import QtTest 1.2
Item {
    width: 800; height: 480
    property string testUrl
    QtObject {
        id: settings
        property bool show_map: false
        property bool adsb_enable: false
    }
    QtObject {
        id: _fcMavlinkSystem
        property bool is_alive: false
        property int gps_fix_type: 0
        property double lat: 0
        property double lon: 0
    }
    QtObject {
        id: adsbManager
        function setReferencePosition(latitude, longitude) {}
    }
    TestCase {
        name: "AutomaticPositionFallback"; when: windowShown
        function init() {
            settings.show_map = false
            settings.adsb_enable = false
            _fcMavlinkSystem.is_alive = false
            _fcMavlinkSystem.gps_fix_type = 0
            _fcMavlinkSystem.lat = 0
            _fcMavlinkSystem.lon = 0
        }
        function test_fallback_data() {
            return [{tag: "desktop", source: "DesktopPosition.qml"},
                    {tag: "pi", source: "PiPosition.qml"}]
        }
        function test_fallback(data) {
            testUrl = "SERVER/valid"
            var component = Qt.createComponent(data.source)
            compare(component.status, Component.Ready, component.errorString())
            var position = component.createObject(parent)
            verify(position !== null)
            verify(!position.locationFallbackEnabled)
            verify(!position.referencePositionValid)
            settings.show_map = true
            verify(!settings.adsb_enable)
            tryCompare(position, "ipPositionValid", true)
            verify(position.referencePositionValid)
            verify(position.referencePositionIsRough)
            compare(position.referenceLatitude, 50)
            compare(position.referenceLongitude, 8)
            // Ground-device positioning wins over the IP estimate.
            position.groundCoordinate = QtPositioning.coordinate(51, 9)
            compare(position.referenceLatitude, 51)
            // A valid live craft fix wins over both fallbacks.
            _fcMavlinkSystem.lat = 52
            _fcMavlinkSystem.lon = 10
            _fcMavlinkSystem.gps_fix_type = 3
            _fcMavlinkSystem.is_alive = true
            compare(position.referenceLatitude, 52)
            verify(!position.referencePositionIsRough)
            // Losing the fix or connection must restore the fallback.
            _fcMavlinkSystem.gps_fix_type = 0
            compare(position.referenceLatitude, 51)
            _fcMavlinkSystem.gps_fix_type = 3
            _fcMavlinkSystem.is_alive = false
            compare(position.referenceLatitude, 51)
            _fcMavlinkSystem.is_alive = true
            _fcMavlinkSystem.lat = Number.NaN
            compare(position.referenceLatitude, 51)
            position.groundCoordinate = QtPositioning.coordinate()
            compare(position.referenceLatitude, 50)
            position.destroy()
            wait(0)
        }
        function test_invalidResponse_data() { return test_fallback_data() }
        function test_invalidResponse(data) {
            testUrl = "SERVER/invalid"
            var component = Qt.createComponent(data.source)
            var position = component.createObject(parent)
            settings.show_map = true
            tryVerify(function() { return position.requestFinished })
            verify(!position.ipPositionValid)
            verify(!position.referencePositionValid)
            position.destroy()
            wait(0)
        }
    }
}
'''


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--qt-bin", required=True, type=Path)
    args = parser.parse_args()
    server = ThreadingHTTPServer(("127.0.0.1", 0), LocationHandler)
    Thread(target=server.serve_forever, daemon=True).start()
    try:
        with tempfile.TemporaryDirectory(prefix="qopenhd-position-") as temp:
            folder = Path(temp)
            for source, target in [("main.qml", "DesktopPosition.qml"),
                                   ("PiFlightContent.qml", "PiPosition.qml")]:
                text = (ROOT / "qml" / source).read_text(encoding="utf-8")
                block = text[text.index("    // Map/ADS-B position priority:"):
                             text.index("    //property int m_window_width:")]
                # Replace only the OS positioning provider, external ADS-B sink,
                # and endpoint; keep production selection, XHR, and timers.
                start = block.index("    PositionSource {")
                end = block.index("\n    }", start) + len("\n    }")
                block = block[:start] + '''
    property var groundCoordinate: QtPositioning.coordinate()
    QtObject {
        id: networkPositionSource
        property var position: QtObject {
            property var coordinate: applicationWindow.groundCoordinate
        }
    }
    property bool requestFinished: false
    onIpLocationRequestActiveChanged: {
        if (!ipLocationRequestActive) requestFinished = true
    }
''' + block[end:]
                block = block.replace("AdsbVehicleManager.", "adsbManager.")
                block = block.replace('"https://ipwho.is/?fields=success,latitude,longitude"', "testUrl")
                (folder / target).write_text(
                    "import QtQuick 2.12\nimport QtPositioning 5.15\n"
                    "Item { id: applicationWindow\n" + block + "}\n", encoding="utf-8")
            (folder / "tst_position.qml").write_text(
                TEST.replace("SERVER", f"http://127.0.0.1:{server.server_port}"), encoding="utf-8")
            env = os.environ.copy()
            env["PATH"] = str(args.qt_bin) + os.pathsep + env.get("PATH", "")
            env["QT_QPA_PLATFORM"] = "offscreen"
            env["QT_QUICK_BACKEND"] = "software"
            log = folder / "results.txt"
            result = subprocess.run([str(args.qt_bin / ("qmltestrunner.exe" if os.name == "nt" else "qmltestrunner")), "-input", str(folder),
                                     "-o", str(log) + ",txt"], env=env, timeout=45)
            output = log.read_text(encoding="utf-8") if log.exists() else "No test results"
            print(output)
            return result.returncode or (0 if "0 failed" in output else 1)
    finally:
        server.shutdown()
        server.server_close()


if __name__ == "__main__":
    raise SystemExit(main())
