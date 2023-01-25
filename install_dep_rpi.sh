#!/usr/bin/env bash


#initial requiremends
apt install -y gnupg gnupg1 gnupg2 apt-transport-https curl apt-utils  libgles2-mesa-dev libegl1-mesa-dev libgbm-dev libboost-dev libsdl2-dev libsdl1.2-dev

#install qt
apt install -y openhd-qt
ldconfig



# Install all the dependencies needed to build QOpenHD from source
apt -y install libgstreamer-plugins-base1.0-dev gstreamer1.0-plugins-good
apt -y install libgstreamer-plugins-base1.0-dev gstreamer1.0-plugins-good
apt -y install ruby ruby-dev libavcodec-dev libavformat-dev
apt -y install git meson
apt -y install build-essential cmake git ruby-dev python3-pip || exit 1
apt -y install cmake curl libjsoncpp-dev libtinyxml2-dev zlib1g libcurl4-gnutls-dev

gem install fpm
pip3 install --upgrade cloudsmith-cli
pip3 install future

# Repairing MMAL-Graph-Lib
sed -i 's/util\/\mmal_connection.h/mmal_connection.h/g' /usr/include/interface/mmal/util/mmal_graph.h

cd lib/MAVSDK
cmake -Bbuild/default -DBUILD_SHARED_LIBS=OFF -DCMAKE_BUILD_TYPE=Release -DBUILD_TESTS=OFF -H.
cmake --build build/default -j4
sudo cmake --build build/default --target install
#sudo ldconfig

ls /usr/local/include/mavsdk
ls /usr/local/lib

cp -r /usr/local/include/mavsdk /home/runner/work/QOpenHD/QOpenHD/mavsdk
mkdir /home/runner/work/QOpenHD/QOpenHD/mavsdk/lib/
cp /usr/local/lib/libmavsdk.a /home/runner/work/QOpenHD/QOpenHD/mavsdk/lib/
ls /home/runner/work/QOpenHD/QOpenHD/mavsdk
cd ../../


