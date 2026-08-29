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

    property int m_model_index: -1;

    property var m_valid_widths: [5, 10, 20, 40]

    function get_current_width_index() {
        var w = _ohdSystemAir.curr_channel_width_mhz;
        for (var i = 0; i < m_valid_widths.length; i++) {
            if (m_valid_widths[i] === w) {
                return i;
            }
        }
        return -1;
    }

    m_button_left_activated: {
        if(!_ohdSystemAir.is_alive)return false;
        return get_current_width_index() > 0;
    }

    m_button_right_activated: {
        if(!_ohdSystemAir.is_alive)return false;
        return get_current_width_index() < (m_valid_widths.length - 1) && get_current_width_index() !== -1;
    }

    m_displayed_value: {
        if(!_ohdSystemAir.is_alive)return "N/A";
        var channel_width=_ohdSystemAir.curr_channel_width_mhz
        if(channel_width==5){
            return "5Mhz"
        }else if(channel_width==10){
            return "10Mhz"
        }else if(channel_width==20){
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
        var idx = get_current_width_index();
        if (idx > 0) {
            set_channel_width_async(m_valid_widths[idx - 1]);
        }
    }

    onChoice_right: {
        var idx = get_current_width_index();
        if (idx < (m_valid_widths.length - 1) && idx !== -1) {
            set_channel_width_async(m_valid_widths[idx + 1]);
        }
    }


}
