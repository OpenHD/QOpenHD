import QtQuick 2.12
import QtQuick.Controls 2.12
import QtQuick.Layouts 1.12
import QtGraphicalEffects 1.12
import QtQuick.Shapes 1.0

import Qt.labs.settings 1.0

import QtQuick.Window 2.12
import QtLocation 5.12
import QtPositioning 5.12

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
                text: "Google or Bing"
                color: "white"
                font.bold: true
                font.pixelSize: detailPanelFontPixels
                anchors.left: parent.left
            }
            Switch {
                width: 32
                height: parent.height
                anchors.rightMargin: 12
                anchors.right: parent.right
                // @disable-check M222
                Component.onCompleted: checked = settings.value(
                                           "map_bing_google", true)
                // @disable-check M222
                onCheckedChanged: settings.setValue("map_bing_google", checked)
            }
        }
        Item {
            width: parent.width
            height: 24
            Text {
                text: "Default Zoom"
                color: "white"
                font.bold: true
                font.pixelSize: detailPanelFontPixels
                anchors.left: parent.left
            }
            Switch {
                width: 32
                height: parent.height
                anchors.rightMargin: 12
                anchors.right: parent.right
                // @disable-check M222
                Component.onCompleted: checked = settings.value("map_zoom",
                                                                true)
                // @disable-check M222
                onCheckedChanged: settings.setValue("map_zoom", checked)
            }
        }
        Item {
            width: parent.width
            height: 24
            GroupBox{
                height: parent.height
                anchors.rightMargin: 12
                anchors.right: parent.right
                ComboBox{
                    model:mapsmall.supportedMapTypes
                    textRole:"description"
                    onCurrentIndexChanged: mapsmall.activeMapType = mapsmall.supportedMapTypes[currentIndex],
                    maplarge.activeMapType = maplarge.supportedMapTypes[currentIndex]
                }
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
            name: "osm" // "osm" , "mapboxgl", "esri", ...

         //   PluginParameter { name: "here.app_id"; value: "****" }
         //   PluginParameter { name: "here.token"; value: "*****" }
        }

        Map {
            anchors.fill: parent
            copyrightsVisible: false
            id: maplarge
            plugin: mapPluginLarge
            zoomLevel: 18
            // Enable pan, flick, and pinch gestures to zoom in and out
            gesture.enabled: true
            gesture.acceptedGestures: MapGestureArea.PanGesture | MapGestureArea.FlickGesture | MapGestureArea.PinchGesture | MapGestureArea.RotationGesture | MapGestureArea.TiltGesture
            gesture.flickDeceleration: 3000


            activeMapType: MapType.SatelliteMapDay
            center {
                latitude: OpenHD.lat_raw
                longitude: OpenHD.lon_raw
            }

            MapQuickItem {
                id: homemarkerLargeMap
                anchorPoint.x: imageLargeMap.width / 2
                anchorPoint.y: imageLargeMap.height
                coordinate {
                    latitude: OpenHD.homelat_raw
                    longitude: OpenHD.homelon_raw
                }

                sourceItem: Image {
                    id: imageLargeMap
                    source: "home_marker.png"
                }
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

//get coordinates on click... for future use
            MouseArea{
                    anchors.fill: parent
                    onClicked: {
                        var coord = maplarge.toCoordinate(Qt.point(mouse.x,mouse.y));
                        console.log(coord.latitude, coord.longitude)
                    }
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



//// ------------------------- split between large map above and small map below------------




    Item {
        id: widgetInner
        anchors.fill: parent

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
            id:mapsmall
            zoomLevel: 18
            gesture.enabled: false

            //      activeMapType: MapType.SatelliteMapDay
            bearing: OpenHD.hdg_raw

            center {
                latitude: OpenHD.lat_raw
                longitude: OpenHD.lon_raw
            }

            MapQuickItem {
                id: homemarkerSmallMap
                anchorPoint.x: imageSmallMap.width / 2
                anchorPoint.y: imageSmallMap.height
                coordinate {
                    latitude: OpenHD.homelat_raw
                    longitude: OpenHD.homelon_raw
                }

                sourceItem: Image {
                    id: imageSmallMap
                    source: "home_marker.png"
                }
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
