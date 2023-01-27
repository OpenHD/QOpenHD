import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.12
import QtQuick.Controls.Styles 1.4
import Qt.labs.settings 1.0


SpinBox {
    id: control

    property bool selected: false

    Keys.onPressed: {
        if (event.key === Qt.Key_Return)
            selected = true
        else if (event.key === Qt.Key_Escape)
            selected = false
        else if (event.key === Qt.Key_Equal){
            if (selected == true){
                control.increase()
            }
        }
        else if (event.key === Qt.Key_Minus){
            if (selected == true){
                control.decrease()
            }
        }
    }

    onActiveFocusChanged: {
        if (control.activeFocus == true){
            console.log("New spinbox has focus");
            highlight.visible=true
            highlight.color= "#33aaff"
        }
        else if (control.activeFocus == false){
            console.log("New spinbox has lost focus");
            highlight.visible=false
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
            width: parent.width
            height: parent.height
            color: up.pressed ? "grey" :
                   control.selected ? "#33aaff" : "transparent"
            border.color: "transparent"
            radius: 20
            opacity: .3
        }

        Text {
            text: "+"
            font.pixelSize: control.font.pixelSize * 2
            color: "grey"
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
            width: parent.width
            height: parent.height
            color: down.pressed ? "grey" :
                   control.selected ? "#33aaff" : "transparent"
            border.color: "transparent"
            radius: 20
            opacity: .3
        }

        Text {
            text: "-"
            font.pixelSize: control.font.pixelSize * 2
            color: "grey"
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
        id: highlight //this is the center highlight of the button

        z:0

        anchors.centerIn: parent

        width: 60
        height: 35
        radius: 20
        opacity: .3


    }






}
