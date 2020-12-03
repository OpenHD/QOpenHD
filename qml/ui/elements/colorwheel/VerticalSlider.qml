/*
 * Copyright Maxime Engel (https://github.com/MaximeEngel)
 *
 * License: GPL v3
 *
 */
 
import QtQuick 2.0

import "mathUtils.js" as MathUtils

Item {
    id: root
    width: 15
    height: 200

    property real value
    signal accepted

    states :
        // When user is moving the slider
        State {
            name: "editing"
            PropertyChanges {
                target: root
                // Initialize with the value in the default state.
                // Allows to break the link in that state.
                value: root.value
            }
        }

    // Cursor
    Item {
        id: pickerCursor
        width: parent.width
        height: 8

        Rectangle {
            id: cursor
            x: -4
            y: MathUtils.clamp(root.height * (1 - root.value), 0.0, root.height)
            width: parent.width + -2*x
            height: parent.height
            border.color: "black"
            border.width: 1
            color: "transparent"

            Rectangle {
                anchors.fill: parent; anchors.margins: 2
                border.color: "white"; border.width: 1
                color: "transparent"
            }
        }
    }

    MouseArea {
        id: mouseAreaSlider
        anchors.fill: parent

        function sliderHandleMouse(mouse){
            root.state = 'editing'
            if (mouse.buttons & Qt.LeftButton) {
                root.value = MathUtils.clampAndProject(mouse.y, 0.0, height, 1.0, 0.0)
            }
        }
        onPositionChanged: sliderHandleMouse(mouse)
        onPressed: sliderHandleMouse(mouse)
        onReleased: {
            root.state = ''
            root.accepted()
        }
    }
}

