#!/bin/sh
set -eu
base=${QOPENHD_ROCKCHIP_HOME:-/usr/local/share/qopenhd-rockchip}
export XDG_RUNTIME_DIR=${ROCKCHIP_RUNTIME_DIR:-/run/qopenhd-rockchip}
export LD_LIBRARY_PATH="$base/mali${LD_LIBRARY_PATH:+:$LD_LIBRARY_PATH}"
if [ -f "$base/mali/egl-platform-compat.so" ]; then
    export LD_PRELOAD="$base/mali/egl-platform-compat.so${LD_PRELOAD:+:$LD_PRELOAD}"
fi
export QT_QPA_PLATFORM=wayland-egl
export WAYLAND_DISPLAY=wayland-qopenhd
export QT_WAYLAND_DISABLE_WINDOWDECORATION=1
attempts=0
while [ ! -S "$XDG_RUNTIME_DIR/$WAYLAND_DISPLAY" ]; do
    attempts=$((attempts+1))
    if [ "$attempts" -ge 100 ]; then
        echo "QOpenHD: Rockchip compositor socket unavailable" >&2
        exit 1
    fi
    sleep 0.1
done
exec "$base/QOpenHD" "$@"
