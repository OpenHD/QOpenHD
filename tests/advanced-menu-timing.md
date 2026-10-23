# Advanced menu timing diagnostics

Timing is automatic whenever the advanced menu opens. No debug switch is needed.
On Linux SBC images the rotating file is alongside OpenHD's persistent logs:

```
/Video/logs/openhd/qopenhd-advanced-menu-timing.jsonl
```

Legacy `/Videos` and `/external/Videos` recording partitions are detected using
`external_video_part.txt`, matching OpenHD. `OPENHD_PERSISTENT_LOG_DIR` overrides
the log directory when set in QOpenHD's environment. Other platforms use Qt's
application data directory under `logs/advanced-menu-timing.jsonl`.
The `open_requested` record includes the actual file path. File I/O runs on the
worker thread. Rotation keeps the current file and one `.1` backup, about 1 MiB
in total. The timing file is always enabled independently of OpenHD's general
persistent logging switch.

Ask users to reproduce the delay and send **both files**. If opening never
finishes, collect the files while QOpenHD is still running. The same records
appear in the system journal with the prefix `ADVANCED_MENU_TIMING`:

```sh
journalctl -u qopenhd --no-pager -o cat | grep ADVANCED_MENU_TIMING
```

The existing **Developer tools > Write Ground log** action exports the journal
to `/boot/openhd/openhd.log`, including these records.

Records sharing `pid` and `open_id` describe one opening:

- `open_requested`: begins before activating the root QML loader; `cached_root`
  distinguishes first use from reopening.
- `stage`: root/selected page loader progress. Loader status numbers are
  0 = Null, 1 = Ready, 2 = Loading, 3 = Error.
- `page_ready`: the menu root and selected page exist; `ready_ms` measures this.
- `first_frame`: a frame synchronized after readiness was presented;
  `elapsed_ms` measures the complete open. A frame already in flight before
  readiness cannot finish the measurement.
- `still_loading`: every five seconds until completion, even when the GUI event
  loop is blocked. Includes the last phase, current/maximum GUI and frame gaps,
  Air/Ground/FC connectivity, telemetry rate, and parameter fetch busy/progress
  state for Ground, Air, and both cameras.
- `failed` or `cancelled`: ends an incomplete opening explicitly.

`gui_thread_stalled` means the GUI heartbeat has not run for at least one second.
`no_presented_frames` means the GUI heartbeat runs but frames are absent for at
least two seconds. `qml_not_ready` means loading has not completed while those
heartbeats remain responsive. These are observations for diagnosis, not proof
of a particular cause. During a GUI stall the telemetry/parameter snapshot is
necessarily stale; `snapshot_age_ms` makes this visible. No parameter values or
position data are recorded. A process suspended by the OS or blocked storage
can delay the watchdog's own output.

Regression check (Qt 5, C++17): build `advanced_menu_diagnostics_test.pro` and run
with `QT_QPA_PLATFORM=offscreen`. It blocks the GUI, checks independent reporting,
frame synchronization, reopen/cancel/failure handling, and rotation.
