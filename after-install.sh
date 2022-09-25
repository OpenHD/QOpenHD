#!/usr/bin/env bash

# the openhd scripts start the correct OSD depending on the distro and settings
systemctl enable qopenhd.service

cd /usr/local/share/
git clone https://github.com/OpenHD/testvideos/
