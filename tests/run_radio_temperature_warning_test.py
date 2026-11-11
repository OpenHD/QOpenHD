"""Run the production temperature banner on Qt 5/6 with a silent audio spy."""
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
qt_major = 6 if "6." in str(args.qt_bin) else 5
with tempfile.TemporaryDirectory(prefix="qopenhd-radio-temperature-") as temp:
    folder = Path(temp)
    shutil.copy(ROOT / "qml/RadioTemperatureWarning.qml", folder)
    # The banner is visual-only; all alert audio is tested through AudioAnnouncements.
    assert "SoundEffect" not in (ROOT / "qml/RadioTemperatureWarning.qml").read_text()
    assert "RadioTemperatureAlarmSound" not in (ROOT / "qml/RadioTemperatureWarning.qml").read_text()
    fixture = (ROOT / "tests/radio_temperature_warning/tst_warning.qml").read_text(encoding="utf-8")
    output = ROOT / "build" / "radio-temperature-warning"
    output.mkdir(parents=True, exist_ok=True)
    fixture = fixture.replace("SCREENSHOT_PATH", (output / "warning.png").as_posix())
    fixture = fixture.replace("QT_MAJOR_VERSION", str(qt_major))
    (folder / "tst_warning.qml").write_text(fixture, encoding="utf-8")
    env = os.environ.copy()
    env["PATH"] = str(args.qt_bin) + os.pathsep + env.get("PATH", "")
    env.update(QT_QUICK_BACKEND="software", QT_SCALE_FACTOR="1",
               QT_QUICK_CONTROLS_STYLE="Material", QT_QPA_PLATFORM="windows",
               QT_QPA_PLATFORM_PLUGIN_PATH=str(args.qt_bin.parent / "plugins/platforms"),
               QML2_IMPORT_PATH=str(args.qt_bin.parent / "qml"),
               QML_IMPORT_PATH=str(args.qt_bin.parent / "qml"))
    log = output / (args.qt_bin.parent.name + ".txt")
    result = subprocess.run([str(args.qt_bin / "qmltestrunner.exe"), "-input", str(folder),
                             "-o", str(log) + ",txt"], env=env, timeout=60)
    print(log.read_text(encoding="utf-8") if log.exists() else "No Qt output")
    raise SystemExit(result.returncode)
