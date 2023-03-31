import QtQuick 2.0

import QtQuick 2.12
import QtQuick.Controls 2.12
import QtQuick.Layouts 1.12
import QtGraphicalEffects 1.12

import OpenHD 1.0

// Slide element "to the right" to enable
// Slide element to the left to disable
// based on @Luke's confirm slider
Rectangle {
    id: root
    // public
    signal clicked(bool checked);  // onClicked:{root.checked = checked;

    //
    property bool checked: false


    property int slider_height:32
    property int slider_width: 180

    property string text_off:"I'm a BUG" // don't forget to override
    property string text_on: "I'm a BUG" //don't forget to override

    property color text_color_on: "black"
    property color text_color_off: "white"

    property color color_on: "green"
    property color color_off: "#02324d"

    property int slider_x: 0
    //
    property bool error_last: false

    function on_user_wants_enable(){
        return false;
    }
    function on_user_wants_disable(){
        return false;
    }

    // private
    width: slider_width;
    height: slider_height;
    border.width: 0.05 * slider_height
    radius:       0.5  * slider_height
    color:        checked? color_on : color_off // background
    opacity:      enabled  &&  !mouseArea.pressed? 1: 0.5 // disabled/pressed state

    Text {
        text:  checked ?    text_on : text_off
        color: checked ? text_color_on : text_color_off
        x:    (checked ? 0: pill.width) + (parent.width - pill.width - width) / 2
        font.pixelSize: 0.5 * slider_height
        anchors.verticalCenter: parent.verticalCenter
    }

    Rectangle { // the moveable control
        id: pill
        color: "#15a4ef"
        x: checked ? slider_width - slider_height : slider_x

        width: slider_height
        height: width // square
        border.width: parent.border.width
        radius:       parent.radius
    }

    MouseArea {
        id: mouseArea

        anchors.fill: parent

        drag {
            target:   pill
            axis:     Drag.XAxis
            maximumX: slider_width - slider_height
            minimumX: 0
        }

        onReleased: { // releasing at the end of drag
            if( checked  &&  pill.x < slider_width - pill.width) {
                // user dragged the pill to the left - he wants to disable something
                root.clicked(false);
                checked=false;
            }
            else if(!checked  &&  pill.x < slider_width - pill.width - slider_width*.02){ //2 percent slop allowed
                // user dragged the pill to the left - he wants to disable something
                root.clicked(false);
                checked=false;
            }
            else if(!checked  &&  pill.x > slider_width - pill.width - slider_width*.02){ //2 percent slop allowed
                // user dragged the pill to the right - he wants to enable something
                root.clicked(true);
                checked=true;
            }
        }
        //onClicked: root.clicked(checked) // emit
    }
}


