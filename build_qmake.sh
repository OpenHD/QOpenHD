#!/bin/bash

set -euo pipefail

# Force Qt 5 tools when both Qt 5 and Qt 6 are installed
export QT_SELECT="${QT_SELECT:-qt5}"

# Ensure submodules are available for the build
MAVLINK_HEADER="lib/mavlink-headers/mavlink/v2.0/openhd/mavlink.h"
if [ ! -f "${MAVLINK_HEADER}" ]; then
    echo "Syncing git submodules (mavlink headers missing)..."
    git submodule update --init --recursive
fi

lupdate ./QOpenHD.pro
lrelease ./QOpenHD.pro
cp ./translations/*.qm ./qml/

rm -rf build
mkdir build
cd build
qmake ..

# Check if the OS is macOS
if [[ "$(uname)" == "Darwin" ]]; then
    make -j2
else
    make -j$(( $(nproc) / 2 ))
fi

