"""Exercise the production startup movie with native Qt media, no GStreamer."""
import argparse
import os
from pathlib import Path
import subprocess
import tempfile

ROOT = Path(__file__).resolve().parents[1]
parser = argparse.ArgumentParser(description=__doc__)
parser.add_argument("--qt-bin", type=Path, required=True)
parser.add_argument("--qt-major", type=int, required=True)
args = parser.parse_args()
fixture = """import QtQuick 2.12
import QtTest 1.2
Item {
    width:850; height:480
    Loader { id:movie; anchors.fill:parent; source:"Movie.qml" }
    SignalSpy { id:started; target:movie.item; signalName:"playbackStarted" }
    SignalSpy { id:finished; target:movie.item; signalName:"playbackFinished" }
    SignalSpy { id:failed; target:movie.item; signalName:"playbackFailed" }
    TestCase {
        name:"NativeStartupMovie"; when:windowShown
        function test_real_video_plays_to_end() {
            tryCompare(movie,"status",Loader.Ready)
            movie.item.running=true
            tryCompare(started,"count",1,12000)
            tryVerify(function(){return movie.item.hasVideoFrames},10000)
            tryVerify(function(){return movie.item.position > 500},10000)
            tryCompare(finished,"count",1,12000)
            compare(failed.count,0)
            movie.item.running=false
        }
    }
}
"""
with tempfile.TemporaryDirectory(prefix="qopenhd-startup-media-") as temporary:
    work = Path(temporary)
    source = (ROOT / "qml" / f"StartupMovieQt{args.qt_major}.qml").read_text(encoding="utf-8")
    source = source.replace("qrc:/boot-video.mp4", (ROOT / "qml/boot-video.mp4").as_uri())
    (work / "Movie.qml").write_text(source, encoding="utf-8")
    (work / "tst_movie.qml").write_text(fixture, encoding="utf-8")
    env = os.environ.copy()
    env.update(QT_QUICK_BACKEND="software", QT_QUICK_CONTROLS_STYLE="Material")
    env["PATH"] = str(args.qt_bin) + os.pathsep + env.get("PATH", "")
    log = ROOT / "build" / f"startup-movie-qt{args.qt_major}.log"
    result = subprocess.run([str(args.qt_bin / "qmltestrunner.exe"), "-input", str(work), "-platform", "offscreen", "-o", str(log) + ",txt"], cwd=ROOT, env=env, timeout=60)
    print(log.read_text(encoding="utf-8") if log.exists() else "No Qt log")
    raise SystemExit(result.returncode)
