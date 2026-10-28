# Link allocation UI

```powershell
$env:QT_QUICK_BACKEND = 'software'
$env:QT_QUICK_CONTROLS_STYLE = 'Basic'
& C:/Qt/5.15.19/mingw81_32/bin/qmltestrunner.exe -input tests/link_allocation -platform offscreen
```

Also run with Qt 6. The test uses production QML and explicit telemetry/parameter
fixtures. It checks persistent parameter writes, slider complement, single/fixed
streams, missing telemetry, preview gating, resized popup and 100% display cutoff.
No hardware parameters are written. OpenHD's `test_bandwidth_allocation` tests the
actual transport-scoped budgeting algorithm.
