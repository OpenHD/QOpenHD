#bin/bash

# build and install mavsk locally such that you can develop QOpenHD

cd lib/MAVSDK
cmake -Bbuild/default -DCMAKE_BUILD_TYPE=Release -H.
cmake --build build/default -j4
sudo cmake --build build/default --target install
sudo ldconfig

ls /usr/local/include/mavsdk
ls /usr/local/lib
