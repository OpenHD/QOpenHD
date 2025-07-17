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

find "$GST_DIR" -type f -name "libavutil.a" -exec rm -v {} +

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

ls -a
echo"[Info]Tree _________"
tree $PWD
# --- x264 fetch + build ---
echo "[INFO] Downloading and building x264..."
git clone --depth 1 https://code.videolan.org/videolan/x264.git x264
cd x264

# NDK r25+ does not ship binutils 'strings', so we skip endian check
export CROSS_PREFIX="$CROSS_PREFIX"
export CC="$CC"
export AR="$AR"
export RANLIB="$RANLIB"
export STRIP=true  # Disable strip
export AS="$CC"    # Avoid using gas

ls -a /home/runner/.setup-ndk/r25c/toolchains/llvm/prebuilt/linux-x86_64/bin/

echo "[INFO] Building x264 manually for $ARCH..."
cd x264

if [[ "$ARCH" == "armv7" ]]; then
  CC="$TOOLCHAIN/bin/armv7a-linux-androideabi${API}-clang"
  CFLAGS="-march=armv7-a"
  HOST="arm-linux"
  CROSS_PREFIX="arm-linux-androideabi-"
elif [[ "$ARCH" == "arm64" ]]; then
  CC="$TOOLCHAIN/bin/aarch64-linux-android${API}-clang"
  CFLAGS=""
  HOST="aarch64-linux"
  CROSS_PREFIX="aarch64-linux-android-"
fi

# Set up proper configure flags
./configure \
  --prefix="../ffmpeg-${FFMPEG_VERSION}/build-android" \
  --enable-static \
  --disable-cli \
  --disable-asm \
  --host=$HOST \
  --cross-prefix="$TOOLCHAIN/bin/$CROSS_PREFIX" \
  --sysroot="$TOOLCHAIN/sysroot" \
  CC="$CC" \
  CFLAGS="$CFLAGS" \
  ac_cv_c_bigendian=no

make -j$(nproc)
make install
cd ..

ls -a

tree