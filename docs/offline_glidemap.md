# OpenHD offline maps

QOpenHD can use the same `.glidemap` packages as OpenHD Glide. Select **OpenHD Offline** in the map provider list;
the existing QtLocation map, vehicle track, home marker, mission items, ADS-B overlays, pan, and pinch zoom continue to
work normally, but map tile requests remain entirely local.

QOpenHD searches these locations:

- `GLIDE_MAP_PACKAGE_DIR` when explicitly configured;
- `/usr/share/openhd-glide/assets/maps/packages`;
- `/usr/local/share/openhd-glide/assets/maps/packages`;
- the platform application-data `maps` directory;
- `$XDG_DATA_HOME/openhd-glide/maps` on Linux.
- `~/openhd-glide/assets/maps/packages` for side-by-side desktop development.

The embedded adapter binds an ephemeral TCP port on `127.0.0.1` and exposes packaged PNGs as an XYZ endpoint to the
Qt OSM mapping plugin. It never binds a LAN interface and the offline provider has no internet fallback. Packages are
selected from GPS bounds using highest available zoom and then smallest covered area; tile lookup can still fall back
to another installed package when the user pans across package boundaries.

The package format is `GLDMAP1`, produced by OpenHD Glide's `scripts/generate_offline_osm_tiles.py`.
