"""Exercise real MAVLink decoding/models using a built Qt 5 application."""
import argparse
import os
from pathlib import Path
import re
import shlex
import subprocess

parser = argparse.ArgumentParser(description=__doc__)
parser.add_argument("build_dir", type=Path)
parser.add_argument("--cxx", default="g++")
args = parser.parse_args()
build = args.build_dir.resolve()
make = (build / "Makefile.Release").read_text(encoding="utf-8")

def flags(name):
    match = re.search(r"^" + name + r"\s*=\s*(.*)$", make, re.M)
    return [value.strip('"') for value in shlex.split(match[1], posix=False)]

source = Path(__file__).with_name("radio_temperature_model_test.cpp").resolve()
subprocess.run([args.cxx, "-std=c++17", "-O0", "-DQT_NO_DEBUG", "-D__windows__",
                *flags("INCPATH"), "-c", str(source), "-o", "obj/radio_temperature_model_test.o"],
               cwd=build, check=True)
objects = (build / "object_script.QOpenHD.Release").read_text().splitlines()
# This headless regression does not instantiate the QML scene/cache. Keep the
# real model/application objects, without requiring cached UI resources.
objects = [value for value in objects if value.strip() not in
           {"obj/main.o", "obj/qmlcache_loader.o", "rcc/qrc_qml_qml_qmlcache.o"}
           and not value.strip().startswith("obj/qml_")]
response = build / "radio_temperature_model_objects.rsp"
response.write_text("\n".join(objects + ["obj/radio_temperature_model_test.o"]), encoding="utf-8")
executable = build / "release/radio_temperature_model_test.exe"
subprocess.run([args.cxx, "-Wl,--allow-multiple-definition", "-mthreads", "-o",
                str(executable), "@" + str(response), *flags("LIBS")], cwd=build, check=True)
environment = dict(os.environ, QT_QPA_PLATFORM="offscreen", QT_FORCE_STDERR_LOGGING="1")
subprocess.run([str(executable)], cwd=build, env=environment, check=True, timeout=40)
