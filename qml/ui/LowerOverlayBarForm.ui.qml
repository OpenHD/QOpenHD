import QtQuick 2.13
import QtGraphicalEffects 1.13

import OpenHD 1.0

import "."
import "./widgets"

Rectangle {
    id: statusBar

    property alias home_distance: home_distance
    property alias flight_timer: flight_timer
    property alias flight_mode: flight_mode
    property alias air_battery: air_battery
    property alias gps: gps

    width: 800
    color: "#8f000000"

    anchors {
        bottom: parent.bottom
        left: parent.left
        right: parent.right
    }

    z: 2.0

    height: 48

    AirBatteryWidget {
        id: air_battery
        anchors.top: parent.top
        anchors.topMargin: 0
        anchors.bottom: parent.bottom
        anchors.bottomMargin: 0
        anchors.left: parent.left
        anchors.leftMargin: 0
    }

    FlightModeWidget {
        id: flight_mode
        anchors.horizontalCenterOffset: -24
        anchors.top: parent.top
        anchors.topMargin: 0
        anchors.horizontalCenter: parent.horizontalCenter
    }


    LatLonWidget {
        id: lat_lon
        anchors.top: parent.top
        anchors.topMargin: 0
        anchors.bottom: parent.bottom
        anchors.bottomMargin: 0
        anchors.left: parent.left
        anchors.leftMargin: 200
        visible: false
    }

    GPSWidget {
        id: gps
        anchors.top: parent.top
        anchors.topMargin: 0
        anchors.right: flight_timer.left
        anchors.rightMargin: 6
    }

    HomeDistanceWidget {
        id: home_distance
        anchors.bottom: parent.bottom
        anchors.bottomMargin: 0
        anchors.right: parent.right
        anchors.rightMargin: 0
    }

    FlightTimerWidget {
        id: flight_timer
        anchors.top: parent.top
        anchors.topMargin: 0
        anchors.right: parent.right
        anchors.rightMargin: 0
    }
}


/*##^##
Designer {
    D{i:2;anchors_x:8}D{i:3;anchors_width:34;anchors_x:62}D{i:1;anchors_height:64;anchors_x:0;anchors_y:0}
D{i:5;anchors_x:8}D{i:6;anchors_width:34;anchors_x:0}D{i:4;anchors_height:64;anchors_x:8;anchors_y:0}
D{i:8;anchors_x:0;invisible:true}D{i:9;anchors_x:21;anchors_y:0;invisible:true}D{i:7;anchors_x:21;invisible:true}
D{i:11;anchors_x:0;invisible:true}D{i:12;anchors_x:21;anchors_y:0}D{i:16;anchors_x:21;anchors_y:0}
D{i:14;anchors_x:21;anchors_y:0}
}
##^##*/
