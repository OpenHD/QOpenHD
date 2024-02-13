import QtQuick 2.0

BaseJoyEditElement{
    m_title: "Resolution"

    ListModel{
        id: resolutions_model
        //ListElement {title: "0x0@0"; info:"AUTO\n"}
        ListElement {title: "640x480@60"; info:"VGA 4:3\n60fps"}
        ListElement {title: "1280x720@60"; info:"HD 16:9\n60fps"}
        ListElement {title: "1920x1080@30"; info:"FHD 16:9\n30fps"}
    }

    property int m_model_index: -1;

    function update_model_index(){
        const curr_res_fps=_cameraStreamModelPrimary.curr_set_video_format;
        for(var i=0;i<resolutions_model.count;i++){
            const resoluton_string=resolutions_model.get(i).title;
            if(curr_res_fps===resoluton_string){
                m_model_index=i;
                return;
            }
        }
        m_model_index=-1;
    }

    property string curr_resolution_fps:_cameraStreamModelPrimary.curr_set_video_format;
    onCurr_resolution_fpsChanged: {
        update_model_index();
    }


    m_button_left_activated: {
        if(!_ohdSystemAir.is_alive)return false;
        return m_model_index!=-1 && m_model_index>0;
    }

    m_button_right_activated: {
        if(!_ohdSystemAir.is_alive)return false;
        return m_model_index!=-1 && m_model_index<resolutions_model.count-1;
    }

    m_displayed_value: {
        if(!_ohdSystemAir.is_alive)return "N/A";
        if(m_model_index==-1){
            return "CUSTOM\n"+_cameraStreamModelPrimary.curr_set_video_format;
        }
        return resolutions_model.get(m_model_index).info;
    }


    function set_air_primary_camera_resolution(increment){
        if(m_model_index==-1)return;
        var new_model_index=m_model_index;
        if(increment){
            new_model_index+=1;
        }else{
            new_model_index-=1;
        }
        var new_resolution_string=resolutions_model.get(new_model_index).title;
         _qopenhd.set_busy_for_milliseconds(1000,"CHANGING RESOLUTION");
        _wbLinkSettingsHelper.set_param_video_resolution_framerate_async(true,new_resolution_string)
    }

    onChoice_left: {
        set_air_primary_camera_resolution(false);
    }

    onChoice_right: {
        set_air_primary_camera_resolution(true);
    }


}
