import QtQuick 2.12
import QtQuick.Controls 2.12
import QtQuick.Layouts 1.12
import QtQuick.Controls.Material 2.12

import Qt.labs.settings 1.0

import OpenHD 1.0

import "../../../ui" as Ui
import "../../elements"

BaseJoyEditElement{
    m_title: "Frequency"

    // 5700,5745,5785,5825,5865
    ListModel{
        id: frequencies_model
        ListElement {frequency: 5700; verbose:"5700Mhz\nOHD 1"}
        ListElement {frequency: 5745; verbose:"5745Mhz\nOHD 2"}
        ListElement {frequency: 5785; verbose:"5785Mhz\nOHD 3"}
        ListElement {frequency: 5825; verbose:"5825Mhz\nOHD 4"}
        ListElement {frequency: 5865; verbose:"5865Mhz\nOHD 5"}
    }

    property int m_model_index: -1;

    function update_model_index(){
        const curr_frequency=curr_air_frequency;
        for(var i=0;i<frequencies_model.count;i++){
            const tmp=frequencies_model.get(i).frequency;
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

    m_button_left_activated: {
        if(!_ohdSystemAir.is_alive)return false;
        return m_model_index!=-1 && m_model_index>0;
    }

    m_button_right_activated: {
        if(!_ohdSystemAir.is_alive)return false;
        return m_model_index!=-1 && m_model_index<frequencies_model.count-1;
    }

    m_displayed_value: {
        if(!_ohdSystemAir.is_alive)return "N/A";
        if(m_model_index==-1){
            return "CUSTOM\n"+curr_air_frequency+"Mhz";
        }
        return frequencies_model.get(m_model_index).verbose;
    }


    function set_air_frequency(increment){
        if(m_model_index==-1)return;
        var new_model_index=m_model_index;
        if(increment){
            new_model_index+=1;
        }else{
            new_model_index-=1;
        }
        const new_frequency=frequencies_model.get(new_model_index).frequency
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
