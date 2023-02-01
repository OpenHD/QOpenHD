import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.12
import QtQuick.Controls.Styles 1.4
import Qt.labs.settings 1.0


SpinBox {
    id: control

    property bool selected: false

    NumberAnimation {
        id: animatePlus
        target: plusHighlight
        properties: "width"
        from: 20
        to: 40
        loops: Animation.Infinite
        duration: 1000
        easing {type: Easing.OutBack; overshoot: 5}
    }

    NumberAnimation {
        id: animateMinus
        target: minusHighlight
        properties: "width"
        from: 20
        to: 40
        loops: Animation.Infinite
        duration: 1000
        easing {type: Easing.OutBack; overshoot: 5}
    }

    Keys.onPressed: {
        if (event.key === Qt.Key_S){
            selected = true
            highlight.color= "#33aaff"
            animateMinus.start()
            animatePlus.start()
        }
        else if (event.key === Qt.Key_Escape){
            selected = false
            highlight.color= "grey"
        }
        else if (event.key === Qt.Key_Equal){
            if (selected == true){
                control.increase()
                up.pressed
            }
        }
        else if (event.key === Qt.Key_Minus){
            if (selected == true){
                control.decrease()
                down.pressed
            }
        }
    }

    onActiveFocusChanged: {
        if (control.activeFocus == true){
            //console.log("New spinbox has focus");
            highlight.visible=true
            highlight.color= "#33aaff"

            if(control.selected){
                highlight.color= "#33aaff"
            }
            else
                highlight.color= "grey"
        }
        else if (control.activeFocus == false){
            //console.log("New spinbox has lost focus");
            highlight.visible=false
            animateMinus.stop()
            animatePlus.stop()
        }
    }

    contentItem: TextInput {
        z: 2
        text: control.textFromValue(control.value, control.locale)

        font: control.font
        color: control.activeFocus ? "black" : "grey"
        selectionColor: "black"
        selectedTextColor: "black"
        horizontalAlignment: Qt.AlignHCenter
        verticalAlignment: Qt.AlignVCenter

        readOnly: !control.editable
    }

    up.indicator: Rectangle {
        x: control.mirrored ? 0 : parent.width - width
        height: parent.height
        implicitWidth: 30
        color: "transparent"

        Rectangle {
            id: plusHighlight
            anchors.centerIn: parent
            width: 30
            height: plusHighlight.width
            color: up.pressed ? "grey" :
                                control.selected ? "#33aaff" : "transparent"
            border.color: "transparent"
            radius: plusHighlight.width/2
            opacity: .2
        }

        Text {
            text: "+"
            anchors.centerIn: parent
            font.pixelSize: control.font.pixelSize * 2
            color: control.selected ? "black" : "grey"
            anchors.fill: parent
            fontSizeMode: Text.Fit
            horizontalAlignment: Text.AlignHCenter
            verticalAlignment: Text.AlignVCenter
            opacity:1
        }
    }


    down.indicator: Rectangle {
        x: control.mirrored ? parent.width - width : 0
        height: parent.height
        implicitWidth: 30
        color: "transparent"

        Rectangle {
            id: minusHighlight
            anchors.centerIn: parent
            width: 30
            height: minusHighlight.width
            color: down.pressed ? "grey" :
                                  control.selected ? "#33aaff" : "transparent"
            border.color: "transparent"
            radius: minusHighlight.width/2
            opacity: .2
        }

        Text {
            text: "-"
            anchors.centerIn: parent
            font.pixelSize: control.font.pixelSize * 2
            color: control.selected ? "black" : "grey"
            anchors.fill: parent
            fontSizeMode: Text.Fit
            horizontalAlignment: Text.AlignHCenter
            verticalAlignment: Text.AlignVCenter
            opacity:1
        }
    }

    background: Rectangle {
        implicitWidth: 100
        border.color: "transparent"
        color: "transparent"
        radius:12
    }

    Rectangle {
        id: highlight //this is the center highlight of the button on text

        z:0

        anchors.centerIn: parent
        width: 60
        height: 35
        radius: 20
        opacity: .3
    }
}
