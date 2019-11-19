import QtQuick 2.12
import QtGraphicalEffects 1.12

import OpenHD 1.0

import "."
import "./widgets"

Rectangle {
    id: statusBar

    width: 800
    color: "#8f000000"

    anchors {
        bottom: parent.bottom
        left: parent.left
        right: parent.right
    }

    z: 2.0

    height: 48
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
