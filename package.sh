#!/bin/bash

QT_VERSION=Qt5.15.4

export LC_ALL=C.UTF-8
export LANG=C.UTF-8

PACKAGE_ARCH=$1
OS=$2
DISTRO=$3
BUILD_TYPE=$4


if [ "${BUILD_TYPE}" == "docker" ]; then
    cat << EOF > /etc/resolv.conf
options rotate
options timeout:1
nameserver 8.8.8.8
nameserver 8.8.4.4
EOF
fi

apt-get install -y apt-utils curl
apt update

apt-get install -y gnupg
apt-get install -y gnupg1
apt-get install -y gnupg2
apt-get install -y apt-transport-https curl

if [[ "${DISTRO}" == "buster" ]]; then
curl -1sLf \
  'https://dl.cloudsmith.io/public/openhd/openhd-2-2-evo/setup.deb.sh' \
  | sudo -E bash
fi

if [[ "${DISTRO}" == "bullseye" ]]; then
    apt install -y openhd-qt-pi-bullseye
fi

if [[ "${DISTRO}" == "buster" ]]; then
    apt install -y openhd-qt 
fi

if [[ "${OS}" == "debian" ]]; then
    PLATFORM_DEV_PACKAGES="openhd-qt"
    PLATFORM_PACKAGES="-d openhd-qt"
fi

if [[ "${OS}" == "ubuntu" ]] && [[ "${PACKAGE_ARCH}" == "armhf" || "${PACKAGE_ARCH}" == "arm64" ]]; then
    PLATFORM_DEV_PACKAGES="openhd-qt-jetson-nano-bionic"
    PLATFORM_PACKAGES="-d openhd-qt-jetson-nano-bionic"
fi

apt -y install ${PLATFORM_DEV_PACKAGES} libgstreamer-plugins-base1.0-dev libgles2-mesa-dev libegl1-mesa-dev libgbm-dev libboost-dev libsdl2-dev libsdl1.2-dev

PACKAGE_NAME=qopenhd

TMPDIR=/tmp/qopenhd/

rm -rf /tmp/qopenhd/*



mkdir -p /tmp/qopenhd/usr/local/bin || exit 1
mkdir -p /tmp/qopenhd/etc/systemd/system || exit 1
mkdir -p /tmp/qopenhd/usr/local/share/openhd || exit 1

ls -a
ls /opt

VER2=$(git rev-parse --short HEAD)


if [[ "${DISTRO}" == "bullseye" ]]; then
    # link libraries and qt
    touch /etc/ld.so.conf.d/qt.conf
    sudo echo "/opt/Qt5.15.4/lib/" > /etc/ld.so.conf.d/qt.conf
    sudo ldconfig
    export PATH="$PATH:/opt/Qt5.15.4/bin/"
    sudo ln -s /opt/Qt5.15.4/bin/qmake /usr/bin/qmake
fi

if [[ "${DISTRO}" == "buster" ]]; then
            touch /etc/ld.so.conf.d/qt.conf
            sudo echo "/opt/Qt5.15.0/lib/" > /etc/ld.so.conf.d/qt.conf
            sudo ldconfig
            export PATH="$PATH:/opt/Qt5.15.0/bin/"
            sudo ln -s /opt/Qt5.15.0/bin/qmake /usr/bin/qmake
fi

qmake

echo "build with qmake done"
make -j$(nproc)|| exit 1
echo "build with make done"

cp release/QOpenHD /tmp/qopenhd/usr/local/bin/ || exit 1
ls -a
# included in the same package since it's sharing code and not independently versioned

cp systemd/* /tmp/qopenhd/etc/systemd/system/ || exit 1
cp qt.json /tmp/qopenhd/usr/local/share/openhd/ || exit 1

VERSION="2.2.0-evo-$(date '+%m%d%H%M')-${VER2}"

rm ${PACKAGE_NAME}_${VERSION}_${PACKAGE_ARCH}.deb > /dev/null 2>&1
ls -a
fpm -a ${PACKAGE_ARCH} -s dir -t deb -n ${PACKAGE_NAME} -v ${VERSION} -C ${TMPDIR} \
  -p qopenhd_VERSION_ARCH.deb \
  --after-install after-install.sh \
  -d "mavsdk" \
  -d "gstreamer1.0-plugins-base" \
  -d "gstreamer1.0-plugins-good" \
  -d "gstreamer1.0-plugins-bad" \
  -d "gstreamer1.0-plugins-ugly" \
  -d "gstreamer1.0-libav" \
  -d "gstreamer1.0-tools" \
  -d "gstreamer1.0-alsa" \
  -d "gstreamer1.0-pulseaudio" \
  -d "gstreamer1.0-gl" \
  ${PLATFORM_PACKAGES} || exit 1
