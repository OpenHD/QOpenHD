import QtQuick 2.0

BaseJoyEditElement{
    m_title: "Rate (Bitrate)"

    // We support MCS 0 ... 2
    m_button_left_activated: {
        if(!_ohdSystemAir.is_alive)return false;
        const mcs_index=_ohdSystemAir.curr_mcs_index;
        if(mcs_index>0)return true;
        return false;
    }

    m_button_right_activated: {
        if(!_ohdSystemAir.is_alive)return false;
        const mcs_index=_ohdSystemAir.curr_mcs_index;
        if(mcs_index<2)return true;
        return false;
    }

    m_displayed_value: {
        if(!_ohdSystemAir.is_alive)return "N/A";
        const mcs_index=_ohdSystemAir.curr_mcs_index;
        var value="["+mcs_index+"]\n";
        if(mcs_index==0){
            value+="LONG RANGE"
        }else if(mcs_index==1){
            value+="RANGE"
        }else if(mcs_index==2){
            value+="QUALITY"
        }else{
            value+="EXPERIMENTAL"
        }
        return value;
    }

    function set_air_only_mcs(mcs_index){
        _wbLinkSettingsHelper.set_param_air_only_mcs_async(mcs_index)
    }

    onChoice_left: {
        const mcs_index=_ohdSystemAir.curr_mcs_index;
        if(mcs_index<=0)return;
        set_air_only_mcs(mcs_index-1);
    }

    onChoice_right: {
        const mcs_index=_ohdSystemAir.curr_mcs_index;
        if(mcs_index>=2)return;
        set_air_only_mcs(mcs_index+1);
    }


}
