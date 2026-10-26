# i.MX8M Plus native video prototype

## ORQA image integration

The canonical OpenHD `final_ci` ORQA job calls `tools/build_orqa_bundle.sh`
with its existing authenticated NXP SDK. It builds QOpenHD and Weston 9.0.0
from verified source, and combines their runtime with OpenHD and SysUtils in
`openhd-orqa-deploy.tar.gz`. `orqa-components.json` records all three source
commits and the compositor source checksum. QOpenHD's repository owns the
native backend, compositor build, runtime packaging and systemd units; the
ImageBuilder verifies and installs that payload into the flashable image.

The image includes `qopenhd.service` and its required
`qopenhd-nxp-compositor.service`. SysUtils starts `qopenhd.service` in Ground
mode; Air images retain the UI binaries without starting a display server.
The production runtime uses DRM/HDMI, selects the display-subsystem DRM card,
and never loads the headless EGL adapter. Its default output profile selects
the monitor's preferred mode. Explicit 720p120 and 1080p60 profiles are included;
select 720p120 only when the connected HDMI sink advertises/supports it.
Override the config/device using
`NXP_WESTON_CONFIG` / `NXP_DRM_DEVICE` in `/etc/default/qopenhd-nxp`.

The runtime preserves the NXP EGL/GLES/GBM/Hantro libraries. Image assembly
checks the UI dependency closure against the actual mounted rootfs, checks
the manifest hashes, and grows ext4 only within the existing GPT rootfs
partition. Missing native decoder libraries or a missing UI/compositor
component fail image creation rather than producing a partial image.

The `nxp_native` qmake configuration uses Hantro hardware decoding and an
independent Wayland video subsurface below the transparent QOpenHD HUD. It
does not build the FFmpeg, GStreamer, QtMultimedia, or speech backends.
The current implementation targets Linux and Qt 5.15.

## Presentation architecture

```
RTP/UDP :5600 -> complete access units -> Hantro G1/G2 -> linear NV12 DMA-BUF
                                                            |
                                  independent Wayland thread + event queue
                                                            |
Qt HUD surface -----------------> GPU compositor <--- desynchronized subsurface
                                        |
                                  RGB DRM scanout
```

The Qt scenegraph never receives a decoded video texture. Video commits do
not wait for Qt's update, frameSwapped, or GUI event loop. The compositor
retains the previous HUD image and can compose each new video frame with it.
This permits different HUD and video update rates; it does not guarantee an
HDMI refresh rate, decoder throughput for every stream, or a latency bound.

The target modes are 1280x720 at 120 fps and 1920x1080 at 60 fps. The output
profiles in `deployment/nxp/` request those HDMI modes. The 1080p60 and
preferred-mode profiles allow 16 ms for composition; the experimental 720p120
profile allows 7 ms. A 1 ms window missed refresh deadlines on the live BSP.
The 120 Hz profile still requires testing with a compatible monitor. Do not interpret a configuration file as proof
that a mode is supported by the attached sink.

The queue limits are two complete compressed access units, one replaceable
decoded frame, and at most two submitted Wayland buffers. Input overload
clears the compressed queue and waits for a random-access picture, preserving
reference correctness instead of accumulating old video. Parameter-set changes
reopen the decoder at the next random-access picture. VPU frame leases retain
their original decoder generation until the compositor releases the buffer.
The framebuffer pool is capped at 16 allocations.
After 500 ms without valid RTP input, the parser accepts a new sequence epoch
and reacquires a random-access picture, including OpenHD sender restarts that
reuse SSRC 0.

H.264 single NAL, STAP-A, FU-A and H.265 single NAL, AP, FU are supported.
HEVC DON fields/interleaved RTP mode are unsupported. Streams should use IPPP
coding without B frames; frame reordering is disabled. Output is progressive,
linear 8-bit NV12; unsupported layouts fail explicitly. Rotation and aspect
ratio use Wayland buffer transforms and viewports. HDR/color-management
protocol integration is not implemented.

Presentation statistics use `wp_presentation` when available. Submitted frames
and presentation feedback are separate counters. The timing diagnostic measures
completed-access-unit reception to receipt of presentation feedback, including
callback delivery. It excludes capture, RF/FEC and the time spent receiving
the access unit, and is not a glass-to-glass measurement.

## Native secondary QML video

With two cameras selected, `SecondaryVideoNxp.qml` loads `NxpVideoItem` into
QOpenHD's existing secondary panel. It uses its own Hantro decoder and bounded
RTP queue on UDP 5601, then imports linear NV12 as an external EGL texture in
Qt's render thread. The existing minimize/maximize and sizing controls apply.
Switching primary and secondary swaps the configured ports/codecs for both
receivers. Both support H.264 and H.265, without GStreamer or FFmpeg.

The secondary follows Qt's scene graph rate. The primary still commits its
independent Wayland surface. Secondary framebuffer leases are retained until their Qt render fence
signals, so the VPU cannot reuse that memory while Qt samples it. At most
two retired textures are held; later updates are dropped while the GPU is
late. Unsupported fence APIs use a synchronous Qt-context fallback. Hantro libraries remain locally loaded
to avoid the CRC symbol collision described below.

## Vivante scanout synchronization

The checked-in `tools/nxp-weston-scanout-fence.patch` makes the compositor
export its native render fence after `eglSwapBuffers`, including the native
window resolve, and pass it to the atomic primary plane's `IN_FENCE_FD`.
The output owns that fd until the next render or output teardown. No per-draw
`glFinish` is used by the primary compositor. The NV12 child advertises an
opaque visible region, avoiding a redundant fullscreen background draw and
unnecessary video alpha blending. Its initial stacking state is committed
after the first video buffer exists, even when the HUD is static.

On the live NXP BSP, missing scanout synchronization caused gray bands and
misplaced HUD graphics despite near-60 presentation callbacks per second.
Serializing every GPU draw improved correctness but missed display deadlines.
The explicit KMS fence and opaque video region corrected this path; the user
confirmed the resulting motion looked and felt good. Source-built ORQA bundles
apply this patch, ship it with the compositor license/source information, and
record `compositor_patch_sha256` alongside the upstream source checksum.

## Why this does not add DRM overlay planes

The physical FRDM target at `192.168.1.90` runs NXP Linux
`6.6.36-lts-next-g3301b9231196`. Its DRM display device exposes planes 31, 34
and 37 with possible-CRTC masks 1, 2 and 4. These are independent LCDIF outputs,
not three layers blendable on HDMI. Their formats are RGB, not NV12.

NXP's *i.MX 8M Plus Applications Processor Reference Manual*, revision 3,
section 13.3, printed pages 5227-5231, documents one LCDIF layer and a single
layer descriptor bank per controller. Software planes could perform GPU/G2D
composition, but cannot add missing physical blend hardware. The Plus must
not be confused with the i.MX8M Quad's DCSS overlay hardware.

The locally supplied ORQA public Yocto source archive includes a GCB Weston
configuration selecting 720p60 and closed TX/DVR binaries using Hantro. That
archive does not establish a 120 Hz ground receiver implementation. No ORQA
closed receiver or SDK binary is included in this repository.

## Vendor-library isolation

The BSP's `libimxvpuapi2` also depends on the Hantro encoder library, which
exports generic CRC symbols. Directly linking that dependency tree into Qt
caused a reproducible crash in PNG loading. `VpuApi` loads it with
`RTLD_LOCAL | RTLD_DEEPBIND` and resolves only the public decoder/allocator
API. Keep these libraries out of QOpenHD's global link dependencies. Keep
the loaded library alive for the process lifetime so outstanding frames can
always return their buffers safely.

## Building and development runtime

Host prerequisites include an AArch64 compiler, native Qt 5 qmake/moc/rcc/
lrelease, wayland-scanner, Python 3, rsync and pkg-config. Supply a compatible
NXP sysroot including `imxvpuapi2` and `imxdmabuffer` headers and libraries.
The scripts default to the existing local WSL SDK; override `NXP_SYSROOT`
and the work-directory argument on another machine.

```sh
bash tools/nxp-prepare-qt-sysroot.sh /path/to/work
NXP_SYSROOT=/path/to/nxp-sysroot bash tools/nxp-cross-build.sh /path/to/work
NXP_SYSROOT=/path/to/nxp-sysroot bash tools/nxp-cross-check.sh /path/to/work
```

The prepared Debian Qt runtime is an isolated development tool. It does not
replace the target's NXP EGL, GLES, GBM, Hantro, libc, or kernel components.
Production images should use a matching native NXP Qt/Weston build. The package
helper takes a list of existing target library filenames to include missing
Qt dependencies without replacing vendor libraries:

```sh
ssh root@192.168.1.90 'ls /usr/lib /lib' > board-libraries.txt
python3 tools/nxp-package-runtime.py --work /path/to/work \
    --board-libraries board-libraries.txt
```

The target had only about 96 MB free on its root filesystem. Development
artifacts were therefore deployed under `/run/qopenhd-nxp`, which is temporary
and disappears on reboot. No persistent OpenHD service or board kernel was
replaced. The runtime's `run-qopenhd.sh` selects Qt Wayland. OpenHD's normal
input is loopback UDP 5600; codec, port, primary/secondary selection, rotation
and aspect-ratio settings are read from QOpenHD settings.

The initial headless deployment used transient services `qopenhd-nxp` and
`qopenhd-nxp-compositor`. Those diagnostics ran until stopped or rebooted;
production images install the persistent units described above. The default selected input is H.264 on
loopback UDP 5600. The test-only EGLDevice adapter is enabled solely for this
headless compositor; remove it when starting the normal DRM/HDMI backend.

```sh
systemctl status qopenhd-nxp qopenhd-nxp-compositor
journalctl -u qopenhd-nxp -u qopenhd-nxp-compositor
systemctl stop qopenhd-nxp qopenhd-nxp-compositor
```

## Headless validation

`nxp_decode_probe` exercises real Hantro decoding, DMA allocation and exported
buffer descriptors without a display. `nxp_rtp_test` covers both codecs,
fragmentation, multi-slice access units, packet loss, duplicate/reordered
packets, sequence wrap, source changes and malformed packets. It was run with
AddressSanitizer and UndefinedBehaviorSanitizer.

`nxp-generate-test-streams.sh` creates deterministic moving-pattern fixtures
using standalone x264/x265 encoders. `nxp-send-rtp.py` sends AUD-delimited
fixtures without any media framework. The target's Python sender avoids
Windows sleep granularity/burst artifacts during paced loopback tests.

Measurements on 26 October 2026, with synthetic low-complexity fixtures:

| Input | Decoded pictures | Decode-only throughput | Mean submission to decoded output |
| --- | ---: | ---: | ---: |
| H.264 720p120 | 1200 | 365 fps | 2.67 ms |
| H.265 720p120 | 1200 | 803 fps | 1.16 ms |
| H.264 1080p60 | 600 | 256 fps | 3.83 ms |
| H.265 1080p60 | 600 | 397 fps | 2.42 ms |

Paced decode-only RTP loopback decoded all 600 pictures at 120 fps for each
codec, with zero queue drops and zero decoder errors. These results establish
decoder headroom for those fixtures, not maximum-complexity codec support.

Vivante EGLDevice initialization succeeds without HDMI. Stock Weston 9's
headless GL backend instead requests Mesa's surfaceless platform, which this
BSP does not expose. The **test-only** `nxp-headless-egl-device.so` adapter
routes that offscreen request to the actual EGLDevice. It must never be used
with a real DRM/HDMI compositor. The actual renderer identified itself as
Vivante GC7000UL, OpenGL ES 3.1.

Both H.264 and H.265 were decoded, imported as NV12 DMA-BUFs and presented by
this headless GPU compositor while QOpenHD was running. For each codec, a
deliberate two-second block of Qt's GUI thread still allowed 77 compositor
presentation callbacks. This directly tests independence from HUD rendering.
The stock headless backend has a hard-coded 60 Hz mode and a fixed finish-frame
timer; its roughly 39-40 fps presentations and 23-24 ms callback timings are
not HDMI throughput or production latency measurements.
The final build also passed live 720p-to-1080p stream changes for both codecs
with zero decoder errors and no input queue drops in those transitions.
The native surface and HUD were confirmed to cover the same 1280x720 output
coordinates after correcting the NXP window's content-orientation hint.

Diagnostics are opt-in environment variables:

* `QOPENHD_NXP_VIDEO_STATS=1`: decoded, submitted, presented, discarded and
  overload counters, plus feedback timing.
* `QOPENHD_NXP_TEST_BLOCK_GUI_MS=2000`: block only Qt's GUI thread once, four
  seconds after controller initialization, and report video presentations
  during the block. Values above 10000 ms are ignored.

On the later live HDMI bring-up, a BenQ XL2411T advertised 1080p60 and 720p60,
but no 720p120 HDMI mode. The actual DRM scanout framebuffer contained the
QOpenHD HUD with both Vivante GL and software rendering. The monitor still
reported black/no signal, so physical HDMI output remained unproven even though
the services and rendered framebuffer were correct.

Production startup explicitly shares `NXP_RUNTIME_DIR` between Weston and Qt:
PAM/logind can overwrite `XDG_RUNTIME_DIR` with `/run/user/0` when opening the
compositor's tty session. Qt waits for the shared socket before starting.
Install the runtime and units persistently; copies under `/run` disappear on
reboot. Check available root filesystem space before deployment.
Deployment archives normalize all entries to UID/GID 0, including `.` and
parent directories. Extracting an archive with build-user-owned root directories
can cause systemd-tmpfiles to reject unsafe path transitions on the next boot,
leaving logind and the compositor stopped. This was reproduced and corrected
during live bring-up; the HUD was then confirmed visible on the attached monitor.

Live 1080p60 HDMI was subsequently confirmed visible. The temporary FPS overlay
was removed. Big Buck Bunny was decoded and re-encoded on Hantro for the final
movie test; an encoder-input NV12 chroma stride mismatch was corrected. The
movie and RTP generators are diagnostics, not production services or image
assets. A B-frame movie must be reordered before preparing an IPPP fixture;
feeding it directly into the no-reorder flight decoder is not a smoothness test.

Remaining physical validation: 720p120 mode selection,
120 Hz scanout, vblank/presentation timing under sustained RF video, GPU load,
visible color/rotation/overlay correctness, recovery with the real Air stream,
and glass-to-glass latency. The initial decoder/compositor tests were headless.

## OpenHD input and deployment checks

SysUtils owns the persistent `run_mode` setting. In Ground mode it starts
`qopenhd.service`, which requires the native compositor. OpenHD Ground forwards
stream 0 to localhost UDP 5600 and stream 1 to 5601. No separate ground decoder
service is needed. The connected FRDM was changed to Ground through the
SysUtils settings socket and OpenHD confirmed `Ground Unit` at startup.

The live integration test fed both streams into OpenHD's Ethernet ingress,
not directly into the UI sockets:

```sh
python3 tools/nxp-send-rtp.py primary.h264 127.0.0.1 --port 5910 --openhd-stream 0 --fps 60
python3 tools/nxp-send-rtp.py secondary.h265 127.0.0.1 --port 5910 --openhd-stream 1 --fps 30
```

H.264 and H.265 secondary pictures were inspected in DRM scanout captures with
the primary visible. Decode errors and input queue drops remained zero in
these paired-stream tests. Secondary rendering follows the available Qt/GPU
rate; simultaneous maximum-rate streams and 120 Hz output are not established
by these tests. RF reception and glass-to-glass latency remain separate checks.

The HDMI regression also exercised H.265 1080p60 primary with H.264 secondary
through OpenHD. During a deliberate two-second Qt GUI block, the independent
primary received 120 presentation callbacks; both decoders reported zero errors
and zero input queue drops.

## Boot splash and animation

The NXP runtime mirrors the Pi sequence without QtMultimedia: an early
OpenHD logo with three pulsing blue dots, then the same bundled six-second
movie, then the HUD. `openhd-nxp-boot-splash.service` starts from the vendor
`sysinit.target.wants` directory and writes only the DRM fbdev-emulation
framebuffer. It retries a missing framebuffer for three seconds, validates
geometry/pixel bounds, and exits after 25 seconds if no compositor starts.
It neither becomes DRM master nor waits for network/OpenHD initialization.

The compositor orders after the splash service and explicitly stops it in
`ExecStartPre`, before Weston accesses the display. A startup `Conflicts=`
would suppress the weak splash start job from the initial boot transaction. This covers
early userspace; firmware/U-Boot and the kernel's initial display setup precede
it. The mode change into Weston can still briefly blank HDMI.

QOpenHD reuses the Pi's permanent startup window. On NXP it selects
`BootVideoNxp.qml`, decodes with Hantro, imports NV12 through the native QML
renderer, holds the last image while the HUD loads, and then reveals the
transparent HUD above the independent live video surface. Boot playback uses
frame reordering and drains all pictures at EOF; live flight video keeps
reordering disabled. A 12-second boot-movie watchdog allows the HUD to load
if playback fails. The early service and the movie require neither FFmpeg
nor GStreamer.

`tools/nxp-prepare-boot-video.py` reads the bundled non-fragmented AVC MP4 at
build time and embeds Annex B samples with their composition timestamps.
The movie has 141 pictures at 24 fps and contains B-frames: preserving the
`ctts` offsets avoids decode-order judder. Timing/bounds tests run in native
NXP CI. The early framebuffer helper and logo travel in the same ORQA runtime;
its PNG dependency is included by the runtime dependency closure.

The kiosk-shell background is black, matching both startup stages and the
no-video HUD. The compositor patch changes the upstream gray fallback rather
than placing an opaque Qt rectangle over the independent live video surface.
