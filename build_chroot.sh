#!/bin/bash
#This file is the install instruction for the CHROOT build
#We're using cloudsmith-cli to upload the file in CHROOT

sudo apt install -y python3-pip git
sudo pip3 install --upgrade cloudsmith-cli
bash install_build_dep.sh rock5
mkdir -p /usr/local/share/openhd/platform/rock/
sudo ./package.sh arm64 debian bullseye-rock5 || exit 1
mkdir -p /opt/out/
cp -v *.dep /opt/out/
echo "copied deb file"
echo "push to cloudsmith"
git describe --exact-match HEAD >/dev/null 2>&1
echo "Pushing the package to OpenHD dev-release repository"
ls -a
API_KEY=$(cat cloudsmith_api_key.txt)
cloudsmith push deb --api-key "$API_KEY" openhd/dev-release/debian/bullseye qopenhd_rk3588*.deb || exit 1
cloudsmith push deb --api-key "$API_KEY" openhd/dev-release/debian/bullseye qopenhd_rk3566*.deb || exit 1


