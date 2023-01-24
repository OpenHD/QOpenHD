#!/bin/bash
QT_VERSION=Qt5.15.7

export LC_ALL=C.UTF-8
export LANG=C.UTF-8

PACKAGE_ARCH=$1
OS=$2
DISTRO=$3
BUILD_TYPE=$4


PACKAGE_NAME=qopenhd
TMPDIR=/tmp/qopenhd/

rm -rf /tmp/qopenhd/*

mkdir -p /tmp/qopenhd/usr/local/bin || exit 1
mkdir -p /tmp/qopenhd/etc/systemd/system || exit 1

ls -a
ls /opt

VER2=$(git rev-parse --short HEAD)


if [[ "${DISTRO}" == "bullseye" ]] || [[ "${DISTRO}" == "bionic" ]] ; then
    QT_VERSION=Qt5.15.4
    # link libraries and qt
    touch /etc/ld.so.conf.d/qt.conf
    sudo echo "/opt/Qt5.15.4/lib/" > /etc/ld.so.conf.d/qt.conf
    sudo ldconfig
    export PATH="$PATH:/opt/Qt5.15.4/bin/"
    sudo rm -Rf /usr/bin/qmake
    sudo ln -s /opt/Qt5.15.4/bin/qmake /usr/bin/qmake
    /opt/Qt5.15.4/bin/qmake
    echo "build with qmake done"
    make -j$(nproc)|| exit 1
    echo "build with make done"
elif [[ "${DISTRO}" == "jammy" ]] && [[ "${BUILD_TYPE}" = "debug" ]] ; then
    QT_VERSION=Qt5.15.7
    touch /etc/ld.so.conf.d/qt.conf
    sudo echo "/opt/Qt5.15.7/lib/" > /etc/ld.so.conf.d/qt.conf
    sudo ldconfig
    export PATH="$PATH:/opt/Qt5.15.7/bin/"
    sudo ln -s /opt/Qt5.15.7/bin/qmake /usr/bin/qmake  
    qmake
    echo "build with qmake done"
    make -j2 || exit 1
    echo "build with make done"
else
    qmake
    echo "build with qmake done"
    make -j$(nproc)|| exit 1
    echo "build with make done"
fi



cp release/QOpenHD /tmp/qopenhd/usr/local/bin/ || exit 1

# copying qopenhd service
if [[ "${PACKAGE_ARCH}" != "x86_64" ]]; then
cp systemd/* /tmp/qopenhd/etc/systemd/system/ || exit 1
fi
# The rpi_qt_eglfs_kms_config.json file makes sure that qopenhd runs at the res
# specified in the config.txt if the user did so
mkdir -p /tmp/qopenhd/usr/local/share/qopenhd/
cp rpi_qt_eglfs_kms_config.json /tmp/qopenhd/usr/local/share/qopenhd/ || exit 1

VERSION="2.3-evo-$(date '+%Y%m%d%H%M')-${VER2}"


rm ${PACKAGE_NAME}_${VERSION}_${PACKAGE_ARCH}.deb > /dev/null 2>&1
ls -a
fpm -a ${PACKAGE_ARCH} -s dir -t deb -n ${PACKAGE_NAME} -v ${VERSION} -C ${TMPDIR} \
  -p qopenhd_VERSION_ARCH.deb \
  --after-install after-install.sh \
  ${PLATFORM_PACKAGES} || exit 1
