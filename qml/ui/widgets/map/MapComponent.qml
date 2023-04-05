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
    property int track_count: 0;
    property int track_skip: 1;
    property int track_limit: 100; //max number of drone track points before it starts averaging

    center {
        latitude: _fcMavlinkSystem.lat == 0.0 ? userLat : followDrone ? _fcMavlinkSystem.lat : 9000
        longitude: _fcMavlinkSystem.lon == 0.0 ? userLon : followDrone ? _fcMavlinkSystem.lon : 9000
    }

    onSupportedMapTypesChanged: {
        console.log("Map component: supported map types has changed"+map.supportedMapTypes.length)
        for (var i = 0; i < map.supportedMapTypes.length; i++)  {
            console.log("Map type "+i+" "+map.supportedMapTypes[i]+" "+map.supportedMapTypes[i].description)
        }
        variantDropdown.model = map.supportedMapTypes
        variantDropdown.currentIndex = settings.selected_map_variant
        console.log("Selected map variant stored:"+settings.selected_map_variant+" actual:"+variantDropdown.currentIndex);
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

        AdsbVehicleManager.newMapCenter(center_coord);

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

    function addDroneTrack() {
        //this function keeps recycling points to preserve memory

        // always remove last point unless it was significant
        if (track_count != 0) {
            droneTrack.removeCoordinate(droneTrack.pathLength());
            //console.log("Map component: total points=", droneTrack.pathLength());
        }

        // always add the current location so drone looks like its connected to line
        droneTrack.addCoordinate(QtPositioning.coordinate(_fcMavlinkSystem.lat, _fcMavlinkSystem.lon));

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

    MapPolyline {
        id: droneTrack
        visible: settings.map_drone_track
        line.color: "red"
        line.width: 3
    }

    MapCircle {
        center {
            latitude: _fcMavlinkSystem.lat
            longitude: _fcMavlinkSystem.lon
        }
        radius: _fcMavlinkSystem.gps_hdop
        color: 'red'
        opacity: .3
    }

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

    MapRectangle {
        id: adsbSquare
        topLeft : AdsbVehicleManager.apiMapCenter.atDistanceAndAzimuth(settings.adsb_distance_limit, 315, 0.0)
        bottomRight: AdsbVehicleManager.apiMapCenter.atDistanceAndAzimuth(settings.adsb_distance_limit, 135, 0.0)
        //enabled: false
        visible: settings.adsb_api_openskynetwork
        color: "white"
        border.color: "red"
        border.width: 5
        smooth: true
        opacity: .3
    }

    MapItemView {
        id: markerMapView
//TODO ADSB needs refactor
        model: AdsbVehicleManager.adsbVehicles
        delegate: markerComponentDelegate
        //visible: false

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

                        drone_heading: OpenHD.hdg; //need this to adjust orientation

                        drone_alt: OpenHD.alt_msl;

                        heading: object.heading;

                        speed: object.velocity

                        alt: object.altitude

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
                    coordinate: object.coordinate;

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


    MapPolyline {
        id: waypointTrack

        line.color: "yellow"
        line.width: 3
    }


    MapItemView {
        id: waypointMapView
// TODO missions refactor
//        model: MissionWaypointManager.missionWaypoints
        delegate: waypointComponent


        Component {
            id: waypointComponent

            MapItemGroup {
                id: waypointGroup

                MapQuickItem {
                    id: waypointMarker

                    //   anchorPoint.x: seq_rect.width / 2
                    //   anchorPoint.y: seq_rect.height


                    sourceItem:

                        Rectangle {
                        id: seq_rect
                        anchors.centerIn: parent

                        width: {
                            if (object.sequence === undefined) {
                                return 22;
                            }

                            if (object.sequence === OpenHD.current_waypoint){
                                return 30;
                            }
                            else{
                                return 22;
                            }
                        }

                        height: {
                            if (object.sequence === undefined) {
                                return 22;
                            }
                            if (object.sequence === OpenHD.current_waypoint){
                                return 30;
                            }
                            else{
                                return 22;
                            }
                        }
                        color: {
                            if (object.sequence === undefined) {
                                return "green";
                            }
                            if (object.sequence === OpenHD.current_waypoint){
                                return "red";
                            }
                            else if(object.sequence < OpenHD.current_waypoint){
                                return "grey";
                            }
                            else{
                                return "green";
                            }
                        }
                        border.color: "black"
                        border.width: 1
                        radius: width*0.5

                        Text{
                            id:seq_text
                            anchors.centerIn: parent
                            color: "white"
                            font.bold: true
                            font.pixelSize: {
                                if (object.sequence === undefined) {
                                    return 15;
                                }
                                if (object.sequence === OpenHD.current_waypoint){
                                    return 17;
                                }
                                else{
                                    return 15;
                                }
                            }
                            horizontalAlignment: Text.AlignHCenter
                            text: {
                                if (object.sequence === undefined) {
                                    return "?";
                                }
                                else if (object.command === 22) {
                                    return "T";
                                }
                                else if (object.command === 21) {
                                    return "L";
                                }
                                else {
                                    return object.sequence;
                                }
                            }
                        }
                    }




                    coordinate: {
                        // TODO "undefined" protection
                        /*
                        console.log("Map sequence="+object.sequence);
                        console.log("Map command="+object.command);
                        console.log("Map latitude="+object.lat);
                        console.log("Map longitude="+object.lon);
                        console.log("Map altitude="+object.altitude);
*/
                        waypointTrack.addCoordinate(object.coordinate);
                        return object.coordinate;
                    }

                }
            }
        }
    }


    MapQuickItem {
        id: dronemarker
        coordinate: QtPositioning.coordinate(_fcMavlinkSystem.lat, _fcMavlinkSystem.lon)

        onCoordinateChanged: {
            addDroneTrack();
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

    // Show Mission Waypoints on the map
    Repeater{
        id: repeaterMissionItems
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
                    // Red circle indicating the wapoint
                    Shape {
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
                    // waypoint number
                    Text{
                        anchors.fill: parent
                        anchors.centerIn: parent
                        horizontalAlignment : Text.AlignHCenter
                        verticalAlignment : Text.AlignVCenter
                        //text: "X"+model.mission_index
                        text: ""+model.mission_index
                        color: "white"
                    }
                }
            }
            /*MapCircle {
                id: innerCircle
                border.color: "green"
                border.width: 3
                center: QtPositioning.coordinate(model.lat, model.lon)
                radius: 5
            }*/
            // IMPORTANT - REPEATER IS BUGGED WITH MAP; WON'T WORK OTHERWISE
            Component.onCompleted: map.addMapItemGroup(this)
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
