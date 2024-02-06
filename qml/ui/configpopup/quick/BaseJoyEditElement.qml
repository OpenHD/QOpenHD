import QtQuick 2.12
import QtQuick.Controls 2.12
import QtQuick.Layouts 1.12
import QtQuick.Controls.Material 2.12

import Qt.labs.settings 1.0

import OpenHD 1.0

import "../../../ui" as Ui
import "../../elements"

//
// Base for an UI element that has the following properties:
// left / right: Increment / Decrement (model) value (If increment / decrement is available)
// top / bottom : Go to next / previous element
// MIDDLE: Show the current value
//
// It looks like this:
// |-------------------------------|
// |             TITLE             |
// | {ARROW L} {CONTENT} {ARROW R} |
// |------------------------------ |
Item{
    id: base_joy_edit_element
    width: 200
    height: 60+30

    property string m_title: "FILL ME"

    property bool m_is_selected: false

    property string m_displayed_value: "VALUE T"

    property bool m_is_enabled: true

    // Set to true if the "select element left" button should be activated
    property bool m_button_left_activated: false
     // Set to true if the "select element right" button should be activated
    property bool  m_button_right_activated: false

    // Emitted if the button left is clicked
    signal choice_left();
    // Emitted if the button right is clicked
    signal choice_right();

    Keys.onPressed: (event)=> {
                        console.log("BaseJoyElement"+m_title+" key was pressed:"+event);
                        if(event.key == Qt.Key_Left){
                           if(m_button_left_activated){
                                choice_left()
                            }else{
                                _qopenhd.show_toast("NOT AVAILABLE");
                            }
                        }else if(event.key == Qt.Key_Right){
                            if(m_button_right_activated){
                                 choice_right()
                             }else{
                                 _qopenhd.show_toast("NOT AVAILABLE");
                             }
                        }
                    }

    Rectangle{
        width: parent.width
        height:parent.height
        border.color: "black"
        border.width: 3
        color: {
            return "blue"
        }
        opacity: base_joy_edit_element.focus ? 1.0 : 0.4;
        //opacity: focus ? 1.0 : 0.4;
        //color: "green"
        //  "#8cbfd7f3" : "#00000000"
        //color: m_is_selected ? "green" : "black"
        //opacity: m_is_selected ? 1.0 : 0.5;
    }

    Text {
        id: title_str
        text: qsTr(m_title)
        width: parent.width
        height: 30
        verticalAlignment: Qt.AlignVCenter
        horizontalAlignment: Qt.AlignHCenter
        font.pixelSize: 18
        anchors.top: parent.top
        color: "white"
    }

    Item{
        id: middle_element_holder
        width: parent.width
        height: 50
        anchors.top: title_str.bottom
        Rectangle{
            color: "white"
            width: parent.width /2;
            height: parent.height
            border.color: "black"
            border.width: 1
            anchors.centerIn: parent
            Text{
                id: middle_element
                width: parent.width
                height: parent.height
                text: m_displayed_value
                verticalAlignment: Qt.AlignVCenter
                horizontalAlignment: Qt.AlignHCenter
                font.pixelSize: 14
            }
        }
        TriangleButton{
            m_point_right: false
            id: button_left
            text: "L"
            anchors.left: parent.left
            height: parent.height
            width: height
            onClicked: choice_left()
            enabled: m_button_left_activated
            m_fill_color: {
                if(enabled){
                    return "green"
                }
                return "black"
            }
        }

        TriangleButton{
            m_point_right: true
            id: button_right
            text: "R"
            anchors.right: parent.right
            height: parent.height
            width: height
            onClicked: choice_right()
            enabled: m_button_right_activated
            m_fill_color: {
                if(enabled){
                    return "green"
                }
                return "black"
            }
        }
    }

    Rectangle{
        width: parent.width
        height: parent.height
        color: "gray"
        opacity: 0.7
        visible: !m_is_enabled
    }

}
