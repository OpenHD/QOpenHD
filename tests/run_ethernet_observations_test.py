"""Run the Ethernet model regression against an already-built Qt 5 qmake application.

Pass its build directory; put that build's MinGW and Qt bin directories on PATH.
Production objects are reused, replacing only main.cpp with the regression main.
"""
import argparse
import os
from pathlib import Path
import re
import shlex
import subprocess


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("build_dir", type=Path)
    parser.add_argument("--cxx", default="g++")
    args = parser.parse_args()
    build = args.build_dir.resolve()
    make = (build / "Makefile.Release").read_text(encoding="utf-8")

    def flags(name):
        match = re.search(r"^" + name + r"\s*=\s*(.*)$", make, re.M)
        if not match:
            raise RuntimeError("Missing qmake variable " + name)
        return [value.strip('"') for value in shlex.split(match[1], posix=False)]

    source = Path(__file__).with_name("ethernet_observations_test.cpp").resolve()
    subprocess.run([args.cxx, "-std=c++17", "-O0", "-DQT_NO_DEBUG", "-D__windows__",
                    *flags("INCPATH"), "-c", str(source), "-o", "obj/ethernet_observations_test.o"],
                   cwd=build, check=True)
    objects = (build / "object_script.QOpenHD.Release").read_text().splitlines()
    objects = [value for value in objects if value.strip() != "obj/main.o"]
    response = build / "ethernet_observations_objects.rsp"
    response.write_text("\n".join(objects + ["obj/ethernet_observations_test.o"]), encoding="utf-8")
    executable = build / "release/ethernet_observations_test.exe"
    subprocess.run([args.cxx, "-Wl,--allow-multiple-definition", "-mthreads", "-o",
                    str(executable), "@" + str(response), *flags("LIBS")], cwd=build, check=True)
    environment = dict(os.environ, QT_QPA_PLATFORM="offscreen", QT_FORCE_STDERR_LOGGING="1")
    subprocess.run([str(executable)], cwd=build, env=environment, check=True, timeout=40)


if __name__ == "__main__":
    main()
