import QtQuick 2.13
import QtQuick.Controls 2.13
import QtQuick.Layouts 1.13
import QtGraphicalEffects 1.13
import QtQuick.Shapes 1.0

import Qt.labs.settings 1.0

import QtQuick.Window 2.13
import QtLocation 5.13
import QtPositioning 5.13

import OpenHD 1.0

BaseWidget {
    id: mapWidget
    width: 100
    height: 100

    // resize with right side (technically top right, but it doesn't matter because VCenter is set)
    defaultAlignment: 1
    defaultXOffset: 685
    defaultYOffset: 296

    widgetIdentifier: "map_widget"

    hasWidgetDetail: true
    widgetDetailComponent: Column {
        Item {
            width: parent.width
            height: 24
            Text {
                text: "Google or Bing"
                color: "white"
                font.bold: true
                font.pixelSize: detailPanelFontPixels;
                anchors.left: parent.left
            }
            Switch {
                width: 32
                height: parent.height
                anchors.rightMargin: 12
                anchors.right: parent.right
                // @disable-check M222
                Component.onCompleted: checked = settings.value(
                                           "map_google_bing", true)
                // @disable-check M222
                onCheckedChanged: settings.setValue("map_google_bing", checked)
            }
        }
    }

    Item {
        id: widgetInner
        anchors.fill: parent

        PositionSource {
            id: positionSource
        }

        Plugin {
            id: mapPlugin
            name: "osm" // "mapboxgl", "esri", ...
            // specify plugin parameters if necessary
            // PluginParameter {
            //     name:
            //     value:
            // }
        }

        Map {
            anchors.fill: parent
            plugin: mapPlugin
            zoomLevel: 19
            gesture.enabled: false

            center {

                latitude: OpenHD.lat_raw
                longitude: OpenHD.lon_raw
            }

            MapCircle {
                center {
                    latitude: OpenHD.lat_raw
                    longitude: OpenHD.lon_raw
                }
                radius: OpenHD.gps_hdop
                color: 'red'
                opacity: .3
            }

            MapCircle {
                center {
                    latitude: OpenHD.lat_raw
                    longitude: OpenHD.lon_raw
                }
                radius: 1
                color: 'blue'
                border.width: 1
                opacity: .75
            }
        }
    }
}

/*##^##
Designer {
    D{i:0;invisible:true}
}
##^##*/

