# QOpenHD native Rockchip MPP port investigation

Historical source investigation on 26 October 2026. The native port was later
implemented and tested on RK3588S/ROCK 5A; see
[Rockchip native video](rockchip-native-video.md) for the implementation and
hardware evidence. The ZERO 3W target below remains untested.
Target: Radxa ZERO 3W (RK3566), initially 1920x1080 at 60 Hz.

## Reference revisions

Reviewed OpenHD Glide commit
[`143bc2501d98a257353be1fbb1cc1803695e6eb8`](https://github.com/OpenHD/openhd-glide/tree/143bc2501d98a257353be1fbb1cc1803695e6eb8).
The existing local Glide checkout has unrelated UI changes; its video files
were read without modifying that checkout.

Relevant source:

* [`rockchip_mpp_rtp_decoder.cpp`](https://github.com/OpenHD/openhd-glide/blob/143bc2501d98a257353be1fbb1cc1803695e6eb8/src/video/rockchip_mpp_rtp_decoder.cpp):
  `init_mpp`, `configure_mpp`, `queue_nal`, `configure_h26x_output_group`,
  `frame_loop`, `frame_to_dmabuf`, `poll`, `mark_presented`.
* [`native presenter`](https://github.com/OpenHD/openhd-glide/blob/143bc2501d98a257353be1fbb1cc1803695e6eb8/src/openhd_glide/main.cpp):
  dedicated presenter thread dequeues and acknowledges displayed frames.
* [`isolated RKMPP regression`](https://github.com/OpenHD/openhd-glide/blob/143bc2501d98a257353be1fbb1cc1803695e6eb8/docs/artosyn-rkmpp-debug.md):
  header/picture packetization and output-pool failures reproduced independently
  of KMS, UI, and the radio. Decoder counters do not prove displayed video.

[Radxa's ZERO 3 specification](https://docs.radxa.com/zero/zero3) identifies
RK3566 and Mali-G52, and advertises 1080p60 Micro HDMI. Its
[display preparation guide](https://docs.radxa.com/en/zero/zero3/getting-started/preparation)
also specifies 1920x1080 at 60 Hz. These sources do not establish 720p120;
inspect the target's connector modes, EDID, and actual page flips before
requesting 120 Hz. Pixel-count arithmetic is not a decoder/display guarantee.

## What Glide establishes

1. Native `librockchip_mpp` accepts AVC/HEVC without GStreamer or FFmpeg.
   Glide creates `MPP_CTX_DEC`, requests `MPP_FMT_YUV420SP`, uses nonblocking
   output and separate feed/output threads. It requests immediate output and
   fast play. Its error-disable policy must be evaluated separately; accepting
   those control calls does not prove correctness under corrupted references.
2. Before `MPP_DEC_SET_INFO_CHANGE_READY`, create a DRM-backed buffer group,
   falling back to ION, size it from `mpp_frame_get_buf_size`, cap at 16 buffers,
   and register `MPP_DEC_SET_EXT_BUF_GROUP`. Glide documents an actual stall
   when it acknowledged info changes without provisioning this pool while
   retaining a scanout frame.
3. A frame owns an `MppFrame` until presentation releases it. An fd alone is
   insufficient: returning the frame lets the VPU overwrite the shared memory.
4. Linear NV12 uses the exported MPP buffer fd for both planes, Y pitch equal
   to horizontal stride, UV pitch equal to horizontal stride, and UV offset
   `horizontal_stride * vertical_stride`. Width/height and padded storage size
   must remain distinct. Reject AFBC/tiled/10-bit output in the first port.
5. Glide submits parameter sets/non-VCL NALs separately and groups only the
   VCL slices of a picture. Its documented vendor MPP case wedged with combined
   seed/header/live-picture packets. Conversely, treating every VCL slice as
   a complete picture produced a top band and green remainder on sliced input.
   Keep our tested RTP bounds/loss parser, but adapt its completed AU into this
   MPP packetization instead of blindly forwarding the Hantro input packet.
6. Glide retains current/pending frames around completed presentation. Its
   direct KMS presentation acknowledgement cannot replace `wl_buffer.release`
   in the QOpenHD Wayland path or GPU completion in a QML texture node.

## Reusable QOpenHD pieces and required separation

`RtpAccessUnit.hpp` is hardware independent. The bounded two-AU input queue,
IDR-based loss recovery, one replaceable decoded frame, independent Wayland
thread and QML secondary behavior can also be shared. However, the present
classes are under `nxp/` and their frame descriptor directly embeds
`ImxVpuApiRawFrame` and `ImxVpuApiDecStreamInfo`: this is not currently a
plug-compatible MPP backend.

The next implementation should first introduce a hardware-neutral DMA-BUF
frame lease containing visible crop, padded dimensions, per-plane fd/offset/
pitch/modifier, reception timestamp, color description, and an opaque owner.
The owner keeps the decoder generation and frame alive. Adapt Hantro to that
contract with unchanged NXP behavior before adding `MppDecoder`.

The primary presenter should consume that descriptor through an independent,
desynchronized Wayland surface. The secondary QML item should consume the
same descriptor through EGL external textures. Retain frames until compositor
release or the Qt render fence signals. Bound outstanding frames and drop
stale output rather than growing a presentation queue. Resolution/codec
changes need a new generation; old frame leases must keep the former MPP
context and pool alive until the GPU/compositor finishes.

MPP needs a bounded output-drain loop separate from compressed input: a call
to `decode_put_packet` does not synchronously yield a frame as the Hantro
wrapper currently assumes. Handle info changes on the output side and bound
packet retry time. Reopen on loss/overload at a random-access picture, preserving
multi-slice input and repeated parameter sets. Do not enable X20/X21 seed
injection globally; Glide's exceptions are stream-specific and its reset
regression needs to remain isolated.

Keep platform selection explicit (`rockchip_native` versus `nxp_native`).
Do not ship Hantro libraries or apply the Vivante Weston patch to the Mali
image. Match the RK3566 kernel, MPP allocator, EGL/GBM driver, and Wayland
DMA-BUF support from the actual image. Prefer the existing canonical Rockchip
sysroot/build integration rather than introducing an unrelated vendor SDK.

## Display options

The Wayland compositor route carries over without tying primary video to Qt's
refresh rate. On a Rockchip kernel with a usable NV12 overlay and alpha UI
plane, the compositor may also put video directly on a hardware plane. Probe
format/modifier/CRTC/scaling/rotation/zpos constraints on the actual ZERO 3W;
the NXP LCDIF plane limitation does not establish Rockchip's capabilities.

A custom KMS master like Glide would require Qt to supply HUD buffers to that
master. Do not start Glide and an independent Qt EGLFS KMS master together.
Start with the shared compositor architecture and measure whether direct
scanout occurs before considering a separate KMS implementation.

## Bring-up gates

1. Inventory the actual ZERO 3W: BSP/kernel, MPP commit/library ABI, decoder
   devices, DRM planes, HDMI modes, EGL external-image/DMA-BUF support.
2. Build Glide's `glide-rkmpp-rtp-probe` against that image and run AVC/HEVC
   IPPP fixtures, multi-slice input, loss, restarts, and resolution changes.
   Include its documented Artosyn regression if those sources are supported.
3. Build the shared QOpenHD frame contract and MPP adapter; decoder-only test
   both codecs and validate every exported layout/buffer extent.
4. Present 1080p60 primary with the HUD idle and moving, then block Qt's GUI
   for two seconds. Verify actual flips/feedback and visual integrity.
5. Add a realistic lower-rate secondary QML stream, test source swapping,
   hide/show, maximize, teardown, codec/resolution changes and sustained pool
   pressure. Prove no fd/texture/frame lease growth.
6. Measure glass-to-glass latency with a real Air unit before making latency
   claims. Treat 720p120 as a separate display/decoder experiment.

No ZERO 3W has been connected or tested as part of this investigation.
