import QtQuick 2.12
import QtQuick.Controls 2.12
import QtQuick.Shapes 1.0

import QtLocation 5.12
import QtPositioning 5.12


Map {
    id: map
    copyrightsVisible: false
    zoomLevel: settings.map_zoom

    /* Enable pan, flick, and pinch gestures to zoom in and out
       gesture is false because openhd starts with small map up
    */
    gesture.enabled: false
    gesture.acceptedGestures: MapGestureArea.PanGesture | MapGestureArea.FlickGesture | MapGestureArea.PinchGesture | MapGestureArea.RotationGesture | MapGestureArea.TiltGesture
    gesture.flickDeceleration: 3000

    bearing: settings.map_orientation ? 360 : OpenHD.hdg


    property double userLat: 0.0
    property double userLon: 0.0
    property double center_coord_lat: 0.0
    property double center_coord_lon: 0.0

    center {
        latitude: OpenHD.lat == 0.0 ? userLat : followDrone ? OpenHD.lat : 9000
        longitude: OpenHD.lon == 0.0 ? userLon : followDrone ? OpenHD.lon : 9000
    }

    onCenterChanged: {
        //findMapBounds();
    }

    /*
    function findMapBounds(){
        var center_coord = map.toCoordinate(Qt.point(map.width/2,map.height/2))
        //console.log("my center",center_coord.latitude, center_coord.longitude);
        OpenSky.mapBoundsChanged(center_coord);
    }*/

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
                    radius: OpenHD.gps_hdop
                    color: 'red'
                    opacity: .3
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
            source: "/homemarker.png"
        }
    }

    /*
    MapCircle {
        id: adsbCircle
        enabled: EnableADSB

        center: OpenSky.adsb_api_coord
        radius: MarkerModel.adsb_radius

        color: "white"
        border.color: "red"
        border.width: 50
        smooth: true
        opacity: .2
    }*/

    MapItemView {
        model: BlackBoxModel
        delegate: trailDelegate
        enabled: EnableADSB

        Component {
            id: trailDelegate


            MapPolyline {
                id: polyline
                /*
               path: { //current_coord=QtPositioning.coordinate(model.lat, model.lon);
                    pathPolyline.addCoordinate(QtPositioning.coordinate(model.lat, model.lon))
                    //addCoordinate(current_coord);
                    console.log("Map Polyline=",model.lat, model.lon);
                }
    */
                path:  { polyline.addCoordinate(QtPositioning.coordinate(model.lat, model.lon));}

                line.color: "red"
                line.width: 5


            }

        }

    }


    Repeater{
        model: MarkerModel
        enabled: EnableADSB
        MapItemGroup {
            id: delegateGroup

            MapQuickItem {
                id: marker
                property alias lastMouseX: markerMouseArea.lastX
                property alias lastMouseY: markerMouseArea.lastY

                anchorPoint.x: image.width/2
                anchorPoint.y: image.height/2

                sourceItem: Image {
                    id: image
                    source: "/airplanemarkerblur.png"

                    Rectangle{// has to be here prior to rotation call
                        id: speedtail

                        x: image.width*.4
                        y: image.height*.8

                        width: image.width*.2
                        height: (model.velocity)/2
                        opacity: .5
                        color: "white"
                        border.color: "grey"
                        border.width: 1
                    }

                    rotation: {
                        var orientation = model.track-OpenHD.hdg;

                        if (orientation < 0) orientation += 360;
                        if (orientation >= 360) orientation -=360;

                        if (settings.map_orientation === false){
                            return orientation;
                        }
                        else {
                            return model.track;
                        }
                    }

                    opacity: markerMouseArea.pressed ? 0.6 : 1.0
                    MouseArea  {
                        id: markerMouseArea
                        property int pressX : -1
                        property int pressY : -1
                        property int jitterThreshold : 10
                        property int lastX: -1
                        property int lastY: -1
                        anchors.fill: parent
                        hoverEnabled : false
                        drag.target: marker
                        preventStealing: true

                        onPressed : {
                            map.pressX = mouse.x
                            map.pressY = mouse.y
                            map.currentMarker = -1
                            for (var i = 0; i< map.markers.length; i++){
                                if (marker == map.markers[i]){
                                    map.currentMarker = i
                                    break
                                }
                            }
                        }

                        onPressAndHold:{
                            if (Math.abs(map.pressX - mouse.x ) < map.jitterThreshold
                                    && Math.abs(map.pressY - mouse.y ) < map.jitterThreshold) {
                                var p = map.fromCoordinate(marker.coordinate)
                                lastX = p.x
                                lastY = p.y
                                map.showMarkerMenu(marker.coordinate)
                            }
                        }
                    }

                    Rectangle{ //holder to "derotate" info block
                        id: holder

                        x: image.width+5
                        y: image.height/2
                        rotation: {
                            var orientation = model.track-OpenHD.hdg;

                            if (orientation < 0) orientation += 360;
                            if (orientation >= 360) orientation -=360;

                            if (settings.map_orientation === false){
                                return -orientation;
                            }
                            else {
                                return -model.track;
                            }
                        }
                        width: image.width
                        height: image.height
                        color: "transparent"

                        Rectangle{
                            id: background

                            width: image.width*1.25
                            height: image.height
                            color: "black"
                            opacity: .2
                            border.width: 2
                            border.color: "white"
                            radius: 8
                        }

                        Text{
                            id: callsign
                            anchors.top: holder.top
                            topPadding: 2
                            leftPadding: 10
                            width: image.width
                            color: "white"
                            //font.bold: true
                            font.pixelSize: 11
                            horizontalAlignment: Text.AlignHCenter
                            Component.onCompleted: {
                                console.log("Model: " + model);
                                text = model.callsign
                                //console.log("Map Callsign=",model.callsign);
                            }
                        }

                        Text{
                            id: alt
                            anchors.top: callsign.bottom
                            topPadding: 2
                            leftPadding: 10
                            width: image.width
                            color: "white"
                            font.bold: true
                            font.pixelSize: 11
                            horizontalAlignment: Text.AlignHCenter
                            Component.onCompleted: {
                                //need adjustment for imperial
                                //only meters now
                                if(model.vertical > .2){ //climbing
                                    if (settings.enable_imperial === false){
                                        text = Math.floor(model.alt-OpenHD.alt_msl)+"m "+"\ue696"
                                    }
                                    else{
                                        text = Math.floor((model.alt-OpenHD.alt_msl)*3.28084)+"Ft "+"\ue696"
                                    }
                                }
                                else if (model.vertical < -.2){//descending
                                    if (settings.enable_imperial === false){
                                        text= Math.floor(model.alt-OpenHD.alt_msl)+"m "+"\ue697"
                                    }
                                    else{
                                        text = Math.floor((model.alt-OpenHD.alt_msl)*3.28084)+"Ft "+"\ue697"
                                    }
                                }
                                else {
                                    if (settings.enable_imperial === false){//level
                                        text= Math.floor(model.alt-OpenHD.alt_msl)+"m "+"\u2501"
                                    }
                                    else{
                                        text = Math.floor((model.alt-OpenHD.alt_msl)*3.28084)+"Ft "+"\u2501"
                                    }
                                }
                            }
                        }
                        Text{
                            id: velocity
                            anchors.top: alt.bottom
                            topPadding: 2
                            leftPadding: 10
                            width: image.width
                            color: "white"
                            //font.bold: true
                            font.pixelSize: 11
                            horizontalAlignment: Text.AlignHCenter
                            Component.onCompleted: {
                                text= settings.enable_imperial ? Math.floor(model.velocity*2.23694) + " mph"
                                                                : Math.floor(model.velocity*3.6) + " kph"
                            }
                        }
                    }
                }
                //position everything
                Component.onCompleted: coordinate = QtPositioning.coordinate(model.lat, model.lon);

            }
            Component.onCompleted: map.addMapItemGroup(this);
        }
    }

    //get coordinates on click... for future use
    MouseArea {
        anchors.fill: parent
        onClicked: {
            var coord = map.toCoordinate(Qt.point(mouse.x,
                                                  mouse.y))
            console.log(coord.latitude, coord.longitude)
            configureLargeMap()
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
