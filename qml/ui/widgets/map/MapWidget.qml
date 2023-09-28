import QtQuick 2.0
import QtQuick.Window 2.14
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
        switch (provider.name) {
        case "mapboxgl":{
            createMap(widgetInnerMap, "mapboxgl")
            break
        }
        case "osm":{
            createMap(widgetInnerMap, "osm")
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
        var plugin
        plugin = Qt.createQmlObject('import QtLocation 5.15; Plugin{ name:"' + provider + '"}', mapWidget);
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
                map = component.createObject(parent, {"anchors.fill": parent});
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
            variantDropdown.currentIndex = settings.selected_map_variant
            console.log("Selected map variant stored:"+settings.selected_map_variant+" actual:"+variantDropdown.currentIndex);
            map.activeMapType = map.supportedMapTypes[variantDropdown.currentIndex]
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

