import QtQuick 2.12
import QtQuick.Controls 2.12
import QtQuick.Shapes 1.0

import QtLocation 5.15
import QtPositioning 5.15
import OpenHD 1.0

// This is the actual Map "canvas" file - the other 2 .qml files are just handling resizing and integration with BaseWidget
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

    bearing: settings.map_orientation ? _fcMavlinkSystem.hdg : 360

    property double userLat: 0.0
    property double userLon: 0.0
    property double center_coord_lat: 0.0
    property double center_coord_lon: 0.0
    property var center_coord

    property int track_limit: 200; //max number of drone track points before it starts averaging
    // We start with a minimum distance of 3m, each time we perform a track reduction, the minimum distance is increased
    property int min_distance_between_points_m: 3.0


    center {
        latitude: _fcMavlinkSystem.lat == 0.0 ? userLat : followDrone ? _fcMavlinkSystem.lat : 9000
        longitude: _fcMavlinkSystem.lon == 0.0 ? userLon : followDrone ? _fcMavlinkSystem.lon : 9000
    }

    onSupportedMapTypesChanged: {
        console.log("Map component: supported map types has changed"+map.supportedMapTypes.length)
        for (var i = 0; i < map.supportedMapTypes.length; i++)  {
            //console.log("Map type "+i+" "+map.supportedMapTypes[i]+" "+map.supportedMapTypes[i].description)
        }
        variantDropdown.model = map.supportedMapTypes
        variantDropdown.currentIndex = settings.selected_map_variant
        //console.log("Selected map variant stored:"+settings.selected_map_variant+" actual:"+variantDropdown.currentIndex);
        map.activeMapType = map.supportedMapTypes[variantDropdown.currentIndex]
    }

    onActiveMapTypeChanged: {
        console.log("Active map type changed")
    }

    onMapReadyChanged: {
        //needed to intitialize adsb api coordinates
        console.log("Map component: is ready");
        findMapBounds();
    }

    onCenterChanged: {
        findMapBounds();
    }

    function findMapBounds(){
        center_coord = map.toCoordinate(Qt.point(map.width/2,map.height/2))
        //console.log("Map component: center",center_coord.latitude, center_coord.longitude);
        AdsbVehicleManager.newMapLat(center_coord.latitude);
        AdsbVehicleManager.newMapLon(center_coord.longitude);
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

    //this function keeps recycling points to preserve memory
    function addDroneTrack() {
        //console.log("Add drone track")
        // only add track while armed
        if(!_fcMavlinkSystem.armed){
            return;
        }
        var new_coordinate=QtPositioning.coordinate(_fcMavlinkSystem.lat, _fcMavlinkSystem.lon)
        if(droneTrack.pathLength()<=1){
            // first ever 2 points
            droneTrack.addCoordinate(new_coordinate);
            return;
        }
        var coordinate_prev1=droneTrack.coordinateAt(droneTrack.pathLength()-1);
        var coordinate_prev2=droneTrack.coordinateAt(droneTrack.pathLength()-2);
        var distance = coordinate_prev1.distanceTo(coordinate_prev2);
        //console.log("Distance is:"+distance+"m");
        if(distance<min_distance_between_points_m){
            // distance is insignificant - just replace the last coordinate
            droneTrack.replaceCoordinate(droneTrack.pathLength()-1,new_coordinate);
        }else{
            // add new coordinate
            droneTrack.addCoordinate(new_coordinate);
            //console.log("Track points:"+droneTrack.pathLength());
            if(droneTrack.pathLength()>track_limit){
                console.log("Track limit reached");
                // make the line more coarse by removing every 2nd element, beginning from the end of the track (front of the list)
                // but keep first and last point intact
                for(var i=droneTrack.pathLength()-2;i>=1;i--){
                    if(i % 2 == 1){
                        droneTrack.removeCoordinate(i);
                    }
                }
                // increase the min distance between points
                min_distance_between_points_m+=3.0;
                console.log("New min distance:"+min_distance_between_points_m+"m");
            }
        }
    }

    MapPolyline {
        id: droneTrack
        visible: settings.map_drone_track
        line.color: "red"
        line.width: 3
    }
    // Visualizes the GPS hdop
    MapCircle {
        center {
            latitude: _fcMavlinkSystem.lat
            longitude: _fcMavlinkSystem.lon
        }
        radius: _fcMavlinkSystem.gps_hdop
        color: 'red'
        opacity: .3
    }
    // Home marker
    MapQuickItem {
        id: homemarkerSmallMap
        anchorPoint.x: imageSmallMap.width / 2
        anchorPoint.y: imageSmallMap.height
        coordinate {
            latitude: _fcMavlinkSystem.home_latitude
            longitude: _fcMavlinkSystem.home_longitude
        }

        sourceItem: Image {
            id: imageSmallMap
            source: "qrc:/resources/homemarker.png"
        }
    }

    // This graphically depicts the area in which adsb traffic is being sourced

    MapCircle {
        id: adsbCircle
        visible: {
            //TODO add control that also responds to no interent setting
            if (!settings.adsb_enable){
                return false;
            }
            else{
                return true;
            }
        }
        center {
            latitude: center_coord.latitude
            longitude: center_coord.longitude
        }
        radius: settings.adsb_radius //in meters
        color: "white"
        border.color: "red"
        border.width: 5
        smooth: true
        opacity: .3
    }

    //>>>>>>>>>>>>>>>>> Begin ADSB <<<<<<<<<<<<<<<<<
    MapItemView {
            id: markerMapView
            model: AdsbVehicleManager.adsbVehicles
            delegate: markerComponentDelegate
            visible: settings.adsb_enable

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


                        sourceItem:

                            Image {

                            id: image
                            source: "ADSBmarker.png"

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
                                        return object.velocity / 10;
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
                                    var orientation = object.heading-_fcMavlinkSystem.hdg;
                                    if (orientation < 0) orientation += 360;
                                    if (orientation >= 360) orientation -=360;
                                    return orientation;
                                }
                                else {
                                    //console.log("TRACK=", object.heading);
                                    return object.heading;
                                }
                            }

                            //UNUSED MOUSE AREA.. for future functionality
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
                                        var orientation = object.heading - _fcMavlinkSystem.hdg;

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
                                        // check if traffic is a threat and change marker image if needed
                                        if (object.altitude - _fcMavlinkSystem.altitude_msl_m < 300 && object.distance < 2){
                                            //console.log("TRAFFIC WARNING");
                                            image.source="ADSBwarnMarker.png";
                                            background.border.color = "red";
                                            background.border.width = 5;
                                            background.opacity = 0.5;
                                        } else if (object.altitude - _fcMavlinkSystem.altitude_msl_m < 500 && object.distance < 5){
                                            //console.log("TRAFFIC ALERT");
                                            image.source="ADSBcautionMarker.png";
                                            background.border.color = "yellow";
                                            background.border.width = 5;
                                            background.opacity = 0.5;
                                        }

                                        //NOW do altitude Text block
                                        if (object.altitude === undefined || object.verticalVel === undefined) {
                                            //console.log("qml: model alt or vertical undefined")
                                            return "---";
                                        } else {
                                            if(object.verticalVel > .2){ //climbing
                                                if (settings.enable_imperial === false){
                                                    return Math.floor(object.altitude - _fcMavlinkSystem.altitude_msl_m) + "m " + "\ue696"
                                                }
                                                else{
                                                    return Math.floor((object.altitude - _fcMavlinkSystem.altitude_msl_m) * 3.28084) + "Ft " + "\ue696"
                                                }
                                            }
                                            else if (object.verticalVel < -.2){//descending
                                                if (settings.enable_imperial === false){
                                                    return Math.floor(object.altitude - _fcMavlinkSystem.altitude_msl_m) + "m " + "\ue697"
                                                }
                                                else{
                                                    return Math.floor((object.altitude - _fcMavlinkSystem.altitude_msl_m) * 3.28084) + "Ft " + "\ue697"
                                                }
                                            }
                                            else {
                                                if (settings.enable_imperial === false){//level
                                                    return Math.floor(object.altitude - _fcMavlinkSystem.altitude_msl_m) + "m " + "\u2501"
                                                }
                                                else{
                                                    return Math.floor((object.altitude - _fcMavlinkSystem.altitude_msl_m) * 3.28084) + "Ft " + "\u2501"
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
                        coordinate: QtPositioning.coordinate( object.lat , object.lon );
                    }
                    //Component.onCompleted: map.addMapItemGroup(this);
                }
            }
        }
    //>>>>>>>>>>>>>>>>>>> end ADSB <<<<<<<<<<<<<<<


    //get coordinates on click... for future use
    MouseArea {
        anchors.fill: parent
        onClicked: {
            var coord = map.toCoordinate(Qt.point(mouse.x,mouse.y))
            console.log("Map clicked, "+coord.latitude+":"+coord.longitude)
            configureLargeMap()
        }
    }
    // Arrow indicating the drone position
    MapQuickItem {
        id: dronemarker
        coordinate: QtPositioning.coordinate(_fcMavlinkSystem.lat, _fcMavlinkSystem.lon)

        onCoordinateChanged: {
            // skip what most likely are not valid coordinates
            if(coordinate.latitude!=0.0 && coordinate.longitude!=0.0){
                addDroneTrack();
            }
        }

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
                angle: settings.map_orientation ? 0 : _fcMavlinkSystem.hdg
            }
        }
    }

    // In development
    MapPolyline {
        id: waypointTrack

        line.color: "yellow"
        line.width: 3
    }
    // Show Mission Waypoints on the map
    Repeater{
        id: repeaterMissionWaypoints
        model: _fcMavlinkMissionItemsModel
        MapItemGroup {
            id: delegateGroup

            MapQuickItem {
                coordinate: QtPositioning.coordinate(model.latitude,model.longitude)
                visible: settings.map_show_mission_waypoints
                //sourceItem: Rectangle{
                //    width: 24
                //    height: 24
                //    color: "red"
                //    opacity: .5
                //}
                sourceItem: Item {
                    anchors.fill: parent
                    visible: model.valid
                    // Red circle indicating the wapoint
                    // NEAT :) https://cuteguide.wordpress.com/2016/11/16/how-to-make-a-circle-from-rectangle/ - ehm doesnt work
                    /*Rectangle {
                        //anchors.centerIn: parent
                        anchors.fill: parent
                        color: "red"
                        radius: width / 2
                    }*/
                    Shape {
                        anchors.fill: parent

                        ShapePath {
                            strokeColor: "red"
                            fillColor: model.index === _fcMavlinkSystem.mission_waypoints_current ? "green" : "red"
                            strokeWidth: 0
                            strokeStyle: ShapePath.SolidLine

                            capStyle: ShapePath.RoundCap

                            PathAngleArc {
                                centerX: 0; centerY: 0
                                radiusX: 10; radiusY: 10
                                startAngle: 0
                                sweepAngle: 360
                            }
                        }
                    }
                    // waypoint number
                    Text{
                        anchors.fill: parent
                        anchors.centerIn: parent
                        horizontalAlignment : Text.AlignHCenter
                        verticalAlignment : Text.AlignVCenter
                        //text: "X"+model.mission_index
                        text: ""+model.index
                        color: "white"
                    }
                }
                Component.onCompleted: {
                    // We cannot do waypoint track until we have proper sorting
                    //waypointTrack.addCoordinate(coordinate);
                }
                /*TapHandler {
                    id: tapHandler
                    //anchors.fill: sourceItem
                    onTapped: {
                        console.log("Clicked mission item"+model.index)
                    }
                }*/
            }
            /*MapCircle {
                id: innerCircle
                border.color: "green"
                border.width: 3
                center: QtPositioning.coordinate(model.lat, model.lon)
                radius: 5
            }*/
            // IMPORTANT - REPEATER IS BUGGED WITH MAP; WON'T WORK OTHERWISE
            Component.onCompleted: {
                map.addMapItemGroup(this)
            }
            Component.onDestruction: {
                map.removeMapItemGroup(this)
            }
        }
    }

    /*MapQuickItem {
        id: waypoint1
        coordinate: QtPositioning.coordinate(0.0,0.0)

        anchorPoint.x : 0
        anchorPoint.y : 0

        sourceItem: Shape {
            anchors.fill: parent

            ShapePath {
                strokeColor: "red"
                fillColor: "red"
                strokeWidth: 1
                strokeStyle: ShapePath.SolidLine

                capStyle: ShapePath.RoundCap

                PathAngleArc {
                    centerX: 0; centerY: 0
                    radiusX: 10; radiusY: 10
                    startAngle: 0
                    sweepAngle: 360
                }
            }
        }
    }*/
}
