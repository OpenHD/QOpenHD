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

    hasWidgetDetail: true

    widgetDetailComponent: Column {
        Item {
            width: parent.width
            height: 24
            Text {
                text: "MSL or Relative"
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
                                           "second_alt_msl_rel", true)
                // @disable-check M222
                onCheckedChanged: settings.setValue("second_alt_msl_rel",
                                                    checked)
            }
        }
    }

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

                width: 20
                height: 20
                flat: true

                checkable: false

                //     display: AbstractButton.IconOnly
                Text {
                    anchors.horizontalCenter: parent.horizontalCenter
                    anchors.verticalCenter: parent.verticalCenter
                    font.family: "Font Awesome 5 Free-Solid-900.otf"
                    color: "black"
                    text: "\ue311"
                }

                onClicked: {
                    print("Map resize large clicked")
                    map_popup.close()
                }


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

                width: 20
                height: 20


                flat: true

                checkable: false

                //     display: AbstractButton.IconOnly
                Text {
                    anchors.horizontalCenter: parent.horizontalCenter
                    anchors.verticalCenter: parent.verticalCenter
                    font.family: "Font Awesome 5 Free-Solid-900.otf"
                    color: "black"
                    text: "\ue311"
                }

                onClicked: {
                    map_popup.open()
                }

            }
        }
    }
}
