import QtQuick 2.12
import QtQuick.Controls 2.12
import QtQuick.Layouts 1.12
import QtGraphicalEffects 1.12
import QtQuick.Shapes 1.0

import Qt.labs.settings 1.0

import OpenHD 1.0

import "../elements"

BaseWidget {
    width: 140*settings.recordTextSize/14
    height: 48

    visible: settings.show_record_widget

    widgetIdentifier: "record_video_widget"

    defaultAlignment: 0
    defaultXOffset: 200
    defaultYOffset: 2
    defaultHCenter: false
    defaultVCenter: false

    hasWidgetDetail: true
    hasWidgetAction: true
    widgetActionWidth: 220
    widgetActionHeight: (settings.dev_qopenhd_n_cameras > 1) ? 95 : 60
    widgetDetailWidth:275
    widgetDetailHeight:150

    widgetDetailComponent: ScrollView {

        contentHeight: missionSettingsColumn.height
        ScrollBar.horizontal.policy: ScrollBar.AlwaysOff
        clip: true
        Column {
            id: missionSettingsColumn
            Item {
                width: parent.width
                height: 42
                Text {
                    id: missionSettingsTitle
                    text: qsTr("Record")
                    color: "white"
                    height: parent.height - 10
                    width: parent.width
                    font.bold: true
                    horizontalAlignment: Text.AlignHCenter
                    font.pixelSize: detailPanelFontPixels
                    verticalAlignment: Text.AlignVCenter
                }
                Rectangle {
                    id: missionSettingsTitleUL
                    y: 34
                    width: parent.width
                    height: 3
                    color: "white"
                    radius: 5
                }
            }

            Item {
                width: parent.width
                height: 32
                Text {
                    text: qsTr("Size")
                    color: "white"
                    height: parent.height
                    font.bold: true
                    font.pixelSize: detailPanelFontPixels
                    anchors.left: parent.left
                    verticalAlignment: Text.AlignVCenter
                }
                Slider {
                    id: record_size_Slider
                    orientation: Qt.Horizontal
                    from: 14
                    value: settings.recordTextSize
                    to: 22
                    stepSize: 1
                    height: parent.height
                    anchors.rightMargin: 0
                    anchors.right: parent.right
                    width: parent.width - 96

                    onValueChanged: {
                        settings.recordTextSize = record_size_Slider.value
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

        Item {
            id:vars
            property bool ret: false
            property bool rec1: false
            property bool rec2: false
            property bool ret1: false
            property bool ret2: false

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
                            vars.rec1=true
                            vars.ret=false
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
                            vars.rec1=false
                            vars.ret=false
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
                            vars.rec2=true
                            vars.ret=false
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
                            vars.rec2=false
                            vars.ret=false
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
                    color: (vars.rec1 == true) ? "green" : "red"
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
                    color: (vars.rec2 == true) ? "green" : "red"
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
                    if (vars.rec1 ==true || vars.rec2 ==true ) {
                        if (_ohdSystemAir.curr_space_left_mb < 500 && _ohdSystemAir.curr_space_left_mb > 200 && _ohdSystemAir.curr_space_left_mb % 10 == 0) {
                            _hudLogMessagesModel.signalAddLogMessage(4,"SD-Card getting full.")
                            }
                        if (_ohdSystemAir.curr_space_left_mb < 200) {
                            _hudLogMessagesModel.signalAddLogMessage(4,"SD-Card getting full.")
                            if (vars.rec1 ==true ) {
                            vars.ret1 = _airCameraSettingsModel.try_update_parameter_int("V_AIR_RECORDING", 0)
                            _hudLogMessagesModel.signalAddLogMessage(0,"stopping recording 1")
                                if (vars.ret1 == true) {
                                record_status_cam1.color = "red"
                                }
                            }
                            if (vars.rec2 ==true) {
                             vars.ret2 = _airCameraSettingsModel.try_update_parameter_int("V_AIR_RECORDING", 0)
                             _hudLogMessagesModel.signalAddLogMessage(0,"stopping recording 2")
                                if (vars.ret2 == true) {
                                record_status_cam2.color = "red"
                                }
                            }

                    }    }
                }
    }       }

}
