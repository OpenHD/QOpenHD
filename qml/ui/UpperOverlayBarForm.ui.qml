import QtQuick 2.13
import QtQuick.Controls 2.13
import QtQuick.Controls.Styles 1.4
import QtQuick.Layouts 1.13
import QtGraphicalEffects 1.13

import OpenHD 1.0

import Qt.labs.settings 1.0


Rectangle {
    id: toolBar
    property alias settingsButton: settingsButton
    property alias settingsButtonMouseArea: settingsButtonMouseArea

    property alias downlink: downlink
    property alias uplink: uplink
    property alias bitrate: bitrate
    property alias air_status: air_status
    property alias ground_status: ground_status

    width: 800

    // fixme: shouldnt exclusively depend on mavlink
    color: MavlinkTelemetry.armed ? "#aeff3333" : "#8f000000"

    anchors {
        top: parent.top
        left: parent.left
        right: parent.right
    }

    z: 2.0

    height: 48

    /*Button {
        id: settingsButton


        x: 8
        y: 8
        width: 42
        height: 42
        display: AbstractButton.IconOnly
        z: 2.2
    }*/

    Image {
        id: settingsButton
        x: 8
        y: 8
        width: 48
        height: 48
        anchors.verticalCenter: parent.verticalCenter
        fillMode: Image.PreserveAspectFit
        z: 2.2

        source: "../ic.png"
        anchors.leftMargin: 8
        anchors.topMargin: 8
        MouseArea {
            id: settingsButtonMouseArea
            anchors.fill: parent

        }

        /*background: Rectangle {
                implicitWidth: 100
                implicitHeight: 40
                opacity: 1
                border.color: "#ffffff"
                color: "#00000000"
                border.width: 1
                radius: 4
            }*/
    }

    Item {
        id: bitrate

        width: 104
        height: 24
        anchors.left: settingsButton.right
        anchors.leftMargin: 6
        anchors.bottom: parent.bottom
        anchors.bottomMargin: 0


        Text {
            id: kbitrate
            y: 0
            width: 84
            height: 24
            color: "#ffffff"
            text: OpenHDTelemetry.kbitrate
            anchors.verticalCenterOffset: 0
            anchors.left: camera_icon.right
            anchors.leftMargin: 6
            anchors.verticalCenter: parent.verticalCenter
            verticalAlignment: Text.AlignTop
            elide: Text.ElideRight
            wrapMode: Text.NoWrap
            clip: false
            horizontalAlignment: Text.AlignLeft
            font.pixelSize: 14
        }

        Text {
            id: camera_icon
            y: 0
            width: 24
            height: 24
            color: "#ffffff"
            text: "\uf03d"
            anchors.left: parent.left
            anchors.leftMargin: 0
            verticalAlignment: Text.AlignTop
            font.family: "Font Awesome 5 Free"
            styleColor: "#f7f7f7"
            font.pixelSize: 16
            horizontalAlignment: Text.AlignRight
        }
    }

    Item {
        id: air_status

        width: 112
        height: 24
        anchors.right: uplink.left
        anchors.rightMargin: 0
        anchors.top: parent.top
        anchors.topMargin: 0

        Text {
            id: chip_air
            y: 0
            width: 24
            height: 24
            color: "#ffffff"
            text: "\uf2db"
            anchors.right: cpuload_air.left
            anchors.rightMargin: 2
            anchors.verticalCenter: parent.verticalCenter
            font.family: "Font Awesome 5 Free"
            verticalAlignment: Text.AlignVCenter
            font.pixelSize: 14
            horizontalAlignment: Text.AlignRight
            elide: Text.ElideRight
        }


        Text {
            id: cpuload_air
            x: 0
            y: 0
            width: 34
            height: 24
            color: "#ffffff"
            text: OpenHDTelemetry.cpuload_air
            anchors.right: temp_air.left
            anchors.rightMargin: 2
            anchors.verticalCenter: parent.verticalCenter
            verticalAlignment: Text.AlignVCenter
            font.pixelSize: 14
            horizontalAlignment: Text.AlignRight
            elide: Text.ElideRight
        }
        Text {
            id: temp_air
            x: 0
            y: 4
            width: 34
            height: 24
            color: "#ffffff"
            text: OpenHDTelemetry.temp_air
            anchors.verticalCenter: parent.verticalCenter
            anchors.right: parent.right
            anchors.rightMargin: 0
            verticalAlignment: Text.AlignVCenter
            font.pixelSize: 14
            horizontalAlignment: Text.AlignRight
            elide: Text.ElideRight
        }
    }

    Item {
        id: ground_status

        width: 112
        height: 24
        anchors.right: uplink.left
        anchors.rightMargin: 0
        anchors.bottom: parent.bottom
        anchors.bottomMargin: 0

        Text {
            id: chip_gnd
            y: 0
            width: 24
            height: 24
            color: "#ffffff"
            text: "\uf2db"
            anchors.right: cpuload_gnd.left
            anchors.rightMargin: 2
            anchors.verticalCenter: parent.verticalCenter
            font.family: "Font Awesome 5 Free"
            verticalAlignment: Text.AlignVCenter
            font.pixelSize: 14
            horizontalAlignment: Text.AlignRight
            elide: Text.ElideRight
        }

        Text {
            id: cpuload_gnd
            x: 0
            y: 0
            width: 34
            height: 24
            color: "#ffffff"
            text: OpenHDTelemetry.cpuload_gnd
            anchors.verticalCenter: parent.verticalCenter
            anchors.right: temp_gnd.left
            anchors.rightMargin: 2
            verticalAlignment: Text.AlignVCenter
            font.pixelSize: 14
            horizontalAlignment: Text.AlignRight
            elide: Text.ElideRight
        }

        Text {
            id: temp_gnd
            x: 0
            y: 0
            width: 34
            height: 24
            color: "#ffffff"
            text: OpenHDTelemetry.temp_gnd
            anchors.verticalCenter: parent.verticalCenter
            anchors.right: parent.right
            anchors.rightMargin: 0
            verticalAlignment: Text.AlignVCenter
            font.pixelSize: 14
            horizontalAlignment: Text.AlignRight
            elide: Text.ElideRight
        }



    }


    Item {
        id: downlink
        y: 0

        width: 184
        height:24
        visible: true
        anchors.left: settingsButton.right
        anchors.leftMargin: 6

        Text {
            id: downlink_icon
            y: 0
            width: 24
            height: 24
            color: "#ffffff"
            text: "\uf381"
            anchors.left: parent.left
            anchors.leftMargin: 0
            anchors.top: parent.top
            anchors.topMargin: 0
            verticalAlignment: Text.AlignVCenter
            font.family: "Font Awesome 5 Free"
            styleColor: "#f7f7f7"
            font.pixelSize: 14
            horizontalAlignment: Text.AlignRight
        }

        Text {
            id: primary_radio_dbm
            width: 32
            height: 24
            color: "#ffffff"
            text: "dBm"
            anchors.left: downlink_rssi.right
            anchors.leftMargin: 2
            anchors.top: parent.top
            anchors.topMargin: 0
            verticalAlignment: Text.AlignTop
            font.pixelSize: 10
            horizontalAlignment: Text.AlignLeft
            wrapMode: Text.NoWrap
            elide: Text.ElideRight
            clip: false
        }

        Text {
            id: downlink_rssi
            width: 34
            height: 24
            color: "#ffffff"
            text: OpenHDTelemetry.downlink_rssi
            anchors.left: downlink_icon.right
            anchors.leftMargin: 0
            anchors.top: parent.top
            anchors.topMargin: 0
            verticalAlignment: Text.AlignVCenter
            font.pixelSize: 14
            horizontalAlignment: Text.AlignRight
            wrapMode: Text.NoWrap
            elide: Text.ElideRight
            clip: true
        }
    }


    Item {
        id: uplink
        y: 0

        width: 148
        height: 48
        anchors.verticalCenter: parent.verticalCenter
        anchors.right: parent.right
        anchors.rightMargin: 0

        Text {
            id: uplink_icon
            y: 0
            width: 24
            height: 24
            color: "#ffffff"
            text: "\uf382"
            anchors.right: uplink_rssi.left
            anchors.rightMargin: 0
            font.family: "Font Awesome 5 Free"
            font.pixelSize: 14
            anchors.top: parent.top
            styleColor: "#f7f7f7"
            verticalAlignment: Text.AlignVCenter
            z: 2.2
            anchors.topMargin: 0
            horizontalAlignment: Text.AlignRight
        }

        Text {
            id: uplink_dbm
            x: 568
            y: 0
            width: 32
            height: 24
            color: "#ffffff"
            text: "dBm"
            anchors.right: parent.right
            anchors.rightMargin: 8
            anchors.top: parent.top
            anchors.topMargin: 0
            horizontalAlignment: Text.AlignLeft
            font.pixelSize: 10
            verticalAlignment: Text.AlignTop
            wrapMode: Text.NoWrap
            elide: Text.ElideRight
            clip: false
        }

        Text {
            id: uplink_rssi
            x: 820
            y: 0
            width: 34
            height: 24
            color: "#ffffff"
            text: OpenHDTelemetry.current_signal_joystick_uplink
            anchors.right: uplink_dbm.left
            anchors.rightMargin: 2
            anchors.top: parent.top
            anchors.topMargin: 0
            horizontalAlignment: Text.AlignRight
            font.pixelSize: 14
            verticalAlignment: Text.AlignVCenter
            wrapMode: Text.NoWrap
            elide: Text.ElideRight
            clip: false
        }

        Text {
            id: uplink_lost_packet_cnt_rc
            x: 0
            y: 0
            width: 64
            height: 24
            color: "#ffffff"
            text: OpenHDTelemetry.lost_packet_cnt_rc
            anchors.bottom: parent.bottom
            anchors.bottomMargin: 0
            anchors.right: uplink_lost_packet_cnt_telemetry_up.left
            anchors.rightMargin: 10
            verticalAlignment: Text.AlignVCenter
            font.pixelSize: 14
            horizontalAlignment: Text.AlignRight
            wrapMode: Text.NoWrap
            elide: Text.ElideRight
            clip: false
            visible: false
        }

        Text {
            id: uplink_lost_packet_cnt_telemetry_up
            x: 0
            y: 0
            width: 64
            height: 24
            color: "#ffffff"
            text: OpenHDTelemetry.lost_packet_cnt_telemetry_up
            anchors.bottom: parent.bottom
            anchors.bottomMargin: 0
            anchors.right: parent.right
            anchors.rightMargin: 8
            horizontalAlignment: Text.AlignLeft
            font.pixelSize: 14
            verticalAlignment: Text.AlignVCenter
            wrapMode: Text.NoWrap
            elide: Text.ElideRight
            clip: false
            visible: false
        }
    }
}

/*##^##
Designer {
    D{i:4;anchors_x:0}D{i:5;anchors_width:24;anchors_x:0}D{i:3;anchors_height:24}D{i:7;anchors_width:24;anchors_x:0}
D{i:8;anchors_width:34;anchors_x:0;anchors_y:0}D{i:9;anchors_height:20;anchors_width:34}
D{i:6;anchors_x:0}D{i:11;anchors_width:34;anchors_x:0;anchors_y:0}D{i:12;anchors_height:20;anchors_width:34;anchors_x:0;anchors_y:11}
D{i:15;anchors_width:34;anchors_x:0;anchors_y:11}D{i:16;anchors_width:32}D{i:17;anchors_width:38}
D{i:19;anchors_width:32}D{i:20;anchors_width:38}
}
##^##*/
