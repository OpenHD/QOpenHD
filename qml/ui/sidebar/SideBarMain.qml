import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.12

import QtQuick.Shapes 1.0
import QtQuick.Controls.Material 2.0
import QtQuick.XmlListModel 2.0

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

    // Dynamic sidebar data loaded from XML
    property int button_count: 1
    property int max_index: 0
    property var stack_buttons: []
    // index of focused element inside the currently opened panel
    property int panel_index: 0
    property int panel_count: 0
    // store values for dynamically created controls
    property var controlState: ({})
    XmlListModel {
        id: menuModel
        source: "Sidebar.xml"
        query: "/sidebar/menu"
        XmlRole { name: "text"; query: "@text" }
        XmlRole { name: "tag"; query: "@tag" }
        XmlRole { name: "index"; query: "@index" }
        onCountChanged: {
            button_count = count
            // highest selectable index, excluding the back button (-1)
            max_index = count > 0 ? count - 2 : 0
        }
    }

    XmlListModel {
        id: controlModel
        source: "Sidebar.xml"
        query: "/sidebar/menu[@index='" + m_stack_index + "']/control"
        XmlRole { name: "type"; query: "@type" }
        XmlRole { name: "text"; query: "@text" }
        XmlRole { name: "action"; query: "@action" }
        XmlRole { name: "setting"; query: "@setting" }
        XmlRole { name: "min"; query: "@min" }
        XmlRole { name: "max"; query: "@max" }
        XmlRole { name: "step"; query: "@step" }
        onCountChanged: {
            panel_count = count
            panel_index = 0
            focusPanelItem()
        }
    }


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
        open_category(0)
    }

    // This is called when the user clicks on the configure button of the CAM1 / CAM2 widget
    function open_video_stream_category(is_primary){
        if(is_primary){
            open_category(1)
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
        for(var i=0; i<stack_buttons.length; i++){
            if(stack_buttons[i].override_index === stack_index){
                stack_buttons[i].takeover_control();
                break;
            }
        }
    }

    function handover_joystick_control_to_panel(){
        panels_item.takeover_control()
    }

    function focusPanelItem(){
        if(controlsColumn.children.length > panel_index){
            var loader = controlsColumn.children[panel_index]
            if(loader.item){
                loader.item.forceActiveFocus()
            }
        }
    }

    onPanel_indexChanged: focusPanelItem()
    onM_stack_indexChanged: panel_index = 0


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

    Column{
        anchors.left: parent.left
        anchors.verticalCenter: parent.verticalCenter
        id: stack_manager
        visible: false
        Repeater {
            model: menuModel
            delegate: SidebarStackButton {
                override_text: model.text
                override_tag: model.tag
                override_index: Number(model.index)
                Component.onCompleted: stack_buttons.push(this)
            }
        }
    }

    Item{
        id: panels_item
        width: secondaryUiWidth
        height: secondaryUiHeight
        anchors.left: stack_manager.right
        anchors.top: stack_manager.top
        focus: false

        function takeover_control(){
            focus = true
            focusPanelItem()
        }

        Keys.onPressed: (event)=>{
            if(event.key === Qt.Key_Up){
                panel_index--
                if(panel_index<0){
                    panel_index=0
                }
                event.accepted=true
            }else if(event.key === Qt.Key_Down){
                panel_index++
                if(panel_index>panel_count-1){
                    panel_index=panel_count-1
                }
                event.accepted=true
            }else if(event.key === Qt.Key_Left){
                sidebar.handover_joystick_control_to_button(sidebar.m_stack_index)
                event.accepted=true
            }
        }

        Column {
            id: controlsColumn
            anchors.fill: parent
            spacing: 6
            Repeater {
                model: controlModel
                delegate: Loader {
                    sourceComponent: model.type === "button" ? buttonComponent : model.type === "switch" ? switchComponent : model.type === "slider" ? sliderComponent : null
                    onLoaded: if(index === panel_index) item.forceActiveFocus()
                }
            }
        }

        Component {
            id: buttonComponent
            Button {
                text: model.text
                onClicked: console.log("action:" + model.action)
            }
        }

        Component {
            id: switchComponent
            Row {
                spacing: 8
                Text { text: model.text; color: "white" }
                Switch {
                    checked: sidebar.controlState[model.setting] || false
                    onToggled: sidebar.controlState[model.setting] = checked
                }
            }
        }

        Component {
            id: sliderComponent
            Column {
                spacing: 4
                Text { text: model.text; color: "white" }
                Slider {
                    from: Number(model.min)
                    to: Number(model.max)
                    stepSize: model.step ? Number(model.step) : 1
                    value: sidebar.controlState[model.setting] || Number(model.min)
                    onValueChanged: sidebar.controlState[model.setting] = value
                }
            }
        }
    }

    ChoiceSelector{
        id: choiceSelector
        anchors.left: panels_item.right
        anchors.top: panels_item.top
        anchors.topMargin: secondaryUiHeight/8
    }

}
