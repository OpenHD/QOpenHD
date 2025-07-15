#!/bin/bash
set -euo pipefail

GST_VERSION="1.20.7"
CERBERO_DIR="$HOME/cerbero"
BUILD_ARCH="arm64"
INSTALL_DIR="$PWD/lib/gstreamer_prebuilts/$BUILD_ARCH"

echo "[INFO] Cloning Cerbero..."
git clone --depth=1 https://gitlab.freedesktop.org/gstreamer/cerbero.git "$CERBERO_DIR"
pip3 install --user distro

echo "[INFO] Bootstrapping Cerbero..."
cd "$CERBERO_DIR"
./cerbero-uninstalled bootstrap

echo "[INFO] Building GStreamer ${GST_VERSION} for Android ($BUILD_ARCH)..."
./cerbero-uninstalled -c config/cross-android-$BUILD_ARCH.cbc package gstreamer-1.0

# Optional: remove old directory first
rm -rf "$INSTALL_DIR"
mkdir -p "$INSTALL_DIR"

echo "[INFO] Copying GStreamer headers and libraries to: $INSTALL_DIR"
cp -rv build/dist/android_$BUILD_ARCH/include "$INSTALL_DIR"
cp -rv build/dist/android_$BUILD_ARCH/lib "$INSTALL_DIR"

echo "[DEBUG] Looking for all 'gst/gstelement.h' headers..."
find "$INSTALL_DIR" -name gstelement.h || echo "[WARNING] No gstelement.h found!"

echo "[INFO] Final install location: $INSTALL_DIR"
echo "[INFO] Contents of include/gstreamer-1.0:"
ls -a "$INSTALL_DIR/include/gstreamer-1.0" || echo "[ERROR] include/gstreamer-1.0 not found"
