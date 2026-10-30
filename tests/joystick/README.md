# Joystick assignment

Run `py -3.12 tests/run_joystick_settings_test.py --qt-bin <Qt bin directory>`.
The fixture uses the real Extras joystick panel and shared menu controls with
isolated OpenHD parameter models and raw input telemetry. It covers all 324
input/output pairs, input learning, disabling outputs, atomic map saves, rejected
writes, old firmware, armed-state restrictions, input monitor teardown, Lua free
blocks, and layouts at 1200, 750 and 440 logical pixels.

OpenHD owns joystick reading and transmission. `RC_CHAN_MAP` remains an 18-value
output-to-input mapping; `0` releases an output on firmware advertising
`JOY_MAP_V2`. Old positive mappings remain compatible. `JOY_MONITOR` starts the
existing reader without enabling RC transmission and emits raw `RC_CHANNELS`
only to local ground clients. QOpenHD keeps this separate from mapped RC override
and FC channels. Leaving the page stops its monitor request. The existing
`ENABLE_JOY_RC` setting independently controls transmission.

The Lua helper selects four consecutive unassigned joystick outputs and updates
Air `RC_SET_BASE`. It cannot inspect ELRS transmitter mixes; the user must match
D2/D1/D0/CLK in the transmitter Lua tool and verify those mixes separately.
It never clears an occupied block or automatically enables the Lua protocol.

Backend mapping coverage is `OpenHD/ohd_telemetry/test/test_channel_mapping.cpp`.
It checks every input/output pair, strict parsing, legacy defaults, and the distinct
MAVLink release values for channels 1-8 and 9-18. Neither the UI fixture nor the
backend mapping test substitutes for a connected joystick/ELRS test.
