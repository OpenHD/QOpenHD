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
        var center_coord = map.toCoordinate(Qt.point(map.width/2,map.height/2))
        //console.log("Map component: center",center_coord.latitude, center_coord.longitude);
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


    //>>>>>>>>>>>>>>>>>>> ADSB <<<<<<<<<<<<<<<<<<<
    /* this graphically depicts the area in which adsb traffic is being sourced
      *TODO fix.... will be a circle per the api
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
    */

    MapItemView {
        id: markerMapView
        model: AdsbVehicleManager.adsbVehicles
        delegate: markerComponentDelegate
        //TODO refactor setting
        //visible: EnableADSB
        visible: true

        Component {
            id: markerComponentDelegate

            MapItemGroup {
                id: delegateGroup

                MapQuickItem {
                    id: marker

                    anchorPoint.x: 0
                    anchorPoint.y: 0
                    width: 260
                    height: 260


                    sourceItem:

                        DrawingCanvas {
                        id: icon
                        anchors.centerIn: parent

                        width: 260
                        height: 260

                        color: settings.color_shape
                        glow: settings.color_glow

                        name: object.callsign

                        drone_heading: _fcMavlinkSystem.hdg; //need this to adjust orientation

                        drone_alt: _fcMavlinkSystem.altitude_msl_m;

                        heading: object.heading;

                        speed: object.velocity

                        alt: {
                            console.log("map lat / lon:" + object.vehicle_lat + " " + object.vehicle_lon);

                   return         object.altitude;

}

//                          {
/*                          check if traffic is a threat.. this should not be done here. Left as REF
                                if (object.altitude - OpenHD.alt_msl < 300 && model.distance < 2){
                                    //console.log("TRAFFIC WARNING");

                                    //image.source="/airplanemarkerwarn.png";
                                    background.border.color = "red";
                                    background.border.width = 5;
                                    background.opacity = 0.5;
                                } else if (object.altitude - OpenHD.alt_msl < 500 && model.distance < 5){
                                    //console.log("TRAFFIC ALERT");

                                    //image.source="/airplanemarkeralert.png";
                                    background.border.color = "yellow";
                                    background.border.width = 5;
                                    background.opacity = 0.5;
                                }
*/

/*                          *discovered issues when the object is referenced multiple times
                            *last attempt at putting altitude into a var still resulted in "nulls"

                            var _adsb_alt;

                            _adsb_alt=object.altitude;

                            if ( _adsb_alt> 9999) {
                                //console.log("qml: model alt or vertical undefined")
                               return "---";
                            } else {
                                if(object.verticalVel > .2){ //climbing
                                    if (settings.enable_imperial === false){
                                        return Math.floor(_adsb_alt - OpenHD.alt_msl) + "m " + "\ue696"
                                    }
                                    else{
                                        return Math.floor((_adsb_alt - OpenHD.alt_msl) * 3.28084) + "Ft " + "\ue696"
                                    }
                                }
                                else if (object.verticalVel < -.2){//descending
                                    if (settings.enable_imperial === false){
                                        return Math.floor(_adsb_alt - OpenHD.alt_msl) + "m " + "\ue697"
                                    }
                                    else{
                                        return Math.floor((_adsb_alt - OpenHD.alt_msl) * 3.28084) + "Ft " + "\ue697"
                                    }
                                }
                                else {
                                    if (settings.enable_imperial === false){//level
                                        return Math.floor(_adsb_alt - OpenHD.alt_msl) + "m " + "\u2501"
                                    }
                                    else{
                                        return Math.floor((_adsb_alt - OpenHD.alt_msl) * 3.28084) + "Ft " + "\u2501"
                                    }
                                }
                            }
                        }
  */
                    }
                    //position everything

                    coordinate : QtPositioning.coordinate( object.lat , object.lon );
                   // coordinate: marker.coordinate;

                   // coordinate {
                    //    latitude: object.lat
                    //    longitude: object.lon
                    // console.log("object lat/lon:"+object.lat+ " "+object.lon);
                  //  }

                }
                Component.onCompleted: map.addMapItemGroup(this);
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
