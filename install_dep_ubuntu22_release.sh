#!/usr/bin/env bash

#initial requiremends
apt install -y gnupg gnupg1 gnupg2 apt-transport-https curl apt-utils libgles2-mesa-dev libegl1-mesa-dev libgbm-dev libboost-dev libsdl2-dev libsdl1.2-dev

# Install all the dependencies needed to build QOpenHD from source.

apt install -y openhd-qt-x86-jammy 

# While we keep the gstreamer code in (in case we want to enable it anyways for the jetson) we have it disabled at compile time by default
#apt -y install libgstreamer-plugins-base1.0-dev gstreamer1.0-plugins-good
# NOT qmlglsink but something else ?! DEFINITELY not qmlglsink or doesn't work anyways
#sudo apt-get install qtgstreamer-plugins-qt5


# now also ffmpeg / avcodec
apt -y install libavcodec-dev libavformat-dev
# Note on pi / your PC this should be already installed, be carefully to pick the right one otherwise
apt -y install libgles2-mesa-dev 

# they are needed to build and install mavsdk
apt -y install pip mavsdk ruby
pip install future
gem install fpm

# build and install mavsdk
# cd lib/MAVSDK
# cmake -Bbuild/default -DCMAKE_BUILD_TYPE=Release -H.
# cmake --build build/default -j4
# sudo cmake --build build/default --target install
# sudo ldconfig

# ls /usr/local/include/mavsdk
# ls /usr/local/lib

# cd ../../
