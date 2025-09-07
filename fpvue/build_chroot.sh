#!/bin/bash
# This file is the install instruction for the CHROOT build
# We're using cloudsmith-cli to upload the file in CHROOT
sudo apt install -y python3-pip
sudo pip3 install --upgrade cloudsmith-cli
curl -1sLf 'https://dl.cloudsmith.io/public/openhd/release/setup.deb.sh'| sudo -E bash
apt update
sudo apt install -y git ruby-dev curl make cmake gcc g++ wget libdrm-dev libcairo-dev
gem install fpm

git clone https://github.com/openhd/mpp.git --recursive
cd mpp
sudo apt install -y git ruby-dev curl make cmake gcc g++ wget libdrm-dev mlocate openhd qopenhd-rk3566 apt-transport-https apt-utils open-hd-web-ui
gem install fpm
cd build/linux/aarch64
./make-Makefiles.bash
make -j4 install

cd ../../../../
ls
cmake -B build -DCMAKE_INSTALL_PREFIX="/opt/fpv/usr/local"
sudo cmake --build build --target install
echo $PWD
cp other/x20_header.h264 /opt/fpv/usr/local/bin/

VERSION="1.2-$(date -d '+1 hour' +'%m-%d-%Y--%H-%M-%S')"
VERSION=$(echo "$VERSION" | sed 's/\//-/g')
fpm -a arm64 -s dir -t deb -n fpv-rk3566 -v "$VERSION" -C /opt/fpv -p fpv-rk3566_VERSION_ARCH.deb
echo "push to cloudsmith"
git describe --exact-match HEAD >/dev/null 2>&1
echo "Pushing the package to OpenHD 2.3 repository"
API_KEY=$(cat /opt/additionalFiles/cloudsmith_api_key.txt)
DISTRO=$(cat /opt/additionalFiles/distro.txt)
FLAVOR=$(cat /opt/additionalFiles/flavor.txt)
BOARD=$(cat /opt/additionalFiles/board.txt)

if [ "$BOARD" = "rk3588" ]; then
    for file in *.deb; do
        mv "$file" "${file%.deb}-rk3588.deb"
    done
    cloudsmith push deb --api-key "$API_KEY" openhd/dev-release/${DISTRO}/${FLAVOR} *.deb || exit 1
else
for file in *.deb; do
        mv "$file" "${file%.deb}-rk3566.deb"
    done
    cloudsmith push deb --api-key "$API_KEY" openhd/dev-release/${DISTRO}/${FLAVOR} *.deb || exit 1
fi
