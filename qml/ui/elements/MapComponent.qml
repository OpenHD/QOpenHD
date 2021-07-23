import QtQuick 2.12
import QtQuick.Controls 2.12
import QtQuick.Shapes 1.0

import QtLocation 5.12
import QtPositioning 5.12
import OpenHD 1.0

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
    property int track_limit: 100; //max number of drone track points before it starts averaging

    Connections {
        //this deletes the lines drawn between mission waypoints
        target: MissionWaypointManager
        function onMapDeleteWaypoints(){
            console.log("onMapDeleteWaypoints from polyline");

            var waypoint_track_count = waypointTrack.pathLength();

            if (waypoint_track_count>0){
                for (var i = 0; i < waypoint_track_count; ++i) {
                    waypointTrack.removeCoordinate(i);
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

    function addDroneTrack() {
        //this function keeps recycling points to preserve memory

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

    MapPolyline {
        id: droneTrack
        visible: settings.map_drone_track
        line.color: "red"
        line.width: 3
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

                    anchorPoint.x: icon.width/2
                    anchorPoint.y: icon.height/2
                    width: icon.width
                    height: icon.height


                    sourceItem:

                        DrawingCanvas {
                            id: icon
                            anchors.centerIn: parent

                            /* could turn the width and height into settings and thereby clip the fpv
                              *even theough clipping is false it still clips
                            */
                            width: 50
                            height: 50
                            clip: false
                            color: settings.color_shape
                            glow: settings.color_glow

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





                        Rectangle{ //holder to "derotate" info block
                            id: holder

                            x: icon.width+5
                            y: icon.height/2
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
                            width: icon.width
                            height: icon.height
                            color: "transparent"

                            Rectangle{
                                id: background

                                width: icon.width*1.25
                                height: icon.height
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
                                width: icon.width
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
                                width: icon.width
                                color: "white"
                                font.bold: true
                                font.pixelSize: 11
                                horizontalAlignment: Text.AlignHCenter
                                text:  {
                                    // check if traffic is a threat
                                    if (object.altitude - OpenHD.alt_msl < 300 && model.distance < 2){
                                        //console.log("TRAFFIC WARNING");
 //todo
                                        //image.source="/airplanemarkerwarn.png";
                                        background.border.color = "red";
                                        background.border.width = 5;
                                        background.opacity = 0.5;
                                    } else if (object.altitude - OpenHD.alt_msl < 500 && model.distance < 5){
                                        //console.log("TRAFFIC ALERT");
 //todo
                                        //image.source="/airplanemarkeralert.png";
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
                                width: icon.width
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


    MapPolyline {
        id: waypointTrack

        line.color: "yellow"
        line.width: 3
    }


    MapItemView {
        id: waypointMapView
        model: MissionWaypointManager.missionWaypoints
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
        coordinate: QtPositioning.coordinate(OpenHD.lat, OpenHD.lon)

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
                angle: settings.map_orientation ? 0 : OpenHD.hdg
            }
        }
    }
}
