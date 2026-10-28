import QtQuick 2.0
import QtQuick.Window 2.14
import QtQml 2.12
//import QtLocation 15.5
//import QtPositioning 15.5

import "../../elements";

// The actual Map canvas is in map/MapComponent.qml
// Here we just do integration with BaseWidget and stuff like
// managing the map pluging and resizing
// Also the .qml file is loaded dynamically, to avoid compilation issues where we don't have the map dependencies
MapWidgetForm {
    id: mapWidget

    useDragHandle: false
    disable_dragging: true // The edge moves the widget; the centre pans the map.

    property bool mapExpanded: false

    property bool followDrone: true
    property bool demoFlight: false

    property variant map: null
    property var mapPlugin: null
    property string mapFailure: ""
    property bool apiKeyMissing: false
    property string activeProviderName: ""
    property var supportedMapTypes: []
    property int activeMapTypeIndex: -1

    // Qt.labs.settings restores values after child components complete.
    // Coalesce changes so the provider and token are restored before creating a map.
    property bool mapSettingsReady: false
    Component.onCompleted: {
        mapSettingsReady = true
        mapReconfigure.restart()
    }
    Timer {
        id: mapReconfigure
        interval: 0
        onTriggered: {
            if (settings.show_map) configure()
            else clearMap()
        }
    }
    function scheduleMapConfigure() {
        if (mapSettingsReady) mapReconfigure.restart()
    }

    function configure() {
        if(settings.selected_map_provider < 0 || settings.selected_map_provider>=pluginModel.count){
            // Fixup possibly invalid index
            settings.selected_map_provider=0;
        }
        var provider = pluginModel.get(settings.selected_map_provider)
        activeProviderName = provider.name
        switch (provider.name) {
        case "mapboxgl":{
            createMap(widgetInnerMap, "mapboxgl")
            break
        }
        case "osm":{
            createMap(widgetInnerMap, "osm")
            break
        }
        case "openhd_offline":{
            _offlineMapTiles.reload()
            createMap(widgetInnerMap, "openhd_offline")
            break
        }
        default:{
            createMap(widgetInnerMap, "osm")
            break
        }
        }
        setup_map_variant()
        if (map && pendingOfflineRegion) {
            map.showOfflineRegion(pendingOfflineRegion)
            pendingOfflineRegion = null
        }
    }

    // Each map owns a fresh plugin: QtLocation cannot switch an existing map's plugin.
    function clearMap() {
        if (map) {
            map.destroy()
            map = null
        }
        if (mapPlugin) {
            mapPlugin.destroy()
            mapPlugin = null
        }
        supportedMapTypes = []
        activeMapTypeIndex = -1
    }

    function createMap(parent, provider) {
        var previousCenter = map ? map.center : null
        clearMap()
        apiKeyMissing = false
        mapFailure = ""
        var token = settings.map_api_key.trim()
        if (provider === "mapboxgl" && !token) {
            apiKeyMissing = true
            return
        }
        // Encode values as QML literals so pasted text cannot break component creation.
        var parameters = provider === "mapboxgl"
                ? 'PluginParameter { name: "mapboxgl.access_token"; value: ' + JSON.stringify(token) + ' }'
                : 'PluginParameter { name: "osm.mapping.custom.host"; value: '
                  + JSON.stringify(provider === "openhd_offline" ? _offlineMapTiles.baseUrl : "https://tile.openstreetmap.org/") + ' }'
        if (provider !== "mapboxgl") {
            parameters += 'PluginParameter { name: "osm.mapping.providersrepository.disabled"; value: true }'
                        + 'PluginParameter { name: "osm.useragent"; value: "OpenHD-OfflineMaps/1.0 (+https://openhd.org)" }'
                        + 'PluginParameter { name: "osm.mapping.prefetching_style"; value: "NoPrefetching" }'
                        + 'PluginParameter { name: "osm.mapping.cache.directory"; value: '
                        + JSON.stringify(_offlineMapBuilder.mapCacheDirectory(provider)) + ' }'
                        + 'PluginParameter { name: "osm.mapping.custom.mapcopyright"; value: "OpenStreetMap contributors" }'
                        + 'PluginParameter { name: "osm.mapping.custom.datacopyright"; value: "OpenStreetMap contributors" }'
        }
        try {
            mapPlugin = Qt.createQmlObject('import QtLocation 5.15; Plugin { name: '
                                          + JSON.stringify(provider === "openhd_offline" ? "osm" : provider)
                                          + '; ' + parameters + ' }', mapWidget)
            if (provider === "mapboxgl" && !mapPlugin.supportsMapping()) {
                mapPlugin.destroy()
                mapPlugin = null
                _offlineMapTiles.setMapboxKey(token)
                activeProviderName = "mapbox_raster"
                var rasterParameters = 'PluginParameter { name: "osm.mapping.custom.host"; value: '
                    + JSON.stringify(_offlineMapTiles.mapboxBaseUrl) + ' }'
                    + 'PluginParameter { name: "osm.mapping.providersrepository.disabled"; value: true }'
                    + 'PluginParameter { name: "osm.mapping.prefetching_style"; value: "NoPrefetching" }'
                    + 'PluginParameter { name: "osm.useragent"; value: "OpenHD-OfflineMaps/1.0 (+https://openhd.org)" }'
                    + 'PluginParameter { name: "osm.mapping.cache.directory"; value: '
                    + JSON.stringify(_offlineMapBuilder.mapCacheDirectory("mapbox_raster")) + ' }'
                    + 'PluginParameter { name: "osm.mapping.custom.mapcopyright"; value: '
                    + JSON.stringify('<a href="https://www.mapbox.com/about/maps/">© Mapbox</a> <a href="https://www.openstreetmap.org/copyright">© OpenStreetMap</a> <a href="https://apps.mapbox.com/feedback/">Improve this map</a>') + ' }'
                mapPlugin = Qt.createQmlObject('import QtLocation 5.15; Plugin { name: "osm"; ' + rasterParameters + ' }', mapWidget)
            }
            if (!mapPlugin.supportsMapping()) {
                clearMap()
                mapFailure = qsTr("Map provider unavailable. Choose another provider in map settings.")
                return
            }
            var component = Qt.createComponent("MapComponent.qml")
            if (component.status !== Component.Ready) {
                clearMap()
                mapFailure = qsTr("Unable to load the map. Choose another provider or retry in map settings.")
                return
            }
            map = component.createObject(parent, {"anchors.fill": parent,
                "plugin": mapPlugin, "forceCustomMapType": provider === "openhd_offline",
                "compassMode": Qt.binding(function() { return mapWidget.roundMap }),
                "demoFlight": Qt.binding(function() { return mapWidget.demoFlight })})
            if (!map) {
                clearMap()
                mapFailure = qsTr("Unable to create the map. Choose another provider or retry in map settings.")
                return
            }
            if (provider === "openhd_offline" && _offlineMapTiles.packages.length) {
                var packages = _offlineMapTiles.packages
                var minZoom = 30, maxZoom = 0
                for (var i = 0; i < packages.length; ++i) {
                    minZoom = Math.min(minZoom, packages[i].minZoom)
                    maxZoom = Math.max(maxZoom, packages[i].maxZoom)
                }
                map.minimumZoomLevel = minZoom
                map.maximumZoomLevel = maxZoom
                map.zoomLevel = Math.max(minZoom, Math.min(maxZoom, settings.map_zoom))
            }
            map.expandRequested.connect(function() {
                if (mapExpanded) configureSmallMap()
                else configureLargeMap()
            })
            map.gesture.enabled = true
            if (!followDrone && previousCenter && previousCenter.isValid)
                map.center = previousCenter
        } catch (error) {
            // Qt errors may include source text containing the token. Never log it.
            clearMap()
            mapFailure = qsTr("Unable to initialize the map. Choose another provider or retry in map settings.")
        }
    }

    property var pendingOfflineRegion: null
    function jumpToOfflineMap(region) {
        if (!region) return
        followDrone = false
        pendingOfflineRegion = region
        settings.show_map = true
        settings.selected_map_provider = 2
        mapReconfigure.restart()
    }
    function zoomMap(delta) {
        if (map) map.zoomLevel = Math.max(map.minimumZoomLevel, Math.min(map.maximumZoomLevel, map.zoomLevel + delta))
    }

    function setup_map_variant() {
        var types = map ? map.supportedMapTypes : []
        supportedMapTypes = types
        if (!types.length) {
            activeMapTypeIndex = -1
            return
        }
        // OSM's built-in Qt 5 styles include retired HTTP endpoints. Our custom
        // style uses the explicit HTTPS (or localhost offline) endpoint above.
        var index = activeProviderName === "mapboxgl" ? settings.selected_map_variant : types.length - 1
        if (index < 0 || index >= types.length)
            index = 0
        activeMapTypeIndex = index
        map.activeMapType = types[index]
    }

    Rectangle {
        parent: widgetInnerMap
        anchors.fill: parent
        visible: activeProviderName === "openhd_offline" && !_offlineMapTiles.available
        color: "#d0090e0f"
        z: 1
        Text {
            anchors.centerIn: parent
            width: parent.width - 20
            horizontalAlignment: Text.AlignHCenter
            wrapMode: Text.WordWrap
            color: "white"
            text: qsTr("No offline map package installed")
        }
    }

    Connections {
        target: settings
        function onShow_mapChanged() {
            scheduleMapConfigure()
        }
        function onSelected_map_providerChanged() { scheduleMapConfigure() }
        function onSelected_map_variantChanged() { setup_map_variant() }
        function onMap_sizeChanged() { if (!mapExpanded) resizeSmallMap() }
        function onMap_roundChanged() { if (!mapExpanded) resizeSmallMap() }
        function onMap_api_keyChanged() {
            if (settings.selected_map_provider >= 0 && settings.selected_map_provider < pluginModel.count
                    && pluginModel.get(settings.selected_map_provider).name === "mapboxgl") {
                scheduleMapConfigure()
            }
        }
    }

    function configureLargeMap() {
        console.log("configureLargeMap()")
        if (mapExpanded == false) {
            resetAnchors()
            setAlignment(0, 0, 48, false, false, true)
            if (map) map.gesture.enabled = true
            mapExpanded = true
            scale = 1
        }
    }

    onFooterHeightChanged: if (!mapExpanded) resizeSmallMap()

    function resizeSmallMap() {
        mapWidget.width = compactWidth
        mapWidget.height = compactHeight
    }
    function configureSmallMap() {
        console.log("configureSmallMap()")
        resetAnchors()
        mapExpanded = false
        resizeSmallMap()
        loadAlignment()
        if (map) map.gesture.enabled = true
    }

}
