#bin/bash

wget --quiet https://gstreamer.freedesktop.org/data/pkg/android/1.20.5/gstreamer-1.0-android-universal-1.20.5.tar.xz

# NOTE: We intentionally do not include the version in the extracted folder
mkdir -p gstreamer-1.0-android-universal

tar xf gstreamer-1.0-android-universal-1.20.5.tar.xz -C gstreamer-1.0-android-universal

ls

