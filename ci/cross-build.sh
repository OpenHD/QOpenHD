#!/usr/bin/env bash
# Adapted from buldo/qopenhd-cross-build-experiment, commit 29ee7d1f4375a0bbb22380f04da553dbeb5358c6.
# Host Qt tools + an extracted target sysroot: no target executables or QEMU.
set -euo pipefail

source_dir=$(cd "$(dirname "$0")/.." && pwd)
target=${1:?Specify pi-bullseye-armhf, pi-bookworm-arm64, or rock-bookworm-arm64}
work=${QOPENHD_CROSS_WORK:-"$source_dir/.cross-build"}
jobs=${BUILD_JOBS:-$(nproc)}
qt_version=5.15.4
case "$target" in
  pi-bullseye-armhf)
    arch=armhf; triplet=arm-linux-gnueabihf; release=bullseye; distro=raspbian
    bootlin_arch=armv7-eabihf; compiler=arm-buildroot-linux-gnueabihf
    qt_prefix=/opt/Qt5.15.4
    qt_deps=openhd-qt
    ;;
  pi-bookworm-arm64|rock-bookworm-arm64)
    arch=arm64; triplet=aarch64-linux-gnu; release=bookworm
    bootlin_arch=aarch64; compiler=aarch64-buildroot-linux-gnu
    distro=debian; [[ "$target" == pi-* ]] && distro=raspbian
    qt_prefix=/usr
    qt_deps=qtbase5-dev,qtbase5-private-dev,qtdeclarative5-dev,qttools5-dev,qttools5-dev-tools,qtmultimedia5-dev,qtpositioning5-dev,libqt5charts5-dev,libqt5texttospeech5-dev
    ;;
  *) echo "Unsupported cross target: $target" >&2; exit 2 ;;
esac
mkdir -p "$work"
work=$(cd "$work" && pwd)
sysroot="$work/sysroot-$target"
gcc="$work/gcc-$arch"
host_qt="$work/qt-host-$qt_version"
tools="$work/qt-cross-$target"
build="$work/build-$target"

download() {
  local url=$1 dest=$2
  if [[ ! -s "$dest" ]]; then
    curl --fail --location --retry 3 "$url" -o "$dest.partial"
    mv "$dest.partial" "$dest"
  fi
}

if [[ ! -x "$gcc/bin/$compiler-g++" ]]; then
  name="$bootlin_arch--glibc--bleeding-edge-2020.08-1.tar.bz2"
  download "https://toolchains.bootlin.com/downloads/releases/toolchains/$bootlin_arch/tarballs/$name" "$work/$name"
  mkdir -p "$gcc"
  tar -xf "$work/$name" -C "$gcc" --strip-components=1
fi

if [[ ! -f "$sysroot/.complete" ]]; then
  sources="$work/$target.sources.list"
  keys="$work/keys"
  mkdir -p "$keys"
  if [[ "$arch" == armhf ]]; then
    download https://archive.raspbian.org/raspbian.public.key "$keys/raspbian.asc"
    download https://archive.raspberrypi.org/debian/raspberrypi.gpg.key "$keys/raspberrypi.asc"
    download https://dl.cloudsmith.io/public/openhd/release/gpg.key "$keys/openhd.asc"
    for key in raspbian raspberrypi openhd; do
      gpg --batch --yes --dearmor -o "$keys/$key.gpg" "$keys/$key.asc"
    done
    cat > "$sources" <<EOF
deb http://raspbian.raspberrypi.org/raspbian/ bullseye main contrib non-free rpi
deb http://archive.raspberrypi.org/debian/ bullseye main
deb https://dl.cloudsmith.io/public/openhd/release/deb/raspbian bullseye main
EOF
  else
    # Ubuntu 22.04's archive keyring predates Bookworm's signing keys.
    download https://ftp-master.debian.org/keys/archive-key-12.asc "$keys/debian.asc"
    download https://ftp-master.debian.org/keys/archive-key-12-security.asc "$keys/debian-security.asc"
    cat "$keys/debian.asc" "$keys/debian-security.asc" | \
      gpg --batch --yes --dearmor -o "$keys/debian.gpg"
    cat > "$sources" <<EOF
deb https://deb.debian.org/debian bookworm main
deb https://deb.debian.org/debian bookworm-updates main
deb https://security.debian.org/debian-security bookworm-security main
EOF
  fi
  deps="$qt_deps,libc6-dev,libavcodec-dev,libavformat-dev,libavutil-dev,libgstreamer1.0-dev,libgstreamer-plugins-base1.0-dev,libdrm-dev,libgles-dev,libegl-dev"
  # extract performs package extraction only, without running foreign maintainer scripts.
  sudo mmdebstrap --mode=root --architectures="$arch" --variant=extract \
    --keyring="$keys" \
    --aptopt='Acquire::ForceIPv4 "true"' --include="$deps" \
    "$release" "$work/sysroot-$target.tar" "$sources"
  mkdir -p "$sysroot"
  sudo tar --exclude=./dev -xf "$work/sysroot-$target.tar" -C "$sysroot"
  sudo chown -R "$(id -u):$(id -g)" "$sysroot"
  python3 "$source_dir/ci/relativize-sysroot.py" "$sysroot"
  touch "$sysroot/.complete"
fi

# Build native tools once, matching the custom Pi Qt kit. The same Qt 5.15
# tools work with the distro Qt 5.15 kits; target libraries always come from
# their own sysroot, never the host Qt build.
if [[ ! -f "$host_qt/.complete" ]]; then
  name="qt-everywhere-opensource-src-$qt_version.tar.xz"
  download "https://download.qt.io/archive/qt/5.15/$qt_version/single/$name" "$work/$name"
  qt_source="$work/qt-everywhere-src-$qt_version"
  if [[ ! -x "$qt_source/configure" ]]; then tar -xf "$work/$name" -C "$work"; fi
  python3 - "$qt_source/qtbase/src/corelib/text/qbytearraymatcher.h" <<'PY'
import pathlib, sys
p = pathlib.Path(sys.argv[1])
s = p.read_text()
if '#include <limits>' not in s:
    p.write_text(s.replace('#include <QtCore/qbytearray.h>', '#include <QtCore/qbytearray.h>\n#include <limits>'))
PY
  (
    cd "$qt_source"
    ./configure -prefix "$host_qt" -opensource -confirm-license -release \
      -optimize-size -nomake examples -nomake tests -no-gui -no-widgets \
      -no-dbus -no-opengl -no-openssl -no-icu -qt-pcre -qt-zlib \
      -qt-doubleconversion -static
    make -j"$jobs" module-qtbase-qmake_all
    make -j"$jobs" -C qtbase/src sub-bootstrap
    make -j"$jobs" -C qtbase/src sub-moc sub-rcc
    make -j"$jobs" -C qtbase/src sub-corelib sub-xml
    (cd qttools; ../qtbase/bin/qmake)
    (cd qttools/src/linguist/lrelease; ../../../../qtbase/bin/qmake; make -j"$jobs")
    (cd qtdeclarative/src/qmltyperegistrar; ../../../qtbase/bin/qmake; make -j"$jobs")
    make -C qtbase/src/tools/moc install
    make -C qtbase/src/tools/rcc install
    make -C qttools/src/linguist/lrelease install
    make -C qtdeclarative/src/qmltyperegistrar install
    cp qtbase/bin/qmake "$host_qt/bin/"
    cp -a qtbase/mkspecs "$host_qt/"
    rm -f "$host_qt/mkspecs/"{qconfig.pri,qmodule.pri,qdevice.pri}
  )
  touch "$host_qt/.complete"
fi


qt_data="$sysroot$qt_prefix"
if [[ "$qt_prefix" == /usr ]]; then qt_data="$sysroot/usr/lib/$triplet/qt5"; fi
test -f "$qt_data/mkspecs/qconfig.pri"
grep -Eq '^QT_VERSION *= *5\.15\.' "$qt_data/mkspecs/qconfig.pri"
mkdir -p "$tools/bin" "$build"
for tool in qmake moc rcc lrelease qmltyperegistrar; do
  cp "$host_qt/bin/$tool" "$tools/bin/"
done
cat > "$tools/bin/qt.conf" <<EOF
[Paths]
Sysroot=$sysroot
SysrootifyPrefix=true
Prefix=$qt_prefix
HostPrefix=$tools
HostData=$qt_data
HostBinaries=$tools/bin
EOF
if [[ "$qt_prefix" == /usr ]]; then
  cat >> "$tools/bin/qt.conf" <<EOF
Headers=include/$triplet/qt5
Libraries=lib/$triplet
ArchData=lib/$triplet/qt5
Plugins=lib/$triplet/qt5/plugins
Qml=lib/$triplet/qt5/qml
EOF
fi
spec="$qt_data/mkspecs/devices/linux-rpi4-v3d-g++"
mkdir -p "$spec"
cat > "$spec/qmake.conf" <<EOF
CROSS_COMPILE = $gcc/bin/$compiler-
include(../common/linux_device_pre.conf)
QMAKE_LIBS_EGL += -lEGL
QMAKE_LIBS_OPENGL_ES2 += -lGLESv2 -lEGL
QMAKE_CFLAGS += --sysroot=\$\$[QT_SYSROOT]
QMAKE_CXXFLAGS += --sysroot=\$\$[QT_SYSROOT]
QMAKE_LFLAGS += --sysroot=\$\$[QT_SYSROOT] -B\$\$[QT_SYSROOT]/usr/lib/$triplet
QMAKE_LFLAGS += -L\$\$[QT_SYSROOT]/usr/lib/$triplet -L\$\$[QT_SYSROOT]/lib/$triplet
DISTRO_OPTS += deb-multi-arch
EOF
if [[ "$arch" == armhf ]]; then
  cat >> "$spec/qmake.conf" <<'EOF'
DISTRO_OPTS += hard-float
include(../common/linux_arm_device_post.conf)
EOF
else
  # ARM64 does not accept the ARM32 hard-float flags from linux_arm_device_post.
  cat >> "$spec/qmake.conf" <<'EOF'
include(../common/linux_device_post.conf)
EOF
fi
cat >> "$spec/qmake.conf" <<'EOF'
EGLFS_DEVICE_INTEGRATION = eglfs_kms
QMAKE_PKG_CONFIG = pkg-config
load(qt_config)
EOF
echo '#include "../../linux-g++/qplatformdefs.h"' > "$spec/qplatformdefs.h"
export PATH="$tools/bin:$gcc/bin:$PATH"
export PKG_CONFIG_SYSROOT_DIR="$sysroot"
export PKG_CONFIG_LIBDIR="$sysroot/usr/lib/$triplet/pkgconfig:$sysroot/usr/lib/pkgconfig:$sysroot/usr/share/pkgconfig"
unset PKG_CONFIG_PATH
(
  cd "$build"
  platform_define=IS_PLATFORM_ROCK
  [[ "$target" == pi-* ]] && platform_define=IS_PLATFORM_RPI
  qmake "$source_dir/QOpenHD.pro" -spec devices/linux-rpi4-v3d-g++ CONFIG+=release "DEFINES+=$platform_define"
  make -j"$jobs"
)
binary="$build/release/QOpenHD"
test -x "$binary"
"$gcc/bin/$compiler-readelf" -h "$binary" | tee "$build/elf-header.txt"
if [[ "$arch" == armhf ]]; then
  grep -q 'Machine:.*ARM$' "$build/elf-header.txt"
else
  grep -q 'Machine:.*AArch64' "$build/elf-header.txt"
fi
"$gcc/bin/$compiler-readelf" -d "$binary" > "$build/elf-dynamic.txt"
"$gcc/bin/$compiler-readelf" --version-info "$binary" > "$build/elf-versions.txt"
(
  cd "$source_dir"
  PREBUILT_QOPENHD="$binary" bash ./package.sh standard "$arch" "$distro" "$release"
)
