#!/bin/bash
# Called by OpenHD's canonical ORQA job; no duplicate private SDK credentials.
set -euo pipefail
sdk_root=$(realpath "${1:?Usage: build_orqa_bundle.sh SDK_ROOT OUTPUT_DIR}")
output=$(realpath -m "${2:?Usage: build_orqa_bundle.sh SDK_ROOT OUTPUT_DIR}")
repo=$(cd "$(dirname "$0")/.." && pwd)
host_python=$(command -v python3)
host_path=$PATH
setup="$sdk_root/environment-setup-armv8a-poky-linux"
test -f "$setup"
# The SDK is sourced in a child, preserving the host's Python/Qt build tools.
env_file=$(mktemp)
trap 'rm -f "$env_file"' EXIT
bash -c 'source "$1"; "$2" - "$3" <<"PY"
import json, os, sys
json.dump({k: os.environ[k] for k in ["SDKTARGETSYSROOT","CC","CXX","AR","STRIP","READELF","PATH"]}, open(sys.argv[1],"w"))
PY' -- "$setup" "$host_python" "$env_file"
read_env() { "$host_python" -c 'import json,sys; print(json.load(open(sys.argv[1]))[sys.argv[2]])' "$env_file" "$1"; }
export NXP_SYSROOT=$(read_env SDKTARGETSYSROOT)
export NXP_CC=$(read_env CC) NXP_CXX=$(read_env CXX) NXP_AR=$(read_env AR)
export NXP_STRIP=$(read_env STRIP) NXP_READELF=$(read_env READELF)
export PATH="$host_path:$(read_env PATH)"
export NXP_VERSION="nxp-$(git -C "$repo" rev-parse --short=12 HEAD)"
work="$output/work"
mkdir -p "$work" "$output/deploy/usr/local/share"
for header in imxvpuapi2/imxvpuapi2.h imxdmabuffer/imxdmabuffer.h; do
    test -s "$NXP_SYSROOT/usr/include/$header"
done
bash "$repo/tools/nxp-prepare-qt-sysroot.sh" "$work"
bash "$repo/tools/nxp-cross-build.sh" "$work"
bash "$repo/tools/nxp-build-compositor.sh" "$work"

# Keep only the BSP/standard-C runtime external. Other dependencies travel in
# the isolated UI runtime even if the development SDK happens to contain them.
"$host_python" - "$NXP_SYSROOT" "$work/board-libraries.txt" <<'PY'
import re, sys
from pathlib import Path
root = Path(sys.argv[1])
native = re.compile(r'^(ld-linux|lib(c\.|m\.|dl\.|rt\.|pthread\.|util\.|anl\.|resolv\.|stdc\+\+\.|gcc_s\.|EGL\.|GLESv|gbm\.|gbm_viv\.|GAL\.|drm\.|wayland-))')
names = {p.name for d in ['lib','usr/lib'] for p in (root/d).glob('*') if native.match(p.name)}
Path(sys.argv[2]).write_text('\n'.join(sorted(names))+'\n')
PY
"$host_python" "$repo/tools/nxp-package-runtime.py" --work "$work" \
    --board-libraries "$work/board-libraries.txt" --production \
    --compositor-root "$work/compositor/stage/usr/local/share/qopenhd-nxp"
runtime="$output/deploy/usr/local/share/qopenhd-nxp"
mkdir -p "$runtime"
cp -a "$work/runtime-production/." "$runtime/"
# Shell scripts and profiles are data in git; explicitly install executables.
chmod 0755 "$runtime/QOpenHD" "$runtime/weston" "$runtime/run-qopenhd.sh" "$runtime/run-weston.sh"
for binary in "$runtime/QOpenHD" "$runtime/weston"; do
    "$NXP_READELF" -h "$binary" | grep -q 'Machine:.*AArch64'
    "$NXP_STRIP" --strip-unneeded "$binary"
done
mkdir -p "$output/deploy/usr/lib/systemd/system" "$output/deploy/etc/qopenhd-nxp"
install -m 0644 "$repo/deployment/nxp/qopenhd.service" "$output/deploy/usr/lib/systemd/system/"
install -m 0644 "$repo/deployment/nxp/qopenhd-nxp-compositor.service" "$output/deploy/usr/lib/systemd/system/"
install -m 0644 "$repo/deployment/nxp/weston-preferred.ini" "$output/deploy/etc/qopenhd-nxp/weston.ini"
"$host_python" - "$repo" "$runtime" <<'PY'
import hashlib, json, subprocess, sys
from pathlib import Path
repo, runtime = map(Path, sys.argv[1:])
manifest = dict(schema_version=1, qopenhd_commit=subprocess.check_output(['git','-C',str(repo),'rev-parse','HEAD'],text=True).strip(),
                compositor='Weston 9.0.0 / EGL-GLES', backend='hantro-wayland-dmabuf', media_frameworks=[],
                compositor_source_sha256='5cf5d6ce192e0eb15c1fc861a436bf21b5bb3b91dbdabbdebe83e1f83aa098fe')
manifest['files'] = {p.relative_to(runtime).as_posix(): hashlib.sha256(p.read_bytes()).hexdigest()
                     for p in runtime.rglob('*') if p.is_file() and p.name != 'manifest.json'}
(runtime/'manifest.json').write_text(json.dumps(manifest, indent=2)+'\n')
PY
tar -czf "$output/qopenhd-nxp-runtime.tar.gz" -C "$output/deploy" .
echo "ORQA QOpenHD/compositor bundle: $output/qopenhd-nxp-runtime.tar.gz"
