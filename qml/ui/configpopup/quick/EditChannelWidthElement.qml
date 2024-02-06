import QtQuick 2.0


BaseJoyEditElement{
    m_title: "Channel Width"


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
        _wbLinkSettingsHelper.change_param_air_channel_width_async(channel_width_mhz,true);
    }

    onChoice_left: {
        set_channel_width_async(20);
    }

    onChoice_right: {
        set_channel_width_async(40);
    }


}
