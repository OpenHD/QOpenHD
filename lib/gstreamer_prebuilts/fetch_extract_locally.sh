#!/bin/bash
set -e

wget --quiet https://gstreamer.freedesktop.org/data/pkg/android/1.20.7/gstreamer-1.0-android-universal-1.20.7.tar.xz

tar xvf gstreamer-1.0-android-universal-1.20.7.tar.xz

ls

cp -rv gstreamer-1.0-android-universal_pre/* .