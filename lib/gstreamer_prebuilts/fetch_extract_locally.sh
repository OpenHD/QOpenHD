#!/bin/bash
set -euo pipefail

GST_VERSION="1.20.7"
GST_ARCHIVE="gstreamer-1.0-android-universal-${GST_VERSION}.tar.xz"
GST_URL="https://gstreamer.freedesktop.org/data/pkg/android/${GST_VERSION}/${GST_ARCHIVE}"
GST_DIR="gstreamer-1.0-android-universal-${GST_VERSION}"

echo "[INFO] Downloading GStreamer ${GST_VERSION} for Android (Universal)..."
wget -q --show-progress "${GST_URL}" || {
  echo "[ERROR] Failed to download GStreamer archive."; exit 1;
}

echo "[INFO] Extracting ${GST_ARCHIVE}..."
tar -xf "${GST_ARCHIVE}" || {
  echo "[ERROR] Failed to extract GStreamer archive."; exit 1;
}

echo "[INFO] Copying precompiled GStreamer libraries and includes..."
cp -rv "${GST_DIR}_pre/"* . || {
  echo "[ERROR] Failed to copy precompiled GStreamer files."; exit 1;
}

echo "[INFO] Directory layout after copy:"
tree . || ls -R .

echo "[DEBUG] Looking for 'gst/gstelement.h'..."
FOUND_HEADER=$(find . -name gstelement.h | head -n 1 || true)
if [[ -n "${FOUND_HEADER}" ]]; then
  echo "[OK] Found gstelement.h at: ${FOUND_HEADER}"
else
  echo "[WARNING] 'gst/gstelement.h' not found! Check include path configuration."
fi

echo
echo "[TIP] For Android ARM64 (aarch64), headers are usually here:"
echo "    ./android/aarch64/include/gst/gstelement.h"
echo "[TIP] Add this to your build includes if needed:"
echo "    -I/path/to/gstreamer/android/aarch64/include"
