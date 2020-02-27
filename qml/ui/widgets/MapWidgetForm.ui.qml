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
    width: 200
    height: 135

    visible: settings.show_map

    defaultAlignment: 1
    defaultXOffset: 12
    defaultYOffset: 48

    widgetIdentifier: "map_widget"

    hasWidgetDetail: true
    widgetDetailWidth: 420
    widgetDetailHeight: 200

    widgetDetailComponent: Column {
        Item {
            width: parent.width
            height: 32

            Text {
                id: zoomTitle
                height: parent.height
                text: "Zoom"
                color: "white"
                font.bold: true
                font.pixelSize: detailPanelFontPixels
                anchors.left: parent.left
                verticalAlignment: Text.AlignVCenter
            }

            Slider {
                id: zoomSlider
                orientation: Qt.Horizontal
                from: 1
                value: settings.map_small_zoom
                to: 30
                stepSize: 1
                anchors.rightMargin: 0
                anchors.right: parent.right
                anchors.leftMargin: 32
                anchors.left: zoomTitle.right
                height: parent.height

                onValueChanged: {
                    mapsmall.zoomLevel = zoomSlider.value
                    settings.map_small_zoom = zoomSlider.value
                }
            }
        }

        Item {
            width: parent.width
            height: 32

            Text {
                id: baseMapTitle
                height: parent.height
                text: "Base Map"
                color: "white"
                font.bold: true
                font.pixelSize: detailPanelFontPixels
                anchors.left: parent.left
                verticalAlignment: Text.AlignVCenter
            }

            ComboBox {
                height: parent.height
                anchors.rightMargin: 0
                anchors.right: parent.right
                anchors.leftMargin: 12
                anchors.left: baseMapTitle.right
                model: mapsmall.supportedMapTypes
                textRole: "description"
                onCurrentIndexChanged: {
                    mapsmall.activeMapType = mapsmall.supportedMapTypes[currentIndex]
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
            gesture.acceptedGestures: MapGestureArea.PanGesture | MapGestureArea.FlickGesture
                                      | MapGestureArea.PinchGesture
                                      | MapGestureArea.RotationGesture | MapGestureArea.TiltGesture
            gesture.flickDeceleration: 3000

            activeMapType: MapType.SatelliteMapDay
            center {
                latitude: followDrone ? OpenHD.lat : 9000
                longitude: followDrone ? OpenHD.lon : 9000
            }

            property bool followDrone: true

            MapQuickItem {
                id: homemarkerLargeMap
                anchorPoint.x: imageLargeMap.width / 2
                anchorPoint.y: imageLargeMap.height
                coordinate {
                    latitude: OpenHD.homelat
                    longitude: OpenHD.homelon
                }

                sourceItem: Image {
                    id: imageLargeMap
                    source: "home_marker.png"
                }
            }

            MapCircle {
                center {
                    latitude: OpenHD.lat
                    longitude: OpenHD.lon
                }
                radius: OpenHD.gps_hdop
                color: 'red'
                opacity: .3
            }

            MapCircle {
                center {
                    latitude: OpenHD.lat
                    longitude: OpenHD.lon
                }
                radius: 1
                color: 'blue'
                border.width: 1
                opacity: .75
            }

            //get coordinates on click... for future use
            MouseArea {
                anchors.fill: parent
                onClicked: {
                    var coord = maplarge.toCoordinate(Qt.point(mouse.x,
                                                               mouse.y))
                    console.log(coord.latitude, coord.longitude)
                }
            }

            Rectangle {
                anchors.top: parent.top
                anchors.topMargin: 6
                anchors.left: parent.left
                anchors.leftMargin: 6

                radius: 12
                color: "#8f000000"

                height: 144
                width: 48
                clip: true

                Button {
                    id: close_button

                    width: parent.width
                    height: 48
                    anchors.top: parent.top
                    anchors.topMargin: 0
                    anchors.left: parent.left
                    anchors.leftMargin: 0
                    flat: true

                    checkable: false

                    //     display: AbstractButton.IconOnly
                    Text {
                        anchors.horizontalCenter: parent.horizontalCenter
                        anchors.verticalCenter: parent.verticalCenter
                        font.family: "Font Awesome 5 Free"
                        color: "white"
                        text: "\uf065"
                        font.pixelSize: 20
                    }

                    onClicked: {
                        print("Map resize large clicked")
                        map_popup.close()
                    }
                }

                Button {
                    id: search_button

                    width: parent.width
                    height: 48
                    anchors.top: parent.top
                    anchors.topMargin: 48
                    anchors.left: parent.left
                    anchors.leftMargin: 0
                    flat: true

                    checkable: false

                    Text {
                        anchors.horizontalCenter: parent.horizontalCenter
                        anchors.verticalCenter: parent.verticalCenter
                        font.family: "Font Awesome 5 Free"
                        color: "white"
                        text: "\uf002"
                        font.pixelSize: 20
                    }

                    onClicked: {
                        print("Map search clicked")
                    }
                }

                Button {
                    id: follow_button

                    width: parent.width
                    height: 48
                    anchors.top: parent.top
                    anchors.topMargin: 96
                    anchors.left: parent.left
                    anchors.leftMargin: 0
                    flat: true

                    checkable: false

                    Text {
                        anchors.horizontalCenter: parent.horizontalCenter
                        anchors.verticalCenter: parent.verticalCenter
                        font.family: "Font Awesome 5 Free"
                        color: maplarge.followDrone ? "#ff00aeef" : "white"
                        text: "\uf05b"
                        font.pixelSize: 20
                    }

                    onClicked: {
                        print("Follow toggle clicked")
                        maplarge.followDrone = !maplarge.followDrone
                    }
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
            id: mapsmall
            //  zoomLevel: 18
            gesture.enabled: false

            //  activeMapType: MapType.SatelliteMapDay
            bearing: OpenHD.hdg

            center {
                latitude: OpenHD.lat
                longitude: OpenHD.lon
            }

            MapQuickItem {
                id: homemarkerSmallMap
                anchorPoint.x: imageSmallMap.width / 2
                anchorPoint.y: imageSmallMap.height
                coordinate {
                    latitude: OpenHD.homelat
                    longitude: OpenHD.homelon
                }

                sourceItem: Image {
                    id: imageSmallMap
                    source: "home_marker.png"
                }
            }

            MapCircle {
                center {
                    latitude: OpenHD.lat
                    longitude: OpenHD.lon
                }
                radius: OpenHD.gps_hdop
                color: 'red'
                opacity: .3
            }

            MapCircle {
                center {
                    latitude: OpenHD.lat
                    longitude: OpenHD.lon
                }
                radius: 1
                color: 'blue'
                border.width: 1
                opacity: .75
            }

            Button {
                id: resize

                width: 32
                height: 32

                flat: true

                checkable: false

                //     display: AbstractButton.IconOnly
                Text {
                    anchors.horizontalCenter: parent.horizontalCenter
                    anchors.verticalCenter: parent.verticalCenter
                    font.family: "Font Awesome 5 Free"
                    color: "black"
                    text: "\uf065"
                    font.pixelSize: 16
                }

                onClicked: {
                    map_popup.open()
                }
            }
        }
    }
}
