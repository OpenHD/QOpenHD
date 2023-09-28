import QtQuick 2.12

// Allows dragging a pill to the right
Rectangle {
    id: root

    // Should be overrridden
    property string m_pill_description: "TODO"

    property int slider_height:32
    property int slider_width: 180

    // square but shown as circle to the user
    property int pill_w_h: slider_height

    width: slider_width;
    height: slider_height;
    border.width: 0.05 * slider_height
    radius:       0.5  * slider_height
    color:        checked ? "green" : "#02324d"

    property bool checked : false

    signal draggedRight;

    function call_dragged_right(){
        console.log("call_dragged_right")
        root.draggedRight()
    }

    function reset_to_dragable(){
        console.log("Reset to be dragable again")
        checked = false;
        pill.x=0;
    }

    Text {
        text:  m_pill_description
        width: parent.width
        height: parent.height
        font.pixelSize: 0.5 * slider_height
        verticalAlignment: Text.AlignVCenter
        horizontalAlignment: Text.AlignHCenter
        //horizontalAlignment: checked ? Text.AlignLeft : Text.AlignRight
        color: checked ? "black" : "white"
    }

    Rectangle { // the moveable control
        id: pill
        color: "#15a4ef"
        x: 0
        width:  pill_w_h
        height:  pill_w_h // square
        border.width: 1
        radius: pill.width * 0.5
        //visible: !checked
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
                }
                return 0;
            }
        }

        onReleased: { // releasing at the end of drag
            // check if the user dragged it further than the minimum required for a valid "change" input
            if(pill.x > slider_width - pill.width - slider_width*0.05){ //X percent slop allowed 0.02
                checked=true
                pill.x = (slider_width - pill.width); // moved all the way to the right
                call_dragged_right();
            }else{
                console.log("Not dragged enough");
                pill.x=0; // moved all the way to the left
                checked=false;
            }
        }
        //onClicked: root.clicked(checked) // emit
    }
}
