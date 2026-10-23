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
New packets update existing tiles on the next diagnostic snapshot. Four firmware palettes and a
neutral Unknown palette are provided.

The diagnostic snapshot publishes every 250 ms rather than rebuilding the entire
MAVLink inspector for every packet. All packets are counted and the latest values
are retained. The closed craft popup does not create its controls. A timer refreshes ages
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

The C++ observation regression reuses the application's actual Qt 5 objects.
After building the application, with its Qt/MinGW bin directories on PATH:

```powershell
py -3 tests/run_fc_observations_test.py build-qt5-clean-repro
```

It checks bounded diagnostic publication during a 10,000-packet burst, retention through an 11-second
outage, explicit session invalidation, matching capacity-parameter senders,
and ArduPilot's integer capacity type. It performs no FC writes.
It also checks vehicle type without the heartbeat custom-mode flag and gates
Betaflight 2026.6+ flight-mode decoding by detected firmware/version. INAV,
unidentified generic systems, ArduPilot, PX4 and older Betaflight retain their
existing flight-mode parsing.

The capacity editor appears only after the FC reports a supported battery
capacity parameter. It uses `BATT_CAPACITY` for ArduPilot or `BAT1_CAPACITY` for
PX4, preserves the reported MAVLink type, and waits for a matching FC echo.
INAV's empty parameter reply does not enable a capacity editor. No MSP fallback
is used. PX4's capacity change requires an FC restart.


Battery capacity uses the same compact tile layout as other readings and is the
last telemetry card. Clicking it opens a small Save/Cancel dialog. It appears
only after a supported FC parameter reply; armed/offline controllers cannot be
edited. Telemetry updates preserve a draft, and the card reflects FC replies.
The main FC status card uses the standard footer button for Craft details and
has no firmware-colored card outline. Firmware themes stay inside diagnostics.

Remote ID appears as a normal craft telemetry card only after onboard OpenDroneID
traffic is received. Its dialog separates aircraft Basic ID, reported operator
ID and module ARM_STATUS; a location packet alone never implies a working beacon.
Traffic describing nearby aircraft (nonzero id_or_mac) is excluded. Identity is
retained through silence and invalidated with the FC session. No Remote ID
broadcasting or regulatory compliance is inferred from these MAVLink reports.

Standard PX4 generates its Basic ID from its board GUID and does not offer a
MAVLink aircraft-ID setter. These PX4 values are read-only. The editor appears
only if an onboard device actually returns a CUSTOM string PARAM_EXT_VALUE for
UAS_ID or OPERATOR_ID. These are optional device parameters, not universal PX4
or ArduPilot parameters. ArduRemoteID currently does not expose its string
parameters through MAVLink, so this path does not edit its locked/DroneCAN IDs.
Edits use the existing asynchronous XParam service, retain source system and
component IDs, and require a matching accepted PARAM_EXT_ACK and echoed value.
No synthetic BASIC_ID broadcasts, MSP, FC firmware changes or local-only ID
substitutes are used. Device persistence and RF broadcasting require separate
hardware tests; the live PX4 integration test exercises readout only.

The FC regression includes a loopback TCP device to test an actual outgoing
ID update, matching confirmation, wrong-component ACK rejection and a denied
update. It never sends an ID change to physical hardware. QML tests cover card
visibility, the read-only dialog, conditional editing, draft retention and
armed/offline gating.
