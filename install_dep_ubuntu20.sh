#!/usr/bin/env bash

# Install all the dependencies needed to build QOpenHD from source.

# Add our own repository to install a custom QT5.15.4
curl -1sLf \
  'https://dl.cloudsmith.io/public/openhd/openhd-2-3-evo/setup.deb.sh' \
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


# See script for more info
./build_install_mavsdk_static.sh || exit 1