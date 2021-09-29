import QtQuick 2.12
import QtQuick.Window 2.12
import QtQuick.Layouts 1.12
import QtLocation 5.12

import "../elements";


MapWidgetForm {
    id: mapWidget

    useDragHandle: true

    property bool mapExpanded: false

    property bool settingsVisible: false
    property bool followDrone: true

    property variant map

    Component.onCompleted: {
        if (!IsRaspPi) {
            pluginModel.append({
                                   "name": "mapboxgl",
                                   "description": "MapboxGL"
                               })
        }
        configure()
    }

    function createMap(parent, provider) {
        console.log("createMap(" + provider + ")");

        var plugin = Qt.createQmlObject('import QtLocation 5.12; Plugin{ name:"' + provider + '"}', mapWidget);

        console.log("Using plugin: " + plugin.name);

        if (plugin.supportsMapping()) {
            var previousCenter;

            if (map) {
                previousCenter = map.center;
                map.destroy()
            }

            var component = Qt.createComponent("qrc:///ui/elements/MapComponent.qml");
            if (component.status === Component.Ready) {
                map = component.createObject(parent, {"anchors.fill": parent});
                map.plugin = plugin;
                var variant = map.supportedMapTypes[settings.selected_map_variant];
                if (variant) {
                        map.activeMapType = map.supportedMapTypes[settings.selected_map_variant];
                } else {
                    /* variant wasn't found in this provider so we must reset the setting and load
                       the default variant */
                    settings.selected_map_variant = 0;
                    map.activeMapType = map.supportedMapTypes[settings.selected_map_variant];
                }

                map.gesture.enabled = true;

                if (previousCenter) {
                    map.center = previousCenter;
                }
            } else {
                console.log(component.errorString())
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

    mini_opacity_Slider.onValueChanged: {
        settings.map_opacity = mini_opacity_Slider.value
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


    providerDropdown.onActivated: {
        settings.selected_map_provider = index
        configure()
    }


    function configure() {
        var provider = pluginModel.get(settings.selected_map_provider)
        switch (provider.name) {
        case "mapboxgl":
        {
            createMap(widgetInnerMap, "mapboxgl")
            break
        }
        case "osm":
        {
            createMap(widgetInnerMap, "osm")
            break
        }
        default:
        {
            createMap(widgetInnerMap, "osm")
            break
        }
        }

        if (map) {
            variantDropdown.model = map.supportedMapTypes
            settings.selected_map_variant = index;
            variantDropdown.currentIndex = settings.selected_map_variant
            map.activeMapType = map.supportedMapTypes[variantDropdown.currentIndex]
        }
    }



//    Component.onCompleted: currentIndex = settings.selected_map_variant

    // @disable-check M223
    //Component.onActivated: {
    variantDropdown.onActivated: {
        variantDropdown.model = map.supportedMapTypes
        settings.selected_map_variant = index
        map.activeMapType = map.supportedMapTypes[index]
        map.gesture.enabled = true
    }


    function configureLargeMap() {
        if (mapExpanded == false) {
            resetAnchors()
            setAlignment(0, 0, 48, false, false, true)
            map.gesture.enabled = true
            mapExpanded = !mapExpanded
        }
    }

    function configureSmallMap() {
        resetAnchors()
        mapWidget.width = 200
        mapWidget.height = 135
        //mapWidget.map
        loadAlignment()
        followDrone = true
        settingsVisible = false
        map.gesture.enabled = false
        mapExpanded = !mapExpanded
    }

    function launchPopup() {
        mapWidget.hasWidgetDetail = true
        widgetDetail.open()
    }
}


