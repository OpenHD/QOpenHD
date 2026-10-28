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

The package format is `GLDMAP1`, shared with OpenHD Glide and FleetControl.

## Create a map in QOpenHD

Open **OSD & Application > Map > Create offline map**. Enter a town or region,
press **Find region**, select a result, then pan/zoom the preview. Press
**50 km radius** to select the map centre, or tap a point on the preview.
The circle always has a 50 km radius (100 km across); its enclosing rectangle
is saved so the entire circle is covered. Alternatively, press **Draw rectangle**
and drag across your flying area. Choose detail and press **Create map**. Download status, rendering progress and a Cancel
button remain available while it runs. After a successful save, QOpenHD selects
**OpenHD Offline** automatically. No restart, account, paid key or Python runtime
is needed on the board.

The preview uses ordinary online OpenStreetMap tiles. Offline generation instead
requests road and waterway geometry from Overpass and renders its own PNG tiles;
it never prefetches the public OSM raster tile service. This is a simple road and
waterway map, rather than satellite imagery or the full online cartographic style.
OpenStreetMap attribution is displayed in the UI, without a watermark across the
saved tiles. Search uses Nominatim only on an explicit submitted search, with a
one-second throttle and an in-memory results cache.

Each package covers one rectangle, with zooms 0 through 13 (overview), 14
(standard), 15 (high) or 16 (maximum). Limits are 11,000 square kilometres,
262,144 tiles, 1 GiB per package and two million geometry points. Geometry is
fetched in sections of at most approximately 25 km per side. Higher detail takes
more time and storage. Polar areas beyond 85 degrees and date-line crossings are
not supported. Downloads require an internet connection. A failed or cancelled
generation never installs a partial package; existing packages stay available.

In Map settings, choose an installed package and press **Jump to map** to frame
its coverage, even when your current position is elsewhere or unavailable. This
disables following without changing GPS or reference position, and never creates
a location marker at the package centre. Use the follow button to return to your
real reference position. Small and expanded maps support pan, pinch/wheel zoom
and the + / - controls; the separate hand handle still moves the HUD widget.

## Map widget appearance

The small map defaults to **Round**. Under **OSD & Application > Map > Small map
shape**, you can also select **Rounded rectangle**. Saved shape preferences are
retained. Round maps have a 30% smaller diameter at the same size setting.
N/E/S/W labels sit outside the circle and follow the live map bearing while
staying upright. While following a connected aircraft, the round map uses
heading-up orientation so the map, aircraft symbol and compass stay aligned.

Drag in the centre to pan the map; drag the outer 18-pixel rim to move the widget
and save its position. The circular rim follows the circle. Double-click to
expand or collapse. Only small 24-pixel + / - zoom buttons remain; there is no
expand button, toolbar, hand handle or tooltip. Wheel and pinch zoom still work.
The GPS position uses the same plane symbol as the demo. Click either plane
to resume following immediately. You can also use **Follow aircraft** in Map
settings to resume following after panning or
jumping to an offline area. Expanded maps stay rectangular. Zoom controls overlay the map without reserving extra space. OpenStreetMap
attribution appears in Map settings and the expanded map, keeping the small
widget clear. Round masking uses
the normal OpenGL renderer; software rendering keeps the map visible without
the GPU mask.

## Debug flight

Use **OSD & Application > Map > Debug: circling plane** to start a map-only demo.
A fixed-wing symbol flies a 250 m radius circle once per minute, leaving a cyan
trail. Its simulated position and heading drive the map and compass; the widget
is labelled **DEMO FLIGHT**. The current map centre is used as the orbit centre
(or 50 N, 8 E if there is no usable position). Use **Stop demo flight** in the same
menu to return to real telemetry. This temporary toggle is not saved across app
restarts and never changes the flight controller or global position/ADS-B data.

## Include a map when flashing with ImageWriter

Configure a **Ground** image, then use **Create offline map** on the flash review
page. The same region search and radius/rectangle picker creates a local `.glidemap`
package and stages it for that flash. ImageWriter's existing customization path
copies it to **openhd/maps** on the Config/boot partition. QOpenHD discovers it
at `/Config/openhd/maps` on the board. Air images do not receive maps. Generation
does not flash a device; the usual flash review and write action still apply.

The portable builder and picker are mirrored in ImageWriter's `src/offlinemaps`;
keep those files identical when changing the workflow. The builder uses Qt Core,
Gui and Network; the picker additionally needs Qt Location and Positioning.

For local fixture testing, `OPENHD_MAP_SEARCH_URL` and `OPENHD_MAP_DATA_URL` can
override Nominatim and Overpass endpoints. Normal builds use their public HTTPS
endpoints. Do not point the data endpoint at a raster tile server.

Validation:

- `cmake -S tests/offline-map-builder -B build-offline-builder` and build/run
  `offline-map-builder-test` test search, bounds, generated packages served by
  the production offline provider, incomplete responses and cancellation.
- `python tests/run_offline_map_ui_test.py --qt-bin <Qt-5-bin>` tests the real
  picker, rectangle selection and create action; its generator is a fixture.
- ImageWriter has a corresponding `offline_map_builder_tests` target under
  `src/test` and `scripts/run_offline_map_ui_test.py`.

## Preview tile requests and caches

Online OSM maps and the create-map preview identify the app with a stable
`OpenHD-OfflineMaps/1.0 (+https://openhd.org)` User-Agent, use the explicit HTTPS
OSM tile endpoint, and disable adjacent-zoom prefetching. Qt 5's built-in legacy
HTTP map styles are not selected. Mapbox retains its provider-specific styles.
Preview tiles, normal online tiles, and localhost offline-package tiles have
separate persistent caches below the application's `map-tiles` cache directory,
so Qt's shared custom-map IDs cannot mix tiles or cached error images between
those sources. Tile-header regression tests use a local HTTP fixture rather than
requesting public tiles. On the Pi, live preview tile fetching was also checked.

When a Mapbox key is configured, the preview uses the current Mapbox Styles
raster API through a localhost-only adapter. This also provides the normal Mapbox
map on Pi Qt kits without Mapbox GL; Qt's obsolete v4 raster API is not used.
The token stays in backend requests and is never placed in QML tile URLs or
error messages. Mapbox preview attribution/logo apply only to the online display;
created `.glidemap` files still contain locally rendered OSM geometry only.
Mapbox preview data uses its own cache, separate from OSM and package tiles.
`OPENHD_MAPBOX_TILE_URL` overrides the adapter endpoint for local fixture tests.

### Online tile failures

Interactive OpenStreetMap tiles use the localhost tile adapter's `/osm/` route.
It requests the canonical HTTPS endpoint with the stable QOpenHD app identifier,
keeps an HTTP disk cache, disables viewport prefetch, and rejects HTTP errors
instead of returning their PNG error artwork to QtLocation. The online Qt cache
uses `online-https-v2` to avoid old blocked-response tiles. Offline packages remain
local-only and are generated from vector geometry, not scraped raster tiles.
Provider blocks caused by excessive traffic or network policy still require
resolution with the provider; this does not bypass them.
