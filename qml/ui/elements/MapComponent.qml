import QtQuick 2.12
import QtQuick.Controls 2.12
import QtQuick.Shapes 1.0

import QtLocation 5.12
import QtPositioning 5.12


Map {
    id: map
    copyrightsVisible: false
    zoomLevel: settings.map_zoom

    // Enable pan, flick, and pinch gestures to zoom in and out
    gesture.enabled: true
    gesture.acceptedGestures: MapGestureArea.PanGesture | MapGestureArea.FlickGesture | MapGestureArea.PinchGesture | MapGestureArea.RotationGesture | MapGestureArea.TiltGesture
    gesture.flickDeceleration: 3000

    bearing: settings.map_orientation ? 360 : OpenHD.hdg


    property double userLat: 0.0
    property double userLon: 0.0

    center {                
        latitude: OpenHD.lat == 0.0 ? userLat : followDrone ? OpenHD.lat : 9000
        longitude: OpenHD.lon == 0.0 ? userLon : followDrone ? OpenHD.lon : 9000
    }


    onZoomLevelChanged: {
        settings.map_zoom = zoomLevel
    }

    PositionSource {
        id: positionSource
        updateInterval: 5000
        active: true

        onPositionChanged: {
            userLat = position.coordinate.latitude
            userLon = position.coordinate.longitude
        }
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
            var coord = map.toCoordinate(Qt.point(mouse.x,
                                                  mouse.y))
            console.log(coord.latitude, coord.longitude)
        }
    }

    MapQuickItem {
        id: dronemarker
        coordinate: QtPositioning.coordinate(OpenHD.lat, OpenHD.lon)
        anchorPoint.x : 0
        anchorPoint.y : 0

        sourceItem: Shape {
            anchors.fill: parent

            ShapePath {
                capStyle: ShapePath.RoundCap
                strokeColor: "darkBlue"
                fillColor: "blue"
                strokeWidth: 1
                strokeStyle: ShapePath.SolidLine

                startX: 0
                startY: 0

                PathLine { x: 10;                y: 17  } //right bottom
                PathLine { x: 0;                 y: 13  } //middle bottom
                PathLine { x: -10;               y: 17  } //left bottom
                PathLine { x: 0;                 y: 0   } //back to start
            }
            
            transform: Rotation {
                origin.x: 0;
                origin.y: 0;
                angle: settings.map_orientation ? OpenHD.hdg : 0
            }
        }
    }
}
