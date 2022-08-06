#!/usr/bin/env bash

# Install all the dependencies needed to build OpenHD from source.
# TODO do we need libgstreamer1.0-dev and libgstreamer-plugins-base1.0-dev ?
   
echo "deb http://deb.debian.org/debian buster-backports main" >> /etc/apt/sources.list.d/backports.list
apt-key adv --keyserver keyserver.ubuntu.com --recv-keys 0E98404D386FA1D9
apt update 
apt install libboost1.74-dev/buster-backports libboost1.74-all-dev/buster-backports cmake/buster-backports -y

apt -y install libgstreamer-plugins-base1.0-dev gstreamer1.0-plugins-good
apt -y install ruby ruby-dev 
apt -y install rubygems libgemplugin-ruby
apt -y install mavsdk
apt -y install git meson fmt

            touch /etc/ld.so.conf.d/qt.conf
            echo "/opt/Qt5.15.0/lib/" >/etc/ld.so.conf.d/qt.conf
            sudo ldconfig
            export PATH="$PATH:/opt/Qt5.15.0/bin/"
            cd /usr/bin
            sudo ln -s /opt/Qt5.15.0/bin/qmake qmake

gem install fpm
