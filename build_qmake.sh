#!/bin/bash

# Convenient script to build this project with CMake

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
