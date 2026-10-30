# Map settings dashboard

Run with a Qt 5.15 or Qt 6 qmltestrunner, Material controls, and the software backend:

    qmltestrunner -input tests/map_settings -o build/map-settings-results.txt,txt

The suite loads the production dashboard and checks round defaults, actual setting writes,
zoom propagation, preview viewport restoration, Developer-only controls, offline search and
builder calls, plus wide/compact/narrow layouts. The map canvas and offline builder are local
fixtures: screenshots prove layout, not live imagery or successful package generation.

`tests/run_map_provider_test.py --qt-bin <Qt bin>` additionally checks the production map
lifecycle, provider switching/recovery and real Qt Location pan/follow interactions.
