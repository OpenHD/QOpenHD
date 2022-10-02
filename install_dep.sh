#!/usr/bin/env bash

# Install all the dependencies needed to build QOpenHD from source
apt -y install libgstreamer-plugins-base1.0-dev gstreamer1.0-plugins-good
apt -y install ruby ruby-dev libavcodec-dev libavformat-dev
sudo apt-mark unhold libraspberrypi-dev
apt -y install libraspberrypi-dev
apt -y install mavsdk
apt -y install git meson fmt

gem install fpm

