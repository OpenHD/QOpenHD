import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.12

import QtQuick.Shapes 1.0
import QtQuick.Controls.Material 2.0

import Qt.labs.settings 1.0

import OpenHD 1.0

import "../elements"


Item {
    id: sidebar
    width: 64
    height: 24
    visible: settings.show_sidebar || m_extra_is_visible

    anchors.left: parent.left
    anchors.verticalCenter: parent.verticalCenter


    property int secondaryUiWidth: 320
    property int secondaryUiHeight: 390
    property string secondaryUiColor: "#000"
    property real secondaryUiOpacity: 0.75
    property string mainDarkColor: "#302f30"
    property string highlightColor: "#555"

    // Set to true if the sidebar is active (and some HUD elements shall be disabled)
    property bool m_is_active : false

    property bool m_extra_is_visible: false
    property int m_stack_index: -1;


    // Gives (keyboard / joystick) control to this element
    function open_and_take_control(enable_joy){
        m_extra_is_visible=true;
        m_stack_index=0;
        m_is_active = true
        stack_manager.visible=true;
        if(enable_joy){
            hudOverlayGrid.focus=false;
            handover_joystick_control_to_button(m_stack_index);
        }
    }

    // This is called whenever the user clicks on the 'WBLIink' widget
    function open_category(category_index){
        open_and_take_control(false);
        m_stack_index=category_index;
    }

    function open_link_category(){
        open_category(1)
    }

    // This is called when the user clicks on the configure button of the CAM1 / CAM2 widget
    function open_video_stream_category(is_primary){
        if(is_primary){
            open_category(2)
        }
    }

    // CLoses the sidebar and gives focus back to HUD overlay grid
    function close(){
        m_stack_index=-1;
        m_is_active=false;
        m_extra_is_visible=false;
        stack_manager.visible=false;
        choiceSelector.discard_and_close();
        hudOverlayGrid.focus=true;
    }

    function regain_control_on_sidebar_stack(){
        choiceSelector.discard_and_close();
        handover_joystick_control_to_button(m_stack_index);
    }

    function update_stack_index(index_stack_new){
        choiceSelector.discard_and_close();
        if(index_stack_new<0){
            // close the sidebar
            close();
        }else{
            m_stack_index=index_stack_new;
        }

    }

    // Called when the sidebar is opened and the user clicked somewhere on the screen where there is no sidebar
    function notify_sidebar_user_clicked_outside(){
        if(stack_manager.visible){
            console.log("Outside area clicked, closing sidebar");
            close();
        }
    }

    function handover_joystick_control_to_button(stack_index){
        if(stack_index==0){
            b1.takeover_control();
        }else if(stack_index==1){
            b2.takeover_control();
        }else if(stack_index==2){
            b3.takeover_control();
        }else if(stack_index==3){
            b4.takeover_control();
        }else if(stack_index==4){
            b5.takeover_control();
        }else if(stack_index==5){
            b6.takeover_control();
        }else if(stack_index==6){
            b7.takeover_control();
        }else if(stack_index==7){
            b8.takeover_control();
        }
    }

    function handover_joystick_control_to_panel(stack_index){
        if(stack_index==0){
            panel1.takeover_control();
        }else if(stack_index==1){
            panel2.takeover_control();
        }else if(stack_index==2){
            panel3.takeover_control();
        }else if(stack_index==3){
            panel4.takeover_control();
        }else if(stack_index==4){
            panel5.takeover_control();
        }else if(stack_index==5){
            panel6.takeover_control();
        }else if(stack_index==6){
            panel7.takeover_control();
        }else if(stack_index==7){
            panel8.takeover_control();
        }
    }


    // Item that opens up the sidebar
    Item {
        id: uiButton
        width: 32
        height: 32
        anchors.verticalCenter: parent.verticalCenter
        visible: m_stack_index<0;
        MouseArea {
            id: mouseArea1
            anchors.fill: parent
            onClicked: {
                open_and_take_control()
            }
            Rectangle {
                width: parent.width
                height: parent.height
                color: "transparent"
                RowLayout {
                    width: parent.width
                    height: parent.height

                    Text {
                        text: "\uf054"
                        font.pixelSize: 16
                        opacity: 1.0
                        font.family: "Font Awesome 5 Free"
                        color: "grey"
                    }
                }
            }
        }
    }

    Item{
        anchors.left: parent.left
        anchors.verticalCenter: parent.verticalCenter
        id: stack_manager
        visible: false

        property int arrowButtonHeight: 24
        property int stackButtonSize: secondaryUiHeight / 9
        property real availableHeight: parent ? parent.height : secondaryUiHeight
        property bool useOverflow: stackButtonsColumn.implicitHeight > (availableHeight - (arrowButtonHeight * 2))

        width: stackButtonSize
        height: useOverflow ? availableHeight : stackButtonsColumn.implicitHeight

        // Up button for overflowing menus
        Rectangle {
            id: scroll_up_button
            visible: stack_manager.useOverflow
            width: parent.width
            height: stack_manager.arrowButtonHeight
            color: mainDarkColor
            opacity: stack_flickable.contentY > 0 ? 0.9 : 0.4

            Text {
                anchors.fill: parent
                text: "\uf077"
                font.pixelSize: 16
                font.family: "Font Awesome 5 Free"
                color: "white"
                horizontalAlignment: Text.AlignHCenter
                verticalAlignment: Text.AlignVCenter
            }

            MouseArea {
                anchors.fill: parent
                enabled: stack_flickable.contentY > 0
                onClicked: {
                    stack_flickable.contentY = Math.max(0, stack_flickable.contentY - stack_flickable.height / 2)
                }
            }
        }

        Flickable {
            id: stack_flickable
            width: stack_manager.width
            anchors.top: scroll_up_button.visible ? scroll_up_button.bottom : parent.top
            anchors.bottom: scroll_down_button.visible ? scroll_down_button.top : parent.bottom
            contentWidth: stackButtonsColumn.width
            contentHeight: stackButtonsColumn.implicitHeight
            clip: true
            interactive: stack_manager.useOverflow

            Column{
                id: stackButtonsColumn
                width: stack_manager.width
                SidebarStackButton{
                    id: b0
                    override_text: "\uf053"
                    override_tag: "back"
                    override_index: -1
                }
                SidebarStackButton{
                    id: b1
                    override_text: "\uf002"
                    override_tag: "scan"
                    override_index: 0
                }
                SidebarStackButton{
                    id: b2
                    override_text: "\uf1eb"
                    override_tag: "link"
                    override_index: 1
                }
                SidebarStackButton{
                    id: b3
                    override_text: "\uf03d"
                    override_tag: "video"
                    override_index: 2
                }
                SidebarStackButton{
                    id: b4
                    override_text:  "\uf030"
                    override_tag: "camera"
                    override_index: 3
                }
                SidebarStackButton{
                    id: b5
                    override_text: "\uf0c7"
                    override_tag: "recording"
                    override_index: 4
                }
                SidebarStackButton{
                    id: b6
                    override_text: "\uf11b"
                    override_tag: "rc"
                    override_index: 5
                }
                SidebarStackButton{
                    id: b7
                    override_text: "\uf26c"
                    override_tag: "misc"
                    override_index: 6
                }
                SidebarStackButton{
                    id: b8
                    override_text: "\uf55b"
                    override_tag: "status"
                    override_index: 7
                }
            }
        }

        // Down button for overflowing menus
        Rectangle {
            id: scroll_down_button
            visible: stack_manager.useOverflow
            anchors.bottom: parent.bottom
            width: parent.width
            height: stack_manager.arrowButtonHeight
            color: mainDarkColor
            opacity: (stack_flickable.contentY + stack_flickable.height) < stack_flickable.contentHeight ? 0.9 : 0.4

            Text {
                anchors.fill: parent
                text: "\uf078"
                font.pixelSize: 16
                font.family: "Font Awesome 5 Free"
                color: "white"
                horizontalAlignment: Text.AlignHCenter
                verticalAlignment: Text.AlignVCenter
            }

            MouseArea {
                anchors.fill: parent
                enabled: (stack_flickable.contentY + stack_flickable.height) < stack_flickable.contentHeight
                onClicked: {
                    var maxY = stack_flickable.contentHeight - stack_flickable.height
                    stack_flickable.contentY = Math.min(maxY, stack_flickable.contentY + stack_flickable.height / 2)
                }
            }
        }
    }


    Item{
        id: panels_item
        width: secondaryUiWidth
        height: secondaryUiHeight
        anchors.left: stack_manager.right
        anchors.top: stack_manager.top

        Panel8FindAirUnit{
            id: panel1
            visible: m_stack_index==0;
        }
        Panel1Link{
            id: panel2
            visible: m_stack_index==1;
        }
        Panel2Video{
            id: panel3
            visible: m_stack_index==2;
        }

        Panel3Camera{
            id: panel4
            visible: m_stack_index==3;
        }

        Panel4Recording{
            id: panel5
            visible: m_stack_index==4;
        }

        Panel5RC{
            id: panel6
            visible: m_stack_index==5;
        }
        Panel6Misc{
            id: panel7
            visible: m_stack_index==6;
        }
        Panel7Status{
            id: panel8
            visible: m_stack_index==7;
        }
    }

    ChoiceSelector{
        id: choiceSelector
        anchors.left: panels_item.right
        anchors.top: panels_item.top
        anchors.topMargin: secondaryUiHeight/8
    }

}
