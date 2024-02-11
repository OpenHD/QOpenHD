import QtQuick 2.0


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

    ListModel{
        id: elements_model_brightness
        ListElement {value: 25; verbose:"25"}
        ListElement {value: 50; verbose:"50\n(Default)"}
        ListElement {value: 75; verbose:"75"}
        ListElement {value: 100; verbose:"100"}
    }
    ListModel{
        id: elements_model_saturation
        ListElement {value: 50; verbose:"50"}
        ListElement {value: 75; verbose:"75"}
        ListElement {value: 100; verbose:"100\n(Default)"}
        ListElement {value: 125; verbose:"125"}
        ListElement {value: 150; verbose:"150"}
    }
    ListModel{
        id: elements_model_rotation
        ListElement {value: 50; verbose:"50"}
        ListElement {value: 75; verbose:"75"}
        ListElement {value: 100; verbose:"100\n(Default)"}
        ListElement {value: 125; verbose:"125"}
        ListElement {value: 150; verbose:"150"}
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
         ListElement {value: 2; verbose:"AUTO\n(IF ARMED)"}
    }
    ListModel{
        id: elements_model_hotspot
        ListElement {value: 0; verbose:"ALWAYS\nOFF"}
        ListElement {value: 1; verbose:"ALWAYS\nON"}
        ListElement {value: 2; verbose:"AUTO\n(IF DISARMED)"}
    }
    ListModel{
        id: elements_model_contrast
        ListElement {value: 50; verbose:"50"}
        ListElement {value: 75; verbose:"75"}
        ListElement {value: 100; verbose:"100\n(Default)"}
        ListElement {value: 125; verbose:"125"}
        ListElement {value: 150; verbose:"150"}
    }

    ListModel{
        id: elements_model_undefined
        ListElement {value: 0; verbose:"0\nUNDEFINED"}
        ListElement {value: 1; verbose:"1\nUNDEFINED"}
        ListElement {value: 2; verbose:"2\nUNDEFINED"}
    }

    property int m_model_index: -1;
    property int m_actual_value: -1;
    property bool m_param_exists: false;

    function get_model(){
        if(m_param_id=="BRIGHTNESS"){
            return elements_model_brightness;
        }else if(m_param_id=="SATURATION_LC"){
            return elements_model_saturation;
        }else if(m_param_id=="ROTATION"){
            return elements_model_rotation;
        }else if(m_param_id=="ENABLE_JOY_RC"){
            return elements_model_on_off;
        }else if(m_param_id=="AIR_RECORDING_E"){
            return elements_model_air_recording;
        }else if(m_param_id=="WIFI_HOTSPOT_E"){
            return elements_model_hotspot
        }else if(m_param_id=="CONTRAST_LC"){
            return elements_model_contrast;
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
        if(!m_settings_model.param_int_exists(m_param_id)){
            console.log("Param "+m_param_id+" does not exist");
            m_param_exists=false;
            m_model_index=-1;
            return;
        }
        m_param_exists=true;
        var value = m_settings_model.get_cached_int(m_param_id);
        m_actual_value=value;
        update_model_index(value);
    }


    function update_model_index(value){
        for(var i=0;i<get_model().count;i++){
            const tmp=get_model().get(i).value;
            if(value==tmp){
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
                return "{"+m_actual_value+"}\nCUSTOM";
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
        m_settings_model.try_set_param_int_async(m_param_id,value_new);
    }

    onChoice_left: {
        try_update_value_async(false);
    }

    onChoice_right: {
        try_update_value_async(true);
    }


}
