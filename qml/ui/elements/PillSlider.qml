import QtQuick 2.12

// Allows dragging a pill to the right / left
Rectangle {
    id: root

    property int slider_height:32
    property int slider_width: 180

    // square but shown as circle to the user
    property int pill_w_h: slider_height

    property double slider_x: 0

    width: slider_width;
    height: slider_height;
    border.width: 0.05 * slider_height
    radius:       0.5  * slider_height
    color:        "#02324d"

    property bool checked : false

    Text {
        text:  "TODO"
        width: parent.width
        height: parent.height
        font.pixelSize: 0.5 * slider_height
        verticalAlignment: Text.AlignVCenter
        horizontalAlignment: Text.AlignHCenter
    }

    Rectangle { // the moveable control
        id: pill
        color: "#15a4ef"
        x: slider_x
        width:  pill_w_h
        height:  pill_w_h // square
        border.width: 1
        radius: pill.width * 0.5
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
            // check if the user dragged it further than the minimum required for a valid "change" input
            if(pill.x > slider_width - pill.width - slider_width*.02){ //2 percent slop allowed
                console.log("Dragged to the right");
            }else{
                console.log("Not dragged enough");
                checked= false;
                slider_x=0;
            }
        }
        //onClicked: root.clicked(checked) // emit
    }
}
