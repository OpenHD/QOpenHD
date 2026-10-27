#!/usr/bin/env bash
# Native payloads are selected only by full images; legacy/Lite packages stay separate.
set -euo pipefail
repo=$(cd "$(dirname "$0")/.." && pwd)
release=${1:?Usage: package-rockchip-native.sh bullseye|bookworm}
case "$release" in bullseye|bookworm) ;; *) exit 2 ;; esac
: "${PREBUILT_QOPENHD:?}" "${PREBUILT_BOOT_SPLASH:?}" "${PREBUILT_EGL_COMPAT:?}"
revision=$(git -C "$repo" rev-parse --short=8 HEAD)
version=${QOPENHD_PACKAGE_VERSION:-3.0-alpha-$(date -u +%Y%m%d%H%M)-$revision}
output=${QOPENHD_PACKAGE_DIR:-$repo}
mkdir -p "$output"
stage=$(mktemp -d /tmp/qopenhd-rockchip-package.XXXXXXXX)
trap 'rm -rf -- "$stage"' EXIT
base="$stage/usr/local/share/qopenhd-rockchip"
mkdir -p "$base/mali" "$base/deployment" "$stage/usr/local/bin" "$stage/DEBIAN"
install -m755 "$PREBUILT_QOPENHD" "$base/QOpenHD"
install -m755 "$PREBUILT_BOOT_SPLASH" "$base/openhd-boot-splash"
install -m755 "$PREBUILT_EGL_COMPAT" "$base/mali/egl-platform-compat.so"
if [[ "$release" == bullseye ]]; then
    : "${PREBUILT_KIOSK_SHELL:?Bullseye requires the matching black Weston 9 kiosk shell}"
    install -m755 "$PREBUILT_KIOSK_SHELL" "$base/kiosk-shell-black.so"
    mkdir -p "$base/licenses/weston-kiosk"
    install -m644 "$PREBUILT_KIOSK_SHELL.COPYING" "$base/licenses/weston-kiosk/COPYING"
    install -m644 "$PREBUILT_KIOSK_SHELL.SOURCE" "$base/licenses/weston-kiosk/SOURCE"
fi
install -m644 "$repo/icons/round.png" "$base/boot-logo.png"
for asset in "$repo/deployment/rockchip/"*; do
    [[ -f "$asset" ]] || continue
    install -m644 "$asset" "$base/deployment/"
done
install -m755 "$repo/deployment/rockchip/run-compositor.sh" "$repo/deployment/rockchip/run-qopenhd.sh" "$base/"
install -m755 "$repo/deployment/rockchip/display-enabled.py" "$base/"
ln -s ../share/qopenhd-rockchip/QOpenHD "$stage/usr/local/bin/QOpenHD"
printf '1\n' > "$base/native-video.version"
printf 'source_commit=%s\nbackend=rockchip_native\ndistribution=%s\n' "$(git -C "$repo" rev-parse HEAD)" "$release" > "$base/build-info.txt"
dependencies=$(paste -sd, "$repo/ci/rockchip-runtime-dependencies.txt")
case "$release" in
    bullseye)
        dependencies=${dependencies/weston,/weston (>= 9),weston (<< 10),}
        dependencies+=",libssl1.1,libweston-9-0"
        ;;
    bookworm) dependencies+=",libssl3" ;;
esac
for family in rk3566 rk3588; do
    other=rk3588; [[ "$family" == rk3588 ]] && other=rk3566
    cat > "$stage/DEBIAN/control" <<EOF
Package: qopenhd-native-$family
Version: $version
Architecture: arm64
Maintainer: OpenHD <contact@openhd.org>
Depends: $dependencies
Conflicts: qopenhd-rk3566, qopenhd-rk3588, qopenhd-rk3588a, qopenhd-native-$other
Replaces: qopenhd-rk3566, qopenhd-rk3588, qopenhd-rk3588a, qopenhd-native-$other
Description: QOpenHD native Rockchip MPP and independent Wayland video for full images
 Includes the hardware startup movie, shared early framebuffer splash,
 compositor launchers and service templates. Full image setup activates it.
EOF
    # Ubuntu's dpkg-deb defaults to zstd, which older Bullseye targets cannot
    # unpack. XZ works on both supported target distributions.
    dpkg-deb -Zxz --root-owner-group --build "$stage" "$output/qopenhd-native-${family}_${version}_arm64.deb"
done
