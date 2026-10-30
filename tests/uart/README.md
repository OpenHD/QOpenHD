# UART settings

Run `py -3.12 tests/run_uart_settings_test.py --qt-bin <Qt bin directory>`.
The fixture uses the real Extras UART panel, existing shared AirSettingRow,
metadata-driven editors, port picker, dialogs, cards and controls. OpenHD models
are isolated fixtures; no hardware or serial commands are sent.

Coverage: Air FC settings versus Ground tracker settings, separate Air/Ground
serial telemetry endpoints, Ground configuration while Air is disconnected,
disconnected/preview write blocking, metadata updates, blank-port validation,
conflicting explicit device paths on the same unit, advanced traffic priorities,
and responsive layouts. Standard board-default aliases are not treated as the
same physical device because OpenHD resolves them per serial role.

All controls reuse existing persisted OpenHD parameters and callbacks. No new
serial transport, CRSF decoder, guessed baud preset, or video-over-UART feature
is introduced. The serial link expects MAVLink from the attached radios/bridges;
external mLRS/ELRS Backpack settings must match the selected port and baud rate.
