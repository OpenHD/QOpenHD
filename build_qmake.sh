#!/bin/bash

set -euo pipefail

# Ensure submodules are available for the build
if [ ! -d "lib/mavlink-headers" ]; then
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

