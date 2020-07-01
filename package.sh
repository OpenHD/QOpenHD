#!/bin/bash

QT_VERSION=Qt5.15.0

PLATFORM=$1
DISTRO=$2

if [[ "${PLATFORM}" == "pi" ]]; then
    OS="raspbian"
    ARCH="arm"
    PACKAGE_ARCH="armhf"
fi



PACKAGE_NAME=qopenhd

TMPDIR=/tmp/${PACKAGE_NAME}-installdir

rm -rf ${TMPDIR}/*

mkdir -p ${TMPDIR}/usr/local/bin || exit 1
mkdir -p ${TMPDIR}/etc/systemd/system || exit 1
mkdir -p ${TMPDIR}/usr/local/share/openhd || exit 1

/opt/${QT_VERSION}/bin/qmake

make clean || exit 1

make -j4 || exit 1
cp QOpenHD ${TMPDIR}/usr/local/bin/ || exit 1

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
    echo "Not a tagged release, skipping push to OpenHD repository"
fi
