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

    width:      settings.record_widget_width*settings.recordTextSize/12
    height:     settings.record_widget_height
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
    widgetActionWidth: 150
    widgetActionHeight: (settings.dev_qopenhd_n_cameras > 1) ? 200 : 115
    widgetDetailWidth:275
    widgetDetailHeight:175

    // Set to true if the camera is currently doing recordng (the UI element(s) turn red in this case)
    property bool m_camera1_is_currently_recording: false
    property bool m_camera2_is_currently_recording: false


    Item {
        id:vars
        property bool ret: false
        property bool rec1: false
        property bool rec2: false
        property bool ret1: false
        property bool ret2: false

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
                    onCheckedChanged:{
                        if (checked) {
                            settings.show_minimal_record_widget = true
                            settings.record_widget_height= 25
                            settings.record_widget_width= 35
                        }
                        else{
                            settings.show_minimal_record_widget = false
                            settings.record_widget_height= 48
                            settings.record_widget_width= 140
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

    widgetActionComponent: ScrollView{

        ScrollBar.horizontal.policy: ScrollBar.AlwaysOff
        clip: true


        ColumnLayout{
            id:recID
            width: 400
            Text {
                text: qsTr("Record Camera 1");
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
            Switch {
                id: switch_rec1
                width: 32
                height: 32
                checked: vars.rec1
                onToggled:{
                    if (checked) {
                        vars.ret=(_airCameraSettingsModel.try_update_parameter_int("V_AIR_RECORDING",1)==="")
                        if (vars.ret==true){
                            vars.rec1=true
                            vars.ret=false
                            _hudLogMessagesModel.signalAddLogMessage(6,"recording cam1 started")
                        }
                        else {
                            _hudLogMessagesModel.signalAddLogMessage(4,"couldn't start recording cam1")
                            switch_rec1.checked=false
                        }
                    }
                    else{
                        vars.ret=(_airCameraSettingsModel.try_update_parameter_int("V_AIR_RECORDING",0)==="")
                        if (vars.ret==true){
                            vars.rec1=false
                            vars.ret=false
                            _hudLogMessagesModel.signalAddLogMessage(6,"recording cam1 stopped")
                        }
                        else {
                            _hudLogMessagesModel.signalAddLogMessage(4,"couldn't stop recording cam1")
                            switch_rec1.checked=true
                        }
                    }
                }
            }
            Text {
                text: qsTr("Record Camera 2");
                color: settings.color_text
                elide: Text.ElideNone
                wrapMode: Text.NoWrap
                horizontalAlignment: Text.AlignLeft
                font.pixelSize: settings.recordTextSize
                font.family: settings.font_text
                style: Text.Outline
                styleColor: settings.color_glow
                visible: settings.dev_qopenhd_n_cameras > 1                            }
            Switch {
                id:switch_rec2
                width: 32
                height: 32
                visible: settings.dev_qopenhd_n_cameras > 1
                checked: vars.rec2
                onToggled:{
                    if (checked) {
                        vars.ret=(_airCameraSettingsModel2.try_update_parameter_int("V_AIR_RECORDING",1)==="")
                        if (vars.ret==true){
                            vars.rec2=true
                            vars.ret=false
                            _hudLogMessagesModel.signalAddLogMessage(6,"recording cam2 started")
                        }
                        else {
                            _hudLogMessagesModel.signalAddLogMessage(4,"couldn't start recording cam2")
                            switch_rec2.checked=false
                        }
                    }
                    else{
                        vars.ret=(_airCameraSettingsModel2.try_update_parameter_int("V_AIR_RECORDING",0)==="")
                        if (vars.ret==true){
                            vars.rec2=false
                            vars.ret=false
                            _hudLogMessagesModel.signalAddLogMessage(6,"recording cam2 stopped")
                        }
                        else {
                            _hudLogMessagesModel.signalAddLogMessage(4,"couldn't stop recording cam2")
                            switch_rec2.checked=true
                        }
                    }
                }

            }
            Text {
                visible:true
                id:airVideoSpaceLeft_minimal
                text: _ohdSystemAir.curr_space_left_mb+" MB"
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
        }       }

}
