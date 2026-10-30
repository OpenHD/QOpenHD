#!/bin/sh
set -eu
base=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
export QT_QPA_PLATFORM=wayland
export QSG_RHI_BACKEND=opengl
export QT_QUICK_CONTROLS_STYLE=Material
export QT_WAYLAND_DISABLE_WINDOWDECORATION=1
export XDG_RUNTIME_DIR=/run/qopenhd-rpi
export WAYLAND_DISPLAY=wayland-qopenhd
attempts=0
while [ ! -S "$XDG_RUNTIME_DIR/$WAYLAND_DISPLAY" ]; do
    attempts=$((attempts + 1))
    [ "$attempts" -lt 150 ] || { echo 'Pi compositor socket did not become ready' >&2; exit 1; }
    sleep 0.1
done
exec "$base/QOpenHD" "$@"
