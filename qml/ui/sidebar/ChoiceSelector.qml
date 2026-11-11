import QtQuick 2.12
import QtQuick.Controls 2.12

Rectangle{
    id: choiceSelector
    width: 200
    property real popupTop: 78
    readonly property int inset: 6
    readonly property int optionHeight: 40
    readonly property real requiredHeight: availableChociesModel.count * (optionHeight + availableChociesListView.spacing)
        - availableChociesListView.spacing + 2 * inset
    height: Math.min(requiredHeight, secondaryUiHeight - popupTop)
    color: "transparent"
    visible: false

    // Index of the element that is selected when the selector is opened (current value)
    property int m_initial_index: -1
    // Changed as the user navigates around
    property int m_current_user_selected_index: -1;
    // We are only 'clickable' if no joystick usage
    property bool m_allow_clickable: false
    property bool m_force_callback: false
    property string m_close_reason: ""

    property var m_parent

    function open_choices(x_model,current_value,parent){
        // First, find the current selection inside the model
        availableChociesModel.clear();
        m_close_reason="";
        var current_value_index=0
        var current_value_found_in_model=false;
        for(var i=0;i<x_model.count;i++){
            const value=x_model.get(i).value;
            const verbose=x_model.get(i).verbose;
            availableChociesModel.insert(i,{'value': (""+value),'verbose': verbose});
            if(!current_value_found_in_model && value==current_value){
                current_value_index=i;
                current_value_found_in_model=true;
            }
        }
        if(!current_value_found_in_model){
            // If the current value is not 'known' to us (not inside the model) we add an extra element
            // to the model containing exactly this value (and a dummy description)
            console.log("Current value not found in model");
            const value=current_value;
            const verbose = "{" + value + "}\n" + qsTr("custom");
            console.log(value+""+verbose)
            availableChociesModel.insert(0,{'value': value,'verbose': verbose});
            current_value_index=0;
        }
        m_initial_index=current_value_index;
        m_current_user_selected_index=m_initial_index;
        m_parent = parent;
        const rowTop = parent.mapToItem(choiceSelector.parent, 0, 0).y
            - (choiceSelector.parent.height - secondaryUiHeight) / 2;
        popupTop = Math.max(0, Math.min(secondaryUiHeight - requiredHeight, rowTop));
        visible = true;
        forceActiveFocus();
        availableChociesListView.positionViewAtIndex(m_current_user_selected_index, ListView.Contain);
    }

    onM_current_user_selected_indexChanged: {
        if (visible && m_current_user_selected_index >= 0)
            availableChociesListView.positionViewAtIndex(m_current_user_selected_index, ListView.Contain)
    }

    function set_clickable(clickable){
        m_allow_clickable=clickable;
    }

    function set_force_callback(force){
        m_force_callback=force;
    }

    // Calls the parent's update method if there is any change and closes
    function close_choices(){
        var should_callback = (m_current_user_selected_index!=m_initial_index);
        if(m_force_callback && m_close_reason!=="cancel" && m_close_reason!=="discard"){
            should_callback = true;
        }
        if(should_callback){
            const value_old=availableChociesModel.get(m_initial_index).value;
            const value_new=availableChociesModel.get(m_current_user_selected_index).value;
            console.log("Changed from ["+m_initial_index+":"+value_old+"] to ["+m_current_user_selected_index+":"+value_new+"]");
            m_parent.user_selected_value(value_new);
        }
        m_current_user_selected_index=-1;
        m_initial_index=-1;
        visible=false;
        focus=false;
        m_force_callback=false;
        m_close_reason="";
        m_parent.takeover_control();
    }

    // Discards a change selected by the user (if there is any) and closes
    function discard_and_close(){
        m_current_user_selected_index=-1;
        m_initial_index=-1;
        visible=false;
        focus=false;
        m_force_callback=false;
        m_close_reason="discard";
    }


    Keys.onPressed: (event)=> {
                        console.log("ChoiceSelector key was pressed:"+event);
                        if(event.key == Qt.Key_Left){
                            // Either close immediately or go back to the initial choice (don't save)
                            if(m_current_user_selected_index==m_initial_index){
                                m_close_reason="cancel";
                                close_choices();
                            }else{
                                m_current_user_selected_index=m_initial_index;
                            }
                            event.accepted=true;
                        }else if(event.key == Qt.Key_Right){
                            // Save and close or do nothing
                            if(m_current_user_selected_index==m_initial_index){
                                if(m_force_callback){
                                    m_close_reason="accept";
                                    close_choices();
                                }
                            }else{
                                m_close_reason="accept";
                                close_choices();
                            }
                            event.accepted=true;
                        }else if(event.key==Qt.Key_Up){
                            if(m_current_user_selected_index>0){
                                m_current_user_selected_index--;
                            }else{
                                // Out of bounds
                            }
                            event.accepted=true;
                        }else if(event.key==Qt.Key_Down){
                            if(m_current_user_selected_index+1<availableChociesModel.count){
                                m_current_user_selected_index++;
                            }else{
                                // Out of bounds
                            }
                            event.accepted=true;
                        }else if(event.key==Qt.Key_Enter || event.key==Qt.Key_Return){
                            m_close_reason="accept";
                            close_choices();
                            event.accepted=true;
                        }
                    }


    ListModel {
        id: availableChociesModel
        //ListElement { value:0; verbose:"0 def"}
        //ListElement { value:1; verbose:"1 def"}
        //ListElement { value:2; verbose:"2 def"}
        //ListElement { value:3; verbose:"3 def"}
    }

    Component {
        id: availableChociesDelegate
        Item {
            width: ListView.view.width
            height: choiceSelector.optionHeight
            id: choice
            // Background
            Rectangle{
                objectName: "sidebarChoiceHighlight"
                anchors.fill: parent
                radius: 6
                color: index === m_current_user_selected_index ? sidebar.highlightFill("#25455f", secondaryUiColor, 0.85) : "transparent"
                border.color: sidebar.highlightColor("#578bab")
                border.width: index === m_current_user_selected_index ? 1 : 0
            }
            Text {
                objectName: "sidebarChoiceText"
                text: qsTr(verbose)
                anchors.fill: parent
                verticalAlignment: Qt.AlignVCenter
                horizontalAlignment: Qt.AlignLeft
                leftPadding: 41
                rightPadding: 4
                wrapMode: Text.WordWrap
                maximumLineCount: 2
                elide: Text.ElideRight
                color: sidebar.textColor("white")
                font.pixelSize: 18
            }
            Rectangle {
                x: 10; anchors.verticalCenter: parent.verticalCenter; width: 20; height: 20; radius: 10
                color: index === m_initial_index ? sidebar.highlightColor("#00a7f5") : "transparent"
                border.color: index === m_initial_index ? sidebar.highlightColor("#00a7f5") : "#8e9da6"; border.width: 2
                Rectangle { anchors.centerIn: parent; width: 8; height: 8; radius: 4; color: "white"; visible: index === m_initial_index }
            }
            MouseArea{
                anchors.fill: parent
                onClicked: {
                    if(m_allow_clickable){
                        m_close_reason="accept";
                        m_current_user_selected_index=index;
                        close_choices();
                    }
                }
            }
        }
    }

    Rectangle{
        anchors.fill: parent
        radius: 14
        border.color: "#506b83"
        border.width: 1
        color: secondaryUiColor
        opacity: secondaryUiOpacity
    }

    ListView {
        id: availableChociesListView
        model: availableChociesModel
        delegate: availableChociesDelegate
        anchors.fill: parent
        anchors.margins: choiceSelector.inset
        clip: true
        spacing: 3

        ScrollBar.vertical: ScrollBar {
            policy: ScrollBar.AsNeeded
        }
    }
}
