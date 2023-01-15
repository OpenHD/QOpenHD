import QtQuick 2.12
import QtQuick.Controls 2.12
import QtQuick.Layouts 1.12

import Qt.labs.settings 1.0


SwitchDelegate {
    id: control
    text: qsTr("SwitchDelegate")
    checked: true
    clip:false

    Keys.onPressed: {
        if (event.key === Qt.Key_Return && !event.isAutoRepeat)
            checked = !checked;
    }

    onActiveFocusChanged: {
        if (control.activeFocus == true){
            console.log("New switch has focus");
            control.highlighted=true
            highlight.color= "#33aaff"
        }
        else if (control.activeFocus == false){
            console.log("New switch has lost focus");
            control.highlighted=false
        }
    }




    contentItem: Text {
        rightPadding: control.indicator.width + control.spacing
        text: control.text
        font: control.font
        opacity: enabled ? 1.0 : 0.3
        color: control.down ? "#17a81a" : "#21be2b"
        elide: Text.ElideRight
        verticalAlignment: Text.AlignVCenter
    }

    indicator: Rectangle {
        id:pill
        implicitWidth: 48
        implicitHeight: 18
        x: control.width - width - control.rightPadding
        y: parent.height / 2 - height / 2
        radius: 13
        color: control.checked ? "#7dbcf0" : "white"
        border.color: control.checked ? "transparent"  : "#464b52"

        Rectangle {
           id: highlight

           x: control.checked ? parent.width - width : 0
           y: parent.height / 2 - height / 2
           width: 35
           height: 35
           radius: 17
           opacity:.3
           visible: control.down || control.highlighted
           color: "grey"

       }

        Rectangle {
            id:knob
            x: control.checked ? parent.width - width : 0
            y: parent.height / 2 - height / 2
            width: 26
            height: 26
            radius: 13
            color: control.checked ? "#33aaff" : "white"
            border.color: control.checked ? "transparent"  : "#464b52"
        }
    }

    background: Rectangle {
        visible:false
    }

    MouseArea {
        id: mouseArea

        implicitWidth: parent.width
        implicitHeight: parent.height
        x: control.width - width - control.rightPadding
        y: parent.height / 2 - height / 2

        onClicked: {

            control.clicked(!checked) // emit

            if (control.checked== true)
                control.checked=false
            else
                control.checked=true
        }

        hoverEnabled:true

        onEntered: {
            control.highlighted=true
                     highlight.color= "#33aaff"
                 }
        onExited: {
                     control.highlighted=false

                 }
    }

}
