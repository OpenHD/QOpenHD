#!/usr/bin/env bash
set -e

# Where the repo is checked out inside the container
export SOURCE_DIR="${SOURCE_DIR:-$PWD}"

# 1) Basic build deps
sudo apt-get update
sudo apt-get install -y \
    build-essential \
    git \
    ccache \
    python3 \
    openjdk-11-jdk \
    unzip \
    wget \
    curl

export JAVA_HOME=/usr/lib/jvm/java-11-openjdk-amd64
export PATH="$JAVA_HOME/bin:${PATH}"

# 2) Install / configure Android NDK r21e
ANDROID_NDK_VERSION=r21e
ANDROID_NDK_ZIP="android-ndk-${ANDROID_NDK_VERSION}-linux-x86_64.zip"
ANDROID_BASE="/opt"
ANDROID_NDK_ROOT="${ANDROID_BASE}/android-ndk-${ANDROID_NDK_VERSION}"

if [ ! -d "${ANDROID_NDK_ROOT}" ]; then
    sudo mkdir -p "${ANDROID_BASE}"
    cd /tmp
    wget -q "https://dl.google.com/android/repository/${ANDROID_NDK_ZIP}"
    sudo unzip -q "${ANDROID_NDK_ZIP}" -d "${ANDROID_BASE}"
fi

export ANDROID_NDK_ROOT
export ANDROID_NDK_HOME="${ANDROID_NDK_ROOT}"
export ANDROID_NDK_LATEST_HOME="${ANDROID_NDK_ROOT}"
export ANDROID_NDK="${ANDROID_NDK_ROOT}"

# 3) Qt for Android (adjust this path to where Qt is installed)
# Example if Qt is under /opt/Qt/5.15.2
export QT_VERSION=5.15.2
export QT_ROOT="/opt/Qt/${QT_VERSION}"
export PATH="${QT_ROOT}/android/bin:${PATH}"

# 3b) Ensure Gradle wrapper JAR is present (not stored in repo)
GRADLE_WRAPPER_JAR="${SOURCE_DIR}/android/gradle/wrapper/gradle-wrapper.jar"
if [ ! -f "${GRADLE_WRAPPER_JAR}" ]; then
    curl -fLo "${GRADLE_WRAPPER_JAR}" "https://raw.githubusercontent.com/gradle/gradle/v5.4.1/gradle/wrapper/gradle-wrapper.jar"
fi

# 4) ccache config (roughly like CI)
mkdir -p "${HOME}/.ccache"
cat > "${HOME}/.ccache/ccache.conf" <<EOF
compression = true
compression_level = 5
max_size = 5G
base_dir = ${SOURCE_DIR}
EOF

ccache -z || true
ccache -s || true

# 5) Pre-download GStreamer prebuilts (your script)
cd "${SOURCE_DIR}/lib/gstreamer_prebuilts"
./fetch_extract_locally.sh

echo "Android Qt5 build environment initialised."
echo "Now you can run the build, for example:"
echo "  mkdir -p /tmp/shadow_build_dir && cd /tmp/shadow_build_dir"
echo "  qmake ${SOURCE_DIR}/QOpenHD.pro -spec android-clang CONFIG+=installer ANDROID_ABIS=\"arm64-v8a\""
echo "  make -j\$(nproc) qmake_all && make -j\$(nproc)"
echo "  make install INSTALL_ROOT=android"
echo "  androiddeployqt --output android --verbose --input android-QOpenHD-deployment-settings.json --android-platform android-34 --gradle"
