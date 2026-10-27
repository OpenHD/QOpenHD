#!/bin/sh
set -eu
base=${QOPENHD_ROCKCHIP_HOME:-/usr/local/share/qopenhd-rockchip}
export XDG_RUNTIME_DIR=${ROCKCHIP_RUNTIME_DIR:-/run/qopenhd-rockchip}
export LD_LIBRARY_PATH="$base/mali${LD_LIBRARY_PATH:+:$LD_LIBRARY_PATH}"
mkdir -p "$XDG_RUNTIME_DIR"
chmod 700 "$XDG_RUNTIME_DIR"
device=${ROCKCHIP_DRM_DEVICE:-}
if [ -z "$device" ] && [ -e /dev/dri/by-path/platform-display-subsystem-card ]; then
    device=$(basename "$(readlink -f /dev/dri/by-path/platform-display-subsystem-card)")
fi
if [ -z "$device" ]; then
    for card in /sys/class/drm/card[0-9]*; do
        [ -f "$card/device/uevent" ] || continue
        if grep -q '^DRIVER=rockchip' "$card/device/uevent"; then
            device=$(basename "$card"); break
        fi
    done
fi
if [ -z "$device" ]; then
    echo 'QOpenHD: Rockchip display DRM card unavailable' >&2
    exit 1
fi
shell=kiosk-shell.so
if [ -f "$base/kiosk-shell-black.so" ]; then shell="$base/kiosk-shell-black.so"; fi
exec /usr/bin/weston --backend=drm-backend.so --drm-device="$device" \
    --shell="$shell" --socket=wayland-qopenhd --idle-time=0 \
    --continue-without-input --config="${ROCKCHIP_WESTON_CONFIG:-/etc/qopenhd-rockchip/weston.ini}" "$@"
