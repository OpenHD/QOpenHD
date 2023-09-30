import QtQuick 2.12
import QtQuick.Controls 2.12
import QtQuick.Layouts 1.12
import QtGraphicalEffects 1.12
import QtQuick.Shapes 1.0

import Qt.labs.settings 1.0

import OpenHD 1.0

import "../elements"

BaseWidget {
    //    width: 140*settings.recordTextSize/14
    //    height: 48

    function get_width(){
        if(settings.show_minimal_record_widget){
            if(settings.dev_qopenhd_n_cameras>1){
                return 35*2;
            }
            return 35;
        }
        return 150;
    }
    function get_height(){
        if(settings.show_minimal_record_widget){
            return 25;
        }
        return 48;
    }

    width:      get_width()
    height:     get_height()
    visible:    settings.show_record_widget

    widgetIdentifier: "record_video_widget"
    bw_verbose_name: "AIR RECORDING"

    defaultAlignment: 0
    defaultXOffset: 200
    defaultYOffset: 2
    defaultHCenter: false
    defaultVCenter: false

    hasWidgetDetail: true
    hasWidgetAction: true
    widgetActionWidth: 250
    widgetActionHeight: (settings.dev_qopenhd_n_cameras > 1) ? 230 : 130
    widgetDetailWidth:275
    widgetDetailHeight:175

    // Set to true if the camera is currently doing recordng (the UI element(s) turn red in this case)
    property bool m_camera1_is_currently_recording: _cameraStreamModelPrimary.air_recording_active
    property bool m_camera2_is_currently_recording: _cameraStreamModelSecondary.air_recording_active

    // THIS IS A MAVLINK PARAM, SYNCHRONIZATION THEREFORE IS HARD AND HERE NOT WORTH IT
    property int m_camera1_recording_mode: -1
    property int m_camera2_recording_mode: -1

    function set_recording_mode_for_camera(cam_idx,mode){
        if(cam_idx===1){
            m_camera1_recording_mode=mode
        }else{
            m_camera2_recording_mode=mode
        }
    }

    function try_set_recording_mode(camera_idx,mode){
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
                set_recording_mode_for_camera(camera_idx,0)
            }else{
                 _hudLogMessagesModel.signalAddLogMessage(6,"update "+camString+" failed")
            }
        }
        if(mode===1){ //mode on
            var result=camModel.try_update_parameter_int("V_AIR_RECORDING",1)===""
            if(result){
                _hudLogMessagesModel.signalAddLogMessage(6,"recording "+camString+" enabled")
                set_recording_mode_for_camera(camera_idx,1)
            }else{
                 _hudLogMessagesModel.signalAddLogMessage(6,"update "+camString+" failed")
            }
        }
        if(mode==2){ //mode auto
            var result=camModel.try_update_parameter_int("V_AIR_RECORDING",2)===""
            if(result){
                _hudLogMessagesModel.signalAddLogMessage(6,"recording "+camString+" auto enabled")
                set_recording_mode_for_camera(camera_idx,2)
            }else{
                 _hudLogMessagesModel.signalAddLogMessage(6,"update "+camString+" failed")
            }
        }
    }

    widgetDetailComponent: ScrollView {

        contentHeight: idBaseWidgetDefaultUiControlElements.height
        ScrollBar.horizontal.policy: ScrollBar.AlwaysOff
        clip: true

        BaseWidgetDefaultUiControlElements{
            id: idBaseWidgetDefaultUiControlElements

            Item {
                width: parent.width
                height: 32
                Text {
                    text: qsTr("Minimal Layout")
                    color: "white"
                    height: parent.height
                    font.bold: true
                    font.pixelSize: detailPanelFontPixels
                    anchors.left: parent.left
                    verticalAlignment: Text.AlignVCenter
                }
                Switch {
                    height: parent.height
                    anchors.rightMargin: 0
                    anchors.right: parent.right
                    width: parent.width - 96
                    checked: settings.show_minimal_record_widget
                    onCheckedChanged:{
                        if (checked) {
                            settings.show_minimal_record_widget = true
                        }
                        else{
                            settings.show_minimal_record_widget = false
                        }

                    }

                }

            }
            Item {
                //dummy for layout
                width: 230
                height: 32
            }

        }
    }

    widgetActionComponent: Item{

        //color:"red"
        width: parent.width-30
        height: parent.height

        ColumnLayout{
            id:recID
            width: parent.width
            height: parent.height
            //
            Text {
                visible:true
                id:airVideoSpaceLeft_minimal
                text: "Free: "+_ohdSystemAir.curr_space_left_mb+" MB"
                color: (_ohdSystemAir.curr_space_left_mb < 500) ? "red" : "green"
                elide: Text.ElideNone
                wrapMode: Text.NoWrap
                font.pixelSize: settings.recordTextSize
                font.family: settings.font_text
                style: Text.Outline
                onTextChanged: {
                    if (m_camera1_is_currently_recording || m_camera2_is_currently_recording ==true ) {
                        if (_ohdSystemAir.curr_space_left_mb < 500 && _ohdSystemAir.curr_space_left_mb > 200 && _ohdSystemAir.curr_space_left_mb % 10 == 0) {
                            _hudLogMessagesModel.signalAddLogMessage(4,"SD-Card getting full.")
                        }
                    }
                }
            }
            Text {
                text: qsTr("(Air) Record Camera 1");
                color: settings.color_text
                elide: Text.ElideNone
                wrapMode: Text.NoWrap
                horizontalAlignment: Text.AlignLeft
                font.pixelSize: settings.recordTextSize
                font.family: settings.font_text
                style: Text.Outline
                styleColor: settings.color_glow
                visible: true
            }
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
                            try_set_recording_mode(1,0)
                        }
                        highlighted: m_camera1_recording_mode==0
                    }
                    Button{
                        text: "ON"
                        onClicked: {
                            try_set_recording_mode(1,1)
                        }
                        highlighted: m_camera1_recording_mode==1
                    }
                    Button{
                        text: "AUTO"
                        onClicked: {
                            try_set_recording_mode(1,2)
                        }
                        highlighted: m_camera1_recording_mode==2
                    }
                }
            }
            Text {
                text: qsTr("(Air) Record Camera 2");
                color: settings.color_text
                elide: Text.ElideNone
                wrapMode: Text.NoWrap
                horizontalAlignment: Text.AlignLeft
                font.pixelSize: settings.recordTextSize
                font.family: settings.font_text
                style: Text.Outline
                styleColor: settings.color_glow
                visible: settings.dev_qopenhd_n_cameras > 1
            }
            Item{
                width: parent.width
                height: 50
                //color:"green"
                visible: settings.dev_qopenhd_n_cameras > 1
                GridLayout{
                    width: parent.width
                    height: parent.height
                    rows: 1
                    columns: 3
                    Button{
                        text: "OFF"
                        onClicked: {
                            try_set_recording_mode(2,0)
                        }
                        highlighted: m_camera2_recording_mode==0
                    }
                    Button{
                        text: "ON"
                        onClicked: {
                            try_set_recording_mode(2,1)
                        }
                        highlighted: m_camera2_recording_mode==1
                    }
                    Button{
                        text: "AUTO"
                        onClicked: {
                            try_set_recording_mode(2,2)
                        }
                        highlighted: m_camera2_recording_mode==2
                    }
                }
            }
        }
    }


    Item {
        id: recordWidgetBig
        visible: !settings.show_minimal_record_widget
        anchors.fill: parent
        Text {
            text: qsTr("Record Video");
            color: settings.color_text
            anchors.fill: parent
            anchors.topMargin: 5*settings.recordTextSize/12
            verticalAlignment: Text.AlignVCenter
            elide: Text.ElideNone
            wrapMode: Text.NoWrap
            horizontalAlignment: Text.AlignLeft
            font.pixelSize: settings.recordTextSize
            font.family: settings.font_text
            style: Text.Outline
            styleColor: settings.color_glow
            visible: true
        }
        Text {
            id:record_status_cam1
            text: "CAM1"
            color: (m_camera1_is_currently_recording == true) ? "green" : "red"
            anchors.fill: parent
            anchors.leftMargin: 95*settings.recordTextSize/14
            anchors.topMargin: 5*settings.recordTextSize/12
            verticalAlignment: Text.AlignVCenter
            elide: Text.ElideNone
            wrapMode: Text.NoWrap
            font.pixelSize: settings.recordTextSize
            font.family: settings.font_text
            style: Text.Outline
            styleColor: settings.color_glow
            visible: true
        }
        Text {
            id:record_status_cam2
            text: "CAM2"
            color: (m_camera2_is_currently_recording == true) ? "green" : "red"
            anchors.fill: parent
            anchors.leftMargin: 140*settings.recordTextSize/14
            anchors.topMargin: 5*settings.recordTextSize/12
            verticalAlignment: Text.AlignVCenter
            elide: Text.ElideNone
            wrapMode: Text.NoWrap
            font.pixelSize: settings.recordTextSize
            font.family: settings.font_text
            style: Text.Outline
            styleColor: settings.color_glow
            visible: settings.dev_qopenhd_n_cameras > 1
        }
        Text {
            text: qsTr("Free Space");
            color: settings.color_text
            anchors.leftMargin: 90
            elide: Text.ElideNone
            wrapMode: Text.NoWrap
            font.pixelSize: settings.recordTextSize
            font.family: settings.font_text
            style: Text.Outline
            styleColor: settings.color_glow
            visible: true
        }
        Text {
            id:airVideoSpaceLeft
            text: _ohdSystemAir.curr_space_left_mb+" MB"
            color: (_ohdSystemAir.curr_space_left_mb < 500) ? "red" : "green"
            anchors.fill: parent
            anchors.leftMargin: 95*settings.recordTextSize/14
            anchors.topMargin: -30
            verticalAlignment: Text.AlignVCenter
            elide: Text.ElideNone
            wrapMode: Text.NoWrap
            font.pixelSize: settings.recordTextSize
            font.family: settings.font_text
            style: Text.Outline
            styleColor: settings.color_glow
            visible: true
            onTextChanged: {
                if (m_camera1_is_currently_recording ==true || m_camera2_is_currently_recording ==true ) {
                    if (_ohdSystemAir.curr_space_left_mb < 500 && _ohdSystemAir.curr_space_left_mb > 200 && _ohdSystemAir.curr_space_left_mb % 10 == 0) {
                        _hudLogMessagesModel.signalAddLogMessage(4,"SD-Card getting full.")
                    }
                }
            }
        }       }
    Item {
        id: recordWidgetMinimal
        visible: settings.show_minimal_record_widget
        anchors.fill: parent
        Text {
            id:record_status_cam1_min
            text: "\uf03d"
            font.family: "Font Awesome 5 Free"
            color: (m_camera1_is_currently_recording == true) ? "red" : "white"
            anchors.fill: parent
            anchors.leftMargin: 5*settings.recordTextSize/14
            anchors.topMargin: 5*settings.recordTextSize/12
            verticalAlignment: Text.AlignVCenter
            elide: Text.ElideNone
            wrapMode: Text.NoWrap
            font.pixelSize: settings.recordTextSize*1.5
            style: Text.Outline
            styleColor: settings.color_glow
            visible: true
        }
        Text {
            id:record_status_cam2_min
            text: "  \uf03d"
            font.family: "Font Awesome 5 Free"
            color: (m_camera2_is_currently_recording == true) ? "red" : "white"
            anchors.fill: parent
            anchors.leftMargin: 25*settings.recordTextSize/14
            anchors.topMargin: 5*settings.recordTextSize/12
            verticalAlignment: Text.AlignVCenter
            elide: Text.ElideNone
            wrapMode: Text.NoWrap
            font.pixelSize: settings.recordTextSize*1.5
            style: Text.Outline
            styleColor: settings.color_glow
            visible: settings.dev_qopenhd_n_cameras > 1
        }
        Text {
            id:airVideoSpaceLeft_min
            text: _ohdSystemAir.curr_space_left_mb+" MB"
            color: (_ohdSystemAir.curr_space_left_mb < 500) ? "red" : "green"
            anchors.fill: parent
            anchors.leftMargin: 95*settings.recordTextSize/14
            anchors.topMargin: -30
            verticalAlignment: Text.AlignVCenter
            elide: Text.ElideNone
            wrapMode: Text.NoWrap
            font.pixelSize: settings.recordTextSize
            font.family: settings.font_text
            style: Text.Outline
            styleColor: settings.color_glow
            visible: !settings.show_minimal_record_widget
            onTextChanged: {
                if (m_camera1_is_currently_recording ==true || m_camera2_is_currently_recording ==true ) {
                    if (_ohdSystemAir.curr_space_left_mb < 500 && _ohdSystemAir.curr_space_left_mb > 200 && _ohdSystemAir.curr_space_left_mb % 10 == 0) {
                        _hudLogMessagesModel.signalAddLogMessage(4,"SD-Card getting full.")
                    }
                }
            }
        }
    }
}
