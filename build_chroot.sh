#!/bin/bash
# This file is the install instruction for the CHROOT build
# We're using cloudsmith-cli to upload the file in CHROOT

# The downloaded Bullseye image references a security repository whose package
# index now points at retired files. The archived base repository has a
# consistent package set for this isolated build chroot, so disable that feed.
echo 'Acquire::Check-Valid-Until "false";' | sudo tee /etc/apt/apt.conf.d/99openhd-ci >/dev/null
sudo find /etc/apt -type f \( -name 'sources.list' -o -name '*.list' \) -exec sed -i '\|security.debian.org/debian-security|d' {} +
sudo apt-get update

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

