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
    widgetActionWidth: 200
    widgetActionHeight: 170

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
                        }
                        console.log(vars.rec)
                    }
                }
            }
            ConfirmSlider {

                visible: true
                text_off: qsTr("Stop Rec CAM1")
                onCheckedChanged: {
                    if (checked == true) {
                        vars.ret=_airCameraSettingsModel.try_update_parameter_int("V_AIR_RECORDING",0)
                        if (vars.ret==true){
                            vars.rec=false
                            vars.ret=false
                            record_status_cam1.text="CAM1"
                            record_status_cam1.color="red"
                        }
                        console.log(vars.rec)
                    }
                }
            }
            ConfirmSlider {

                visible: true
                text_off: qsTr("Record CAM2")
                onCheckedChanged: {
                    if (checked == true) {
                        vars.ret=_airCameraSettingsModel2.try_update_parameter_int("V_AIR_RECORDING",1)
                        if (vars.ret==true){
                            vars.rec=true
                            vars.ret=false
                            record_status_cam2.text="CAM2"
                            record_status_cam2.color="green"
                        }
                        console.log(vars.rec)
                    }
                }
            }
            ConfirmSlider {

                visible: true
                text_off: qsTr("Stop Rec CAM2")
                onCheckedChanged: {
                    if (checked == true) {
                        vars.ret=_airCameraSettingsModel2.try_update_parameter_int("V_AIR_RECORDING",0)
                        if (vars.ret==true){
                            vars.rec=false
                            vars.ret=false
                            record_status_cam2.text="CAM2"
                            record_status_cam2.color="red"
                        }
                        console.log(vars.rec)
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
                    visible: true
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
                    color: "green"
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
