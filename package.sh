#!/bin/bash

QT_VERSION=Qt5.15.0

PLATFORM=$1
DISTRO=$2
BUILD_TYPE=$3

if [[ "${PLATFORM}" == "pi" ]]; then
    OS="raspbian"
    ARCH="arm"
    PACKAGE_ARCH="armhf"
fi

if [ "${BUILD_TYPE}" == "docker" ]; then
    cat << EOF > /etc/resolv.conf
options rotate
options timeout:1
nameserver 8.8.8.8
nameserver 8.8.4.4
EOF
fi

apt-get install -y apt-transport-https
curl -1sLf 'https://dl.cloudsmith.io/public/openhd/openhd-2-0/cfg/gpg/gpg.B9F0E99CF5787237.key' | apt-key add -


echo "deb https://dl.cloudsmith.io/public/openhd/openhd-2-0/deb/${OS} ${DISTRO} main" > /etc/apt/sources.list.d/openhd-2-0.list

apt -y update

apt -y install openhd-qt=5.15.0\* libgles2-mesa-dev libegl1-mesa-dev libgbm-dev libboost-dev

PACKAGE_NAME=qopenhd

TMPDIR=/tmp/${PACKAGE_NAME}-installdir

rm -rf ${TMPDIR}/*

mkdir -p ${TMPDIR}/usr/local/bin || exit 1
mkdir -p ${TMPDIR}/etc/systemd/system || exit 1
mkdir -p ${TMPDIR}/usr/local/share/openhd || exit 1

/opt/${QT_VERSION}/bin/qmake

make clean || exit 1

make -j4 || exit 1
cp release/QOpenHD ${TMPDIR}/usr/local/bin/ || exit 1

# included in the same package since it's sharing code and not independently versioned
pushd OpenHDBoot
/opt/${QT_VERSION}/bin/qmake
make clean || exit 1
make -j4 || exit 1
cp OpenHDBoot ${TMPDIR}/usr/local/bin/ || exit 1
popd

cp systemd/* ${TMPDIR}/etc/systemd/system/ || exit 1
cp qt.json ${TMPDIR}/usr/local/share/openhd/ || exit 1

VERSION=$(git describe)

rm ${PACKAGE_NAME}_${VERSION//v}_${PACKAGE_ARCH}.deb > /dev/null 2>&1

fpm -a ${PACKAGE_ARCH} -s dir -t deb -n ${PACKAGE_NAME} -v ${VERSION//v} -C ${TMPDIR} \
  --after-install after-install.sh \
  -p ${PACKAGE_NAME}_VERSION_ARCH.deb \
  -d "libboost-dev" \
  -d "openhd-qt >= 5.15.0" || exit 1

#
# Only push to cloudsmith for tags. If you don't want something to be pushed to the repo, 
# don't create a tag. You can build packages and test them locally without tagging.
#
git describe --exact-match HEAD > /dev/null 2>&1
if [[ $? -eq 0 ]]; then
    echo "Pushing package to OpenHD repository"
    cloudsmith push deb openhd/openhd-2-0/${OS}/${DISTRO} ${PACKAGE_NAME}_${VERSION//v}_${PACKAGE_ARCH}.deb
else
    echo "Pushing package to OpenHD testing repository"
    cloudsmith push deb openhd/openhd-2-0-testing/${OS}/${DISTRO} ${PACKAGE_NAME}_${VERSION//v}_${PACKAGE_ARCH}.deb
fi
