# FPVue_rk

WFB-ng client (Video Decoder) for Rockchip platform powered by the [Rockchip MPP library](https://github.com/rockchip-linux/mpp).
It also includes an experimental Allwinner A733 path that decodes via the
V4L2 stateless interface and displays frames using the sunxi-drm KMS driver.

Tested on RK3566 (Radxa Zero 3W) and RK3588s (Orange Pi 5).

# Compilation

Build on the Rockchip linux system directly.

## Install dependencies

- rockchip_mpp

```
git clone https://github.com/rockchip-linux/mpp.git
sudo cmake --build build --target install
```

- drm

```
sudo apt install libdrm-dev
```

## Build Instructions

Build and run application in production environment:

```
cmake -B build
sudo cmake --build build --target install
build/fpvue
```

Build and run application for debugging purposes:

```
cmake -B build -DCMAKE_BUILD_TYPE=Debug
cmake --build build
build/fpvue
```

### Usage

Show command line options:
```
fpvue --help
```

### Color cycle test mode

Run without any video input and cycle between solid green, red and blue screens:

```
fpvue --color-cycle
```

### Display host

The `display_host` utility opens the DRM device, shares its file descriptor
over a UNIX socket and launches `fpvue` in color cycle mode. This is useful for
testing the display stack or sharing the DRM master with another application.

Run the host:

```
display_host 720p
```

To run a Qt5 application against this host, point Qt at the DRM FD socket and
export the EGLFS platform before launching your app:

```
export FPVUE_DRM_FD_SOCKET=/tmp/drm-master
export QT_QPA_PLATFORM=eglfs
```

The socket path must match the one passed to `display_host` via `--socket`
 (default: `/tmp/drm-master`).

### Allwinner A733 experimental mode

The Allwinner path uses the Cedrus V4L2 decoder and presents frames through
the sunxi-drm driver:

```
fpvue --aw-display --udp-port 5600
```

The stream is expected to be RTP with H.264 or H.265 payloads.

### Known issues

1. Video is cropped when the fpv feed resolution is bigger than the screen mode.
1. Crashes when video feed resolution is higher than the screen resolution.
