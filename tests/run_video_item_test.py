"""Run video lifecycle or two-stream rendering checks using a Qt 5 qmake build.

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
    parser.add_argument("--render", action="store_true", help="Check primary and secondary pixels using an OpenGL window")
    args = parser.parse_args()
    build = args.build_dir.resolve()
    make = (build / "Makefile.Release").read_text(encoding="utf-8")

    def flags(name):
        match = re.search(r"^" + name + r"\s*=\s*(.*)$", make, re.M)
        if not match:
            raise RuntimeError("Missing qmake variable " + name)
        return [value.strip('"') for value in shlex.split(match[1], posix=False)]

    stem = "secondary_video_render_test" if args.render else "video_item_lifecycle_test"
    source = Path(__file__).resolve().parent / (stem + ".cpp")
    subprocess.run([args.cxx, "-std=c++17", "-O0", "-DQT_NO_DEBUG", "-D__windows__",
                    *flags("INCPATH"), "-c", str(source), "-o", "obj/" + stem + ".o"],
                   cwd=build, check=True)
    objects = (build / "object_script.QOpenHD.Release").read_text().splitlines()
    objects = [value for value in objects if value.strip() != "obj/main.o"]
    response = build / (stem + "_objects.rsp")
    response.write_text("\n".join(objects + ["obj/" + stem + ".o"]), encoding="utf-8")
    executable = build / ("release/" + stem + ".exe")
    subprocess.run([args.cxx, "-Wl,--allow-multiple-definition", "-mthreads", "-o",
                    str(executable), "@" + str(response), *flags("LIBS")], cwd=build, check=True)
    environment = dict(os.environ, QT_QPA_PLATFORM="windows" if args.render else "offscreen", QT_FORCE_STDERR_LOGGING="1")
    subprocess.run([str(executable)], cwd=build, env=environment, check=True, timeout=40)


if __name__ == "__main__":
    main()
