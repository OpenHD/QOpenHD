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

    property variant map
    property bool apiKeyMissing: false
    property string activeProviderName: ""

    Component.onCompleted: {
        // TODO: Figure out how we can get better (terrain) maps
        if(false){
            pluginModel.append({
                                   "name": "mapboxgl",
                                   "description": "MapboxGL"
                               })
        }
        // Consti10: This way we need a restart of QOpenHD when the map is enabled, but we
        // save some performance in case the map is not enabled
        if(settings.show_map){
            configure()
        }
    }

    function configure() {
        if(settings.selected_map_provider>=pluginModel.count){
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

    // To create the map, we know the provider.
    // The map variant (aka street view, terrain view, ...) is set later
    function createMap(parent, provider) {
        console.log("createMap(" + provider + ")");
        apiKeyMissing = false;
        var plugin
        if (provider === "mapboxgl") {
            if (!settings.map_api_key || settings.map_api_key.length === 0) {
                console.log("MapboxGL provider selected without API key");
                apiKeyMissing = true;
                if (map) {
                    map.destroy();
                    map = null;
                }
                return;
            }
            plugin = Qt.createQmlObject(`
                                        import QtLocation 5.15
                                        Plugin {
                                        name: "` + provider + `"
                                        PluginParameter { name: "mapbox.access_token"; value: "` + settings.map_api_key + `" }
                                        }
                                        `, mapWidget);
        } else if (provider === "openhd_offline") {
            plugin = Qt.createQmlObject(`
                                        import QtLocation 5.15
                                        Plugin {
                                        name: "osm"
                                        PluginParameter { name: "osm.mapping.providersrepository.disabled"; value: true }
                                        PluginParameter { name: "osm.mapping.custom.host"; value: "` + _offlineMapTiles.baseUrl + `" }
                                        PluginParameter { name: "osm.mapping.custom.mapcopyright"; value: "OpenStreetMap contributors" }
                                        PluginParameter { name: "osm.mapping.custom.datacopyright"; value: "OpenStreetMap contributors" }
                                        }
                                        `, mapWidget);
        } else {
            plugin = Qt.createQmlObject(`
                                        import QtLocation 5.15
                                        Plugin {
                                        name: "` + provider + `"
                                        PluginParameter {
                                        name: "osm.mapping.custom.host";
                                        value: "https://tile.openstreetmap.org/" }
                                        }
                                        `, mapWidget);
        }
        console.log("Using plugin: " + plugin.name);

        if (plugin.supportsMapping()) {
            // Store previous center for a more fluent transition
            var previousCenter;
            // Completely delete any previously created map (the plugin cannot be changed dynamically)
            if (map) {
                previousCenter = map.center;
                map.destroy()
            }
            var component = Qt.createComponent("qrc:///ui/widgets/map/MapComponent.qml");
            if (component.status === Component.Ready) {
                map = component.createObject(parent, {"anchors.fill": parent, "forceCustomMapType": provider === "openhd_offline"});
                map.plugin = plugin;

                map.gesture.enabled = true;

                if (previousCenter) {
                    map.center = previousCenter;
                }
            } else {
                console.log(component.errorString())
            }
        }else{
            console.log("Plugin does not support mapping");
        }
    }

    function setup_map_variant(){
        if (map) {
            variantDropdown.model = map.supportedMapTypes
            variantDropdown.currentIndex = activeProviderName === "openhd_offline" ? Math.max(0, map.supportedMapTypes.length - 1) : settings.selected_map_variant
            console.log("Selected map variant stored:"+settings.selected_map_variant+" actual:"+variantDropdown.currentIndex);
            map.activeMapType = map.supportedMapTypes[variantDropdown.currentIndex]
        }
    }

    Rectangle {
        anchors.fill: widgetInnerMap
        visible: activeProviderName === "openhd_offline" && !_offlineMapTiles.available
        color: "#d0090e0f"
        z: 20
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
        function onMap_api_keyChanged() {
            if (settings.selected_map_provider < pluginModel.count
                    && pluginModel.get(settings.selected_map_provider).name === "mapboxgl") {
                configure()
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
        configure()
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
            map.gesture.enabled = true
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
        map.gesture.enabled = false
        mapExpanded = !mapExpanded
        //scale = settings.map_size
        //mapWidget.widgetInner.opacity = 0
    }

    function launchPopup() {
        mapWidget.hasWidgetDetail = true
        widgetDetail.open()
    }
}
