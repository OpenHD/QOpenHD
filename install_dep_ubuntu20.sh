#!/usr/bin/env bash

# Install all the dependencies needed to build QOpenHD from source.

# Add our own repository to install a custom QT5.15.4
curl -1sLf \
  'https://dl.cloudsmith.io/public/openhd/openhd-2-2-evo/setup.deb.sh' \
  | sudo -E bash
apt install openhd-qt-x86-focal ruby 
gem install fpm


# While we keep the gstreamer code in (in case we want to enable it anyways for the jetson) we have it disabled at compile time by default
#apt -y install libgstreamer-plugins-base1.0-dev gstreamer1.0-plugins-good
# NOT qmlglsink but something else ?! DEFINITELY not qmlglsink or doesn't work anyways
#sudo apt-get install qtgstreamer-plugins-qt5


# now also ffmpeg / avcodec
apt -y install libavcodec-dev libavformat-dev
# Note on pi / your PC this should be already installed, be carefully to pick the right one otherwise
apt -y install libgles2-mesa-dev
apt -y install libgstreamer-plugins-base1.0-dev gstreamer1.0-plugins-good qtgstreamer-plugins-qt5


# they are needed to build and install mavsdk
apt -y install pip
pip install future

# build and install mavsdk
cd lib/MAVSDK
cmake -Bbuild/default -DCMAKE_BUILD_TYPE=Release -H.
cmake --build build/default -j4
sudo cmake --build build/default --target install
sudo ldconfig

ls /usr/local/include/mavsdk
ls /usr/local/lib

cd ../../
