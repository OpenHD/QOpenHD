import QtQuick 2.12
import QtQuick.Controls 2.12
import QtQuick.Controls.Styles 1.4
import QtQuick.Layouts 1.12
import QtGraphicalEffects 1.12

import OpenHD 1.0

import Qt.labs.settings 1.0

import "./widgets";

Rectangle {
    id: toolBar

    width: 800      
    height: 48

    z: 1.0

    Component.onCompleted: {
        getBarColor()
    }

    function getBarColor() {
        var barColor = settings.bar_behavior
        switch (barColor) {
            case "none": {
                toolBar.color= "#00000000"
                break;
            }
            case "disappear": {
                toolBar.color= OpenHD.armed ? "#00000000" : "#8f000000"
                break;
            }
            case "red": {
                toolBar.color= OpenHD.armed ? "#aeff3333" : "#8f000000"
                break;
            }
            case "black": {
                toolBar.color= "#8f000000"
                break;
            }
        }
    }

    Connections{
        target:settings
        function onBar_behaviorChanged() {
            //console.log("onbar behavior changed!");
            getBarColor()
        }
    }

    Connections{
        target:OpenHD
        function onArmedChanged() {
            //console.log("onbar behavior changed!");
            getBarColor()
        }
    }

    anchors {
        top: parent.top
        left: parent.left
        right: parent.right
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
