#!/usr/bin/env bash
set -euo pipefail

# Qt 5.15's Windows network backend loads OpenSSL 1.1 at runtime.
# Build the matching Win32 libraries from the upstream, checksum-pinned source.
output=$(realpath -m "${1:?Usage: build-windows-openssl.sh OUTPUT_DIR}")
version=1.1.1w
checksum=cf3098950cb4d853ad95c0841f1f9c6d3dc102dccfcacd521d93925208b76ac8
build=$(mktemp -d)
trap 'rm -rf "$build"' EXIT
cd "$build"
curl --fail --location --retry 3 -o openssl.tar.gz \
  "https://github.com/openssl/openssl/releases/download/OpenSSL_1_1_1w/openssl-${version}.tar.gz"
echo "$checksum  openssl.tar.gz" | sha256sum --check
tar -xf openssl.tar.gz
cd "openssl-${version}"
perl Configure mingw shared no-tests --cross-compile-prefix=i686-w64-mingw32-
make -j2
mkdir -p "$output"
cp libcrypto-1_1.dll libssl-1_1.dll LICENSE "$output/"
