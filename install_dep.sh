#!/usr/bin/env bash

# Install all the dependencies needed to build QOpenHD from source.

apt -y install libgstreamer-plugins-base1.0-dev gst-plugins-good ruby ruby-dev rubygems
apt -y install git meson fmt

gem install fpm

