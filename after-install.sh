#!/usr/bin/env bash

if [ -f /etc/systemd/system/qopenhd.service ]; then
    # systemctl enable qopenhd.service
    echo "QOpenHD can be started from OpenHD ,via systemctl or manually."
else
    echo "QOpenHD is not started with a service on this system"
fi
#cd /usr/local/share/
#if [ -d "/usr/local/share/testvideos" ]; then
#  # Take action if $DIR exists. #
#  echo "Testvideos are already there"
#else
#git clone https://github.com/OpenHD/testvideos/
#fi
