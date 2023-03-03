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
    echo "debug"
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
    echo "\ndebug\ndebug\ndebug\n"
    qmake
    echo "build with qmake done"
    make -j$(nproc)|| exit 1
    echo "build with make done"
fi

#Here are the dependencies depending on the platform
if [[ "${DISTRO}" == "bullseye" ]] && [[ "${OS}" == "raspbian" ]] ; then
#Raspberry
PLATFORM_PACKAGES=git,openhd-userland,libavcodec-dev,libavformat-dev,openhd-qt,gst-plugins-good,gst-openhd-plugins
if [[ "${DISTRO}" == "jammy" ]] && [[ "${OS}" == "ubuntu" ]] ; then
#X86
PLATFORM_PACKAGES=git,libavcodec-dev,libavformat-dev,openhd-qt-x86-jammy,gst-plugins-good
else
PLATFORM_PACKAGES=git,libavcodec-dev,libavformat-dev,gst-plugins-good,qml-module-qtquick-controls2,libqt5concurrent5,libqt5core5a,libqt5dbus5,libqt5gui5,libqt5help5,libqt5location5,libqt5location5-plugins,libqt5multimedia5,libqt5multimedia5-plugins,libqt5multimediagsttools5,libqt5multimediawidgets5,libqt5network5,libqt5opengl5,libqt5opengl5-dev,libqt5positioning5,libqt5positioning5-plugins,libqt5positioningquick5,libqt5printsupport5,libqt5qml5,libqt5quick5,libqt5quickparticles5,libqt5quickshapes5,libqt5quicktest5,libqt5quickwidgets5,libqt5sensors5,libqt5sql5,libqt5sql5-sqlite,libqt5svg5,libqt5test5,libqt5webchannel5,libqt5webkit5,libqt5widgets5,libqt5x11extras5,libqt5xml5,openshot-qt,python3-pyqt5,python3-pyqt5.qtopengl,python3-pyqt5.qtsvg,python3-pyqt5.qtwebkit,python3-pyqtgraph,qml-module-qt-labs-settings,qml-module-qtgraphicaleffects,qml-module-qtlocation,qml-module-qtpositioning,qml-module-qtquick-controls,qml-module-qtquick-dialogs,qml-module-qtquick-extras,qml-module-qtquick-layouts,qml-module-qtquick-privatewidgets,qml-module-qtquick-shapes,qml-module-qtquick-window2,qml-module-qtquick2,qt5-gtk-platformtheme,qt5-qmake,qt5-qmake-bin,qt5-qmltooling-plugins,qtbase5-dev,qtbase5-dev-tools,qtchooser,qtdeclarative5-dev,qtdeclarative5-dev-tools,qtpositioning5-dev,qttranslations5-l10n

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
