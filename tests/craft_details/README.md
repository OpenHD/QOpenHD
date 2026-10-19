# Craft details

Open **Status**, then click the Flight controller card (or focus it and press
Enter). The popup shows live instruments, firmware identity when reported,
sensor health, recent FC events, and an expandable MAVLink inspector with decoded
fields and wire payloads. OpenHD Air owns the asynchronous MAVLink firmware
detector and reports its result through the existing telemetry infrastructure.
QOpenHD never starts another detector or an MSP/USB probe. The menu uses plain
firmware names; confidence remains in internal diagnostics. INAV compatibility
is applied automatically and has no manual toggle. No commands are enabled just
by a family name.

Tiles appear only for valid, observed fields. Unknown battery temperature,
invalid throttle and unreported sensors have no tile. Last readings and their
tiles survive packet loss; age and offline indicators show their freshness.
New packets update existing tiles immediately. Four firmware palettes and a
neutral Unknown palette are provided.

The diagnostic snapshot updates on incoming messages. A timer refreshes ages
and packet rates without clearing observations. Storage is bounded to 128 message IDs and 20 distinct recent
status texts. Rates describe packets reaching QOpenHD, not the FC's configured
transmit rates. Decoded inspector values retain raw MAVLink units and sentinels.
Sensor health comes from `SYS_STATUS`; it does not imply successful calibration.

Run the QML interaction tests with Qt Quick Test installed:

```powershell
New-Item -ItemType Directory -Force build | Out-Null
$env:QT_QUICK_BACKEND = 'software'
$env:QT_QUICK_CONTROLS_STYLE = 'Basic'
& C:/Qt/6.9.1/mingw_64/bin/qmltestrunner.exe -input tests/craft_details -platform offscreen -o build/craft-test.txt,txt
Get-Content build/craft-test.txt
```

The test checks card mouse/keyboard activation, navigation, message expansion
and preservation across telemetry updates, and closing the details page. It also
renders desktop and narrow/offline PNGs to `build/craft-*.png` using representative
FC data. It also checks missing fields, stale readings, labels and firmware
palettes. These fixtures do not establish live compatibility with every FC firmware.
