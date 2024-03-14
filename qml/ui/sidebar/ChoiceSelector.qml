import QtQuick 2.12

Rectangle{
    id: choiceSelector
    anchors.left: parent.right
    anchors.top: parent.top
    width: 200
    height: 300
    color: "green"
    visible: false

    // Needs to contain the unique ID of the param inside the param set
    property string m_param_id: "FILL ME"
    // Set to air / ground /air cam 1 / air cam 2 depending on where the param is stored
    property var m_settings_model: _ohdSystemGroundSettings
    // Int param is much more common, but string param is also possible
    property bool override_takes_string_param: false

    property int m_initial_index: -1
    property int m_current_user_selected_index: -1;

    property var m_parent

    function open_choices(param_id,current_value,takes_string_param,parent){
        m_param_id=param_id;
        m_initial_index=0;
        m_current_user_selected_index=0;
        visible=true;
        focus=true;
        m_parent=parent
    }

    function close_choices(){
        m_current_user_selected_index=-1;
        m_initial_index=-1;
        visible=false;
        focus=false;
        m_parent.takeover_control();
    }


    Keys.onPressed: (event)=> {
                        console.log("ChoiceSelector"+m_param_id+" key was pressed:"+event);
                        if(event.key == Qt.Key_Left){
                            // Give back
                            close_choices();
                            event.accepted=true;
                        }else if(event.key == Qt.Key_Right){
                            // Do nothing
                            event.accepted=true;
                        }else if(event.key==Qt.Key_Up){
                            if(m_current_user_selected_index+1<availableChociesModel.count){
                                m_current_user_selected_index++;
                            }else{
                                // Out of bounds
                            }
                            event.accepted=true;
                        }else if(event.key==Qt.Key_Down){
                            if(m_current_user_selected_index>0){
                                m_current_user_selected_index--;
                            }else{
                                // Out of bounds
                            }
                            event.accepted=true;
                        }
                    }


    ListModel {
        id: availableChociesModel
        ListElement {value: 0; verbose:"0%"}
        ListElement {value: 1; verbose:"1%"}
    }

    Component {
        id: availableChociesDelegate
        Rectangle {
            width: 200
            height: 50
            id: choice
            color: index==m_current_user_selected_index ? "yellow" : "orange"
            Text {
                text: verbose
            }
        }
    }

    ListView {
        property color fruit_color: "green"
        model: availableChociesModel
        delegate: availableChociesDelegate
        anchors.fill: parent
    }
}
