import QtQuick 2.0

BaseJoyEditElement{
    m_title: "Rate (Bitrate)"

    // We support MCS 0..2 and 8..10 (2SS partial streams)
    property var m_supported_mcs: [0, 1, 2, 8, 9, 10]

    function supported_mcs_index(mcs_index){
        for(var i = 0; i < m_supported_mcs.length; i++){
            if(m_supported_mcs[i] === mcs_index){
                return i;
            }
        }
        return -1;
    }
    m_button_left_activated: {
        if(!_ohdSystemAir.is_alive)return false;
        const mcs_index=_ohdSystemAir.curr_mcs_index;
        const idx=supported_mcs_index(mcs_index);
        if(idx>0)return true;
        return false;
    }

    m_button_right_activated: {
        if(!_ohdSystemAir.is_alive)return false;
        const mcs_index=_ohdSystemAir.curr_mcs_index;
        const idx=supported_mcs_index(mcs_index);
        if(idx>=0 && idx<m_supported_mcs.length-1)return true;
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
        }else if(mcs_index==8){
            value+="2SS PARTIAL 0"
        }else if(mcs_index==9){
            value+="2SS PARTIAL 1"
        }else if(mcs_index==10){
            value+="2SS PARTIAL 2"
        }else{
            value+="EXPERIMENTAL"
        }
        return value;
    }

    function set_air_only_mcs(mcs_index){
         _qopenhd.set_busy_for_milliseconds(2000,"CHANGING RATE");
        _wbLinkSettingsHelper.set_param_air_only_mcs_async(mcs_index)
    }

    onChoice_left: {
        const mcs_index=_ohdSystemAir.curr_mcs_index;
        const idx=supported_mcs_index(mcs_index);
        if(idx<=0)return;
        set_air_only_mcs(m_supported_mcs[idx-1]);
    }

    onChoice_right: {
        const mcs_index=_ohdSystemAir.curr_mcs_index;
        const idx=supported_mcs_index(mcs_index);
        if(idx<0 || idx>=m_supported_mcs.length-1)return;
        set_air_only_mcs(m_supported_mcs[idx+1]);
    }


}
