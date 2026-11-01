"""Exercise camera detection and the production secondary panel/Loader.

Native video backends and the unrelated settings popup are replaced by lightweight
items so this checks decoder creation without requiring hardware or OpenHD types.
"""
import argparse
import os
from pathlib import Path
import subprocess
import tempfile

ROOT = Path(__file__).resolve().parents[1]
parser = argparse.ArgumentParser()
parser.add_argument("--qt-bin", required=True, type=Path)
args = parser.parse_args()
with tempfile.TemporaryDirectory(prefix="camera-autodetection-") as directory:
    folder = Path(directory)
    video = folder / "video"
    video.mkdir()
    source = (ROOT / "qml/video/SecondaryVideoGStreamer.qml").read_text(encoding="utf-8")
    source = source.replace('import OpenHD 1.0', '').replace('import "../ui/elements"', '')
    for flag in ["QOPENHD_ENABLE_NXP_VIDEO", "QOPENHD_ENABLE_VIDEO_VIA_ANDROID",
                 "QOPENHD_ENABLE_VIDEO_VIA_AVCODEC"]:
        source = source.replace(flag, "false")
    source = source.replace("QOPENHD_ENABLE_GSTREAMER_QMLGLSINK", "true")
    (video / "SecondaryVideoGStreamer.qml").write_text(source, encoding="utf-8")
    (video / "SecondaryVideoSettingsPopup.qml").write_text(
        'import QtQuick 2.12\nItem { function open() {} }', encoding="utf-8")
    (video / "SecondaryVideoGstreamerPane.qml").write_text('''import QtQuick 2.12
Item {
    objectName: "secondaryBackend"
    Component.onCompleted: backendLifecycle.starts++
    Component.onDestruction: backendLifecycle.stops++
}
''', encoding="utf-8")
    fixture = (ROOT / "tests/camera_autodetection/tst_camera_autodetection.qml").read_text(encoding="utf-8")
    fixture = fixture.replace('"../../qml/ui/elements"', '"' + (ROOT / 'qml/ui/elements').as_uri() + '"')
    fixture = fixture.replace("TEST_SETTINGS_FILE", (folder / "settings.ini").as_posix())
    (folder / "tst_camera_autodetection.qml").write_text(fixture, encoding="utf-8")
    env = dict(os.environ, QT_QUICK_BACKEND="software", QT_FORCE_STDERR_LOGGING="1")
    env["PATH"] = str(args.qt_bin.resolve()) + os.pathsep + env.get("PATH", "")
    result = subprocess.run([str(args.qt_bin / "qmltestrunner.exe"), "-input", str(folder)],
                            cwd=ROOT, env=env, timeout=60)
    raise SystemExit(result.returncode)
