import QtQuick 2.12

Rectangle{
    id: choiceSelector
    anchors.left: parent.right
    anchors.top: parent.top
    width: 200
    height: 300
    color: "green"
    visible: false

    // Index of the element that is selected when the selector is opened (current value)
    property int m_initial_index: -1
    // Changed as the user navigates around
    property int m_current_user_selected_index: -1;

    property var m_parent

    function open_choices(x_model,current_value_index,parent){
        availableChociesModel.clear();
        for(var i=0;i<x_model.count;i++){
            const tmp=x_model.get(i).verbose;
            var data = {'verbose': tmp};
            availableChociesModel.insert(i,{ verbose: tmp});
        }
        if(current_value_index>=availableChociesModel.count || current_value_index<0){
            console.log("index out of bounds !");
            return false;
        }
        m_initial_index=current_value_index;
        m_current_user_selected_index=m_initial_index;
        visible=true;
        focus=true;
        m_parent=parent
    }

    function open_choices2(x_model,current_value,parent){
        // First, find the current selection inside the model
        availableChociesModel.clear();
        var current_value_index=0
        var current_value_found_in_model=false;
        for(var i=0;i<x_model.count;i++){
            const value=x_model.get(i).value;
            const verbose=x_model.get(i).verbose;
            availableChociesModel.insert(i,{'value': value,'verbose': verbose});
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
            const verbose="{"+value+"}\n"+"custom";
            console.log(value+""+verbose)
            availableChociesModel.insert(0,{'value': value,'verbose': verbose});
            current_value_index=0;
        }
        m_initial_index=current_value_index;
        m_current_user_selected_index=m_initial_index;
        visible=true;
        focus=true;
        m_parent=parent
    }

    function close_choices(){
        if(m_current_user_selected_index!=m_initial_index){
            const value_old=availableChociesModel.get(m_initial_index).value;
            const value_new=availableChociesModel.get(m_current_user_selected_index).value;
            console.log("Changed from ["+m_initial_index+":"+value_old+"] to ["+m_current_user_selected_index+":"+value_new+"]");
            m_parent.user_selected_value(value_new);
        }
        m_current_user_selected_index=-1;
        m_initial_index=-1;
        visible=false;
        focus=false;
        m_parent.takeover_control();
    }


    Keys.onPressed: (event)=> {
                        console.log("ChoiceSelector key was pressed:"+event);
                        if(event.key == Qt.Key_Left){
                            // Give back
                            close_choices();
                            event.accepted=true;
                        }else if(event.key == Qt.Key_Right){
                            // Do nothing
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
        Rectangle {
            width: 200
            height: 80
            id: choice
            color: index==m_initial_index ? "yellow" : "orange"

            border.color: "white"
            border.width: (index==m_current_user_selected_index) ? 3 : 0

            Text {
                text: verbose
                anchors.fill: parent
                verticalAlignment: Qt.AlignVCenter
                horizontalAlignment: Qt.AlignHCenter
            }
        }
    }

    ListView {
        model: availableChociesModel
        delegate: availableChociesDelegate
        anchors.fill: parent
    }
}
