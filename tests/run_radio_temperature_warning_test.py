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
    # Only the hardware audio sink is replaced. Alarm timing, mute, aggregation
    # and every pixel of the warning are the production component.
    for name in ("RadioTemperatureAlarmSound.qml", "RadioTemperatureAlarmSoundQt6.qml"):
        (folder / name).write_text(
            'import QtQuick 2.12\nItem { property bool failed: false; '
            'function playAlarm() {} }\n', encoding="utf-8")
    fixture = (ROOT / "tests/radio_temperature_warning/tst_warning.qml").read_text(encoding="utf-8")
    output = ROOT / "build" / "radio-temperature-warning"
    output.mkdir(parents=True, exist_ok=True)
    fixture = fixture.replace("SCREENSHOT_PATH", (output / "warning.png").as_posix())
    fixture = fixture.replace("QT_MAJOR_VERSION", str(qt_major))
    (folder / "tst_warning.qml").write_text(fixture, encoding="utf-8")
    audio = folder / "audio"
    (audio / "resources").mkdir(parents=True)
    sound_component = "RadioTemperatureAlarmSoundQt6.qml" if qt_major >= 6 else "RadioTemperatureAlarmSound.qml"
    shutil.copy(ROOT / "qml" / sound_component, audio)
    shutil.copy(ROOT / "qml/resources/radio-temperature-alarm.wav", audio / "resources")
    audio_fixture = (ROOT / "tests/radio_temperature_warning/tst_audio.qml").read_text(encoding="utf-8")
    (audio / "tst_audio.qml").write_text(audio_fixture.replace("AUDIO_COMPONENT", sound_component), encoding="utf-8")
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
