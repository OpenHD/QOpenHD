#!/bin/bash
# Source-build the same Weston GL compositor used by the native NXP port.
set -euo pipefail
work=${1:?Usage: nxp-build-compositor.sh WORKDIR}
sdk=${NXP_SYSROOT:?Set NXP_SYSROOT to the matching NXP target sysroot}
qt="$work/sysroot"
version=9.0.0
sha=5cf5d6ce192e0eb15c1fc861a436bf21b5bb3b91dbdabbdebe83e1f83aa098fe
mkdir -p "$work/compositor"
archive="$work/compositor/weston-$version.tar.xz"
if [[ ! -f $archive ]]; then
    curl --fail --location --retry 4 "https://wayland.freedesktop.org/releases/weston-$version.tar.xz" -o "$archive"
fi
echo "$sha  $archive" | sha256sum -c -
if [[ ! -d $work/compositor/weston-$version ]]; then
    tar -xf "$archive" -C "$work/compositor"
fi
export NXP_CC=${NXP_CC:-aarch64-linux-gnu-gcc}
export NXP_AR=${NXP_AR:-aarch64-linux-gnu-ar}
export NXP_STRIP=${NXP_STRIP:-aarch64-linux-gnu-strip}
export NXP_SYSROOT="$sdk" NXP_QT_SYSROOT="$qt" NXP_COMPOSITOR_WORK="$work/compositor"
mkdir -p "$work/compositor/wayland-headers"
cp "$qt"/usr/include/wayland-*.h "$work/compositor/wayland-headers/"
python3 - <<'PY'
import os, shlex
from pathlib import Path
sdk, qt = os.environ['NXP_SYSROOT'], os.environ['NXP_QT_SYSROOT']
flags = ['--sysroot='+sdk, '-I'+os.environ['NXP_COMPOSITOR_WORK']+'/wayland-headers', '-idirafter', qt+'/usr/include']
links = ['--sysroot='+sdk, '-L'+sdk+'/usr/lib', '-Wl,-rpath-link,'+sdk+'/usr/lib',
         '-Wl,-rpath-link,'+sdk+'/lib', '-Wl,-rpath-link,'+qt+'/usr/lib/aarch64-linux-gnu',
         '-Wl,-rpath-link,'+qt+'/lib/aarch64-linux-gnu']
text = '[binaries]\n'
for key, env in [('c','NXP_CC'), ('ar','NXP_AR'), ('strip','NXP_STRIP')]:
    text += key+' = '+repr(shlex.split(os.environ[env]))+'\n'
text += "pkgconfig = '/usr/bin/pkg-config'\n[host_machine]\nsystem = 'linux'\ncpu_family = 'aarch64'\ncpu = 'aarch64'\nendian = 'little'\n"
text += '[properties]\nneeds_exe_wrapper = true\nsys_root = '+repr(qt)+'\n'
text += 'pkg_config_libdir = '+repr([qt+'/usr/lib/aarch64-linux-gnu/pkgconfig', qt+'/usr/share/pkgconfig'])+'\n'
text += '[built-in options]\nc_args = '+repr(flags)+'\nc_link_args = '+repr(links)+'\n'
Path(os.environ['NXP_COMPOSITOR_WORK']+'/cross.ini').write_text(text)
PY
build="$work/compositor/build-native"
if [[ ! -f $build/build.ninja ]]; then
    meson setup "$build" "$work/compositor/weston-$version" \
        --cross-file "$work/compositor/cross.ini" --buildtype=release \
        --prefix=/usr/local/share/qopenhd-nxp --bindir=. --libdir=lib \
        -Dbackend-default=drm -Dbackend-drm=true -Dbackend-headless=true \
        -Drenderer-gl=true -Dshell-kiosk=true -Dshell-desktop=false \
        -Dshell-fullscreen=false -Dshell-ivi=false -Dbackend-rdp=false \
        -Dbackend-wayland=false -Dbackend-x11=false -Dbackend-fbdev=false \
        -Dbackend-drm-screencast-vaapi=false -Dremoting=false -Dpipewire=false \
        -Dscreenshare=false -Dxwayland=false -Dweston-launch=false \
        -Dlauncher-logind=true -Dsystemd=false -Dcolor-management-lcms=false \
        -Dcolor-management-colord=false -Dimage-jpeg=false -Dimage-webp=false \
        -Dtools=[] -Ddemo-clients=false -Dsimple-clients=[] -Dwcap-decode=false \
        -Dtest-gl-renderer=false -Dtest-junit-xml=false -Ddoc=false
fi
meson setup --reconfigure "$build" "$work/compositor/weston-$version"
# Build the deployable server/modules, not upstream target-side test clients.
ninja -C "$build" -j"${NXP_JOBS:-4}" compositor/weston kiosk-shell/kiosk-shell.so \
    libweston/renderer-gl/gl-renderer.so libweston/backend-drm/drm-backend.so \
    libweston/backend-headless/headless-backend.so
DESTDIR="$work/compositor/stage" meson install --no-rebuild -C "$build"
prefix="$work/compositor/stage/usr/local/share/qopenhd-nxp"
mkdir -p "$prefix/share/licenses/weston"
cp "$work/compositor/weston-$version/COPYING" "$prefix/share/licenses/weston/COPYING"
printf '%s\n' "Weston $version" "Source: https://wayland.freedesktop.org/releases/weston-$version.tar.xz" \
    "SHA256: $sha" > "$prefix/share/licenses/weston/SOURCE"
echo "NXP compositor built at $prefix"
