#!/bin/bash
# This file is the install instruction for the CHROOT build
# We're using cloudsmith-cli to upload the file in CHROOT

sudo apt install -y python3-pip git
DISTRO=$(cat distro.txt)
FLAVOR=$(cat flavor.txt)
REPO=$(cat repo.txt)
CUSTOM=$(cat custom.txt)
ARCH=$(cat arch.txt)

echo ${DISTRO}
echo ${FLAVOR}
echo ${CUSTOM}
echo ${ARCH}

mkdir -p /usr/local/share/openhd/platform/rock/
bash install_build_dep.sh rock5
sudo ./package.sh ${CUSTOM} ${ARCH} ${DISTRO} ${FLAVOR} || exit 1

