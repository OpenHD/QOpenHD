# bin/bash

# convenient script to build this project with cmake

rm -rf build

mkdir build

cd build

qmake ..

make -j4