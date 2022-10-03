#!/usr/bin/env bash

# Install all the dependencies needed to build QOpenHD from source
apt -y install libgstreamer-plugins-base1.0-dev gstreamer1.0-plugins-good
apt -y install ruby ruby-dev libavcodec-dev libavformat-dev
apt -y install mavsdk
apt -y install git meson fmt

# Repairing MMAL-Graph-Lib
sed -i 's/util\/\mmal_connection.h/mmal_connection.h/g' /usr/include/interface/mmal/util/mmal_graph.h

gem install fpm

