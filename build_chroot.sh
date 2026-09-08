#!/bin/bash
# This file is the install instruction for the CHROOT build
# We're using cloudsmith-cli to upload the file in CHROOT

# The downloaded Bullseye image references a security repository whose package
# files have since been retired. Use Debian's archive copy, which keeps its
# package index and files in sync.
echo 'Acquire::Check-Valid-Until "false";' | sudo tee /etc/apt/apt.conf.d/99openhd-ci >/dev/null
sudo find /etc/apt -type f \( -name 'sources.list' -o -name '*.list' -o -name '*.sources' \) -exec sed -i 's|https://security.debian.org/debian-security|http://archive.debian.org/debian-security|g' {} +
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

