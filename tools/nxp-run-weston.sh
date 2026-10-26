#!/bin/sh
set -eu
base=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
export LD_LIBRARY_PATH="$base/lib${LD_LIBRARY_PATH:+:$LD_LIBRARY_PATH}"
export XDG_RUNTIME_DIR=${XDG_RUNTIME_DIR:-/run/qopenhd-wayland}
export XKB_CONFIG_ROOT="$base/xkb"
mkdir -p "$XDG_RUNTIME_DIR"
chmod 700 "$XDG_RUNTIME_DIR"
export WESTON_MODULE_MAP="gl-renderer.so=$base/libweston-9/gl-renderer.so;headless-backend.so=$base/libweston-9/headless-backend.so;drm-backend.so=$base/libweston-9/drm-backend.so;kiosk-shell.so=$base/weston-modules/kiosk-shell.so;"
if [ "${1:-}" = headless ]; then
    shift
    exec "$base/weston" --backend="$base/libweston-9/headless-backend.so" \
        --shell="$base/weston-modules/kiosk-shell.so" --socket=wayland-qopenhd \
        --idle-time=0 --no-config "$@"
fi
# Production uses the matching NXP Weston build with its Vivante renderer.
# Supply an output configuration selecting 1280x720@120 or 1920x1080@60.
config=${NXP_WESTON_CONFIG:-/etc/qopenhd-nxp/weston.ini}
device=${NXP_DRM_DEVICE:-}
if [ -z "$device" ] && [ -e /dev/dri/by-path/platform-display-subsystem-card ]; then
    device=$(basename "$(readlink -f /dev/dri/by-path/platform-display-subsystem-card)")
fi
if [ -n "$device" ]; then set -- "--drm-device=$device" "$@"; fi
exec "$base/weston" --backend="$base/libweston-9/drm-backend.so" \
    --shell="$base/weston-modules/kiosk-shell.so" --socket=wayland-qopenhd --config="$config" "$@"
