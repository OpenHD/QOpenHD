#!/usr/bin/env bash
# Weston 9's kiosk shell hardcodes grey; build its exact ABI with black instead.
# Weston 10+ supports [shell] background-color and needs no private module.
set -euo pipefail
work=${1:?Usage: prepare-rockchip-kiosk.sh WORK OUTPUT}
output=${2:?}
version=9.0.0
sha=5cf5d6ce192e0eb15c1fc861a436bf21b5bb3b91dbdabbdebe83e1f83aa098fe
mkdir -p "$work"
archive="$work/weston-$version.tar.xz"
if [[ ! -s "$archive" ]]; then
    curl --fail --location --retry 4 "https://wayland.freedesktop.org/releases/weston-$version.tar.xz" -o "$archive"
fi
echo "$sha  $archive" | sha256sum -c -
source="$work/weston-$version"
[[ -d "$source" ]] || tar -xf "$archive" -C "$work"
python3 - "$source/kiosk-shell/kiosk-shell.c" <<'PY'
from pathlib import Path
import sys
p = Path(sys.argv[1]); text = p.read_text()
if text.count('0.5, 0.5, 0.5,') == 1:
    p.write_text(text.replace('0.5, 0.5, 0.5,', '0.0, 0.0, 0.0,'))
elif text.count('0.0, 0.0, 0.0,') != 1:
    raise SystemExit('Unexpected Weston 9 kiosk background source')
PY
mkdir -p "$(dirname "$output")"
${CC:-cc} ${CFLAGS:-} -shared -fPIC -O2 -D_GNU_SOURCE -I"$source" \
    "$source/kiosk-shell/kiosk-shell.c" "$source/kiosk-shell/kiosk-shell-grab.c" "$source/kiosk-shell/util.c" \
    $(pkg-config --cflags --libs libweston-9 libweston-desktop-9) ${LDFLAGS:-} -lm -o "$output"
cp "$source/COPYING" "$output.COPYING"
printf '%s\n' "Weston $version kiosk shell" \
    "Source: https://wayland.freedesktop.org/releases/weston-$version.tar.xz" \
    "SHA256: $sha" 'Change: replace the hardcoded grey background with black' > "$output.SOURCE"
