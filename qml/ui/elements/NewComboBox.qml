import QtQuick 2.12
import QtQuick.Controls 2.12


//This combobox logic could be improved after a selection is made and
//an escape is still required to "exit" the combo box...

ComboBox {
    id: control
    //anchors.fill: parent

    activeFocusOnTab: true

    property bool activeFocusOnPress: false

    property bool selected: false

    property int selection: control.currentIndex

    popup.visible: selected

    background.opacity:.5

    NumberAnimation {
        id: animateBackground
        target: background
        properties: "opacity"
        from: .1
        to: .3
        loops: Animation.Infinite
        duration: 1000
        easing {type: Easing.OutBack; overshoot: 5}
    }

    onActiveFocusChanged: {
        if (control.activeFocus == true){
            background.color="grey"
            background.opacity=.3
        }
        else if (control.activeFocus == false){
            background.color="white"
            background.opacity=.5
            animateBackground.stop()
        }
    }

    textRole: "text"

    //Keys.forwardTo: comboBox
    //Keys.onPressed: allowComplete = (event.key !== Qt.Key_Backspace && event.key !== Qt.Key_Delete);
    Keys.onPressed: {
        if (event.key === Qt.Key_S){
            if (selected == false){
                control.popup.open()
                selected = true
                background.color = "#33aaff"
                animateBackground.start()
            } else {
                //console.log("Make Selection");
                control.currentIndex=selection
                control.activated(selection)
                control.popup.close()
                selected = false
            }
        } else if (event.key === Qt.Key_Escape){
            if (selected == true){
                control.popup.close()
                selected = false
                control.activeFocus=false
            }
            else {
                animateBackground.stop()
                background.color = "grey"
                background.opacity=.3
            }
        } else if (event.key === Qt.Key_Minus){
            if (selected == true){
                control.incrementCurrentIndex()
                selection= selection+1
                //event.accepted = true;
                //console.log("event accepted<<<<<<<");
                //event.key = accepted() //prevent the keypress from "bubbling up" to parent
            }
        } else if (event.key === Qt.Key_Equal){
            if (selected == true){
                control.decrementCurrentIndex()
                selection= selection-1
                //event.accepted = true;
                //console.log("event accepted<<<<<<<");
                // event.key = accepted() //prevent the keypress from "bubbling up" to parent
            }
        }

    }

    onPressedChanged: if (pressed)selected=true



}
