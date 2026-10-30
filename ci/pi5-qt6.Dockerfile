FROM debian:trixie
RUN apt-get update && apt-get install -y --no-install-recommends python3 ca-certificates
COPY apt-prefetch.py /usr/local/bin/apt-prefetch.py
RUN python3 /usr/local/bin/apt-prefetch.py \
    build-essential crossbuild-essential-arm64 cmake ninja-build meson \
    pkg-config python3 curl ca-certificates patch rsync git \
    qt6-base-dev qt6-declarative-dev qt6-tools-dev qt6-tools-dev-tools \
    qt6-shadertools-dev wayland-protocols libwayland-bin libglib2.0-dev ffmpeg \
    && apt-get install -y --no-install-recommends \
    build-essential crossbuild-essential-arm64 cmake ninja-build meson \
    pkg-config python3 curl ca-certificates patch rsync git \
    qt6-base-dev qt6-declarative-dev qt6-tools-dev qt6-tools-dev-tools \
    qt6-shadertools-dev wayland-protocols libwayland-bin libglib2.0-dev ffmpeg \
    && rm -rf /var/lib/apt/lists/*
