# Backup and restore

`py -3.12 tests/run_settings_backup_test.py --qt-bin <Qt bin directory> --make-bin <MinGW bin directory>`
checks the real Qt backend: arbitrary writable folders, overwrite protection,
JSON/legacy validation, typed local settings, staged restart application, sequential
remote acknowledgements, disconnect/rejection handling and simulation guards.
Board, camera, Wi-Fi module, local OS/architecture/family and embedded board identity
checks run before restore; mismatches or absent hardware identity block that section.
Legacy files can be inspected but cannot be restored without verifiable hardware.
Read-only/action parameters are excluded from device snapshots; unsupported target
parameters are skipped, and rejected or interrupted restores explicitly report
that earlier changes may already be applied. No physical hardware is touched.

`py -3.12 tests/run_backup_ui_test.py --qt-bin <Qt bin directory>` checks the actual
popup and file browser with isolated services: export/import, writable-volume
filtering, /Video and USB paths, timestamp filenames, minimum file viewport at
short window sizes, cloud authentication/online gating and restore review.

FleetControl is implemented in its separate checkout. Its account-scoped API,
encrypted persistence, quota/validation and real HTTPS end-to-end authorization
checks are covered there. QOpenHD uses its existing cookie-authenticated
FleetControl connection; downloaded backups pass through the same hardware
compatibility review as local files. Filesystem access requires mounted writable
storage; this code does not partition, remount or format devices.
