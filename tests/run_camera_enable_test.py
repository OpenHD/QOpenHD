"""Exercise the camera card's production toggle functions in Qt Quick."""
import argparse
import os
from pathlib import Path
import subprocess
import tempfile

root = Path(__file__).resolve().parents[1]
parser = argparse.ArgumentParser()
parser.add_argument("--qt-bin", required=True)
args = parser.parse_args()
source = (root / "qml/ui/configpopup/openhd_settings/CameraDualPanel.qml").read_text(encoding="utf-8")
functions = source[source.index("    function cameraModel("):source.index("    readonly property bool raspberryPi:")]
fixture = (root / "tests/camera_enable/camera_enable.qml.in").read_text(encoding="utf-8").replace("FUNCTIONS", functions)
env = dict(os.environ, QT_QUICK_BACKEND="software", QT_QUICK_CONTROLS_STYLE="Basic", QT_FORCE_STDERR_LOGGING="1")
env["PATH"] = str(Path(args.qt_bin).resolve()) + os.pathsep + env.get("PATH", "")
with tempfile.TemporaryDirectory(prefix="camera-enable-") as directory:
    (Path(directory) / "tst_enable.qml").write_text(fixture, encoding="utf-8")
    raise SystemExit(subprocess.run([str(Path(args.qt_bin) / "qmltestrunner.exe"), "-input", directory], env=env, timeout=45).returncode)
