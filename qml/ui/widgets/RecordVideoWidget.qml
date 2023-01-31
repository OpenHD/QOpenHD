import QtQuick 2.12
import QtQuick.Controls 2.12
import QtQuick.Layouts 1.12
import QtGraphicalEffects 1.12
import QtQuick.Shapes 1.0

import Qt.labs.settings 1.0

import OpenHD 1.0

import "../elements"

BaseWidget {
    width: 256
    height: 48

    visible: settings.show_record_widget

    widgetIdentifier: "record_video_widget"

    defaultAlignment: 0
    defaultXOffset: 200
    defaultYOffset: 2
    defaultHCenter: false
    defaultVCenter: false

    hasWidgetDetail: false
    hasWidgetAction: true
    widgetActionWidth: 220
    widgetActionHeight: (settings.dev_qopenhd_n_cameras > 1) ? 95 : 60

   widgetActionComponent: ScrollView{

        ScrollBar.horizontal.policy: ScrollBar.AlwaysOff
        clip: true

        Item {
            id:vars
            property bool rec: false
            property bool ret: false
        }

        ColumnLayout{
            id:recID
            width: 400
            ConfirmSlider {
                id:cam1rec
                visible: true
                text_off: qsTr("Record CAM1")
                onCheckedChanged: {
                    if (checked == true) {
                        vars.ret=_airCameraSettingsModel.try_update_parameter_int("V_AIR_RECORDING",1)
                        if (vars.ret==true){
                            vars.rec=true
                            vars.ret=false
                            record_status_cam1.text="CAM1"
                            record_status_cam1.color="green"
                            _hudLogMessagesModel.signalAddLogMessage(6,"recording cam1 started")
                            cam1stop.visible= true
                            cam1rec.visible= false
                        }
                        else {
                            _hudLogMessagesModel.signalAddLogMessage(4,"couldn't start cam1 recording")
                        }
                    }
                }
            }
            ConfirmSlider {
                id:cam1stop
                visible: false
                text_off: qsTr("Stop Rec CAM1")
                onCheckedChanged: {
                    if (checked == true) {
                        vars.ret=_airCameraSettingsModel.try_update_parameter_int("V_AIR_RECORDING",0)
                        if (vars.ret==true){
                            vars.rec=false
                            vars.ret=false
                            record_status_cam1.text="CAM1"
                            record_status_cam1.color="red"
                            _hudLogMessagesModel.signalAddLogMessage(6,"recording cam1 stopped")
                            cam1stop.visible= false
                            cam1rec.visible= true
                        }
                        else {
                            _hudLogMessagesModel.signalAddLogMessage(4,"couldn't stop cam1 recording")
                        }
                    }
                }
            }
            ConfirmSlider {
                id:cam2rec
                visible: settings.dev_qopenhd_n_cameras > 1
                text_off: qsTr("Record CAM2")
                onCheckedChanged: {
                    if (checked == true) {
                        vars.ret=_airCameraSettingsModel2.try_update_parameter_int("V_AIR_RECORDING",1)
                        if (vars.ret==true){
                            vars.rec=true
                            vars.ret=false
                            record_status_cam2.text="CAM2"
                            record_status_cam2.color="green"
                            _hudLogMessagesModel.signalAddLogMessage(6,"recording cam2 started")
                            cam2stop.visible= true
                            cam2rec.visible= false
                        }
                        else {
                            _hudLogMessagesModel.signalAddLogMessage(4,"couldn't start cam2 recording")
                        }
                    }
                }
            }
            ConfirmSlider {
                id:cam2stop
                visible: settings.dev_qopenhd_n_cameras > 1
                text_off: qsTr("Stop Rec CAM2")
                onCheckedChanged: {
                    if (checked == true) {
                        vars.ret=_airCameraSettingsModel2.try_update_parameter_int("V_AIR_RECORDING",0)
                        if (vars.ret==true){
                            vars.rec=false
                            vars.ret=false
                            record_status_cam2.text="CAM2"
                            record_status_cam2.color="red"
                            _hudLogMessagesModel.signalAddLogMessage(6,"recording cam2 stopped")
                            cam2stop.visible= false
                            cam2rec.visible= true
                        }
                        else {
                            _hudLogMessagesModel.signalAddLogMessage(4,"couldn't stop recording cam2")
                        }
                    }
                }
            }


           }
    }


    Item {
        id: widgetInner
        anchors.fill: parent
                Text {
                    text: qsTr("Record Video");
                    color: settings.color_text
                    anchors.fill: parent
                    verticalAlignment: Text.AlignVCenter
                    elide: Text.ElideNone
                    wrapMode: Text.NoWrap
                    horizontalAlignment: Text.AlignLeft
                    font.pixelSize: 14
                    font.family: settings.font_text
                    style: Text.Outline
                    styleColor: settings.color_glow
                    visible: true
                }
                Text {
                    id:record_status_cam1
                    text: "CAM1"
                    color: "red"
                    anchors.fill: parent
                    anchors.leftMargin: 95
                    verticalAlignment: Text.AlignVCenter
                    elide: Text.ElideNone
                    wrapMode: Text.NoWrap
                    font.pixelSize: 14
                    font.family: settings.font_text
                    style: Text.Outline
                    styleColor: settings.color_glow
                    visible: true
                }
                Text {
                    id:record_status_cam2
                    text: "CAM2"
                    color: "red"
                    anchors.fill: parent
                    anchors.leftMargin: 140
                    verticalAlignment: Text.AlignVCenter
                    elide: Text.ElideNone
                    wrapMode: Text.NoWrap
                    font.pixelSize: 14
                    font.family: settings.font_text
                    style: Text.Outline
                    styleColor: settings.color_glow
                    visible: settings.dev_qopenhd_n_cameras > 1
                }
                Text {
                    text: qsTr("Free Space");
                    color: settings.color_text
                    anchors.topMargin: 30
                    anchors.leftMargin: 90
                    verticalAlignment: Text.AlignVCenter
                    elide: Text.ElideNone
                    wrapMode: Text.NoWrap
                    font.pixelSize: 14
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
                    anchors.leftMargin: 95
                    anchors.topMargin: -30
                    verticalAlignment: Text.AlignVCenter
                    elide: Text.ElideNone
                    wrapMode: Text.NoWrap
                    font.pixelSize: 14
                    font.family: settings.font_text
                    style: Text.Outline
                    styleColor: settings.color_glow
                    visible: true
                }
    }

}
