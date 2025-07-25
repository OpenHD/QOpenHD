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
    CPU="armv7-a"
    ;;
  -arm64)
    ARCH="arm64"
    TARGET="aarch64-linux-android"
    CPU="armv8-a"
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
SYSROOT="$TOOLCHAIN/sysroot"

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
CROSS_PREFIX="$TOOLCHAIN/bin/${TARGET}-"

./configure \
  --prefix="../x264-build" \
  --enable-static \
  --disable-cli \
  --host="${TARGET}" \
  --cross-prefix="$CROSS_PREFIX" \
  --sysroot="$SYSROOT" \
  --extra-cflags="$CFLAGS" \
  --extra-ldflags="-fPIC" \
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

# 🛠️ Patch Vulkan NULL bug
sed -i 's/common->session = NULL;/common->session = VK_NULL_HANDLE;/' libavcodec/vulkan_video.c

# --- Set toolchain paths ---
CC="$TOOLCHAIN/bin/${TARGET}${API}-clang"
CROSS_PREFIX="$TOOLCHAIN/bin/${TARGET}-"
AR="$TOOLCHAIN/bin/llvm-ar"
RANLIB="$TOOLCHAIN/bin/llvm-ranlib"
NM="$TOOLCHAIN/bin/llvm-nm"
EXTRA_CFLAGS="-I../x264-build/include -fPIC"
EXTRA_LDFLAGS="-L../x264-build/lib -lx264 -fPIC -lm"

echo "[INFO] Configuring FFmpeg for $ARCH..."

unset PKG_CONFIG_PATH
unset PKG_CONFIG_LIBDIR

./configure \
  --prefix="$PWD/build-android" \
  --target-os=android \
  --arch="$ARCH" \
  --cpu="$CPU" \
  --cc="$CC" \
  --cross-prefix="$CROSS_PREFIX" \
  --ar="$AR" \
  --ranlib="$RANLIB" \
  --nm="$NM" \
  --sysroot="$SYSROOT" \
  --enable-cross-compile \
  --disable-shared \
  --enable-static \
  --enable-pic \
  --disable-programs \
  --disable-doc \
  --disable-everything \
  --enable-avcodec \
  --enable-avformat \
  --enable-avutil \
  --enable-swresample \
  --enable-libx264 \
  --enable-gpl \
  --extra-cflags="$EXTRA_CFLAGS" \
  --extra-ldflags="$EXTRA_LDFLAGS" \
  --pkg-config=":" \
  --disable-runtime-cpudetect

make -j$(nproc)
make install

cd ../

# --- Build GStreamer full from source ---
echo "[INFO] Cloning GStreamer mono-repo..."
rm -rf gstreamer && git clone --depth 1 https://gitlab.freedesktop.org/gstreamer/gstreamer.git
cd gstreamer

GST_INSTALL_DIR="$PWD/gst-install"
MESON_CROSS_FILE="cross-android-${ARCH}.txt"

echo "[INFO] Generating Meson cross file..."
cat > "$MESON_CROSS_FILE" <<EOF
[binaries]
c = '$TOOLCHAIN/bin/${TARGET}${API}-clang'
cpp = '$TOOLCHAIN/bin/${TARGET}${API}-clang++'
ar = '$TOOLCHAIN/bin/llvm-ar'
nm = '$TOOLCHAIN/bin/llvm-nm'
strip = '$TOOLCHAIN/bin/llvm-strip'
pkgconfig = 'pkg-config'

[host_machine]
system = 'android'
cpu_family = '${ARCH}'
cpu = '${TARGET}'
endian = 'little'

[properties]
needs_exe_wrapper = true
qt5_dir = '${QT_ANDROID_PATH}'
EOF

echo "[INFO] Configuring GStreamer with x264, libav, and qmlglsink..."
meson setup build-android \
  --cross-file "$MESON_CROSS_FILE" \
  --prefix="$GST_INSTALL_DIR" \
  -Ddefault_library=shared \
  -Dbuildtype=release \
  -Dgpl=enabled \
  -Dugly=enabled \
  -Dbad=enabled \
  -Dgood=enabled \
  -Dqt5=enabled \
  -Dgst-plugins-good:qt5=enabled \
  -Dgst-plugins-good:qmlgl=enabled \
  -Dgst-plugins-ugly:x264=enabled \
  -Dgst-libav:enabled=true \
  -Dx264_library="../x264-build/lib/libx264.a" \
  -Dx264_include="../x264-build/include" \
  -Dlibavcodec_library="../ffmpeg-${FFMPEG_VERSION}/build-android/lib/libavcodec.a" \
  -Dlibavformat_library="../ffmpeg-${FFMPEG_VERSION}/build-android/lib/libavformat.a" \
  -Dlibavutil_library="../ffmpeg-${FFMPEG_VERSION}/build-android/lib/libavutil.a" \
  -Dlibswresample_library="../ffmpeg-${FFMPEG_VERSION}/build-android/lib/libswresample.a" \
  -Dlibavcodec_include="../ffmpeg-${FFMPEG_VERSION}/build-android/include" \
  -Dlibavformat_include="../ffmpeg-${FFMPEG_VERSION}/build-android/include" \
  -Dlibavutil_include="../ffmpeg-${FFMPEG_VERSION}/build-android/include" \
  -Dlibswresample_include="../ffmpeg-${FFMPEG_VERSION}/build-android/include" \
  -Dandroid_ndk="$NDK_ROOT" \
  -Dandroid_sdk_version="$API" \
  -Dexamples=disabled

echo "[INFO] Building GStreamer..."
ninja -C build-android install

echo "[INFO] GStreamer successfully built to $GST_INSTALL_DIR"
