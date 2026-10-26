#!/bin/bash
set -euo pipefail
repo=$(cd "$(dirname "$0")/.." && pwd)
work=${1:-/home/damien/qopenhd-nxp}
sdk=${NXP_SYSROOT:-/home/damien/orqa-sysroot}
cross_cc=${NXP_CC:-aarch64-linux-gnu-gcc}
cross_cxx=${NXP_CXX:-aarch64-linux-gnu-g++}
cross_ar=${NXP_AR:-aarch64-linux-gnu-ar}
qt="$work/sysroot"
export PATH="$work/hosttools/usr/lib/qt5/bin:$PATH"
revision=$(git -C "$repo" rev-parse HEAD)
# qmake dependency scans on Windows-mounted source trees are extremely slow.
# Stage only build inputs on the Linux filesystem; leave the checkout untouched.
mkdir -p "$work/source"
if [[ ${NXP_SKIP_STAGE:-0} != 1 ]]; then
    rsync -a --exclude=.git --exclude=gstreamer_prebuilts --exclude='*.o' --exclude='*.so*' \
        "$repo/app" "$repo/qml" "$repo/lib" "$repo/translations" "$repo/icons" "$work/source/"
fi
cp "$repo"/*.pri "$repo"/*.pro "$work/source/"
repo="$work/source"
mkdir -p "$work/build-qopenhd-native"
cat > "$work/qt.conf" <<EOF
[Paths]
Prefix=$qt/usr
Headers=include/aarch64-linux-gnu/qt5
Libraries=lib/aarch64-linux-gnu
ArchData=lib/aarch64-linux-gnu/qt5
Data=share/qt5
HostPrefix=/usr
HostBinaries=lib/qt5/bin
HostData=$qt/usr/lib/aarch64-linux-gnu/qt5
EOF
export PKG_CONFIG_SYSROOT_DIR="$qt"
export PKG_CONFIG_LIBDIR="$qt/usr/lib/aarch64-linux-gnu/pkgconfig:$qt/usr/share/pkgconfig"
cd "$work/build-qopenhd-native"
/usr/lib/qt5/bin/qmake -qtconf "$work/qt.conf" "$repo/QOpenHD.pro" \
    CONFIG+=nxp_native CONFIG+=release CONFIG-=ltcg \
    "QOPENHD_GIT_VERSION=${NXP_VERSION:-nxp-port-dev}" "QOPENHD_GIT_COMMIT_HASH=$revision" \
    "QMAKE_CC=$cross_cc" "QMAKE_CXX=$cross_cxx" \
    "QMAKE_LINK=$cross_cxx" "QMAKE_AR=$cross_ar cqs" \
    "QMAKE_CFLAGS+=--sysroot=$sdk -idirafter $qt/usr/include" "QMAKE_CXXFLAGS+=--sysroot=$sdk -idirafter $qt/usr/include" \
    "QMAKE_LFLAGS+=--sysroot=$sdk -L$sdk/usr/lib -L$qt/usr/lib/aarch64-linux-gnu -Wl,-rpath-link,$sdk/usr/lib -Wl,-rpath-link,$sdk/lib -Wl,-rpath-link,$qt/usr/lib/aarch64-linux-gnu -Wl,-rpath-link,$qt/lib/aarch64-linux-gnu" \
    "WAYLAND_PROTOCOLS_DIR=$qt/usr/share/wayland-protocols"
make -j"${NXP_JOBS:-4}" > "$work/qopenhd-build.log" 2>&1 || { tail -80 "$work/qopenhd-build.log"; exit 1; }
echo "Built: $work/build-qopenhd-native/release/QOpenHD"
