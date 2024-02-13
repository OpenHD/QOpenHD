import QtQuick 2.12
import QtQuick.Controls 2.12
import QtQuick.Layouts 1.12
import QtQuick.Controls.Material 2.12

import Qt.labs.settings 1.0

import OpenHD 1.0

import "../../ui" as Ui
import "../elements"


//
// Complex ;)
// Way more javascript code than i'd like, but as long as you:
// 1) Specify the right param_id
// 2) Specify the right settings model instance
// 3) Declare a matching choices-model here
// This handles all the edge cases that might arise ;)
BaseJoyEditElement{

    // Needs to contain the unique ID of the param inside the param set
    property string m_param_id: "FILL ME"
    property var m_settings_model: _ohdSystemGroundSettings
    // Int param is much more common, but string param is also possible
    property bool override_takes_string_param: false

    ListModel{
        id: elements_model_brightness
        ListElement {value: 0; verbose:"0%"}
        ListElement {value: 25; verbose:"25%"}
        ListElement {value: 50; verbose:"50%"}
        ListElement {value: 75; verbose:"75%"}
        ListElement {value: 95; verbose:"95%"}
        ListElement {value: 98; verbose:"98%"}
        ListElement {value: 100; verbose:"100%\n(Default)"}
        ListElement {value: 102; verbose:"102%"}
        ListElement {value: 105; verbose:"105%"}
        ListElement {value: 125; verbose:"125%"}
        ListElement {value: 150; verbose:"150%"}
        ListElement {value: 175; verbose:"175%"}
        ListElement {value: 200; verbose:"200%"}
    }
    ListModel{
        id: elements_model_saturation
        ListElement {value: 50; verbose:"50%"}
        ListElement {value: 75; verbose:"75%"}
        ListElement {value: 90; verbose:"90%"}
        ListElement {value: 100; verbose:"100%\n(Default)"}
        ListElement {value: 110; verbose:"110%"}
        ListElement {value: 125; verbose:"125%"}
        ListElement {value: 150; verbose:"150%"}
    }
    ListModel{
        id: elements_model_contrast
        ListElement {value: 50; verbose:"50%"}
        ListElement {value: 75; verbose:"75%"}
         ListElement {value: 90; verbose:"90%"}
        ListElement {value: 100; verbose:"100%\n(Default)"}
        ListElement {value: 125; verbose:"125%"}
        ListElement {value: 150; verbose:"150%"}
    }
    ListModel{
        id: elements_model_sharpness
        ListElement {value: 50; verbose:"50%"}
        ListElement {value: 75; verbose:"75%"}
        ListElement {value: 90; verbose:"90%"}
        ListElement {value: 100; verbose:"100%\n(Default)"}
        ListElement {value: 110; verbose:"110%"}
        ListElement {value: 125; verbose:"125%"}
        ListElement {value: 150; verbose:"150%"}
    }
    ListModel{
        id: elements_model_rotation
        ListElement {value: 50; verbose:"50%"}
        ListElement {value: 75; verbose:"75%"}
        ListElement {value: 90; verbose:"90%"}
        ListElement {value: 100; verbose:"100%\n(Default)"}
        ListElement {value: 110; verbose:"110%"}
        ListElement {value: 125; verbose:"125%"}
        ListElement {value: 150; verbose:"150%"}
    }
    ListModel{
        id: elements_model_on_off
        ListElement {value: 0; verbose:"OFF"}
        ListElement {value: 1; verbose:"ON"}
    }
    ListModel{
        id: elements_model_air_recording
        ListElement {value: 0; verbose:"ALWAYS\nOFF"}
        ListElement {value: 1; verbose:"ALWAYS\nON"}
         ListElement {value: 2; verbose:"AUTO\n(WHEN ARMED)"}
    }
    ListModel{
        id: elements_model_hotspot
        ListElement {value: 0; verbose:"AUTO\n(WHEN DISARMED)"}
        ListElement {value: 1; verbose:"ALWAYS\nOFF"}
        ListElement {value: 2; verbose:"ALWAYS\nON"}
    }
    ListModel{
        id: elements_model_camera_rotation_degree
        ListElement {value: 0; verbose:"0°\n(Default)"}
        ListElement {value: 1; verbose:"180°\n"}
    }

    ListModel{
        id: elements_model_undefined
        ListElement {value: 0; verbose:"0\nUNDEFINED"}
        ListElement {value: 1; verbose:"1\nUNDEFINED"}
        ListElement {value: 2; verbose:"2\nUNDEFINED"}
    }

    // NOTE: This is for a string param !
    ListModel{
        id: elements_model_camera_resolution
        ListElement {value: "640x480@60"; verbose:"VGA 4:3\n60fps"}
        ListElement {value: "1280x720@60"; verbose:"HD 16:9\n60fps"}
        ListElement {value: "1920x1080@30"; verbose:"FHD 16:9\n30fps"}
    }

    property int m_model_index: -1;
    property int m_actual_value_int: -1;
    property string m_actual_value_string: ""
    property bool m_param_exists: false;

    function get_model(){
        if(m_param_id=="BRIGHTNESS"){
            return elements_model_brightness;
        }else if(m_param_id=="SATURATION"){
            return elements_model_saturation;
        }else if(m_param_id=="CONTRAST"){
            return elements_model_contrast;
        }else if(m_param_id=="SHARPNESS"){
            return elements_model_sharpness;
        }else if(m_param_id=="ROTATION"){
            return elements_model_rotation;
        }else if(m_param_id=="ENABLE_JOY_RC"){
            return elements_model_on_off;
        }else if(m_param_id=="AIR_RECORDING_E"){
            return elements_model_air_recording;
        }else if(m_param_id=="WIFI_HOTSPOT_E"){
            return elements_model_hotspot
        }else if(m_param_id=="RESOLUTION_FPS"){
            return elements_model_camera_resolution;
        }
        return elements_model_undefined;
    }

    onVisibleChanged: {
        if(visible){
            populate();
        }
    }

    property int m_update_count: m_settings_model.update_count
    onM_update_countChanged: {
        if(visible){
            populate();
        }
    }
    property bool m_has_params_fetched: m_settings_model.has_params_fetched
    onM_has_params_fetchedChanged: {
        if(visible){
            populate();
        }
    }

    function populate(){
        // First, check if the system is alive
        if(!m_settings_model.system_is_alive()){
            // Do not enable the elements, system is not alive
            m_model_index=-1;
            return;
        }
        if(!m_settings_model.has_params_fetched){
            m_model_index=-1;
            return;
        }
        var param_exists;
        if(override_takes_string_param){
            param_exists=m_settings_model.param_string_exists(m_param_id)
        }else{
            param_exists=m_settings_model.param_int_exists(m_param_id)
        }
        if(!param_exists){
            console.log("Param "+m_param_id+" does not exist");
            m_param_exists=false;
            m_model_index=-1;
            return;
        }
        m_param_exists=true;
        if(override_takes_string_param){
            m_actual_value_string=m_settings_model.get_cached_string(m_param_id);
            update_model_index(m_actual_value_string);
        }else{
            m_actual_value_int=m_settings_model.get_cached_int(m_param_id);
            update_model_index(m_actual_value_int);
        }
    }


    function update_model_index(value){
        for(var i=0;i<get_model().count;i++){
            const tmp=get_model().get(i).value;
            if(value===tmp){
                m_model_index=i;
                return;
            }
        }
        m_model_index=-1;
    }


    m_button_left_activated: {
        return m_model_index!=-1 && m_model_index>0 && !m_settings_model.ui_is_busy;
    }

    m_button_right_activated: {
        return m_model_index!=-1 && m_model_index<get_model().count-1 && !m_settings_model.ui_is_busy;
    }

    m_displayed_value: {
        if(m_model_index==-1){
            if(m_param_exists){
                var ret="{";
                if(override_takes_string_param){
                    ret+=m_actual_value_string;
                }else{
                    ret+=m_actual_value_int;
                }
                ret+="}\nCUSTOM";
                return ret;
            }else{
                return "NOT\nAVAILABLE"
            }
        }
        return get_model().get(m_model_index).verbose;
    }

    function try_update_value_async(increment){
        if(m_model_index==-1)return;
        var new_model_index=m_model_index;
        if(increment){
            new_model_index+=1;
        }else{
            new_model_index-=1;
        }
        const value_new=get_model().get(new_model_index).value;
        if(override_takes_string_param){
             m_settings_model.try_set_param_string_async(m_param_id,value_new);
        }else{
             m_settings_model.try_set_param_int_async(m_param_id,value_new);
        }
    }

    onChoice_left: {
        try_update_value_async(false);
    }

    onChoice_right: {
        try_update_value_async(true);
    }


}
