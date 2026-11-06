# OSD Style page

The Style page renders the existing production HUD widgets to one still image over `qml/resources/osd-style-alpine.png`. The picture uses the current widget layout and visibility, colours, fonts and bar overrides. It does not create a second HUD, map provider or video receiver, and does not change the source HUD's visibility.

A 100 ms single-shot timer coalesces style changes, including multi-setting presets and slider movement. The preview captures once when opened and after an edit; telemetry updates alone never refresh it. Each capture temporarily creates a non-live `ShaderEffectSource`, capped at 1024 pixels on the longest edge while retaining the full HUD aspect ratio. `grabToImage` produces an in-memory image URL consumed by an ordinary `Image`. After readback, the capture item is destroyed and its framebuffer released. No PNG encoding, base64 conversion, file writes or network requests are needed. The previous image remains displayed while its replacement is rendered.

Only one capture can run at a time. Changes during a capture queue one coalesced follow-up capture. Closing the page cancels pending work, invalidates callbacks and releases its image and capture item. Raspberry Pi uses the same actual-HUD snapshot path as other platforms. This replaces the unbounded, double-resolution retained capture; whether it resolves the reported Pi 4 freeze still requires live hardware validation.

Controls are backed by actual settings: Default/Matrix/Trainwreck/High Contrast presets; shape, text, glow, caution and warning colours; bundled font selection; glow alpha; and global OSD opacity (`osd_opacity`, default 1.0). Independent top/bottom bar background, foreground and font overrides are also available; empty overrides retain the original shared style and Quicksand/ShareTechMono defaults. Opacity is applied to the actual HUD subtree as well as the preview. No unsupported outline-width, corner-style or letter-spacing controls are presented.

All edits persist immediately, including presets, colours, fonts, opacity and smoothing. Leaving or destroying the page does not undo changes. Reset to default is available beside Style presets and also takes effect immediately. Existing per-widget scale and appearance settings remain in use. The bottom bar is horizontally pinned edge to edge; scale changes its contents without shrinking its screen coverage. The scenic background is zoomed by 6%, while the OSD preview uses the actual source aspect ratio to fill its frame without stretching or side gaps.

## Background asset

The project asset is `qml/resources/osd-style-alpine.png`. It was generated with the built-in image-generation tool, then copied into the repository. It is not fetched from the network at runtime.

Prompt:

Create a photorealistic scenic landscape background asset for a desktop drone OSD style preview. Wide 16:9 composition, aerial view over an alpine lake and broad green valley with scattered fields, pine forests, layered snowy mountain ridges near the horizon, calm natural blue sky. Late-afternoon clear daylight, natural muted blue and green palette, good fine detail but subdued contrast so white flight instruments will be legible over it. Horizon across upper third, lake in lower right middle, land visible across lower left. No text, no symbols, no aircraft, no cockpit, no UI, no borders. Save as a standalone clean landscape image.

## Verification

From the repository root, run `qmltestrunner -input tests/osd_style -import tests/widget_gallery/fixtures` with the Qt runtime and compiler on PATH. Tests use an isolated settings fixture and a hidden OSD source, verifying presets, immediate persistence, colour/font/opacity writes, snapshot-only refresh, and responsive layouts. Snapshot tests check rendered pixels before/after an edit, bounded image dimensions, release of the capture item, unchanged images during telemetry updates, queued edits and cancellation when the page closes. Captures are written under `build/osd-style-*.png`. These desktop checks do not establish that the reported system freeze is resolved on Pi hardware.
