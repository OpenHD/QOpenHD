import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.12

import QtQuick.Shapes 1.0
import QtQuick.Controls.Material 2.0

import Qt.labs.settings 1.0

import OpenHD 1.0

import "../elements"

//
// Joystick controllable (override the events)
// (But also clickable)
//
Item {
    id: sidebar_stack_button
    height: 52
    width: 68
    objectName: "sidebarCategory_" + override_tag
    readonly property bool selected: m_stack_index === override_index

    property string override_text: "OVERRIDE ME"
    property string override_tag: "OVERRIDE ME"
    property int override_index: -100;


    function takeover_control(){
        forceActiveFocus();
    }

    onActiveFocusChanged: {
        if(activeFocus){
            sidebar.ensure_stack_item_visible(sidebar_stack_button);
        }
    }


    Rectangle {
        anchors.centerIn: parent
        width: 54
        height: 46
        radius: 12
        color: selected ? "#234f70" : (mouseArea.containsMouse ? "#223647" : "transparent")
        border.color: "#71d4ff"
        border.width: activeFocus ? 2 : 0
    }

    Rectangle {
        anchors.left: parent.left
        anchors.verticalCenter: parent.verticalCenter
        width: 4
        height: 22
        radius: 2
        color: "#58ccff"
        visible: selected
    }

    Text {
        anchors.centerIn: parent
        text: override_text
        font.pixelSize: 24
        font.family: "Font Awesome 5 Free"
        color: selected ? "#d6f3ff" : "#bbcbd8"
    }
    MouseArea {
        id: mouseArea
        anchors.fill: parent
        hoverEnabled: true
        onClicked: {
            console.log("Item clicked: " + override_tag)
            sidebar.update_stack_index(override_index)
        }
    }

    Keys.onPressed: (event)=> {
                        console.log("SidebarStackButton"+override_tag+" key was pressed:"+event);
                        if(event.key === Qt.Key_Up){
                            m_stack_index--;
                            if(m_stack_index<-1){
                                m_stack_index=-1;
                            }
                            sidebar.handover_joystick_control_to_button(m_stack_index);
                            if(m_stack_index==-1){
                                sidebar.close();
                            }
                            event.accepted=true;
                        }else if(event.key === Qt.Key_Down){
                            m_stack_index++;
                            if(m_stack_index>6){
                                m_stack_index=0;
                            }
                            sidebar.handover_joystick_control_to_button(m_stack_index);
                            event.accepted=true;
                        }else if(event.key==Qt.Key_Right && focus){
                            sidebar.handover_joystick_control_to_panel(sidebar.m_stack_index);
                            event.accepted=true;
                        }
                    }
}
