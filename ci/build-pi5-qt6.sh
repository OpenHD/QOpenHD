#!/bin/bash
# Runs in pi5-qt6.Dockerfile with /source, /target, /sysutils and /work mounted.
set -euo pipefail
exec 9>/work/native-build.lock
flock 9
export PKG_CONFIG_SYSROOT_DIR=/target
export PKG_CONFIG_LIBDIR=/target/usr/lib/aarch64-linux-gnu/pkgconfig:/target/usr/share/pkgconfig
export PKG_CONFIG_PATH=
export QT_HOST_PATH=/usr
cat > /work/pi5-toolchain.cmake <<'EOF'
set(CMAKE_SYSTEM_NAME Linux)
set(CMAKE_SYSTEM_PROCESSOR aarch64)
set(CMAKE_C_COMPILER aarch64-linux-gnu-gcc)
set(CMAKE_CXX_COMPILER aarch64-linux-gnu-g++)
set(CMAKE_SYSROOT /target)
set(CMAKE_FIND_ROOT_PATH /target)
set(CMAKE_FIND_ROOT_PATH_MODE_PROGRAM NEVER)
set(CMAKE_FIND_ROOT_PATH_MODE_LIBRARY ONLY)
set(CMAKE_FIND_ROOT_PATH_MODE_INCLUDE ONLY)
set(CMAKE_FIND_ROOT_PATH_MODE_PACKAGE ONLY)
EOF
cmake -S /source -B /work/qt6-build -G Ninja \
    -DCMAKE_TOOLCHAIN_FILE=/work/pi5-toolchain.cmake -DCMAKE_BUILD_TYPE=Release \
    -DQT_HOST_PATH=/usr -DQOPENHD_RPI_NATIVE=ON \
    -DQt6CoreTools_DIR=/usr/lib/x86_64-linux-gnu/cmake/Qt6CoreTools \
    -DQt6QmlTools_DIR=/usr/lib/x86_64-linux-gnu/cmake/Qt6QmlTools \
    -DQt6QuickTools_DIR=/usr/lib/x86_64-linux-gnu/cmake/Qt6QuickTools \
    -DQt6LinguistTools_DIR=/usr/lib/x86_64-linux-gnu/cmake/Qt6LinguistTools \
    -DQt6ShaderToolsTools_DIR=/usr/lib/x86_64-linux-gnu/cmake/Qt6ShaderToolsTools
cmake --build /work/qt6-build --target QOpenHDApp -j"${BUILD_JOBS:-4}"
cmake -S /sysutils -B /work/sysutils-build -G Ninja \
    -DCMAKE_TOOLCHAIN_FILE=/work/pi5-toolchain.cmake -DCMAKE_BUILD_TYPE=Release \
    -DBUILD_TESTING=OFF
cmake --build /work/sysutils-build -j"${BUILD_JOBS:-4}"
NXP_SYSROOT=/target NATIVE_COMPOSITOR_TARGET=rpi NXP_JOBS="${BUILD_JOBS:-4}" \
    bash /source/tools/nxp-build-compositor.sh /work
mkdir -p /work/runtime
cp -a /work/compositor/stage/usr/local/share/qopenhd-rpi/. /work/runtime/
install -m755 /work/qt6-build/QOpenHD /work/runtime/QOpenHD
install -m755 /source/deployment/rpi/run-*.sh /work/runtime/
aarch64-linux-gnu-readelf -d /work/runtime/QOpenHD | tee /work/qt6-dynamic.txt
grep -q 'libQt6Core.so.6' /work/qt6-dynamic.txt
if grep -q 'libQt5' /work/qt6-dynamic.txt; then
    echo 'Unexpected Qt 5 dependency in the Pi 5 Qt 6 binary' >&2
    exit 1
fi
sha256sum /work/runtime/QOpenHD /work/runtime/weston > /work/runtime/SHA256SUMS
