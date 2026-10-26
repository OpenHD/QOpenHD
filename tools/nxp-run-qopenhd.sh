#!/bin/sh
set -eu
base=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
export LD_LIBRARY_PATH="$base/lib${LD_LIBRARY_PATH:+:$LD_LIBRARY_PATH}"
export QT_PLUGIN_PATH="$base/plugins"
export QML2_IMPORT_PATH="$base/qml"
export QT_QPA_PLATFORM=${QT_QPA_PLATFORM:-wayland}
export QT_WAYLAND_DISABLE_WINDOWDECORATION=1
export XDG_RUNTIME_DIR=${XDG_RUNTIME_DIR:-/run/qopenhd-wayland}
export WAYLAND_DISPLAY=${WAYLAND_DISPLAY:-wayland-qopenhd}
export XKB_CONFIG_ROOT="$base/xkb"
if [ -n "${NXP_DEBUG_SERVER:-}" ]; then
    exec "$NXP_DEBUG_SERVER" --once :2345 "$base/QOpenHD" "$@"
fi
exec "$base/QOpenHD" "$@"
