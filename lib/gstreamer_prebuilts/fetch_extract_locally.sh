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

API=21
FFMPEG_VERSION=6.1.1
GST_VERSION=1.24.13
NDK_ROOT="${NDK_ROOT:-$HOME/android-ndk-r25c}"
TOOLCHAIN="$NDK_ROOT/toolchains/llvm/prebuilt/linux-x86_64"

echo "[INFO] Building for ARCH=$ARCH using TARGET=$TARGET"

# --- GStreamer download + extract ---
echo "[INFO] Downloading GStreamer $GST_VERSION..."
wget --quiet "https://gstreamer.freedesktop.org/data/pkg/android/${GST_VERSION}/gstreamer-1.0-android-universal-${GST_VERSION}.tar.xz"

GST_DIR="gstreamer-1.0-android-universal"
mkdir -p "$GST_DIR"
tar xf gstreamer-1.0-android-universal-*.tar.xz -C "$GST_DIR"

# --- FFmpeg fetch + build ---
echo "[INFO] Downloading FFmpeg ${FFMPEG_VERSION}..."
curl -sSL "https://ffmpeg.org/releases/ffmpeg-${FFMPEG_VERSION}.tar.xz" -o ffmpeg.tar.xz
tar -xf ffmpeg.tar.xz
cd ffmpeg-${FFMPEG_VERSION}

if [[ "$ARCH" == "armv7" ]]; then
  CC="$TOOLCHAIN/bin/${TARGET}${API}-clang"
  CROSS_PREFIX="$TOOLCHAIN/bin/arm-linux-androideabi-"
elif [[ "$ARCH" == "arm64" ]]; then
  CC="$TOOLCHAIN/bin/${TARGET}${API}-clang"
  CROSS_PREFIX="$TOOLCHAIN/bin/aarch64-linux-android-"
fi

echo "[INFO] Configuring FFmpeg for $ARCH..."

./configure \
  --prefix="$PWD/build-android" \
  --ranlib="$RANLIB" \
  --target-os=android \
  --arch="$ARCH" \
  --cc="$CC" \
  --cross-prefix="$CROSS_PREFIX" \
  --ar="$AR" \
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
  --disable-runtime-cpudetect \
  --extra-cflags="-fPIC" \
  --extra-ldflags="-fPIC"

echo "[INFO] Building FFmpeg..."
make -j$(nproc)
make install
cd ..

# --- Copy over .a files into GStreamer folder ---
GST_ARCH_LIB="$GST_DIR/$ARCH/lib"
FFMPEG_LIBS="libavcodec.a libavformat.a libavutil.a libswresample.a"

echo "[INFO] Copying FFmpeg static libs to $GST_ARCH_LIB..."
for lib in $FFMPEG_LIBS; do
  src="ffmpeg-${FFMPEG_VERSION}/build-android/lib/$lib"
  if [[ -f "$src" ]]; then
    echo "[COPY] $lib -> $GST_ARCH_LIB"
    cp -v "$src" "$GST_ARCH_LIB/"
  else
    echo "[WARNING] $lib not found in $src"
  fi
done

echo "[DONE] FFmpeg replacement complete for $ARCH."
