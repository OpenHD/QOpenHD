#!/usr/bin/env bash

#ffmpeg / avcodec
apt -y install libavcodec-dev libavformat-dev
# Note on pi / your PC this should be already installed, be carefully to pick the right one otherwise
apt -y install libgles2-mesa-dev

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
rm -f /usr/bin/qmake
sudo ln -s /opt/Qt5.15.7/bin/qmake /usr/bin/qmake

apt -y install libgstreamer-plugins-base1.0-dev gstreamer1.0-plugins-good qtgstreamer-plugins-qt5


# See script for more info
echo "$PWD"
bash build_install_mavsdk_static.sh || exit 1
