# Using the OpenHD MAVLink profile from external applications

This note summarizes how third-party tools can re-use the same MAVLink profile QOpenHD relies on to configure and query an OpenHD air/ground pair. It focuses on the OpenHD-specific command IDs and extended parameters that back the menu items described below and now ships with a minimal CLI you can use for quick validation.

## Connection and addressing
- OpenHD uses a custom MAVLink dialect (`openhd`).【F:lib/Readme.md†L1-L10】
- The ground station listens on TCP `5760` and the default client UDP ports are `14550` (out) and `14551` (in). Target system IDs are `100` for the ground unit and `101` for the air unit; use component ID `191` for link parameters and `100/101` for the primary/secondary cameras.【F:app/telemetry/tutil/openhd_defines.hpp†L8-L21】
- Write parameters with MAV_CMD or PARAM_EXT_SET against the air unit first and then the ground unit when you need both sides updated, mirroring `change_param_air_and_ground_blocking` in QOpenHD.【F:app/telemetry/settings/wblinksettingshelper.cpp†L183-L200】

## F1 – Find AirUnit / Channel scan
- Start a spectrum analyze pass by sending `OPENHD_CMD_INITIATE_CHANNEL_ANALYZE` to system 100 / component 191 with `param1` set to the frequency bands bitmask you want to inspect.【F:app/telemetry/action/ohdaction.cpp†L35-L44】
- Start a channel search (auto-find the air unit) by sending `OPENHD_CMD_INITIATE_CHANNEL_SEARCH` with `param1` = frequency bands bitmask and `param2` = allowed channel widths bitmask.【F:app/telemetry/action/ohdaction.cpp†L46-L55】
- Progress and results are streamed through the `openhd_wifbroadcast_*` messages (supported channels, analyze progress, scan progress). These are consumed in `WBLinkSettingsHelper` to rebuild UI state; external tools should watch the same messages to render progress and discovered channels.【F:app/telemetry/settings/wblinksettingshelper.cpp†L89-L181】

## F2 – Link
Use MAVLink extended parameters against system 101 (air) component 191 to change the live link, then optionally mirror to system 100.
- Frequency: `WB_FREQUENCY` (MHz).【F:app/telemetry/settings/param_names.h†L11-L11】
- Bandwidth: `WB_CHANNEL_W` (10/20/40/80 MHz).【F:app/telemetry/settings/param_names.h†L12-L12】【F:app/telemetry/settings/wblinksettingshelper.cpp†L67-L87】
- RF mode / modulation: `WB_MCS_INDEX` (MCS0..n enum).【F:app/telemetry/settings/param_names.h†L13-L13】
- TX power: `TX_POWER_MW` (unarmed) and `TX_POWER_MW_ARM` (armed override); RTL8812AU drivers can also use `TX_POWER_I` / `TX_POWER_I_ARMED` for index-based overrides.【F:app/telemetry/settings/param_names.h†L18-L22】

## F3 – Video
- Video mode (resolution/fps) comes from the string parameter `RESOLUTION_FPS` (values such as `1280x720@60`).【F:app/telemetry/settings/documentedparam.cpp†L244-L259】
- Codec selection is `VIDEO_CODEC` with `h264`/`h265` enumerations; bitrate and keyframe cadence are `BITRATE_MBITS` and `KEYFRAME_I` if you need manual control.【F:app/telemetry/settings/documentedparam.cpp†L261-L309】
- Orientation: use `ROTATION_FLIP` (mirror/flip) and `ROTATION_DEG` (0 or 180 degrees).【F:app/telemetry/settings/documentedparam.cpp†L322-L340】

## F4 – Camera menu (O)
Most camera ISP controls are exposed as extended parameters. Values depend on the active camera stack (gstreamer/libcamera), but the IDs below match QOpenHD:
- ISO: `ISO` (0 = auto).【F:app/telemetry/settings/documentedparam.cpp†L351-L353】
- Contrast / Sharpness / Saturation (libcamera): `CONTRAST_LC`, `SHARPNESS_LC`, `SATURATION_LC`.【F:app/telemetry/settings/documentedparam.cpp†L438-L467】
- White balance: `AWB_MODE` for gstreamer pipelines or `AWB_MODE_LC` for libcamera.【F:app/telemetry/settings/documentedparam.cpp†L354-L389】【F:app/telemetry/settings/documentedparam.cpp†L418-L423】
- Additional exposure tools (metering, shutter, exposure bias) follow the `*_LC` names shown in the source if you need parity with QOpenHD menus.【F:app/telemetry/settings/documentedparam.cpp†L413-L477】

## F5 – Recording
- `AIR_RECORDING_E` controls air-side recording with enum values `DISABLE`, `ENABLE`, and `AUTO(armed)` to mirror the On/Off/Auto UI states.【F:app/telemetry/settings/documentedparam.cpp†L269-L273】
- TODO: Expose a dedicated target selector that distinguishes Air vs. Goggles vs. Both. The current implementation only offers the air-unit flag above.
- TODO: Surface a telemetry message for remaining recording space; QOpenHD does not currently export a volume indicator.

## F6 – Stats (O)
- TODO: Add a verbosity/diagnostic level parameter or message; no dedicated stats-verbosity field is published in the current tree.

## CLI helper for quick testing
The repository ships a lightweight helper that can issue these commands without running QOpenHD. Build it with CMake (preferred):

```bash
cmake -S integration -B build/integration
cmake --build build/integration
```

You can still build it directly with `g++` if you prefer:

```bash
g++ -std=c++17 -Ilib/mavlink-headers -Ilib/mavlink-headers/mavlink/v2.0 \
  integration/openhd_mavlink_tool.cpp -o integration/openhd_mavlink_tool
```

Examples (UDP endpoint defaults to `127.0.0.1:14550`):

- Scan 5.8 GHz bands (mask `4`) and widths (mask `7`) using the auto-search command:
  ```bash
  ./integration/openhd_mavlink_tool scan --bands 4 --widths 7 --search
  ```
- Set link frequency, bandwidth, and RF mode on both air and ground:
  ```bash
  ./integration/openhd_mavlink_tool set-link --frequency 5805 --bandwidth 20 --mcs 3
  ```
- Configure video and camera parameters:
  ```bash
  ./integration/openhd_mavlink_tool set-video --mode 1280x720@60 --codec h265 --bitrate 12 --keyframe 60 --rotation 0 --flip 0
  ./integration/openhd_mavlink_tool set-camera --iso 200 --awb auto --contrast 1 --sharpness 1 --saturation 0
  ```
- Toggle air-unit recording:
  ```bash
  ./integration/openhd_mavlink_tool set-recording --mode auto
  ```

## Implementation checklist for external clients
1. Open a MAVLink session to the ground station (TCP `5760` preferred) and subscribe to the OpenHD dialect.
2. Use the system/component IDs above when issuing `PARAM_EXT_` requests and `COMMAND_LONG` calls.
3. Track `openhd_wifbroadcast_*` telemetry to mirror scan/analyze workflows and rebuild your menu options when supported channels change.
4. Apply parameter writes to the air unit first, then mirror to the ground unit if you need deterministic synchronization.
