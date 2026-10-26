#!/bin/bash
# Build-only Debian Qt 5.15 sysroot. The target keeps its NXP EGL/VPU libraries.
set -euo pipefail
work=${1:-/home/damien/qopenhd-nxp}
mkdir -p "$work"/{apt/lists/partial,apt/archives/partial,sysroot}
touch "$work/apt/status"
echo 'deb [signed-by=/usr/share/keyrings/debian-archive-keyring.gpg] https://deb.debian.org/debian bullseye main' > "$work/apt/sources.list"
opts=(-o "Dir::Etc::sourcelist=$work/apt/sources.list" -o Dir::Etc::sourceparts=-
      -o "Dir::State::lists=$work/apt/lists" -o "Dir::State::status=$work/apt/status"
      -o "Dir::Cache::archives=$work/apt/archives" -o APT::Architecture=arm64
      -o APT::Architectures=arm64 -o Debug::NoLocking=1 -o APT::Sandbox::User=root)
apt-get "${opts[@]}" update
apt-get "${opts[@]}" --download-only --no-install-recommends -y install \
    qtbase5-dev qtbase5-private-dev qtdeclarative5-dev libqt5charts5-dev \
    qttools5-dev-tools libqt5svg5 qml-module-qtquick2 qml-module-qtquick-window2 \
    qml-module-qtquick-controls qml-module-qtquick-controls2 qml-module-qtquick-layouts \
    qml-module-qtquick-shapes qml-module-qtquick-dialogs \
    qml-module-qt-labs-settings qml-module-qt-labs-folderlistmodel qml-module-qtgraphicaleffects \
    qml-module-qtpositioning qml-module-qtlocation qml-module-qtcharts libdrm-dev libgbm-dev \
    qtwayland5 wayland-protocols libwayland-dev weston gdbserver \
    libpixman-1-dev libudev-dev libsystemd-dev libdbus-1-dev libpng-dev libcairo2-dev libgles2-mesa-dev
for deb in "$work"/apt/archives/*.deb; do dpkg-deb -x "$deb" "$work/sysroot"; done
python3 "$(dirname "$0")/../ci/relativize-sysroot.py" "$work/sysroot"
echo "Qt sysroot ready: $work/sysroot"
