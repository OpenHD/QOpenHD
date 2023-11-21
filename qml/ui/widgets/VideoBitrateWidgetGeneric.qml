import QtQuick 2.12
import QtQuick.Controls 2.12
import QtQuick.Layouts 1.12
import QtGraphicalEffects 1.12
import QtQuick.Shapes 1.0

import Qt.labs.settings 1.0

import OpenHD 1.0
import "../elements"

// Generic since we use the same widget for primary and secondary camera (allbei with different values, of course)
BaseWidget {
    id: bitrateWidget
    width: 112
    height: 48

    property bool m_is_for_primary_camera: true

    widgetIdentifier: m_is_for_primary_camera ? "bitrate_widget" : "bitrate_widget2"
    bw_verbose_name: m_is_for_primary_camera ? "VIDEO BITRATE CAM1" : "VIDEO BITRATE CAM2"

    defaultAlignment: 1
    defaultXOffset: 224
    defaultYOffset: m_is_for_primary_camera ? 0 : 50
    defaultHCenter: false
    defaultVCenter: false


    hasWidgetDetail: true
    hasWidgetAction: true
    widgetActionHeight: 420

    property var m_camera_stream_model: m_is_for_primary_camera ? _cameraStreamModelPrimary : _cameraStreamModelSecondary

    // param - so therefore might not be always synchronized
    property string m_curr_video_format:  m_is_for_primary_camera ? _cameraStreamModelPrimary.curr_set_video_format : _cameraStreamModelSecondary.curr_set_video_format


    function bitrate_color(curr_set_and_measured_bitrate_mismatch){
        if(curr_set_and_measured_bitrate_mismatch===1){
            return "yellow" // too low
        }else if(curr_set_and_measured_bitrate_mismatch==2){
            return "red" // too high
        }
        return settings.color_text // all ok
    }

    function set_camera_resolution(resolution_str){
        if(m_is_for_primary_camera){
           _wbLinkSettingsHelper.set_param_video_resolution_framerate_async(true,resolution_str)
        }else{
            _wbLinkSettingsHelper.set_param_video_resolution_framerate_async(false,resolution_str)
        }
    }
    function get_drop_str_tx_rx(){
        //return _cameraStreamModelPrimary.total_n_tx_dropped_frames+":"+_cameraStreamModelPrimary.count_blocks_lost;
        //return m_camera_stream_model.curr_delta_tx_dropped_frames+":"+m_camera_stream_model.total_n_tx_dropped_frames
        return m_camera_stream_model.total_n_tx_dropped_frames+":"+m_camera_stream_model.count_blocks_lost;
    }

    // Complicated
    // Set to true if the camera is currently doing recordng (the UI element(s) turn red in this case)
    property bool m_camera_is_currently_recording: m_is_for_primary_camera ? _cameraStreamModelPrimary.air_recording_active :  _cameraStreamModelSecondary.air_recording_active

    // THIS IS A MAVLINK PARAM, SYNCHRONIZATION THEREFORE IS HARD AND HERE NOT WORTH IT
    property int m_camera_recording_mode: -1

    function try_set_recording_mode(mode){
        var camera_idx=m_is_for_primary_camera ? 0 : 1;
        console.log("try_set_recording_mode "+camera_idx+" "+mode)
        var camModel=_airCameraSettingsModel;
        var camString="CAM1"
        if(camera_idx===2){
            camModel=_airCameraSettingsModel2;
            camString="CAM2"
        }
        if(!_ohdSystemAir.is_alive){
            _hudLogMessagesModel.signalAddLogMessage(6,"Air unit not alive, cannot set recording for "+camString)
            return;
        }
        if(mode===0){ //mode off
            var result=camModel.try_update_parameter_int("V_AIR_RECORDING",0)===""
            if(result){
                _hudLogMessagesModel.signalAddLogMessage(6,"recording "+camString+" disabled")
                m_camera_recording_mode=0;
            }else{
                 _hudLogMessagesModel.signalAddLogMessage(6,"update "+camString+" failed")
            }
        }
        if(mode===1){ //mode on
            var result=camModel.try_update_parameter_int("V_AIR_RECORDING",1)===""
            if(result){
                _hudLogMessagesModel.signalAddLogMessage(6,"recording "+camString+" enabled")
                m_camera_recording_mode=1;
            }else{
                _hudLogMessagesModel.signalAddLogMessage(6,"update "+camString+" failed")
            }
        }
        if(mode==2){ //mode auto
            var result=camModel.try_update_parameter_int("V_AIR_RECORDING",2)===""
            if(result){
                _hudLogMessagesModel.signalAddLogMessage(6,"recording "+camString+" auto enabled")
                m_camera_recording_mode=2;
            }else{
                 _hudLogMessagesModel.signalAddLogMessage(6,"update "+camString+" failed")
            }
        }
    }

    ListModel{
        id: resolutions_model
        ListElement {title: "480p@30fps  (4:3)"; value: "640x480@30"}
        ListElement {title: "480p@60fps  (4:3)"; value: "640x480@60"}
        ListElement {title: "480p@60fps  (16:9)"; value: "848x480@60"}
        ListElement {title: "720p@49fps  (16:9)"; value: "1280x720@49"}
        ListElement {title: "720p@60fps  (4:3)"; value: "960x720@60"}
        ListElement {title: "720p@60fps  (16:9)"; value: "1280x720@60"}
        ListElement {title: "1080p@30fps (16:9)"; value: "1920x1080@30"}
        ListElement {title: "1080p@30fps (4:3)"; value: "1440x1080@30"}
        ListElement {title: "1080p@49fps (4:3)"; value: "1440x1080@49"}
    }


    //----------------------------- DETAIL BELOW ----------------------------------


    widgetDetailComponent: ScrollView {

        contentHeight: idBaseWidgetDefaultUiControlElements.height
        ScrollBar.horizontal.policy: ScrollBar.AlwaysOff
        clip: true

        BaseWidgetDefaultUiControlElements{
            id: idBaseWidgetDefaultUiControlElements
            Item {
                width: 230
                height: 32
                Text {
                    text: qsTr("Show RED recording active")
                    color: "white"
                    height: parent.height
                    font.bold: true
                    font.pixelSize: detailPanelFontPixels
                    anchors.left: parent.left
                    verticalAlignment: Text.AlignVCenter
                }
                Switch {
                    width: 32
                    height: parent.height
                    anchors.rightMargin: 6
                    anchors.right: parent.right
                    checked: settings.camera_bitrate_widget_show_recording
                    onCheckedChanged: settings.camera_bitrate_widget_show_recording = checked
                }
            }
        }
    }

    //---------------------------ACTION WIDGET COMPONENT BELOW-----------------------------

    widgetActionComponent: ScrollView{

        ScrollBar.horizontal.policy: ScrollBar.AlwaysOff
        clip: true

        ColumnLayout{
            width:200

            SimpleLeftRightText{
                m_left_text: qsTr("Status:")
                m_right_text:  {
                    if(!_ohdSystemAir.is_alive)return "no air";
                    return _cameraStreamModelPrimary.camera_status_to_string(m_camera_stream_model.camera_status);
                }
            }
            SimpleLeftRightText{
                m_left_text: qsTr("Type:")
                m_right_text: {
                    if(!_ohdSystemAir.is_alive)return "n/a";
                    return _cameraStreamModelPrimary.camera_type_to_string(m_camera_stream_model.camera_type);
                }
            }
            SimpleLeftRightText{
                m_left_text: qsTr("Codec:")
                m_right_text: {
                    if(!_ohdSystemAir.is_alive)return "n/a";
                    return _cameraStreamModelPrimary.camera_codec_to_string(m_camera_stream_model.encoding_codec);
                }
            }

            ComboBox{
                id: resolution_fps_cb
                model: resolutions_model
                textRole: "title"
                width: 200
                Layout.preferredWidth: 200
                Layout.minimumWidth: 200
                height: 50
                currentIndex: -1
                displayText: {
                    if(!_ohdSystemAir.is_alive)return "Res@fps N/A";
                    return m_curr_video_format;
                }
                onActivated: {
                    console.log("onActivated:"+currentIndex);
                    if(currentIndex<0)return;
                    const resolution=model.get(currentIndex).value
                    console.log("Selected resolution: "+resolution);
                    set_camera_resolution(resolution);
                    _qopenhd.show_toast("NOTE: OpenHD cannot check if your HW actually supports a given resolution / framerate");
                }
                enabled: _ohdSystemAir.is_alive;
            }
            /*Item{
                width: parent.width
                height: 150
                //color: "green"
                GridLayout{
                    width: parent.width
                    height: parent.height
                    rows: 3
                    columns: 2 //
                    // 1 dummy sw
                    // 2 mmal
                    // 3 veye
                    // 4 libcamera
                    //enabled: (m_camera_stream_model.camera_type==1 || m_camera_stream_model.camera_type==2 || m_camera_stream_model.camera_type==4)
                    Button{
                        text: "480p60(16:9)"
                        onClicked: set_camera_resolution("848x480@60")
                        highlighted: m_curr_video_format=="848x480@60"
                    }
                    Button{
                        text: "480p60(4:3)"
                        onClicked: set_camera_resolution("640x480@60")
                        highlighted: m_curr_video_format=="640x480@60"
                    }
                    Button{
                        text: "720p49(16:9)"
                        onClicked: set_camera_resolution("1280x720@49")
                        highlighted: m_curr_video_format=="1280x720@49"
                    }
                    Button{
                        text: "720p60(4:3)"
                        onClicked: set_camera_resolution("960x720@60")
                        highlighted: m_curr_video_format=="960x720@60"
                    }
                    Button{
                        text: "1080p30(16:9)"
                        onClicked: set_camera_resolution("1920x1080@30")
                        highlighted: m_curr_video_format=="1920x1080@30"
                    }
                    Button{
                        text: "1080p30(4:3)"
                        onClicked: set_camera_resolution("1440x1080@30")
                        highlighted: m_curr_video_format=="1440x1080@30"
                    }
                }
            }*/
            SimpleLeftRightText{
                m_left_text: qsTr("Bitrate SET:")
                m_right_text: m_camera_stream_model.curr_recomended_video_bitrate_string
            }

            SimpleLeftRightText{
                m_left_text: qsTr("MEASURED:")
                m_right_text: m_camera_stream_model.curr_video_measured_encoder_bitrate
            }

            SimpleLeftRightText{
                m_left_text: qsTr("Injected(+FEC):")
                m_right_text: m_camera_stream_model.curr_video_injected_bitrate
            }


            SimpleLeftRightText{
                m_left_text: qsTr("TX Dropped/RX lost:")
                m_right_text: get_drop_str_tx_rx()
            }

            Item{
                width: parent.width
                height: 32
                Text{
                    width: parent.width
                    height: parent.height
                    verticalAlignment: Qt.AlignVCenter
                    horizontalAlignment: Qt.AlignHCenter
                    text: "AIR RECORDING"
                    color: "white"
                }
            }
            SimpleLeftRightText{
                m_left_text:  qsTr("FREE SPACE:")
                m_right_text: {
                    if(!_ohdSystemAir.is_alive)return "N/A";
                    return _ohdSystemAir.curr_space_left_mb+" MB"
                }
                m_right_text_color: {
                    if(!_ohdSystemAir.is_alive)return "white"
                    return (_ohdSystemAir.curr_space_left_mb < 500) ? "red" : "green"
                }
            }
            SimpleLeftRightText{
                m_left_text: qsTr("AIR RECORD:");
                m_right_text: {
                    if(!_ohdSystemAir.is_alive)return "N/A";
                    return _cameraStreamModelPrimary.camera_recording_mode_to_string(m_camera_stream_model.air_recording_active);
                }
            }
            // For camera 1
            Item{
                width: parent.width
                height: 50
                //color:"green"
                GridLayout{
                    width: parent.width
                    height: parent.height
                    rows: 1
                    columns: 3
                    Button{
                        text: "OFF"
                        onClicked: {
                            try_set_recording_mode(0)
                        }
                        highlighted: m_camera_recording_mode==0
                    }
                    Button{
                        text: "ON"
                        onClicked: {
                            try_set_recording_mode(1)
                        }
                        highlighted: m_camera_recording_mode==1
                    }
                    Button{
                        text: "AUTO"
                        onClicked: {
                            try_set_recording_mode(2)
                        }
                        highlighted: m_camera_recording_mode==2
                    }
                }
            }
            Item {
                width: parent.width
                height: 32
                visible: !m_is_for_primary_camera
                Button{
                    text: "Switch primary & secondary"
                    onClicked: settings.qopenhd_switch_primary_secondary = !settings.qopenhd_switch_primary_secondary
                    highlighted: settings.qopenhd_switch_primary_secondary == true
                }
            }
        }
    }

    Item {
        id: widgetInner

        anchors.fill: parent
        opacity: bw_current_opacity
        scale: bw_current_scale

        Text {
            id: camera_icon
            y: 0
            width: 24
            height: 48
            text: "\uf03d"
            anchors.left: parent.left
            anchors.leftMargin: -2
            verticalAlignment: Text.AlignVCenter
            font.family: "Font Awesome 5 Free"
            font.pixelSize: 18
            horizontalAlignment: Text.AlignRight
            style: Text.Outline
            styleColor: settings.color_glow
        }

        Text {
            id: kbitrate
            y: 0
            width: 84
            height: 32
            color: bitrate_color(m_camera_stream_model.curr_set_and_measured_bitrate_mismatch)
            text: m_camera_stream_model.curr_received_bitrate_with_fec
            anchors.verticalCenterOffset: 0
            anchors.left: camera_icon.right
            anchors.leftMargin: 6
            anchors.verticalCenter: parent.verticalCenter
            verticalAlignment: Text.AlignVCenter
            elide: Text.ElideNone
            wrapMode: Text.NoWrap
            clip: false
            horizontalAlignment: Text.AlignLeft
            font.pixelSize: 14
            font.family: settings.font_text
            style: Text.Outline
            styleColor: settings.color_glow
        }

        Rectangle{
            width: 12
            height: width
            radius: width
            color: "red";
            anchors.right: camera_icon.left
            anchors.rightMargin: 2
            anchors.verticalCenter: parent.verticalCenter
            visible: settings.camera_bitrate_widget_show_recording && m_camera_is_currently_recording
        }

    }
}
