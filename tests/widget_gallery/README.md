# Widget gallery checks

From the repository root, run `qmltestrunner -input tests/widget_gallery -import tests/widget_gallery/fixtures` with the Qt runtime and compiler on PATH. Use `QT_QUICK_BACKEND=software` for deterministic rendering. A Windows platform window is required for image capture; the offscreen plugin can return empty captures on Windows. The fixture module only supplies the OpenHD import namespace for tests of the real QML Flight Mode widget; it supplies no replacement widget visuals.

The tests cover all 57 unique setting keys, developer-only entries, category navigation, absence of the removed search/filter row, real switch writes, master visibility, presets, hidden source-item rendering, transformed bank-indicator bounds, capture resolution and preview isolation. They render wide, compact and narrow layouts to `build/widget-gallery-*.png` for visual review.

Run `py -3.12 tests/widget_gallery/verify_sources.py` to validate the complete production HUD registry. Production previews sample the existing HUD items through ShaderEffectSource. They never create duplicate HUD widgets, map providers or video receivers, and do not change source-item visibility or widget settings.

The native visual audit covers all eight categories with the real production HUD and isolated simulator models:

`py -3.12 tests/ui_simulator/run_native_smoke.py --build-dir build/Desktop_Qt_5_15_19_MinGW_32_bit-Release --audit`

It saves `gallery-audit-0.png` through `gallery-audit-7.png` and `gallery-audit-report.txt` in the build directory, and fails if any of the 57 previews is blank. The map shows the actual configured provider state; no map or sensor data is fabricated.

`py -3.12 tests/run_widget_centering_test.py` additionally checks rendered pixel bounds of the native horizon, ladders, heading, flight-path vector, angle of attack and other flight instruments.
