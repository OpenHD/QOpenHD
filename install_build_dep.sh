#!/usr/bin/env bash
set -e

PLATFORM="$1"
QTTYPE="$2"


BASE_PACKAGES="gnupg libjsoncpp-dev libtinyxml2-dev zlib1g libcurl4-gnutls-dev gnupg1 gnupg2 apt-transport-https apt-utils libgles2-mesa-dev libegl1-mesa-dev libgbm-dev libsdl2-dev libsdl1.2-dev"
VIDEO_PACKAGES="libgstreamer-plugins-base1.0-dev gstreamer1.0-plugins-good libavcodec-dev libavformat-dev"
BUILD_PACKAGES="ruby-dev meson build-essential cmake git ruby-dev python3-pip python3-future"


function install_pi_packages {
PLATFORM_PACKAGES=""
}
function install_x86_packages {
PLATFORM_PACKAGES="qml-module-qt-labs-platform"
}
function install_rock_packages {
PLATFORM_PACKAGES="qml-module-qt-labs-platform"
}

 # Add OpenHD Repository platform-specific packages
 apt install -y curl
 curl -1sLf 'https://dl.cloudsmith.io/public/openhd/release/setup.deb.sh'| sudo -E bash
 apt update

# Main function
 
 if [[ "${PLATFORM}" == "rpi" ]]; then
    install_pi_packages
    # Repairing MMAL-Graph-Lib
    sed -i 's/util\/\mmal_connection.h/mmal_connection.h/g' /usr/include/interface/mmal/util/mmal_graph.h
 elif [[ "${PLATFORM}" == "ubuntu-x86" ]] ; then
    install_x86_packages
 elif [[ "${PLATFORM}" == "rock5" ]] ; then
    install_rock_packages
 else
    echo "platform not supported "
 fi

 if [[ "${QTTYPE}" == "custom" ]]; then
    apt install -y openhd-qt 
 else
    apt -y install qml-module-qtquick-controls2 libqt5texttospeech5-dev libqt5concurrent5 libqt5core5a libqt5dbus5 libqt5designer5 libqt5gui5 libqt5help5 libqt5location5 libqt5location5-plugins libqt5multimedia5 libqt5multimedia5-plugins libqt5multimediagsttools5 libqt5multimediawidgets5 libqt5network5 libqt5opengl5 libqt5opengl5-dev libqt5positioning5 libqt5positioning5-plugins libqt5positioningquick5 libqt5printsupport5 libqt5qml5 libqt5quick5 libqt5quickparticles5 libqt5quickshapes5 libqt5quicktest5 libqt5quickwidgets5 libqt5sensors5 libqt5sql5 libqt5sql5-sqlite libqt5svg5 libqt5test5 libqt5webchannel5 libqt5webkit5 libqt5widgets5 libqt5x11extras5 libqt5xml5 openshot-qt python3-pyqt5 python3-pyqt5.qtopengl python3-pyqt5.qtsvg python3-pyqt5.qtwebkit python3-pyqtgraph qml-module-qt-labs-settings qml-module-qtgraphicaleffects qml-module-qtlocation qml-module-qtpositioning qml-module-qtquick-controls qml-module-qtquick-dialogs qml-module-qtquick-extras qml-module-qtquick-layouts qml-module-qtquick-privatewidgets qml-module-qtquick-shapes qml-module-qtquick-window2 qml-module-qtquick2 qt5-gtk-platformtheme qt5-qmake qt5-qmake-bin qt5-qmltooling-plugins qtbase5-dev qtbase5-dev-tools qtchooser qtdeclarative5-dev qtdeclarative5-dev-tools qtpositioning5-dev qttranslations5-l10n
 fi

 # Install platform-specific packages
 echo "Installing platform-specific packages..."
 for package in ${BASE_PACKAGES} ${VIDEO_PACKAGES} ${BUILD_PACKAGES} ${PLATFORM_PACKAGES}; do
     echo "Installing ${package}..."
     apt install -y -o Dpkg::Options::="--force-overwrite" --no-install-recommends ${package}
     if [ $? -ne 0 ]; then
         echo "Failed to install ${package}!"
         exit 1
     fi
 done

# Installing python packages
gem install fpm

