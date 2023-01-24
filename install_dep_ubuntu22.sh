#!/usr/bin/env bash

#ffmpeg / avcodec
apt -y install libavcodec-dev libavformat-dev
# Note on pi / your PC this should be already installed, be carefully to pick the right one otherwise
apt -y install libgles2-mesa-dev

# they are needed to build and install mavsdk
apt -y install pip tee
pip install future

# build and install mavsdk


cd lib/MAVSDK
cmake -Bbuild/default -DBUILD_SHARED_LIBS=OFF -DCMAKE_BUILD_TYPE=Release -H.
cmake --build build/default -j4
sudo cmake --build build/default --target install
#sudo ldconfig

ls /usr/local/include/mavsdk
ls /usr/local/lib
cd ../../




# Install all the dependencies needed to build QOpenHD from source.
curl -1sLf \
  'https://dl.cloudsmith.io/public/openhd/openhd-2-2-evo/setup.deb.sh' \
  | sudo -E bash
curl -1sLf \
  'https://dl.cloudsmith.io/public/openhd/openhd-2-2-dev/setup.deb.sh' \
  | sudo -E bash
apt install -y openhd-qt-x86-jammy  

#linking qt for x86 jammy

rm /etc/ld.so.conf.d/qt.conf
touch /etc/ld.so.conf.d/qt.conf
echo "/opt/Qt5.15.7/lib/" >/etc/ld.so.conf.d/qt.conf
sudo ldconfig
export PATH="$PATH:/opt/Qt5.15.7/bin/"
cd /usr/bin
rm -f qmake
sudo ln -s /opt/Qt5.15.7/bin/qmake qmake

apt -y install libgstreamer-plugins-base1.0-dev gstreamer1.0-plugins-good qtgstreamer-plugins-qt5


