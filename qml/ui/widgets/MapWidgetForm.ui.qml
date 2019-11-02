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
    defaultAlignment: 1
    defaultXOffset: 12
    defaultYOffset: 48

    widgetIdentifier: "map_widget"

    hasWidgetDetail: false
    hasWidgetPopup: true

    widgetPopup: Popup {
        id: map_popup
        parent: Overlay.overlay

        x: Math.round((Overlay.overlay.width - width) / 2)
        y: Math.round((Overlay.overlay.height - height) / 2)

        width: applicationWindow.width
        height: applicationWindow.height - 96

        padding: 0
        rightPadding: 0
        bottomPadding: 0
        leftPadding: 0
        topPadding: 0
        margins: 0
        rightMargin: 0
        bottomMargin: 0
        leftMargin: 0
        topMargin: 0
        modal: true
        clip: true

        visible: false

        Plugin {
            id: mapPluginLarge
            name: "osm" // "mapboxgl", "esri", ...
            // specify plugin parameters if necessary
            // PluginParameter {
            //     name:
            //     value:
            // }
        }

        Map {
            anchors.fill: parent
            copyrightsVisible: false

            plugin: mapPluginLarge
            zoomLevel: 12
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

            Button {
                id: close_button

                width: 24
                height: 24
                flat: true

                checkable: false

                //     display: AbstractButton.IconOnly
                Text {
                    anchors.horizontalCenter: parent.horizontalCenter
                    anchors.verticalCenter: parent.verticalCenter
                    font.family: "Font Awesome 5 Free-Solid-900.otf"
                    color: "black"
                    text: "\uf30c"
                }

                onClicked: {
                    print("Map resize large clicked")
                    map_popup.close()
                }

                anchors.topMargin: 0
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
            copyrightsVisible: false
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

            Button {
                id: resize

                width: 24
                height: 24
                flat: true

                checkable: false

                //     display: AbstractButton.IconOnly
                Text {
                    anchors.horizontalCenter: parent.horizontalCenter
                    anchors.verticalCenter: parent.verticalCenter
                    font.family: "Font Awesome 5 Free-Solid-900.otf"
                    color: "black"
                    text: "\uf30c"
                }

                anchors.topMargin: 0

                onClicked: {
                    map_popup.open()
                }
            }
        }
    }
}

/*##^##
Designer {
    D{i:0;invisible:true}
}
##^##*/
