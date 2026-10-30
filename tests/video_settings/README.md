# Application Video redesign

Run `py -3.12 tests/run_video_settings_test.py --qt-bin <Qt bin directory>`.

The runner loads copies of the production QML, replacing only C++ compile-time
capability context constants with a controllable fixture object. It uses the real
cards, rows, dropdowns, sliders, toggles and numeric controls. Preferences, audio,
mouse and restart services are isolated fixtures; no connected device is needed.

Coverage includes Normal/Advanced/Developer access, desktop/Linux/Raspberry Pi/
Android/native/no-decoder capabilities, secondary-stream changes, collapsed-group
visibility, port/FPS bounds and text editing, both software-decoder preferences,
real mouse API calls, absence of the redundant audio/playback section, preserving legacy cursor/codec values, no initialization
writes and responsive captures. Screenshots are under build/video-settings-*.png.

The Application navigation test separately checks that Vehicle is absent while
General, Video and Developer keep their existing page IDs and the OSD menu remains
unchanged. The former Vehicle QML, backend and preferences remain in place.

The compiled layout regression uses the production Application shell and lazy page
loader with Qt Quick Compiler (including the 32-bit Qt Creator kit):

`py -3.12 tests/run_video_compiled_layout_test.py --qt-bin <Qt bin directory> --make-bin <MinGW bin directory>`

It checks row bounds and overlap after loading at zero width and resizing across
five window sizes in Normal, Advanced and Developer modes.
