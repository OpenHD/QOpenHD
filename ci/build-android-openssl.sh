#!/usr/bin/env bash
set -euo pipefail
# Qt 5.15 Android expects the _1_1 suffix, separate from Android's system SSL.
abi=${1:?Usage: build-android-openssl.sh ABI OUTPUT_DIR}
output=$(realpath -m "${2:?Missing output directory}")
: "${ANDROID_NDK_ROOT:?Set ANDROID_NDK_ROOT}"
# OpenSSL 1.1 reads HOME/NDK, not ROOT, and compares canonical compiler paths.
export ANDROID_NDK_ROOT=$(realpath "$ANDROID_NDK_ROOT")
export ANDROID_NDK_HOME="$ANDROID_NDK_ROOT"
export ANDROID_NDK="$ANDROID_NDK_ROOT"
case "$abi" in
    armeabi-v7a) target=android-arm ;;
    arm64-v8a) target=android-arm64 ;;
    *) echo "Unsupported Android ABI: $abi" >&2; exit 1 ;;
esac
export PATH="$ANDROID_NDK_ROOT/toolchains/llvm/prebuilt/linux-x86_64/bin:$PATH"
build=$(mktemp -d)
trap 'rm -rf "$build"' EXIT
cd "$build"
curl --fail --location --retry 3 -o openssl.tar.gz \
    https://github.com/openssl/openssl/releases/download/OpenSSL_1_1_1w/openssl-1.1.1w.tar.gz
echo 'cf3098950cb4d853ad95c0841f1f9c6d3dc102dccfcacd521d93925208b76ac8  openssl.tar.gz' | sha256sum --check
tar -xf openssl.tar.gz
cd openssl-1.1.1w
./Configure shared "$target" -D__ANDROID_API__=21 -Wl,-z,max-page-size=16384 no-tests
make -j2 SHLIB_VERSION_NUMBER= SHLIB_EXT=_1_1.so build_libs
mkdir -p "$output"
cp libcrypto_1_1.so libssl_1_1.so LICENSE "$output/"
# Fail before deployment if the libraries accidentally retain a versioned SONAME.
readelf -d "$output/libssl_1_1.so" | grep -F '[libcrypto_1_1.so]'
