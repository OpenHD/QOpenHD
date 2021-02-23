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

    bearing: settings.map_orientation ? OpenHD.hdg : 360

    property double userLat: 0.0
    property double userLon: 0.0
    property double center_coord_lat: 0.0
    property double center_coord_lon: 0.0
    property int track_count: 0;
    property int track_skip: 1;
    property int track_limit: 100;

    Connections {
        target: BlackBoxModel
        function onDataChanged() {
            if (settings.map_drone_track === true) {
                addDroneTrack();
            }
        }
    }

    function addDroneTrack() {

        // always remove last point unless it was significant
        if (track_count != 0) {
            droneTrack.removeCoordinate(droneTrack.pathLength());
            //console.log("total points=", droneTrack.pathLength());
        }

        // always add the current location so drone looks like its connected to line
        droneTrack.addCoordinate(QtPositioning.coordinate(OpenHD.lat, OpenHD.lon));

        track_count = track_count + 1;

        if (track_count == track_skip) {
            track_count = 0;
        }

        if (droneTrack.pathLength() === track_limit) {
            //make line more coarse
            track_skip = track_skip * 2;
            //cut the points in the list by half
            for (var i = 0; i < track_limit; ++i) {
                if (i % 2) {
                    // it's odd
                    droneTrack.removeCoordinate(i);
                }
            }
        }
    }

    center {
        latitude: OpenHD.lat == 0.0 ? userLat : followDrone ? OpenHD.lat : 9000
        longitude: OpenHD.lon == 0.0 ? userLon : followDrone ? OpenHD.lon : 9000
    }

    onMapReadyChanged: {
        //needed to intitialize adsb api coordinates
        console.log("map is ready");
        findMapBounds();
    }

    onCenterChanged: {
        findMapBounds();
    }

    function findMapBounds(){
        var center_coord = map.toCoordinate(Qt.point(map.width/2,map.height/2))
        //console.log("my center",center_coord.latitude, center_coord.longitude);
        if (EnableADSB) {
            AdsbVehicleManager.newMapCenter(center_coord);
        }
    }

    PositionSource {
        id: positionSource
        updateInterval: 5000
        active: followDrone

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

    MapRectangle {
        id: adsbSquare
        topLeft : EnableADSB ? AdsbVehicleManager.apiMapCenter.atDistanceAndAzimuth(settings.adsb_distance_limit, 315, 0.0) : QtPositioning.coordinate(0, 0)
        bottomRight: EnableADSB ? AdsbVehicleManager.apiMapCenter.atDistanceAndAzimuth(settings.adsb_distance_limit, 135, 0.0) : QtPositioning.coordinate(0, 0)
        enabled: EnableADSB
        visible: settings.adsb_api_openskynetwork
        color: "white"
        border.color: "red"
        border.width: 5
        smooth: true
        opacity: .3
    }

    MapItemView {
        model: BlackBoxModel
        enabled: EnableBlackbox

        function addDroneTrack() {
            
            // always remove last point unless it was significant
            if (track_count != 0) {
                droneTrack.removeCoordinate(droneTrack.pathLength());
                //console.log("total points=", droneTrack.pathLength());
            }

            // always add the current location so drone looks like its connected to line
            droneTrack.addCoordinate(QtPositioning.coordinate(OpenHD.lat, OpenHD.lon));

            track_count = track_count + 1;

            if (track_count == track_skip) {
                track_count = 0;
            }

            if (droneTrack.pathLength() === track_limit) {
                //make line more coarse
                track_skip = track_skip * 2;
                //cut the points in the list by half
                for (var i = 0; i < track_limit; ++i) {
                    if (i % 2) {
                        // it's odd
                        droneTrack.removeCoordinate(i);
                    }
                }
            }

            //console.log("drone position=",OpenHD.lat, OpenHD.lon);
        }
    }

    MapPolyline {
        id: droneTrack
        visible: EnableBlackbox

        line.color: "red"
        line.width: 3
    }


    MapItemView {
        id: markerMapView
        model: AdsbVehicleManager.adsbVehicles
        delegate: markerComponentDelegate
        visible: EnableADSB

        Component {
            id: markerComponentDelegate

            MapItemGroup {
                id: delegateGroup

                MapQuickItem {
                    id: marker
                    property alias lastMouseX: markerMouseArea.lastX
                    property alias lastMouseY: markerMouseArea.lastY

                    anchorPoint.x: image.width/2
                    anchorPoint.y: image.height/2
                    width: image.width
                    height: image.height


                    sourceItem: Image {
                        id: image
                        source: "/airplanemarkerblur.png"

                        Rectangle{// has to be here prior to rotation call
                            id: speedtail

                            x: image.width*.4
                            y: image.height*.8

                            width: image.width*.2
                            height: {
                                if (object.velocity === undefined) {
                                    console.log("qml: object velocity undefined")
                                    return 0;
                                }
                                else {
                                    return object.velocity / 2;
                                }
                            }
                            opacity: .5
                            color: "white"
                            border.color: "grey"
                            border.width: 1
                        }

                        rotation: {
                            if (object.heading === undefined) {
                                console.log("qml: model heading undefined")
                                return 0;
                            }



                            if (settings.map_orientation === true){
                                var orientation = object.heading-OpenHD.hdg;
                                if (orientation < 0) orientation += 360;
                                if (orientation >= 360) orientation -=360;
                                return orientation;
                            }
                            else {                                
                                //console.log("TRACK=", object.heading);
                                return object.heading;
                            }
                        }

                        //UNUSED MOUSE AREA.. reating for future functionality
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
                                if (object.heading === undefined) {
                                    console.log("qml: model velocity undefined")
                                    return 0;
                                }

                                if (settings.map_orientation === true){
                                    var orientation = object.heading - OpenHD.hdg;

                                    if (orientation < 0) orientation += 360;
                                    if (orientation >= 360) orientation -=360;
                                    return -orientation;
                                }
                                else {
                                    return -object.heading;
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
                                text: {
                                    if (object.callsign === undefined) {
                                        console.log("qml: model callsign undefined")
                                        return "---"
                                    }
                                    else {
                                        return object.callsign
                                        //console.log("Map Callsign=",object.callsign);
                                    }
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
                                text:  {
                                    // check if traffic is a threat
                                    if (object.altitude - OpenHD.alt_msl < 300 && model.distance < 2){
                                        //console.log("TRAFFIC WARNING");
                                        image.source="/airplanemarkerwarn.png";
                                        background.border.color = "red";
                                        background.border.width = 5;
                                        background.opacity = 0.5;
                                    } else if (object.altitude - OpenHD.alt_msl < 500 && model.distance < 5){
                                        //console.log("TRAFFIC ALERT");
                                        image.source="/airplanemarkeralert.png";
                                        background.border.color = "yellow";
                                        background.border.width = 5;
                                        background.opacity = 0.5;
                                    }

                                    if (object.altitude === undefined || object.verticalVel === undefined) {
                                        //console.log("qml: model alt or vertical undefined")
                                        return "---";
                                    } else {
                                        if(object.verticalVel > .2){ //climbing
                                            if (settings.enable_imperial === false){
                                                return Math.floor(object.altitude - OpenHD.alt_msl) + "m " + "\ue696"
                                            }
                                            else{
                                                return Math.floor((object.altitude - OpenHD.alt_msl) * 3.28084) + "Ft " + "\ue696"
                                            }
                                        }
                                        else if (object.verticalVel < -.2){//descending
                                            if (settings.enable_imperial === false){
                                                return Math.floor(object.altitude - OpenHD.alt_msl) + "m " + "\ue697"
                                            }
                                            else{
                                                return Math.floor((object.altitude - OpenHD.alt_msl) * 3.28084) + "Ft " + "\ue697"
                                            }
                                        }
                                        else {
                                            if (settings.enable_imperial === false){//level
                                                return Math.floor(object.altitude - OpenHD.alt_msl) + "m " + "\u2501"
                                            }
                                            else{
                                                return Math.floor((object.altitude - OpenHD.alt_msl) * 3.28084) + "Ft " + "\u2501"
                                            }
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
                                text: {
                                    if (object.velocity === undefined) {
                                        return "---";
                                    }
                                    else {
                                        return settings.enable_imperial ? Math.floor(object.velocity * 2.23694) + " mph"
                                                                        : Math.floor(object.velocity * 3.6) + " kph";
                                    }
                                }
                            }
                        }
                    }
                    //position everything
                    coordinate: {
                        if (object.coordinate === undefined) {
                            console.log("qml: model geo undefined")
                            marker.visible = false;
                            return QtPositioning.coordinate(0.0, 0.0);
                        }
                        else {
                            return object.coordinate;
                        }
                    }
                }
                //Component.onCompleted: map.addMapItemGroup(this);
            }
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
                angle: settings.map_orientation ? 0 : OpenHD.hdg
            }
        }
    }
}
