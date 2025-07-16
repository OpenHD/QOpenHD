#!/bin/bash
set -euo pipefail

GST_VERSION="1.20.7"
CERBERO_DIR="$HOME/cerbero"
BUILD_ARCH="arm64"
INSTALL_DIR="$PWD/lib/gstreamer_prebuilts/$BUILD_ARCH"

if [[ $# -lt 1 ]]; then
    echo "[ERROR] NDK path not provided!"
    exit 1
fi

NDK_PATH="$1"

echo "[INFO] Using NDK path: $NDK_PATH"
echo "[INFO] Cloning Cerbero into $CERBERO_DIR..."
rm -rf "$CERBERO_DIR"
git clone --depth=1 https://gitlab.freedesktop.org/gstreamer/cerbero.git "$CERBERO_DIR"

echo "[INFO] Installing required Python package..."
pip3 install --user distro

echo "[INFO] Bootstrapping Cerbero with --ndk-path..."
cd "$CERBERO_DIR"
./cerbero-uninstalled bootstrap --ndk-path "$NDK_PATH"

echo "[INFO] Building GStreamer $GST_VERSION for Android ($BUILD_ARCH)..."
./cerbero-uninstalled -c config/cross-android-$BUILD_ARCH.cbc package gstreamer-1.0

echo "[INFO] Installing built headers and libs to: $INSTALL_DIR"
rm -rf "$INSTALL_DIR"
mkdir -p "$INSTALL_DIR"

cp -rv build/dist/android_$BUILD_ARCH/include "$INSTALL_DIR"
cp -rv build/dist/android_$BUILD_ARCH/lib "$INSTALL_DIR"

echo "[DEBUG] Looking for 'gst/gstelement.h'..."
find "$INSTALL_DIR" -name gstelement.h || echo "[WARNING] Not found!"

echo "[INFO] Final install location: $INSTALL_DIR"
echo "[INFO] Contents of include/gstreamer-1.0:"
ls -a "$INSTALL_DIR/include/gstreamer-1.0" || echo "[ERROR] include/gstreamer-1.0 not found"
