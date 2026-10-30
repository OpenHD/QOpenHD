#!/bin/sh
set -eu
base=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
export XDG_RUNTIME_DIR=/run/qopenhd-rpi
export XKB_CONFIG_ROOT=/usr/share/X11/xkb
export LD_LIBRARY_PATH="$base/lib${LD_LIBRARY_PATH:+:$LD_LIBRARY_PATH}"
export WESTON_MODULE_MAP="gl-renderer.so=$base/lib/libweston-9/gl-renderer.so;drm-backend.so=$base/lib/libweston-9/drm-backend.so;headless-backend.so=$base/lib/libweston-9/headless-backend.so;kiosk-shell.so=$base/lib/weston/kiosk-shell.so;"
device=${QOPENHD_DRM_DEVICE:-}
if [ -z "$device" ]; then
    for card in /sys/class/drm/card[0-9]*; do
        [ -e "$card/device/driver" ] || continue
        driver=$(basename "$(readlink -f "$card/device/driver")")
        case "$driver" in vc4*) device=$(basename "$card"); break ;; esac
    done
fi
[ -n "$device" ] || { echo 'Pi 5 display: no vc4 KMS card found' >&2; exit 1; }
exec "$base/weston" --backend="$base/lib/libweston-9/drm-backend.so" \
    --shell="$base/lib/weston/kiosk-shell.so" --socket=wayland-qopenhd \
    --drm-device="$device" --config=/etc/qopenhd-rpi/weston.ini --idle-time=0 \
    --tty=7 --continue-without-input "$@"
