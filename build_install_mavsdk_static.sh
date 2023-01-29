#!/bin/bash

cd lib/MAVSDK
cmake -Bbuild/default -DBUILD_SHARED_LIBS=OFF -DCMAKE_BUILD_TYPE=Release -DBUILD_TESTS=OFF -H.
cmake --build build/default -j4
sudo cmake --build build/default --target install

# Now the static libs are installed and can be found and statically linked by qmake