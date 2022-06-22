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
if [[ "${DISTRO}" != "bullseye" ]]; then
    echo "..."
fi
if [[ "${DISTRO}" == "bullseye" ]]; then
    apt install -y openhd-qt-pi-bullseye
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

            touch /etc/ld.so.conf.d/qt.conf
            echo "/opt/Qt5.15.4/lib/" >/etc/ld.so.conf.d/qt.conf
            sudo ldconfig
            export PATH="$PATH:/opt/Qt5.15.4/bin/"
            git clone https://github.com/GStreamer/gst-plugins-good
            cd gst-plugins-good
            git checkout 1.18.4
            meson --prefix /usr build
            ninja -C build
            ninja -C build install
            rm -Rf build
            meson --prefix /tmp/qopenhd/usr build
            ninja -C build
            ninja -C build install
            cd ..


mkdir -p /tmp/qopenhd/usr/local/bin || exit 1
mkdir -p /tmp/qopenhd/etc/systemd/system || exit 1
mkdir -p /tmp/qopenhd/usr/local/share/openhd || exit 1

ls -a
ls /opt


if [[ "${PACKAGE_ARCH}" == x86 ]]; then
    qmake
else
    /opt/Qt5.15.4/bin/qmake  
fi

make -j2 || exit 1
cp release/QOpenHD /tmp/qopenhd/usr/local/bin/ || exit 1
ls -a
# included in the same package since it's sharing code and not independently versioned

cp systemd/* /tmp/qopenhd/etc/systemd/system/ || exit 1
cp qt.json /tmp/qopenhd/usr/local/share/openhd/ || exit 1

VERSION=2.1-$(date '+%m%d%H%M')

rm ${PACKAGE_NAME}_${VERSION//v}_${PACKAGE_ARCH}.deb > /dev/null 2>&1
ls -a
fpm -a ${PACKAGE_ARCH} -s dir -t deb -n ${PACKAGE_NAME} -v ${VERSION//v} -C ${TMPDIR} \
  -p qopenhd_VERSION_ARCH.deb \
  --after-install after-install.sh \
  -d "libboost-dev" \
  -d "gstreamer1.0-plugins-base" \
  -d "gstreamer1.0-plugins-good" \
  -d "gstreamer1.0-plugins-bad" \
  -d "gstreamer1.0-plugins-ugly" \
  -d "gstreamer1.0-libav" \
  -d "gstreamer1.0-tools" \
  -d "gstreamer1.0-alsa" \
  -d "gstreamer1.0-pulseaudio" \
  ${PLATFORM_PACKAGES} || exit 1

#
# Only push to cloudsmith for tags. If you don't want something to be pushed to the repo, 
# don't create a tag. You can build packages and test them locally without tagging.
#
git describe --exact-match HEAD > /dev/null 2>&1
if [[ $? -eq 0 ]]; then
    echo "normal"
else
    echo "testing"
fi
