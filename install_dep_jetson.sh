#!/usr/bin/env bash

# Install all the dependencies needed to build QOpenHD from source
apt -y install libgstreamer-plugins-base1.0-dev gstreamer1.0-plugins-good
apt -y install libavcodec-dev libavformat-dev
apt -y install mavsdk
apt -y install ruby openhd-qt-jetson-nano-bionic
apt -y install git meson fmt

# linking ruby install
ln -s /usr/local/bin/ruby /usr/bin/ruby

gem install fpm

