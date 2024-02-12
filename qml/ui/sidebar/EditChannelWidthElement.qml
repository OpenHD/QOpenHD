import QtQuick 2.12
import QtQuick.Controls 2.12
import QtQuick.Layouts 1.12
import QtQuick.Controls.Material 2.12

import Qt.labs.settings 1.0

import OpenHD 1.0

import "../../ui" as Ui
import "../elements"


BaseJoyEditElement{
    m_title: "Channel Width"


    ListModel{
        id: elements_model
        ListElement {value: 5700; verbose:"5700Mhz\nOHD 1"}
        ListElement {value: 5745; verbose:"5745Mhz\nOHD 2"}
        ListElement {value: 5785; verbose:"5785Mhz\nOHD 3"}
        ListElement {value: 5825; verbose:"5825Mhz\nOHD 4"}
        ListElement {value: 5865; verbose:"5865Mhz\nOHD 5"}
    }

    property int m_model_index: -1;

    m_button_left_activated: {
        if(!_ohdSystemAir.is_alive)return false;
        return _ohdSystemAir.curr_channel_width_mhz==40;
    }

    m_button_right_activated: {
        if(!_ohdSystemAir.is_alive)return false;
        return _ohdSystemAir.curr_channel_width_mhz==20;
    }

    m_displayed_value: {
        if(!_ohdSystemAir.is_alive)return "N/A";
        var channel_width=_ohdSystemAir.curr_channel_width_mhz
        if(channel_width==20){
            return "20Mhz"
        }else if(channel_width==40){
            return "40Mhz\n(HIGH BW)"
        }
        return "N/A"
    }

    function set_channel_width_async(channel_width_mhz){
        if(!_ohdSystemAir.is_alive){
            _hudLogMessagesModel.add_message_warning("Cannot change BW:"+channel_width_mhz+"Mhz, AIR not alive");
            return;
        }
         _qopenhd.set_busy_for_milliseconds(2000,"CHANGING BW");
        _wbLinkSettingsHelper.change_param_air_channel_width_async(channel_width_mhz,true);
    }

    onChoice_left: {
        set_channel_width_async(20);
    }

    onChoice_right: {
        set_channel_width_async(40);
    }


}
