import QtQuick 2.12
import QtGraphicalEffects 1.12

import OpenHD 1.0

import "."
import "./widgets"

Rectangle {
    id: statusBar

    width: 800
    height: 48

    z: 1.0

    Component.onCompleted: {
        getLowerBarColor()
    }

    function getLowerBarColor() {
        var barColor = settings.bar_behavior
        switch (barColor) {
            case "none": {
                statusBar.color= "#00000000"
                break;
            }
            case "disappear": {
                statusBar.color= OpenHD.armed ? "#00000000" : "#8f000000"
                break;
            }
            case "red": {
                statusBar.color= OpenHD.armed ? "#aeff3333" : "#8f000000"
                break;
            }
            case "black": {
                statusBar.color= "#8f000000"
                break;
            }
        }
    }

    Connections{
        target:settings
        function onBar_behaviorChanged() {
            //console.log("onbar behavior changed!");
            getLowerBarColor()
        }
    }

    Connections{
        target:OpenHD
        function onArmedChanged() {
            //console.log("onbar behavior changed!");
            getLowerBarColor()
        }
    }

    anchors {
        bottom: parent.bottom
        left: parent.left
        right: parent.right
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
