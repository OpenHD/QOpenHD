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

    useDragHandle: true

    property bool mapExpanded: false

    property bool settingsVisible: false
    property bool followDrone: true

    property variant map: null
    property var mapPlugin: null
    property string mapFailure: ""
    property bool apiKeyMissing: false
    property string activeProviderName: ""

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
        variantDropdown.model = []
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
                        + 'PluginParameter { name: "osm.mapping.cache.directory"; value: ' + JSON.stringify(_offlineMapTiles.tileCacheDirectory(provider)) + ' }'
                        + 'PluginParameter { name: "osm.useragent"; value: "QOpenHD/3.0 (+https://openhd.org)" }'
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
                    + 'PluginParameter { name: "osm.mapping.cache.directory"; value: ' + JSON.stringify(_offlineMapTiles.mapboxCacheDirectory) + ' }'
                    + 'PluginParameter { name: "osm.mapping.custom.mapcopyright"; value: "Mapbox / OpenStreetMap contributors" }'
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
                "plugin": mapPlugin, "forceCustomMapType": provider === "openhd_offline"})
            if (!map) {
                clearMap()
                mapFailure = qsTr("Unable to create the map. Choose another provider or retry in map settings.")
                return
            }
            map.gesture.enabled = mapExpanded
            if (previousCenter && previousCenter.isValid)
                map.center = previousCenter
        } catch (error) {
            // Qt errors may include source text containing the token. Never log it.
            clearMap()
            mapFailure = qsTr("Unable to initialize the map. Choose another provider or retry in map settings.")
        }
    }

    function setup_map_variant() {
        var types = map ? map.supportedMapTypes : []
        variantDropdown.model = types
        if (!types.length) {
            variantDropdown.currentIndex = -1
            return
        }
        var index = activeProviderName !== "mapboxgl" ? types.length - 1 : settings.selected_map_variant
        if (index < 0 || index >= types.length)
            index = 0
        variantDropdown.currentIndex = index
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
        function onShow_mapChanged() { scheduleMapConfigure() }
        function onSelected_map_providerChanged() { scheduleMapConfigure() }
        function onSelected_map_variantChanged() { if (map) setup_map_variant() }
        function onMap_api_keyChanged() {
            if (settings.selected_map_provider >= 0 && settings.selected_map_provider < pluginModel.count
                    && pluginModel.get(settings.selected_map_provider).name === "mapboxgl") {
                scheduleMapConfigure()
            }
        }
    }

    /*function getPlugins() {
        var plugin = Qt.createQmlObject ('import QtLocation 5.12; Plugin {}', page)
        var tempPlugin
        var myArray = new Array()
        for (var i = 0; i<plugin.availableServiceProviders.length; i++){
            tempPlugin = Qt.createQmlObject ('import QtLocation 5.12; Plugin {name: "' + plugin.availableServiceProviders[i]+ '"}', page)

            if (tempPlugin.supportsMapping()
             && tempPlugin.supportsGeocoding(Plugin.ReverseGeocodingFeature)
             && tempPlugin.supportsRouting()) {
                myArray.push(tempPlugin.name)
            }
        }

        return myArray
    }*/

    mini_zoomSlider.onValueChanged: {
        settings.map_zoom = mini_zoomSlider.value
    }

    mini_sizeSlider.onValueChanged: {
        settings.map_size = mini_sizeSlider.value
        // mapWidget.scale = mini_sizeSlider.value
        mapWidget.height = 135*mini_sizeSlider.value
        mapWidget.width = 200*mini_sizeSlider.value
    }

    openclose_button.onClicked: {
        if (mapExpanded) {
            console.log("X button clicked")
            configureSmallMap()
        } else {
            console.log("gear button clicked")
            launchPopup()
        }
    }

    Behavior on sidebar_wrapper.width {
        NumberAnimation {
            duration: 200
        }
    }

    Behavior on sidebar_wrapper.height {
        NumberAnimation {
            duration: 200
        }
    }

    // Changing the provider needs destroy and reconstruct
    providerDropdown.onActivated: {
        settings.selected_map_provider = index
        scheduleMapConfigure()
    }

    // Changing the variant can happen dynamically
    variantDropdown.onActivated: {
        console.log("variantDropdown.onActivated:"+index);
        settings.selected_map_variant = index
        setup_map_variant();
    }


    function configureLargeMap() {
        console.log("configureLargeMap()")
        if (mapExpanded == false) {
            resetAnchors()
            setAlignment(0, 0, 48, false, false, true)
            if (map) map.gesture.enabled = true
            mapExpanded = !mapExpanded
            scale = 1
        }
    }

    function configureSmallMap() {
        console.log("configureSmallMap()")
        resetAnchors()
        mapWidget.width = 200*settings.map_size
        mapWidget.height = 135*settings.map_size
        //mapWidget.map
        loadAlignment()
        followDrone = true
        settingsVisible = false
        if (map) map.gesture.enabled = false
        mapExpanded = !mapExpanded
        //scale = settings.map_size
        //mapWidget.widgetInner.opacity = 0
    }

    function launchPopup() {
        mapWidget.hasWidgetDetail = true
        widgetDetail.open()
    }
}
