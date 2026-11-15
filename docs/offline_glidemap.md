# OpenHD offline maps

OpenHD Offline prefers local Shortbread vector `.mbtiles` packs. Download a
region in ImageWriter or import a Shortbread extract. ImageWriter installs the
selected pack at `/Config/openhd/maps` when flashing a Ground image.

On an existing QOpenHD installation, open **OSD & Application > Map > Offline
Maps > Open map folder**, copy in an MBTiles file, and select **Reload maps**.
Select **OpenHD Offline** or use **Jump to map** to visit a pack's coverage
without a GPS fix. With a default provider setting and an installed MBTiles
pack, QOpenHD automatically chooses **OpenHD Offline**. Existing explicit
provider settings are respected. For development, `OPENHD_MAP_PACKAGE_DIR` can
point to a separate pack directory.

QOpenHD reads SQLite packs in read-only mode and serves vector tiles, style
and bundled glyphs on loopback. The map renderer draws the vector data in
real time. A compatible MapLibre Qt Location plugin is preferred when
available. The Windows Qt 5 build uses its bundled Mapbox GL renderer with a
local style and no Mapbox account or key. Qt kits without either vector
renderer require one to display MBTiles.

Existing `.glidemap` files still work through the raster provider. Choose one in
the installed maps list and select **Jump to map** to use it when both
formats are installed. The legacy raster creator remains in developer
settings. FleetControl and Glide still use GLDMAP1 where applicable.

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
