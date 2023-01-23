#!/usr/bin/env bash

# Install all the dependencies needed to build QOpenHD from source.

# Add our own repository to install a custom QT5.15.4
curl -1sLf \
  'https://dl.cloudsmith.io/public/openhd/openhd-2-3-evo/setup.deb.sh' \
  | sudo -E bash
  
apt install -y ruby 
gem install fpm


# While we keep the gstreamer code in (in case we want to enable it anyways for the jetson) we have it disabled at compile time by default
#apt -y install libgstreamer-plugins-base1.0-dev gstreamer1.0-plugins-good
# NOT qmlglsink but something else ?! DEFINITELY not qmlglsink or doesn't work anyways
#sudo apt-get install qtgstreamer-plugins-qt5
apt -y install libqt5concurrent5 libqt5core5a libqt5dbus5 libqt5designer5 libqt5gui5 libqt5help5 libqt5location5 libqt5location5-plugins libqt5multimedia5 libqt5multimedia5-plugins libqt5multimediagsttools5 libqt5multimediawidgets5 libqt5network5 libqt5opengl5 libqt5opengl5-dev libqt5positioning5 libqt5positioning5-plugins libqt5positioningquick5 libqt5printsupport5 libqt5qml5 libqt5quick5 libqt5quickparticles5 libqt5quickshapes5 libqt5quicktest5 libqt5quickwidgets5 libqt5sensors5 libqt5sql5 libqt5sql5-sqlite libqt5svg5 libqt5test5 libqt5webchannel5 libqt5webkit5 libqt5widgets5 libqt5x11extras5 libqt5xml5 openshot-qt python3-pyqt5 python3-pyqt5.qtopengl python3-pyqt5.qtsvg python3-pyqt5.qtwebkit python3-pyqtgraph 
apt -y install qml-module-qt-labs-settings qml-module-qtgraphicaleffects qml-module-qtlocation qml-module-qtpositioning qml-module-qtquick-controls qml-module-qtquick-dialogs qml-module-qtquick-extras qml-module-qtquick-layouts qml-module-qtquick-privatewidgets qml-module-qtquick-shapes qml-module-qtquick-window2 qml-module-qtquick2 qt5-gtk-platformtheme qt5-qmake qt5-qmake-bin qt5-qmltooling-plugins qtbase5-dev qtbase5-dev-tools qtchooser qtdeclarative5-dev qtdeclarative5-dev-tools qtpositioning5-dev qttranslations5-l10n
apt -y install libqt5texttospeech5-dev

# now also ffmpeg / avcodec
apt -y install libavcodec-dev libavformat-dev
apt -y install libgstreamer-plugins-base1.0-dev gstreamer1.0-plugins-good qtgstreamer-plugins-qt5

# Note on pi / your PC this should be already installed, be carefully to pick the right one otherwise

# they are needed to build and install mavsdk
apt -y install pip
pip install future

# build and install mavsdk
cd lib/MAVSDK
cmake -Bbuild/default -DCMAKE_BUILD_TYPE=Release -H.
cmake --build build/default -j4
sudo cmake --build build/default --target install
sudo ldconfig

ls /usr/local/include/mavsdk
ls /usr/local/lib

cd ../../
