import QtQuick 2.12
import QtQuick.Controls 2.12
import QtQuick.Layouts 1.12
import QtQuick.Dialogs 1.0
import QtQuick.Controls.Material 2.12

import "../../elements"

// Dialoque to select a resolution for a camera
Card {
    id: dialoque_choose_resolution
    width: 360
    height: 340
    z: 5.0
    anchors.centerIn: parent
    cardName: "Resolution Selection"
    cardNameColor: "black"
    visible: false

    property string m_current_resolution_fps: "1920x1080@30"
    property bool m_is_for_secondary: false
    property bool m_textinput_display_text_valid: false;


    function close(){
        visible=false;
        enabled=false;
    }


    function initialize_and_show(){
        m_current_resolution_fps=m_is_for_secondary ? _cameraStreamModelSecondary.curr_set_video_format : _cameraStreamModelPrimary.curr_set_video_format;
        visible=true;
        enabled=true;
        // Check if the current cam resolution is inside the list
        var curr_res_index=-1;
        for(var i=0;i<resolutions_model.count;i++){
            if(m_current_resolution_fps==resolutions_model.get(i).value){
                curr_res_index=i;
                break;
            }
        }
        combobox_resolutions.model=resolutions_model;
        // If the current camera resolution is not in the list,
        // enable the 'experiment' mode automatically
        if(curr_res_index>=0){
            combobox_resolutions.currentIndex=curr_res_index;
            advanced_checkbox.checked=false;
        }else{
            console.log("Current resolution not found in model");
            advanced_checkbox.checked=true;
            combobox_resolutions.currentIndex=0;
        }
        text_input_cameras.text=m_current_resolution_fps;
    }

    function get_user_selected_resolution(){
        if(advanced_checkbox.checked){
            return text_input_cameras.displayText;
        }
        return combobox_resolutions.model.get(combobox_resolutions.currentIndex).value;
    }

    ListModel{
        id: resolutions_model
        //ListElement {title: "0x0@0   (AUTO)"; value: "0x0@0"}
        ListElement {title: "480p@30fps  (4:3)"; value: "640x480@30"}
        ListElement {title: "480p@60fps  (4:3)"; value: "640x480@60"}
        ListElement {title: "480p@60fps  (16:9)"; value: "848x480@60"}
        ListElement {title: "720p@49fps  (16:9)"; value: "1280x720@49"}
        ListElement {title: "720p@60fps  (4:3)"; value: "960x720@60"}
        ListElement {title: "720p@60fps  (16:9)"; value: "1280x720@60"}
        ListElement {title: "1080p@30fps (16:9)"; value: "1920x1080@30"}
        ListElement {title: "1080p@30fps (4:3)"; value: "1440x1080@30"}
        ListElement {title: "1080p@49fps (4:3)"; value: "1440x1080@49"}
    }


    cardBody: Column{
        spacing: 10
        padding: 10
        Text{
            width: 200
            text: "Your Camera: "+(m_is_for_secondary ? _cameraStreamModelSecondary.camera_type_to_string(_cameraStreamModelSecondary.camera_type) :
                                                        _cameraStreamModelPrimary.camera_type_to_string(_cameraStreamModelPrimary.camera_type) )
        }
        Text{
            width: 200
            text: "Default Resolution: "+"1920x1080@30";
        }
        ComboBox {
            width: 300
            id: combobox_resolutions
            model: resolutions_model
            textRole: "title"
            implicitWidth:  elementComboBoxWidth
            currentIndex: 0
            visible: !advanced_checkbox.checked
        }
        Row{
            spacing: 10
            padding: 0
            TextInput{
                //width: 300
                id: text_input_cameras
                text: "WIDTHxHEIGHT@FPS"
                visible: advanced_checkbox.checked
                maximumLength: 13 //3840x2160@200 | 13 chars
                font.pixelSize: 20
                padding: 2
                topPadding: 6
                Rectangle{
                    implicitWidth: parent.width
                    implicitHeight: 2
                    color: "black"
                    anchors.left: parent.left
                    anchors.bottom: parent.bottom
                }
                color: m_textinput_display_text_valid ? "black" : "red";
                onDisplayTextChanged: {
                    if(_cameraStreamModelPrimary.is_valid_resolution_fps_string(displayText)){
                        m_textinput_display_text_valid=true;
                    }else{
                        m_textinput_display_text_valid=false;
                    }
                }
            }
            // padding
            Item {
                width: 10
            }
            ButtonIconInfo{
                visible: text_input_cameras.visible
                onClicked: {
                    _messageBoxInstance.set_text_and_show("You can enter any (UNCHECKED !) resolution@fps you like here.")
                }
            }
        }
        // Toggles between text and drop down input
        CheckBox{
            id: advanced_checkbox
            text: "experiment"
        }
    }
    hasFooter: true
    cardFooter: Item {
        anchors.fill: parent
        RowLayout{
            anchors.fill: parent

            Button{
                Layout.preferredWidth: 150
                text: "CANCEL"
                onPressed: {
                   close();
                }
            }
            Button{
                Layout.preferredWidth: 150
                text: "SAVE"
                onPressed: {
                    var success=false;
                    const selected_res_fps=get_user_selected_resolution();
                    console.log("Setting "+(m_is_for_secondary ? "CAM2" : "CAM1")+" to {"+selected_res_fps+"}");
                    if(m_is_for_secondary){
                        success=_airCameraSettingsModel2.try_update_parameter_string("RESOLUTION_FPS",selected_res_fps)===""
                    }else{
                        success=_airCameraSettingsModel.try_update_parameter_string("RESOLUTION_FPS",selected_res_fps)===""
                    }
                    if(success){
                        _messageBoxInstance.set_text_and_show("Saved "+selected_res_fps);
                        close();
                    }else{
                        _messageBoxInstance.set_text_and_show("Failed,please try again");
                    }
                }
                enabled: {
                    const selected_res_fps=get_user_selected_resolution();
                    return _cameraStreamModelPrimary.is_valid_resolution_fps_string(selected_res_fps) && selected_res_fps!=m_current_resolution_fps;
                }
            }
        }
    }
}

