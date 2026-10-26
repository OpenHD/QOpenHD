#!/usr/bin/env bash
set -euo pipefail
root=$(cd "$(dirname "$0")/.." && pwd)
build=$(mktemp -d)
trap 'rm -rf "$build"' EXIT
moc "$root/app/map/offlinemaptileprovider.h" -o "$build/moc_map.cpp"
g++ -std=c++17 -fPIC -I"$root/app" "$root/tests/map_raster_test.cpp" \
    "$root/app/map/offlinemaptileprovider.cpp" "$build/moc_map.cpp" \
    $(pkg-config --cflags --libs Qt5Core Qt5Network) -o "$build/map-raster-test"
"$build/map-raster-test"
