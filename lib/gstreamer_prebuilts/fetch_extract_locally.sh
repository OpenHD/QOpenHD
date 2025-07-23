#!/bin/bash
set -euo pipefail

# --- Parse architecture argument ---
if [[ $# -ne 1 ]]; then
  echo "Usage: $0 -armv7 | -arm64"
  exit 1
fi

case "$1" in
  -armv7)
    ARCH="armv7"
    TARGET="armv7a-linux-androideabi"
    ;;
  -arm64)
    ARCH="arm64"
    TARGET="aarch64-linux-android"
    ;;
  *)
    echo "Unknown argument: $1"
    echo "Usage: $0 -armv7 | -arm64"
    exit 1
    ;;
esac

API=35
FFMPEG_VERSION=6.1.1
GST_VERSION=1.24.13
NDK_ROOT="${NDK_ROOT:-$HOME/android-ndk-r27}"
TOOLCHAIN="$NDK_ROOT/toolchains/llvm/prebuilt/linux-x86_64"

echo "[INFO] Building for ARCH=$ARCH using TARGET=$TARGET (API $API)"

# --- GStreamer download + extract ---
echo "[INFO] Downloading GStreamer $GST_VERSION..."
wget --quiet "https://gstreamer.freedesktop.org/data/pkg/android/${GST_VERSION}/gstreamer-1.0-android-universal-${GST_VERSION}.tar.xz"

GST_DIR="gstreamer-1.0-android-universal"
mkdir -p "$GST_DIR"
tar xf gstreamer-1.0-android-universal-*.tar.xz -C "$GST_DIR"

# Remove conflicting static libs
find "$GST_DIR" -type f -name "libavutil.a" -exec rm -v {} +
find "$GST_DIR" -type f -name "libx264.a" -exec rm -v {} +

# --- x264 fetch + build ---
echo "[INFO] Downloading and building x264..."
rm -rf x264 && mkdir x264 && cd x264
git clone --depth 1 https://code.videolan.org/videolan/x264.git .
export CC="$TOOLCHAIN/bin/${TARGET}${API}-clang"
export AR="$TOOLCHAIN/bin/llvm-ar"
export RANLIB="$TOOLCHAIN/bin/llvm-ranlib"
export STRINGS="/usr/bin/strings"
export ac_cv_c_bigendian=no

CFLAGS="-fPIC"
HOST="$TARGET"
CROSS_PREFIX="$TOOLCHAIN/bin/${TARGET}-"

./configure \
  --prefix="../ffmpeg-${FFMPEG_VERSION}/build-android" \
  --enable-static \
  --disable-cli \
  --host="${TARGET}" \
  --cross-prefix="$CROSS_PREFIX" \
  --sysroot="$TOOLCHAIN/sysroot" \
  --extra-cflags="$CFLAGS" \
  --extra-ldflags="-fPIC" \
  --as=clang \
  --extra-asflags="-fPIC" \
  --disable-asm

make -j$(nproc)
make install
cd ..

# --- FFmpeg fetch + build ---
echo "[INFO] Downloading FFmpeg ${FFMPEG_VERSION}..."
rm -rf ffmpeg-${FFMPEG_VERSION}
curl -sSL "https://ffmpeg.org/releases/ffmpeg-${FFMPEG_VERSION}.tar.xz" -o ffmpeg.tar.xz
tar -xf ffmpeg.tar.xz
cd ffmpeg-${FFMPEG_VERSION}

# 🔧 Patch Vulkan assignment issue
sed -i 's/common->session = NULL;/common->session = VK_NULL_HANDLE;/' libavcodec/vulkan_video.c

CC="$TOOLCHAIN/bin/${TARGET}${API}-clang"
CROSS_PREFIX="$TOOLCHAIN/bin/${TARGET}-"

echo "[INFO] Configuring FFmpeg for $ARCH..."

unset PKG_CONFIG_PATH
unset PKG_CONFIG_LIBDIR

./configure \
  --prefix="$PWD/build-android" \
  --target-os=android \
  --arch="$ARCH" \
  --cc="$CC" \
  --cross-prefix="$CROSS_PREFIX" \
  --ar="$AR" \
  --ranlib="$RANLIB" \
  --enable-cross-compile \
  --disable-shared \
  --enable-static \
  --enable-pic \
  --disable-doc \
  --disable-programs \
  --disable-everything \
  --enable-avcodec \
  --enable-avformat \
  --enable-avutil \
  --enable-swresample \
  --enable-libx264 \
  --enable-gpl \
  --pkg-config=":" \
  --extra-cflags="-fPIC -I../ffmpeg-${FFMPEG_VERSION}/build-android/include" \
  --extra-ldflags="-L../ffmpeg-${FFMPEG_VERSION}/build-android/lib -lx264 -fPIC -lm" \
  --disable-runtime-cpudetect \
  --nm="$TOOLCHAIN/bin/llvm-nm"

make -j$(nproc)
make install
