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

echo "Installing QOpenHD..."
if [ -f "release/QOpenHD" ]; then
    sudo cp release/QOpenHD /usr/local/bin/QOpenHD
elif [ -f "debug/QOpenHD" ]; then
    sudo cp debug/QOpenHD /usr/local/bin/QOpenHD
elif [ -f "QOpenHD" ]; then
    sudo cp QOpenHD /usr/local/bin/QOpenHD
else
    echo "Warning: QOpenHD binary not found in build directory."
    exit 0
fi

sudo chmod +x /usr/local/bin/QOpenHD
echo "QOpenHD installed to /usr/local/bin/QOpenHD"

