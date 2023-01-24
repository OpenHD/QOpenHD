#!/usr/bin/env bash


#initial requiremends
apt install -y gnupg gnupg1 gnupg2 apt-transport-https curl apt-utils  libgles2-mesa-dev libegl1-mesa-dev libgbm-dev libboost-dev libsdl2-dev libsdl1.2-dev

#install qt
openhd-qt-jetson-nano-bionic

# Install all the dependencies needed to build QOpenHD from source
apt -y install libgstreamer-plugins-base1.0-dev gstreamer1.0-plugins-good
apt -y install libavcodec-dev libavformat-dev
apt -y install ruby openhd-qt-jetson-nano-bionic
apt -y install git meson fmt

# linking ruby install
ln -s /usr/local/bin/ruby /usr/bin/ruby

gem install fpm

cd lib/MAVSDK
cmake -Bbuild/default -DBUILD_SHARED_LIBS=OFF -DCMAKE_BUILD_TYPE=Release -H.
cmake --build build/default -j4
sudo cmake --build build/default --target install
cd ../../


