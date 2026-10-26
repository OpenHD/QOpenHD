"""Assemble an isolated Qt/Weston test runtime; retain the board's NXP driver libraries."""
import argparse
import re
import shutil
import subprocess
import os
import shlex
from pathlib import Path

p = argparse.ArgumentParser(description=__doc__)
p.add_argument("--work", type=Path, default=Path("/home/damien/qopenhd-nxp"))
p.add_argument("--board-libraries", type=Path, required=True)
p.add_argument("--compositor-root", type=Path, help="Source-built compositor install prefix")
p.add_argument("--production", action="store_true", help="Exclude headless test tools and drivers")
args = p.parse_args()
root = args.work / "sysroot"
runtime = args.work / ("runtime-production" if args.production else "runtime")
if args.production and runtime.exists():
    if runtime.is_symlink() or runtime.resolve().parent != args.work.resolve():
        raise RuntimeError("Unsafe production runtime directory")
    shutil.rmtree(runtime)
lib = runtime / "lib"
lib.mkdir(parents=True, exist_ok=True)
board = set(args.board_libraries.read_text(encoding="utf-8-sig").splitlines())
library_dirs = [root / "usr/lib/aarch64-linux-gnu", root / "lib/aarch64-linux-gnu",
                root / "usr/lib/aarch64-linux-gnu/weston"]
compositor = args.compositor_root
if compositor:
    library_dirs[0:0] = [compositor / "lib", compositor / "lib/weston"]
readelf = shlex.split(os.environ.get("NXP_READELF", "aarch64-linux-gnu-readelf"))
files = []
def copy_file(src, dest):
    dest.parent.mkdir(parents=True, exist_ok=True)
    shutil.copyfile(src, dest)
    shutil.copymode(src, dest)
    files.append(dest)

copy_file(args.work / "build-qopenhd-native/release/QOpenHD", runtime / "QOpenHD")
if args.production and not compositor:
    raise RuntimeError("Production bundles require a source-built compositor")
if args.production:
    shutil.rmtree(runtime / "tests", ignore_errors=True)
copy_file(compositor / "weston" if compositor else root / "usr/bin/weston", runtime / "weston")
for subtree, destination in [("usr/lib/aarch64-linux-gnu/qt5/plugins", "plugins"),
                             ("usr/lib/aarch64-linux-gnu/qt5/qml", "qml"),
                             ("usr/lib/aarch64-linux-gnu/libweston-9", "libweston-9"),
                             ("usr/lib/aarch64-linux-gnu/weston", "weston-modules")]:
    source = root / subtree
    if compositor and destination in ("libweston-9", "weston-modules"):
        source = compositor / ("lib/libweston-9" if destination == "libweston-9" else "lib/weston")
    if source.exists():
        target = runtime / destination
        if destination in ("libweston-9", "weston-modules"):
            shutil.rmtree(target, ignore_errors=True)
            target.mkdir(parents=True)
            selected = ["kiosk-shell.so"] if destination == "weston-modules" else ["drm-backend.so", "gl-renderer.so"]
            if destination == "libweston-9" and not args.production:
                selected.append("headless-backend.so")
            for name in selected:
                copy_file(source / name, target / name)
        else:
            shutil.copytree(source, target, dirs_exist_ok=True)
        files.extend(f for f in (runtime / destination).rglob("*") if f.is_file())

# Do not ship plugins unrelated to this port or load media-framework plugins.
for unwanted in ["mediaservice", "audio", "texttospeech", "bearer", "xcbglintegrations"]:
    shutil.rmtree(runtime / "plugins" / unwanted, ignore_errors=True)
if args.production:
    allowed = {"platforms", "imageformats", "iconengines", "platforminputcontexts",
               "geoservices", "position", "generic", "wayland-decoration-client",
               "wayland-shell-integration", "wayland-graphics-integration-client"}
    for directory in (runtime / "plugins").iterdir():
        if directory.is_dir() and directory.name not in allowed:
            shutil.rmtree(directory)
files = [f for f in files if f.exists()]
done = set()
while files:
    f = files.pop()
    if f in done:
        continue
    done.add(f)
    result = subprocess.run([*readelf, "-d", str(f)], capture_output=True, text=True)
    for name in re.findall(r"\(NEEDED\).*?\[(.*?)\]", result.stdout):
        if name.startswith(("libavcodec", "libavformat", "libavutil", "libgst")):
            raise RuntimeError(f"Forbidden runtime dependency: {f}: {name}")
        # Bundle the compositor we built even when an older system copy exists.
        own_compositor = name.startswith(("libweston-9", "libweston-desktop-9", "libexec_weston"))
        if name in board and not own_compositor:
            continue
        if (lib / name).exists():
            if lib / name not in done:
                files.append(lib / name)
            continue
        source = next((d / name for d in library_dirs if (d / name).exists()), None)
        if source is None:
            raise RuntimeError(f"Unresolved dependency {name} from {f}")
        copy_file(source, lib / name)

(runtime / "qt.conf").write_text("[Paths]\nPrefix=.\nPlugins=plugins\nQml2Imports=qml\n")
shutil.copytree(root / "usr/share/X11/xkb", runtime / "xkb", dirs_exist_ok=True)
shutil.copyfile(Path(__file__).with_name("nxp-run-qopenhd.sh"), runtime / "run-qopenhd.sh")
shutil.copyfile(Path(__file__).with_name("nxp-run-weston.sh"), runtime / "run-weston.sh")
repo = Path(__file__).resolve().parent.parent
shutil.copytree(repo / "deployment/nxp", runtime / "profiles", dirs_exist_ok=True)
for name in ([] if args.production else ["nxp-decode-probe", "nxp-drm-probe", "nxp-headless-egl-device.so"]):
    source = args.work / "build" / name
    if source.exists():
        copy_file(source, runtime / "tests" / name)
if compositor:
    shutil.copytree(compositor / "share/licenses", runtime / "licenses/compositor", dirs_exist_ok=True)
for copyright_file in (root / "usr/share/doc").glob("*/copyright"):
    if copyright_file.is_file():
        target = runtime / "licenses/debian" / copyright_file.parent.name / "copyright"
        target.parent.mkdir(parents=True, exist_ok=True)
        shutil.copyfile(copyright_file, target)
print(f"Runtime: {runtime}")
