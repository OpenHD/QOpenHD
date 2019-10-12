import QtQuick 2.13
import QtGraphicalEffects 1.13

import OpenHD 1.0

import "."

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

    Item {
        id: air_battery
        width: 118
        anchors.top: parent.top
        anchors.topMargin: 0
        anchors.bottom: parent.bottom
        anchors.bottomMargin: 0
        anchors.left: parent.left
        anchors.leftMargin: 0

        Text {
            id: battery_percent
            y: 0
            width: 48
            height: 24
            color: "#ffffff"
            text: MavlinkTelemetry.battery_percent
            anchors.verticalCenter: parent.verticalCenter
            anchors.left: batteryGauge.right
            anchors.leftMargin: 0
            clip: true
            verticalAlignment: Text.AlignVCenter
            elide: Text.ElideRight
            horizontalAlignment: Text.AlignLeft
            font.pixelSize: 14
        }

        Text {
            id: batteryGauge
            y: 8
            width: 36
            height: 48
            color: MavlinkTelemetry.battery_voltage_raw < 11.2 ? (MavlinkTelemetry.battery_voltage_raw < 10.9 ? "#ff0000" : "#fbfd15") : "#ffffff"
            text: MavlinkTelemetry.battery_gauge
            anchors.left: parent.left
            anchors.leftMargin: 12
            fontSizeMode: Text.VerticalFit
            anchors.verticalCenter: parent.verticalCenter
            clip: true
            elide: Text.ElideMiddle
            font.family: "Material Design Icons"
            verticalAlignment: Text.AlignVCenter
            horizontalAlignment: Text.AlignHCenter
            font.pixelSize: 36
        }
    }

    Item {
        id: flight_mode
        x: 0

        width: 184
        height: 48
        anchors.horizontalCenterOffset: -24
        anchors.top: parent.top
        anchors.topMargin: 0

        anchors.horizontalCenter: parent.horizontalCenter

        Text {
            id: flight_mode_icon
            width: 48
            height: 48
            color: "#ffffff"
            text: "\uf072"
            //"\uf01d"
            anchors.left: parent.left
            anchors.leftMargin: 0
            anchors.verticalCenter: parent.verticalCenter
            font.family: "Font Awesome 5 Free"
            horizontalAlignment: Text.AlignRight
            verticalAlignment: Text.AlignVCenter
            font.pixelSize: 20
        }

        Text {
            id: flight_mode_text

            width: 184
            height: 48
            color: "#ffffff"
            text: MavlinkTelemetry.flight_mode
            anchors.verticalCenter: parent.verticalCenter
            anchors.left: flight_mode_icon.right
            anchors.leftMargin: 8
            verticalAlignment: Text.AlignVCenter
            horizontalAlignment: Text.AlignLeft
            font.pixelSize: 24
            elide: Text.ElideMiddle
        }
    }


    Item {
        id: lat_lon
        width: 104
        anchors.top: parent.top
        anchors.topMargin: 0
        anchors.bottom: parent.bottom
        anchors.bottomMargin: 0
        anchors.left: parent.left
        anchors.leftMargin: 200
        visible: false

        Text {
            id: homelat
            width: 92
            height: 24
            color: "#ffffff"
            text: MavlinkTelemetry.homelat
            horizontalAlignment: Text.AlignRight
            elide: Text.ElideRight
            verticalAlignment: Text.AlignVCenter
            anchors.top: parent.top
            font.pixelSize: 14
        }

        Text {
            id: homelon
            width: 92
            height: 24
            color: "#ffffff"
            text: MavlinkTelemetry.homelon
            horizontalAlignment: Text.AlignRight
            elide: Text.ElideRight
            verticalAlignment: Text.AlignVCenter
            anchors.bottom: parent.bottom
            font.pixelSize: 14
        }
    }

    Item {
        id: gps
        x: 419
        width: 96
        height: 24
        anchors.top: parent.top
        anchors.topMargin: 0
        anchors.right: flight_timer.left
        anchors.rightMargin: 6

        Text {
            id: satellite_icon
            y: 0
            width: 24
            height: 24
            color: "#ffffff"
            text: "\uf0ac"
            anchors.right: satellites_visible.left
            anchors.rightMargin: 6
            font.family: "Font Awesome 5 Free"
            horizontalAlignment: Text.AlignRight
            verticalAlignment: Text.AlignVCenter
            styleColor: "#f7f7f7"
            font.pixelSize: 14
        }

        Text {
            id: satellites_visible
            y: 0
            width: 20
            height: 24
            color: "#ffffff"
            text: MavlinkTelemetry.satellites_visible
            anchors.right: gps_hdop.left
            anchors.rightMargin: 2
            elide: Text.ElideRight
            clip: true
            verticalAlignment: Text.AlignVCenter
            horizontalAlignment: Text.AlignRight
            font.pixelSize: 16
        }

        Text {
            id: gps_hdop
            width: 48
            height: 24
            color: "#ffffff"
            text: "(%1)".arg(MavlinkTelemetry.gps_hdop)
            anchors.right: parent.right
            anchors.rightMargin: 0
            verticalAlignment: Text.AlignTop
            font.pixelSize: 10
            horizontalAlignment: Text.AlignLeft
        }
    }

    Item {
        id: home_distance
        x: 520
        y: 32
        width: 96
        height: 24
        anchors.bottom: parent.bottom
        anchors.bottomMargin: 0
        anchors.right: parent.right
        anchors.rightMargin: 0

        Text {
            id: home_icon
            x: 0

            width: 24
            height: 24
            color: "#ffffff"
            text: "\uf015"
            anchors.right: home_distance_text.left
            anchors.rightMargin: 6
            verticalAlignment: Text.AlignVCenter
            font.family: "Font Awesome 5 Free"
            styleColor: "#f7f7f7"
            font.pixelSize: 14
            horizontalAlignment: Text.AlignRight
        }

        Text {
            id: home_distance_text
            width: 64
            height: 24
            color: "#ffffff"
            text: qsTr("00000ft")
            elide: Text.ElideRight
            anchors.right: parent.right
            anchors.rightMargin: 8
            verticalAlignment: Text.AlignVCenter
            font.pixelSize: 16
            horizontalAlignment: Text.AlignLeft
        }
    }

    Item {
        id: flight_timer
        x: 520
        width: 96
        height: 24
        anchors.top: parent.top
        anchors.topMargin: 0
        anchors.right: parent.right
        anchors.rightMargin: 0

        Text {
            id: flight_timer_text
            y: 0
            width: 64
            height: 24
            color: "#ffffff"
            text: qsTr("0:00")
            elide: Text.ElideRight
            anchors.right: parent.right
            anchors.rightMargin: 8
            verticalAlignment: Text.AlignVCenter
            font.pixelSize: 16
            horizontalAlignment: Text.AlignLeft
        }

        Text {
            id: time_icon
            x: 0
            y: 0
            width: 24
            height: 24
            color: "#ffffff"
            text: "\uf017"
            font.family: "Font Awesome 5 Free"
            anchors.right: flight_timer_text.left
            horizontalAlignment: Text.AlignRight
            verticalAlignment: Text.AlignVCenter
            styleColor: "#f7f7f7"
            anchors.rightMargin: 6
            font.pixelSize: 14
        }
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
