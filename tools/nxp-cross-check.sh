#!/bin/bash
set -euo pipefail
repo=$(cd "$(dirname "$0")/.." && pwd)
work=${1:-/home/damien/qopenhd-nxp}
sdk=${NXP_SYSROOT:-/home/damien/orqa-sysroot}
mkdir -p "$work/build"
aarch64-linux-gnu-gcc --sysroot="$sdk" -shared -fPIC "$repo/tests/nxp_headless_egl_device.c" \
    -ldl -o "$work/build/nxp-headless-egl-device.so"
aarch64-linux-gnu-g++ --sysroot="$sdk" -std=c++17 \
    -I"$sdk/usr/include/libdrm" "$repo/tests/nxp_drm_probe.cpp" \
    -L"$sdk/usr/lib" -Wl,-rpath-link,"$sdk/usr/lib" -ldrm -o "$work/build/nxp-drm-probe"
aarch64-linux-gnu-g++ --sysroot="$sdk" -std=c++17 -pthread \
    -I"$sdk/usr/include" -c "$repo/app/videostreaming/nxp/HantroDecoder.cpp" -o "$work/build/HantroDecoder.o"
aarch64-linux-gnu-g++ --sysroot="$sdk" -std=c++17 -pthread \
    -I"$sdk/usr/include" -c "$repo/app/videostreaming/nxp/UdpVideo.cpp" -o "$work/build/UdpVideo.o"
aarch64-linux-gnu-g++ --sysroot="$sdk" -std=c++17 -pthread -I"$repo/app" \
    "$repo/tests/nxp_decode_probe.cpp" "$repo/app/videostreaming/nxp/VpuApi.cpp" "$work/build/HantroDecoder.o" "$work/build/UdpVideo.o" \
    -ldl -o "$work/build/nxp-decode-probe"
