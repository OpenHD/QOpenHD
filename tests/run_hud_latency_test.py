"""Run the HUD/UDP regression against an existing Windows qmake release build.

python tests/run_hud_latency_test.py build-qt5-win32-fleetcontrol \
    --compiler C:/Qt/Tools/mingw810_32/bin/g++.exe
"""
import argparse
import os
from pathlib import Path
import subprocess


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("build_dir", type=Path)
    parser.add_argument("--compiler", required=True, type=Path)
    args = parser.parse_args()
    if os.name != "nt":
        parser.error("This harness uses the Windows qmake build.")
    build = args.build_dir.resolve()
    compiler = args.compiler.resolve()
    makefile = (build / "Makefile.Release").read_text()

    def value(key):
        return next(line.split("=", 1)[1].strip() for line in makefile.splitlines()
                    if line.startswith(key + " "))

    qt = Path(value("QMAKE")).parent.parent
    objects = (build / "object_script.QOpenHD.Release").read_text().splitlines()
    response = build / "hud-latency-test-objects.txt"
    response.write_text("\n".join(obj for obj in objects
                                  if not obj.replace("\\", "/").endswith("/main.o")))
    exe = build / "hud-latency-test.exe"
    source = Path(__file__).with_name("hud_latency_test.cpp").resolve()
    env = os.environ.copy()
    env["PATH"] = os.pathsep.join([str(build / "release"), str(qt / "bin"),
                                   str(compiler.parent), env["PATH"]])
    command = [str(compiler), "-std=gnu++17", "-D__windows__", "-DWIN32", "-DQT_NO_DEBUG",
               "-o", str(exe), str(source), "@" + str(response), "-Wl,--allow-multiple-definition"]
    command += value("INCPATH").split() + value("LIBS").split()
    subprocess.run(command, cwd=build, env=env, check=True)
    env.update(QT_QPA_PLATFORM="offscreen", QT_QUICK_BACKEND="software",
               QT_FORCE_STDERR_LOGGING="1",
               QT_QPA_PLATFORM_PLUGIN_PATH=str(qt / "plugins/platforms"),
               QML2_IMPORT_PATH=str(qt / "qml"),
               QT_QPA_FONTDIR=str(Path(os.environ["WINDIR"]) / "Fonts"))
    result = subprocess.run([str(exe)], cwd=build, env=env, capture_output=True, timeout=15)
    output = result.stdout.decode(errors="replace") + result.stderr.decode(errors="replace")
    (build / "hud-latency-test-results.txt").write_text(output)
    print(output)
    return result.returncode


if __name__ == "__main__":
    raise SystemExit(main())
