#!/bin/bash

rm -rf build
mkdir build
cd build

QT6_DIRECTORY="$HOME/Qt/6.6.2/gcc_64/lib/cmake"

cmake -DCMAKE_PREFIX_PATH=$QT6_DIRECTORY ..
make -j$($(nproc))