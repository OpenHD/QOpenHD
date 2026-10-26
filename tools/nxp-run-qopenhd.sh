#!/bin/sh
set -eu
base=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
export LD_LIBRARY_PATH="$base/lib${LD_LIBRARY_PATH:+:$LD_LIBRARY_PATH}"
export QT_PLUGIN_PATH="$base/plugins"
export QML2_IMPORT_PATH="$base/qml"
export QT_QPA_PLATFORM=${QT_QPA_PLATFORM:-wayland}
export QT_WAYLAND_DISABLE_WINDOWDECORATION=1
export XDG_RUNTIME_DIR=${NXP_RUNTIME_DIR:-${XDG_RUNTIME_DIR:-/run/qopenhd-wayland}}
export WAYLAND_DISPLAY=${WAYLAND_DISPLAY:-wayland-qopenhd}
export XKB_CONFIG_ROOT="$base/xkb"
case "$QT_QPA_PLATFORM" in
    wayland*)
        case "$WAYLAND_DISPLAY" in
            /*) socket=$WAYLAND_DISPLAY ;;
            *) socket=$XDG_RUNTIME_DIR/$WAYLAND_DISPLAY ;;
        esac
        attempts=0
        while [ ! -S "$socket" ]; do
            attempts=$((attempts + 1))
            if [ "$attempts" -ge 100 ]; then
                echo "QOpenHD: compositor socket did not become ready: $socket" >&2
                exit 1
            fi
            sleep 0.1
        done
        ;;
esac
if [ -n "${NXP_DEBUG_SERVER:-}" ]; then
    exec "$NXP_DEBUG_SERVER" --once :2345 "$base/QOpenHD" "$@"
fi
exec "$base/QOpenHD" "$@"
