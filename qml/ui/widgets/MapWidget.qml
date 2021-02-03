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

    function createMap(parent, provider) {
        console.log("createMap(" + provider + ")");

        var plugin = Qt.createQmlObject('import QtLocation 5.12; Plugin{ name:"' + provider + '"}', mapWidget);

        console.log("Using plugin: " + plugin);

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
                    map.activeMapType = variant;
                } else {
                    /* variant wasn't found in this provider so we must reset the setting and load
                       the default variant */
                    settings.selected_map_variant = 0;
                    map.activeMapType = map.supportedMapTypes[settings.selected_map_variant];
                }

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


}
