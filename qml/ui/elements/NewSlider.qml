import QtQuick 2.12
import QtQuick.Controls 2.12
import QtQuick.Layouts 1.12

import Qt.labs.settings 1.0


Slider {
    id: control

    //NEW feature of this slider is possibility to go vertical
    property bool sliderVertical: false

    rotation: sliderVertical ? 90 : 0

    property bool selected: false

    NumberAnimation {
        id: animateHighlight
        target: highlight
        properties: "width"
        from: 5
        to: 35
        loops: Animation.Infinite
        duration: 1000
        easing {type: Easing.OutBack; overshoot: 5}
    }

    onActiveFocusChanged: {
        if (control.activeFocus == true){
            if (selected == false){
                handle.color="grey"
                highlight.color="grey"
            }
            else{
                handle.color="#33aaff"
                highlight.color="#33aaff"
                animateHighlight.start()
            }
        }
        else if (control.activeFocus == false){
            //console.log("New slider has lost focus");
            handle.color="#33aaff"
            highlight.color="transparent"
            animateHighlight.stop()
        }
    }

    onHoveredChanged: {
        if (control.hovered == true){
            handle.color="#33aaff"
            highlight.color="#33aaff"
            animateHighlight.start()
        }
        else{
            handle.color="#33aaff"
            highlight.color="transparent"
            animateHighlight.stop()
        }
    }

    Keys.onPressed: {
        if (event.key === Qt.Key_S){
            if (selected == false){
                selected = true
                handle.color="#33aaff"
                highlight.color="#33aaff"
                animateHighlight.start()
            } else {
                //console.log("Make Selection");
                selected = false
            }
        } else if (event.key === Qt.Key_Escape){
            if (selected == true){
                selected = false
                handle.color="grey"
                highlight.color="grey"
                animateHighlight.stop()
            }
        } else if (event.key === Qt.Key_Minus){
            if (selected == true){
                control.increase()
            }
        } else if (event.key === Qt.Key_Equal){
            if (selected == true){
                control.decrease()
            }
        }

    }

    handle: Rectangle {
        id:handle
        x: control.leftPadding + control.visualPosition * (control.availableWidth - width)
        y: control.topPadding + control.availableHeight / 2 - height / 2
        width: 20
        height: 20
        radius: width/2
        color: "#33aaff"

        Rectangle {
            id:highlight
            anchors.centerIn: handle
            z:0
            width: 40
            height: highlight.width
            radius: width/2
            opacity: .3
            color: "transparent"

            /*   This could be extended later to fix the mouse hover effect...

            MouseArea {
                    anchors.fill: parent
                    hoverEnabled: true
                    onEntered: { highlight.color="#33aaff" }
                    onExited: { highlight.color="transparent" }

                    DragHandler {

                                    target: handle
                                }
                } */
        }
    }
}
