# OSD Style page

The Style page uses the existing HUD visual subtree as its source, without creating a second HUD, map or video receiver. It composites that OSD over `qml/resources/osd-style-alpine.png`.

The preview is a snapshot: capture once on page opening and after a supported style setting changes. A 60 ms single-shot timer coalesces preset and slider changes. `ShaderEffectSource.live` is false, so telemetry updates alone do not refresh the preview. Captures stop when the page is hidden.

Controls are backed by actual settings: Default/Matrix/Trainwreck/High Contrast presets; shape, text, glow, caution and warning colours; bundled font selection; glow alpha; and global OSD opacity (`osd_opacity`, default 1.0). Independent top/bottom bar background, foreground and font overrides are also available; empty overrides retain the original shared style and Quicksand/ShareTechMono defaults. Opacity is applied to the actual HUD subtree as well as the preview. No unsupported outline-width, corner-style or letter-spacing controls are presented.

All edits persist immediately, including presets, colours, fonts, opacity and smoothing. Leaving or destroying the page does not undo changes. Reset to default is available beside Style presets and also takes effect immediately. Existing per-widget scale and appearance settings remain in use. The bottom bar is horizontally pinned edge to edge; scale changes its contents without shrinking its screen coverage. The scenic background is zoomed by 6%, while the OSD preview uses the actual source aspect ratio to fill its frame without stretching or side gaps.

## Background asset

The project asset is `qml/resources/osd-style-alpine.png`. It was generated with the built-in image-generation tool, then copied into the repository. It is not fetched from the network at runtime.

Prompt:

Create a photorealistic scenic landscape background asset for a desktop drone OSD style preview. Wide 16:9 composition, aerial view over an alpine lake and broad green valley with scattered fields, pine forests, layered snowy mountain ridges near the horizon, calm natural blue sky. Late-afternoon clear daylight, natural muted blue and green palette, good fine detail but subdued contrast so white flight instruments will be legible over it. Horizon across upper third, lake in lower right middle, land visible across lower left. No text, no symbols, no aircraft, no cockpit, no UI, no borders. Save as a standalone clean landscape image.

## Verification

From the repository root, run `qmltestrunner -input tests/osd_style -import tests/widget_gallery/fixtures` with the Qt runtime and compiler on PATH. Tests use an isolated settings fixture and an existing hidden OSD source, verifying presets, immediate persistence, colour/font/opacity writes, snapshot-only refresh, and responsive layouts. Captures are written under `build/osd-style-*.png`.
