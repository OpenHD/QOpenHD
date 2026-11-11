# Joystick assignment

Run `py -3.12 tests/run_joystick_settings_test.py --qt-bin <Qt bin directory>`.
The fixture uses the real main-menu joystick page and mapping panel and shared menu controls with
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

The main-menu overview uses FC-reported PWM for OpenHD function ranges. Channel
popups stage joystick input and Air radio-function changes until Apply. Coverage
includes Cancel, rejected writes, stale configuration, disconnection, armed-state
protection, draft input detection, and live range highlighting. Channel width,
MCS and channel width support custom areas on Air firmware exposing
`RC_MCS_RANGES` and `RC_BW_RANGES`. Transmit mode and FHSS retain fixed thresholds.
This UI does not configure flight-controller mixes. Air parameter writes are
sequential; a partial failure leaves the popup open and reports saved changes.

The channel overview replaces the separate FC live-view card; joystick controls
sit below the overview. The popup adds multiple functions through a dropdown,
shows connected range segments with live highlighting, and keeps Apply/Cancel
visible while its body scrolls. Layout coverage includes a 440 x 480 viewport.

Select an area, choose its output value, and edit its inclusive upper PWM bound.
`+ Area` splits the selected area; Remove merges it with a neighbor. One to five
areas cover 900–2100 µs continuously; the last upper bound stays at 2100. Values
and order are independent, so users can select 10/20/40 MHz, MCS 1/3/4, or all
MCS 0–4. Defaults are 20/40 MHz and MCS 0/2/3. Apply saves each complete profile
as a PARAM_EXT string (`upper:value,...`) before moving its channel assignment.
Cancel discards drafts. Old firmware shows its original fixed profiles without
editing. Tests cover splitting, removing, boundaries, custom values, defaults,
rejected writes, stale profiles, and compatibility.
