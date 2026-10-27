# Rockchip native MPP and independent Wayland video

The `rockchip_native` qmake configuration uses the tested native RTP parser,
Rockchip MPP H.264/H.265 decoding, and the independent Wayland presenter from
the NXP implementation. It does not compile the Hantro, FFmpeg, GStreamer,
QtMultimedia or speech backends. Primary video commits a desynchronized
DMA-BUF subsurface below the transparent HUD. Secondary video and the startup
movie use EGL external textures in Qt's render thread.

The shared `nxp/DecodedFrame.hpp` is a vendor-independent linear NV12 lease.
It carries visible/padded dimensions, crop, offsets, pitches, DMA-BUF fd and
PTS, with a release callback retaining the original decoder generation.
Neither presenter includes vendor frame types. NXP retains its existing
Hantro API; Rockchip frames retain their `MppFrame` until display/GPU release.
The existing native QML flag and item names are retained for compatibility;
`QOPENHD_ENABLE_ROCKCHIP_VIDEO` selects the actual decoder.

MPP input/output is nonblocking. The receive thread keeps two compressed
pictures; the decoder worker polls output even without input and while
backpressured, provisioning a DRM/ION output pool before acknowledging info
changes. The pool is capped at 16. Header NALs are submitted separately while
all VCL slices of a picture stay together. Input overrun, corruption or changed
parameter sets reopen at a keyframe. AFBC, tiled, 10-bit and interlaced output
are rejected; fd/layout/storage extents are checked before presentation.

## Build and installation

Use the target image's MPP headers/library, Qt 5 development tools and private
GUI headers, EGL/DRM, Wayland development packages and wayland-protocols. The
Bullseye test board uses its packaged Weston 9.0.0. Do not apply the NXP
Vivante compositor patch or install NXP libraries on this target.

```sh
git submodule update --init --recursive
mkdir -p build-rockchip-native
cd build-rockchip-native
qmake ../QOpenHD.pro CONFIG+=rockchip_native CONFIG+=release CONFIG-=ltcg
make -j6
```

`ROCKCHIP_MPP_INCLUDE` defaults to `/usr/local/include/rockchip`; override it
for another SDK. Building on the actual image avoids mismatched Qt private
headers and vendor allocator ABIs.

The canonical cross-package workflow builds Bullseye and Bookworm native
packages for `rk3566` and `rk3588`. These are named `qopenhd-native-rk3566` and
`qopenhd-native-rk3588`; only full images select them. `ci/package-rockchip-native.sh`
stages the binary under `/usr/local/share/qopenhd-rockchip`, the EGL adapter,
early framebuffer splash, logo, launchers and service templates. Package
installation alone does not activate the full-image marker.

ImageBuilder's `configure-rockchip-native.sh` installs the templates, selects
the matching Mali Wayland driver, quiets boot output and enables the early
logo. SysUtils owns Ground/Air startup and starts QOpenHD/compositor only in
Ground mode. A service condition rejects Air/Record independently. The same
native startup movie and permanent window then hand off to the flight HUD.

The launchers share `ROCKCHIP_RUNTIME_DIR=/run/qopenhd-rockchip` explicitly
because PAM can change `XDG_RUNTIME_DIR`. Qt waits for the compositor socket.
The display card is discovered from the display-subsystem path or Rockchip
DRM driver, and connected HDMI/DP outputs use the sink's preferred mode.
Override `ROCKCHIP_DRM_DEVICE` or `ROCKCHIP_WESTON_CONFIG` in
`/etc/default/qopenhd-rockchip` when the target differs.

Only one process may own DRM and UDP 5600. Stop `openhd-video.service`, install
`openhd-video-native.conf` under its service drop-in directory, and create
`/etc/qopenhd-rockchip/native-video-enabled`. The condition prevents SysUtils
from restarting the old fpvue/direct-KMS path while this marker exists.
Then reload systemd. Full images enable OpenHD/SysUtils and the early splash;
SysUtils starts `qopenhd.service` and its compositor dependency in Ground mode.

For manual prototype deployments, back up original units, binary and settings
first. Rollback stops
QOpenHD and the compositor, removes the two native service drop-ins and marker,
reloads systemd, and starts the original `openhd-video` and `qopenhd` services.
The prototype retained the original `/usr/local/bin/QOpenHD`. Packaged native
images replace the legacy QOpenHD package with a native launcher symlink, so
rollback there also requires reinstalling the legacy package. System graphics
libraries remain intact. Restore previous service enablement if it differed.

## Matching Mali Wayland runtime

The tested ROCK 5A image has a g6p0 Mali X11/GBM library without Wayland.
The isolated native runtime instead uses the same DDK generation's
`libmali-valhall-g610-g6p0-x11-wayland-gbm.so` from the Rockchip-maintained
[libmali mirror](https://github.com/JeffyCN/mirrors/tree/961afae0c1e6af8db7197cc722a26b5a998067e6),
commit `961afae0c1e6af8db7197cc722a26b5a998067e6`:

```text
lib/aarch64-linux-gnu/libmali-valhall-g610-g6p0-x11-wayland-gbm.so
SHA256 4b3f9e47375ecdbfbb10f6546b9f331bbbe86c74e2f61e1dd779a7ace067425f
```

It lives in the runtime's `mali/` directory as `libmali.so.1`, with symlinks
`libEGL.so.1`, `libGLESv2.so.2`, and `libgbm.so.1`. Include its upstream
`END_USER_LICENCE_AGREEMENT.txt` and source/hash record. The launchers set a
private library path; they do not replace system graphics libraries. Other
boards must use a driver matching their own GPU and kernel DDK.

Bullseye Qt Wayland references two EGL 1.5 platform functions that this Mali
DDK exposes through `EGL_EXT_platform_base`. Build the narrow adapter:

```sh
gcc -shared -fPIC -O2 deployment/rockchip/egl-platform-compat.c \
    -o /usr/local/share/qopenhd-rockchip/mali/egl-platform-compat.so -lEGL
```

The Qt launcher preloads it if present. It translates bounded EGL attribute
lists to the EXT entry points; vendor EGL still handles rendering/imports.
The offscreen GBM adapter used during bring-up is diagnostic only and is not
installed or preloaded by either production launcher.

## Hardware validation, 27 October 2026

Target confirmed over SSH: Radxa ROCK 5A, RK3588S, aarch64, Debian Bullseye,
kernel `5.10.110-radxa-rockchip`. OpenHD was updated from the configured
development feed to `3.0-alpha-202610270056-7ee93e72`. QOpenHD was source-built
from `b39bb58886b8f8a334137f6f083a1988fb09448c` plus this local native port.

* Decoder-only AVC/HEVC fixtures each produced 480 frames over four decoder
  generations, retaining two display-like frame leases across teardown, with
  valid fd-backed NV12 and zero decoder errors.
* Mali hardware rendering and DMA-BUF support worked with packaged Weston 9.
  The connected display is **DP-1**, at 2560x1440p60; HDMI-A-1 is disconnected.
* Primary 1080p60 H.264 presented **119 frames during a two-second Qt GUI
  block**. An initial 50-second fixture run decoded 2880 frames, presented
  2844, and reported zero input drops/decoder errors. Presentation discards
  are recorded separately from decoding and replacement.
* Simultaneous H.265 primary and H.264 secondary decoded without errors;
  secondary EGL textures rendered while primary feedback continued.
* The startup movie decoded all 141 pictures using MPP with B-frame PTS.
  Its paced callbacks have a separate one-second input retry budget; live
  streams retain the 100 ms bound.
* Big Buck Bunny played through MPP and the real DRM compositor. A captured
  2560x1440 linear XR24 scanout contained the movie beneath the HUD. The RTP
  sender handles this AUD-less multi-slice clip and avoids catch-up bursts
  after host scheduling delays.
  The user confirmed correct picture and motion on the physical display.
* Shared NXP decoder/presenter sources cross-compiled after the frame-contract
  change. Native RTP tests passed with ASan/UBSan; startup and movie-container
  regressions also passed. This does not replace a fresh NXP device test.

Presentation feedback is not physical-display or glass-to-glass latency
proof. No 120 Hz mode was advertised by this display, and no 120 Hz or RF
latency claim is made. RK3566/ZERO 3W remains untested. Rotation, dynamic
primary/secondary swapping, repeated resize and long-duration memory-pressure
testing remain additional device acceptance work.

For diagnostics, `QOPENHD_NXP_VIDEO_STATS=1` and
`QOPENHD_NXP_TEST_BLOCK_GUI_MS=2000` retain their legacy names for both native
backends. Keep the deliberate GUI block out of production defaults.

## Bullseye package compatibility correction

The ROCK 5A deployment test caught two differences from the prototype:
Bullseye dpkg requires XZ rather than Ubuntu default zstd package compression,
and Weston 9 stock kiosk shell hardcodes grey. Native Bullseye packages now
include an ABI-matched black kiosk module built from verified Weston 9 source,
with its license and provenance. Weston 10 uses the configured black
background color. Compositor-only scanout on the ROCK 5A was verified as entirely
black. Reboot and physical handoff acceptance remain separate from that capture.
