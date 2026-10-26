#!/bin/bash
# Deterministic moving YUV pattern, encoded by standalone x264/x265 tools.
set -euo pipefail
work=${1:-/home/damien/qopenhd-nxp}
mkdir -p "$work/fixtures"
for mode in '1280 720 120' '1920 1080 60'; do
    read -r width height fps <<< "$mode"
    raw="$work/fixtures/${height}p.yuv"
    python3 - "$raw" "$width" "$height" <<'PY'
import sys
path, width, height = sys.argv[1], int(sys.argv[2]), int(sys.argv[3])
with open(path, 'wb') as f:
    for frame in range(120):
        row = bytes(16 + ((x + frame * 7) % 220) for x in range(width))
        f.write(row * height)
        f.write(bytes([96 + frame % 64]) * (width * height // 4))
        f.write(bytes([160 - frame % 64]) * (width * height // 4))
PY
    x264 --demuxer raw --input-res "${width}x${height}" --fps "$fps" --frames 120 \
        --preset ultrafast --tune zerolatency --keyint 30 --aud \
        --output "$work/fixtures/${height}p${fps}.h264" "$raw"
    x265 --input-res "${width}x${height}" --fps "$fps" --frames 120 \
        --preset ultrafast --tune zerolatency --keyint 30 --aud --repeat-headers \
        --input "$raw" --output "$work/fixtures/${height}p${fps}.h265" --pools 2 --frame-threads 1
    rm "$raw"
done
