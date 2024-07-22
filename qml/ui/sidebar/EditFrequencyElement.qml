import QtQuick 2.12
import QtQuick.Controls 2.12
import QtQuick.Layouts 1.12
import QtQuick.Controls.Material 2.12

import Qt.labs.settings 1.0

import OpenHD 1.0

BaseJoyEditElement{
    m_title: "Frequency"

    // 5700,5745,5785,5825,5865,5280,5260
    ListModel{
        id: frequencies_model
        ListElement {frequency: 5700; verbose:"5700Mhz\nOHD 1"}
        ListElement {frequency: 5745; verbose:"5745Mhz\nOHD 2"}
        ListElement {frequency: 5785; verbose:"5785Mhz\nOHD 3"}
        ListElement {frequency: 5825; verbose:"5825Mhz\nOHD 4"}
        ListElement {frequency: 5865; verbose:"5865Mhz\nOHD 5"}
        ListElement {frequency: 5280; verbose:"5280Mhz\nOHD 6"}
        ListElement {frequency: 5260; verbose:"5260Mhz\nOHD 7"}
    }
    ListModel{
        id: frequencies_model_with_5180mhz_lowband
        ListElement {frequency: 5180; verbose:"5180Mhz\n{CUSTOM LB}"}
        ListElement {frequency: 5220; verbose:"5220Mhz\n{CUSTOM LB}"}
        ListElement {frequency: 5260; verbose:"5260Mhz\n{CUSTOM LB}"}
        ListElement {frequency: 5300; verbose:"5300Mhz\n{CUSTOM LB}"}
        //
        ListElement {frequency: 5700; verbose:"5700Mhz\nOHD 1"}
        ListElement {frequency: 5745; verbose:"5745Mhz\nOHD 2"}
        ListElement {frequency: 5785; verbose:"5785Mhz\nOHD 3"}
        ListElement {frequency: 5825; verbose:"5825Mhz\nOHD 4"}
        ListElement {frequency: 5865; verbose:"5865Mhz\nOHD 5"}
        ListElement {frequency: 5260; verbose:"5260Mhz\nOHD 6"}
        ListElement {frequency: 5280; verbose:"5280Mhz\nOHD 7"}
    }
    function get_model(){
        if(settings.dev_show_5180mhz_lowband){
            return frequencies_model_with_5180mhz_lowband
        }
        return frequencies_model;
    }

    property int m_model_index: -1;

    function update_model_index(){
        const model=get_model();
        const curr_frequency=curr_air_frequency;
        for(var i=0;i<model.count;i++){
            const tmp=model.get(i).frequency;
            if(curr_frequency==tmp){
                m_model_index=i;
                return;
            }
        }
        m_model_index=-1;
    }

    property int curr_air_frequency: _ohdSystemAir.curr_channel_mhz

    onCurr_air_frequencyChanged: {
        update_model_index()
    }
    onVisibleChanged: {
        if(visible){
            update_model_index();
        }
    }


    function is_armed(){
        if(settings.dev_allow_freq_change_when_armed){
            // Never report as armed
            return false;
        }
        if(_fcMavlinkSystem.is_alive && _fcMavlinkSystem.armed){
            return true;
        }
        return false;
    }
    override_show_red_text: is_armed();


    m_button_left_activated: {
        if(!_ohdSystemAir.is_alive)return false;
        return m_model_index!=-1 && m_model_index>0 && (!is_armed());
    }

    m_button_right_activated: {
        if(!_ohdSystemAir.is_alive)return false;
        return m_model_index!=-1 && m_model_index<get_model().count-1 && (!is_armed());
    }

    m_displayed_value: {
        if(!_ohdSystemAir.is_alive)return "N/A";
        if(m_model_index==-1){
            return "CUSTOM\n"+curr_air_frequency+"Mhz";
        }
        return get_model().get(m_model_index).verbose;
    }


    function set_air_frequency(increment){
        if(m_model_index==-1)return;
        var new_model_index=m_model_index;
        if(increment){
            new_model_index+=1;
        }else{
            new_model_index-=1;
        }
        const new_frequency=get_model().get(new_model_index).frequency
        _qopenhd.set_busy_for_milliseconds(2000,"CHANGING FREQUENCY");
        _wbLinkSettingsHelper.change_param_air_and_ground_frequency(new_frequency)
    }

    onChoice_left: {
        set_air_frequency(false);
    }

    onChoice_right: {
        set_air_frequency(true);
    }


}
