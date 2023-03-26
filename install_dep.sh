#!/usr/bin/env bash
set -e

PLATFORM=$1
QT-TYPE=$2


BASE_PACKAGES="gnupg libjsoncpp-dev libtinyxml2-dev zlib1g libcurl4-gnutls-dev gnupg1 gnupg2 apt-transport-https apt-utils libgles2-mesa-dev libegl1-mesa-dev libgbm-dev libboost-dev libsdl2-dev libsdl1.2-dev"
VIDEO_PACKAGES="libgstreamer-plugins-base1.0-dev gstreamer1.0-plugins-good libavcodec-dev libavformat-dev"
BUILD_PACKAGES="ruby-dev meson build-essential cmake git ruby-dev python3-pip"


function install_jetson_packages {
PLATFORM_PACKAGES=""
}
function install_pi_packages {
PLATFORM_PACKAGES=""
}
function install_x86_packages {
PLATFORM_PACKAGES=""
}
function install_rock_packages {
PLATFORM_PACKAGES=""
}

 # Add OpenHD Repository platform-specific packages
 apt install -y curl
 curl -1sLf 'https://dl.cloudsmith.io/public/openhd/openhd-2-3-evo/setup.deb.sh'| sudo -E bash
 apt update

# Main function
 
 if [[ "$1" == "rpi" ]]; then
    echo "rpi"
 elif [[ "$1" == "jetson" ]] ; then
    echo "jetson"
 elif [[ "$1" == "ubuntu-x86" ]] ; then
    echo "ubuntu-x86"
 elif [[ "$1" == "rock5" ]] ; then
    echo "rock5"
 else
    echo "platform not supported"
 fi

 # Install platform-specific packages
 echo "Installing platform-specific packages..."
 for package in ${BASE_PACKAGES} ${PLATFORM_PACKAGES}; do
     echo "Installing ${package}..."
     apt install -y -o Dpkg::Options::="--force-overwrite" --no-install-recommends ${package}
     if [ $? -ne 0 ]; then
         echo "Failed to install ${package}!"
         exit 1
     fi
 done

# Installing python packages
gem install fpm
pip3 install future

# Repairing MMAL-Graph-Lib
sed -i 's/util\/\mmal_connection.h/mmal_connection.h/g' /usr/include/interface/mmal/util/mmal_graph.h

# Building MAVSDK
bash build_install_mavsdk_static.sh || exit 1


