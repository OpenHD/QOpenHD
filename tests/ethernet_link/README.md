# Ethernet telemetry regression

The card tests use the production `SimulatedLinkCard.qml` with live-model fixtures.

```powershell
$env:QT_QUICK_BACKEND = 'software'
$env:QT_QUICK_CONTROLS_STYLE = 'Basic'
& C:/Qt/5.15.19/mingw81_32/bin/qmltestrunner.exe -input tests/ethernet_link -platform offscreen
```

Run with Qt 6 as well. Check actual measurements and unknown values, including
zero throughput versus unavailable telemetry, correct RTT/probe-loss units and
keyboard focus after removal of the redundant details card.

The production C++ decoder test reuses a compiled Qt 5 application build:

```powershell
# Rebuild obj/aohdsystem.o first. Use the matching Qt/MinGW tools on PATH.
python tests/run_ethernet_observations_test.py build/Desktop_Qt_5_15_19_MinGW_32_bit-Release
```

It verifies OHLU/ETH1 fields, backwards compatibility, unavailable sentinels,
truncated extensions, malformed category counts and stale usage expiry.

The OpenHD checkout also supplies `test_ethernet_metrics` for actual localhost
UDP probing, responder outage, rolling probe-loss/jitter calculations, rate
saturation and registry lifetime. No test proves physical Ethernet performance.
