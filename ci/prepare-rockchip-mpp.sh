#!/usr/bin/env bash
# Same pinned upstream MPP revision as OpenHD's canonical ARM64 sysroot builder.
set -euo pipefail
sysroot=${1:?}; work=${2:?}; cc=${3:?}; cxx=${4:?}
triplet=aarch64-linux-gnu
test -f "$sysroot/usr/lib/$triplet/crt1.o"
test -f "$sysroot/usr/lib/$triplet/crti.o"
commit=2e93ab791e0b2c803022622c30fea79b80450830
source="$work/mpp-$commit"
build="$work/build-mpp-$commit"
if [[ ! -d "$source" ]]; then
    mkdir -p "$source"
    curl --fail --location --retry 4 "https://codeload.github.com/rockchip-linux/mpp/tar.gz/$commit" | tar -xz --strip-components=1 -C "$source"
fi
cmake -S "$source" -B "$build" -DCMAKE_SYSTEM_NAME=Linux -DCMAKE_SYSTEM_PROCESSOR=aarch64 \
    -DCMAKE_SYSROOT="$sysroot" -DCMAKE_C_COMPILER="$cc" -DCMAKE_CXX_COMPILER="$cxx" \
    -DCMAKE_C_FLAGS="-B$sysroot/usr/lib/$triplet -isystem $sysroot/usr/include/$triplet" \
    -DCMAKE_CXX_FLAGS="-B$sysroot/usr/lib/$triplet -isystem $sysroot/usr/include/$triplet" \
    -DCMAKE_EXE_LINKER_FLAGS="-L$sysroot/usr/lib/$triplet -Wl,-rpath-link,$sysroot/usr/lib/$triplet" \
    -DCMAKE_SHARED_LINKER_FLAGS="-L$sysroot/usr/lib/$triplet -Wl,-rpath-link,$sysroot/usr/lib/$triplet" \
    -DCMAKE_INSTALL_PREFIX=/usr -DCMAKE_BUILD_TYPE=Release -DBUILD_TEST=OFF -DBUILD_SHARED_LIBS=ON
cmake --build "$build" --parallel "${BUILD_JOBS:-4}"
DESTDIR="$sysroot" cmake --install "$build"
test -f "$sysroot/usr/include/rockchip/rk_mpi.h"
