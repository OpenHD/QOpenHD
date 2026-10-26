"""Load the production picker, draw a rectangle, and verify the generate action.

Uses Qt 5 Location with a real map canvas; map generation is a small UI fixture.
"""
import argparse
import os
from pathlib import Path
import subprocess
import shutil
import tempfile
import contextlib
from http.server import BaseHTTPRequestHandler, ThreadingHTTPServer
from threading import Thread
import struct
import zlib

ROOT = Path(__file__).resolve().parents[1]
@contextlib.contextmanager
def tile_fixture():
    requests = []
    def chunk(kind, data):
        return struct.pack(">I", len(data)) + kind + data + struct.pack(">I", zlib.crc32(kind + data) & 0xffffffff)
    png = (b"\x89PNG\r\n\x1a\n" + chunk(b"IHDR", struct.pack(">IIBBBBB", 256, 256, 8, 2, 0, 0, 0))
           + chunk(b"IDAT", zlib.compress((b"\0" + b"\x80\x90\x80" * 256) * 256)) + chunk(b"IEND", b""))
    class Handler(BaseHTTPRequestHandler):
        def do_GET(self):
            requests.append(dict(self.headers))
            self.send_response(200)
            self.send_header("Content-Type", "image/png")
            self.send_header("Content-Length", str(len(png)))
            self.send_header("Cache-Control", "public,max-age=604800")
            self.end_headers()
            self.wfile.write(png)
        def log_message(self, *_args): pass
    server = ThreadingHTTPServer(("127.0.0.1", 0), Handler)
    Thread(target=server.serve_forever, daemon=True).start()
    try: yield f"http://127.0.0.1:{server.server_port}/", requests
    finally:
        server.shutdown()
        server.server_close()


TEST = '''import QtQuick 2.12
import QtQuick.Controls 2.12
import QtTest 1.2
Item {
    id: scene
    width: 850; height: 480
    property bool packageReady: false
    QtObject {
        id: builder
        property string previewCacheDirectory: "CACHE_DIR"
        property bool busy: false
        property bool searching: false
        property string status: "Choose a search result, then draw your area."
        property double progress: 0
        property var searchResults: []
        property int generatedCount: 0
        property var lastBounds: []
        signal generated(string path)
        function tileCount(s, w, n, e, zoom) { return s < n && w < e ? 20 : -1 }
        function search(query) {
            searchResults = [{name: "Test region", north: 50.01, south: 49.99, west: 7.99, east: 8.01}]
        }
        function generate(name, s, w, n, e, zoom) {
            generatedCount++
            lastBounds = [s, w, n, e]
            generated("test.glidemap")
        }
        function cancel() { busy = false }
    }
    OfflineMapDialog {
        id: dialog
        builder: builder
        initialLatitude: 50
        initialLongitude: 8
        onMapReady: scene.packageReady = true
    }
    TestCase {
        name: "OfflineMapPicker"; when: windowShown
        function test_rectangleAndGenerate() {
            dialog.open()
            var canvas = findChild(dialog, "offlineMapCanvas")
            verify(canvas !== null)
            tryCompare(canvas, "status", Loader.Ready, 10000)
            var map = findChild(canvas.item, "offlineSelectionMap")
            tryCompare(map, "mapReady", true, 10000)
            var search = findChild(dialog, "offlineRegionSearch")
            search.text = "Test region"
            search.accepted()
            wait(100)
            var selection = findChild(canvas.item, "offlineRectangleInput")
            canvas.item.drawing = true
            mousePress(selection, 120, 25)
            mouseMove(selection, 400, 95)
            mouseRelease(selection, 400, 95)
            verify(canvas.item.selectionValid)
            verify(canvas.item.north > canvas.item.south)
            verify(canvas.item.east > canvas.item.west)
            var create = findChild(dialog, "createOfflineMap")
            verify(create.enabled)
            verify(canvas.height >= 120)
            verify(create.mapToItem(dialog.contentItem, 0, create.height).y <= dialog.contentItem.height + 1)
            var content = findChild(dialog, "offlineMapDialogContent")
            waitForRendering(content)
            var saved = false
            verify(content.grabToImage(function(result) {
                saved = result.saveToFile("SCREENSHOT")
            }))
            tryVerify(function() { return saved })
            builder.busy = true
            builder.progress = 0.45
            builder.status = "Creating offline map..."
            wait(50)
            var progress = findChild(dialog, "offlineMapProgress")
            verify(progress.visible)
            verify(!progress.indeterminate)
            compare(progress.value, 0.45)
            verify(!create.enabled)
            verify(create.mapToItem(dialog.contentItem, 0, create.height).y <= dialog.contentItem.height + 1)
            mouseClick(findChild(dialog, "cancelOfflineMap"))
            verify(!builder.busy)
            verify(create.enabled)
            mouseClick(create)
            compare(builder.generatedCount, 1)
            compare(builder.lastBounds[0], canvas.item.south)
            compare(builder.lastBounds[3], canvas.item.east)
            verify(scene.packageReady)
            dialog.close()
        }
    }
}
'''


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--qt-bin", required=True, type=Path)
    parser.add_argument("--screenshot", type=Path, default=ROOT / "build-offline-builder-qt5/picker.png")
    args = parser.parse_args()
    args.screenshot.parent.mkdir(parents=True, exist_ok=True)
    with tile_fixture() as (tile_url, requests), tempfile.TemporaryDirectory(prefix="openhd-offline-ui-") as temp:
        folder = Path(temp)
        for name in ["OfflineMapDialog.qml", "OfflineMapSelection.qml"]:
            source = (ROOT / "qml/ui/widgets/map" / name).read_text(encoding="utf-8")
            source = source.replace("https://tile.openstreetmap.org/", tile_url)
            (folder / name).write_text(source, encoding="utf-8")
        (folder / "tst_picker.qml").write_text(TEST.replace("SCREENSHOT", args.screenshot.as_posix()).replace("CACHE_DIR", (folder / "tiles").as_posix()), encoding="utf-8")
        fonts = folder / "fonts"
        fonts.mkdir()
        for name in ["segoeui.ttf", "segoeuib.ttf"]:
            source = Path(os.environ.get("WINDIR", "C:/Windows")) / "Fonts" / name
            if source.exists(): shutil.copyfile(source, fonts / name)
        env = os.environ.copy()
        env["PATH"] = str(args.qt_bin) + os.pathsep + env.get("PATH", "")
        env.setdefault("QT_QPA_PLATFORM", "offscreen")
        env["QT_QPA_FONTDIR"] = str(fonts)
        env.setdefault("QT_QUICK_BACKEND", "software")
        log = folder / "results.txt"
        try:
            result = subprocess.run([str(args.qt_bin / ("qmltestrunner.exe" if os.name == "nt" else "qmltestrunner")), "-input", str(folder),
                                     "-o", str(log) + ",txt"], env=env, timeout=45)
        except subprocess.TimeoutExpired:
            print(log.read_text(encoding="utf-8") if log.exists() else "No Qt test output", flush=True)
            raise
        output = log.read_text(encoding="utf-8") if log.exists() else "No test results"
        print(output)
        assert requests, "Map preview did not request fixture tiles"
        for headers in requests:
            assert headers.get("User-Agent") == "OpenHD-OfflineMaps/1.0 (+https://openhd.org)", headers
            assert "no-cache" not in headers.get("Cache-Control", ""), headers
        print("Preview tile headers verified against local HTTP fixture")
        return result.returncode or (0 if "0 failed" in output else 1)


if __name__ == "__main__":
    raise SystemExit(main())
