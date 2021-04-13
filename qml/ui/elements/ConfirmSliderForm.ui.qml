import QtQuick 2.12
import QtQuick.Controls 2.12
import QtQuick.Layouts 1.12
import QtGraphicalEffects 1.12

import OpenHD 1.0

Rectangle {
    id: root
    // public
    signal clicked(bool checked);  // onClicked:{root.checked = checked;

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
            minimumX: { //handle if this is checked you cant move it
                if (checked==true){
                    return slider_width - slider_height;
                } else {
                    return 0;
                }

            }
        }

        onReleased: { // releasing at the end of drag
            if( checked  &&  pill.x < slider_width - pill.width) {
                root.clicked(false);
                checked=false;
            }
            else if(!checked  &&  pill.x < slider_width - pill.width - slider_width*.02){ //2 percent slop allowed
                root.clicked(false);
                slider_x=0;
                checked=false;
            }
            else if(!checked  &&  pill.x > slider_width - pill.width - slider_width*.02){ //2 percent slop allowed
                root.clicked(true);
                checked=true;
                if (timer_reset==true){//reset via timer
                    selectionResetTimer.start();
                }
            }
        }
        //onClicked: root.clicked(checked) // emit
    }
}

