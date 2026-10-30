# Offline UI simulator

Unlock developer mode with five clicks on the Credits star. Open **Application > Dev > Simulate Air / Ground**, or press **Ctrl+Shift+S** while the advanced menu is open. In Qt Creator, holding the bug button also opens the simulator after the developer unlock.

The default is ROCK 5A Ground, Raspberry Pi 4 Air, IMX708 plus an IP camera, WiFiBroadcast, and an INAV flight controller. The popup lets you select either platform, both camera types, Wi-Fi chipset, radio counts, primary/secondary link, online/disconnected/restarting state, and FC presence. Camera choices come from the existing platform camera registry. Choose Not connected to exercise one-camera layouts.

Choose **Normal**, **Advanced**, or **Developer** under **Settings mode**. Normal hides advanced and developer controls; Advanced shows advanced controls; Developer shows both. This only changes the simulated view, without changing your saved preferences or developer unlock. The simulation strip and shortcut still let you reopen the popup in every mode.

Apply a profile, then use the normal Status, Link, Camera, Storage, Air, Ground, Extras and RC pages. Device parameter edits are stored in separate in-memory models. Camera enable, type and format changes update the simulated camera state. Link shares, frequency, MCS and hotspot mode update the synthetic data. Scan/analysis and storage operations run locally against synthetic fixtures.

A **SIMULATION - no device writes** strip remains visible in the advanced menu. Use **Configure / Stop** to change the profile or restore live data. Restarting QOpenHD also clears simulation. Activation does not change the real platform on which QOpenHD is running.

## Isolation and limits

- Original telemetry models, parameter caches and device metadata remain separate. Stopping restores their original context bindings.
- Simulated metadata uses negative system IDs, and camera options reuse the production registry.
- Simulated native parameter and command requests are handled locally. An outbound MAVLink guard also blocks background transmissions while simulation is active.
- Ground battery configuration in the details popup uses an ephemeral settings map. Normal application preferences outside simulated device settings still retain their normal persistence behavior.
- Host reboot/service/network/restart helpers record a simulated action instead of changing the host while simulation is active.
- No firmware, radio, filesystem, camera encoder, decoder, authentication server or real video stream is emulated. Telemetry and budgets are explicit UI fixtures, not physical performance predictions. Metadata is derived from the bundled catalog and a platform/camera filter; actual firmware can expose different parameters or constraints.
- Existing live connections can remain connected and receive real telemetry into the original caches. Simulation is intended for UI configuration testing, not testing transport delivery, video quality, RF performance, firmware or reboot reliability.

See `tests/ui_simulator/README.md` for popup and native regression checks.
