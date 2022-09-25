#!/usr/bin/env bash

# the openhd scripts start the correct OSD depending on the distro and settings
systemctl enable qopenhd.service

mkdir -p /usr/local/share/testvideos
cd /usr/local/share/testvideos
git clone https://github.com/OpenHD/TestVideos/
cd TestVideos mv * ../
cd /usr/local/share/testvideos
rm -Rf TestVideos