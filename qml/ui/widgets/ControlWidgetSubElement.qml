import QtQuick 2.0

import "../elements"

// Simple way to show a "stick" position in qml
// Draws a big circle to show the full range and
// a small circle to show the input itself
Rectangle {

    //color: "green"
    //color: "yellow"
    color: "transparent"

    // 1.0 - full right
    //-1.0 - full left
    // same for top / bottom

    property double position_x: 0.0;
    property double position_y: 0.0;

    // The main circle
    Rectangle {
        id: circle

        anchors.fill: parent

        color: "transparent"
        radius: width * 0.3

        border.color: settings.color_shape
        border.width: 1
    }

    // The stick
    Rectangle {
        id: stick1
        anchors.centerIn: circle


        width: circle.width*0.2
        height: circle.height*0.2

        color: settings.color_text
        //color: "transparent"

        border.color: settings.color_glow
        border.width: 1
        radius: width*0.5

        visible: true

        transformOrigin: Item.Center

        transform: Translate {
            x: position_x*(width/2.0)
            y: -1*(position_y*(height/2.0))
        }
    }

}
