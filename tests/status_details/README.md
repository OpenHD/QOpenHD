# Status and ground station details

Run the production menu with representative telemetry and parameter models:

```powershell
$env:QT_QUICK_BACKEND = 'software'
$env:QT_QUICK_CONTROLS_STYLE = 'Basic'
& C:/Qt/5.15.19/mingw81_32/bin/qmltestrunner.exe -input tests/status_details -import tests/status_details -platform offscreen
```

Also runs with Qt 6. Exercises five window sizes, shared health/battery row placement,
volume/mute controls and automatic playback, deferred Ground Details creation, hotspot parameter values,
battery chemistry thresholds, capacity, cell count, preview write blocking and closing.
No hardware commands are sent. Telemetry gaps remain `Not reported`; channel selection
is read-only because current firmware does not offer a hotspot-channel parameter.
Ground capacity is local configuration and is not sent to the FC.

Wi-Fi chipset coverage can also be run alone with
`FullStatusLayout::test_wifi_chipsets`. It checks live card-statistics fallback,
multiple CARD_TYPE_n parameters (including a second Air adapter), and clears
reported chipset names when the unit disconnects. The type labels reuse the
native WiFiCard decoder rather than maintaining a separate QML enum table.
