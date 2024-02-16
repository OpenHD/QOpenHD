
import QtQuick 2.12
import QtQuick.Controls 2.12
import QtQuick.Controls.Styles 1.4
import QtQuick.Controls.Material 2.12
import QtQuick.Layouts 1.0
import QtGraphicalEffects 1.12
import Qt.labs.settings 1.0

import OpenHD 1.0

Item{
    width: parent.width
    height: parent.height
    property int busy_indicator_size: 120;
    property int text_font_pixel_size: 18

    // This indicates a busy param
    BusyIndicator{
        id: any_param_busy_indiscator
        width: busy_indicator_size
        height: busy_indicator_size
        anchors.centerIn: parent
        running: _airCameraSettingsModel.ui_is_busy || _airCameraSettingsModel2.ui_is_busy || _ohdSystemAirSettingsModel.ui_is_busy || _ohdSystemGroundSettings.ui_is_busy ||
                 _qopenhd.is_busy
        //visible: _xParamUI.is_busy
    }
    Text{
        id: busy_description
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.top: any_param_busy_indiscator.bottom
        text: {
            if(_qopenhd.is_busy){
                return _qopenhd.busy_reason;
            }
            var busy_param="ERROR"
            if(_airCameraSettingsModel.ui_is_busy){
                busy_param="CAM1";
            }else if(_airCameraSettingsModel2.ui_is_busy){
                busy_param="CAM2";
            }else if(_ohdSystemAirSettingsModel.ui_is_busy){
               busy_param="AIR";
            }else if(_ohdSystemGroundSettings.ui_is_busy){
                busy_param="GND";
            }
            return busy_param+" PARAM BUSY ...";
        }
        visible: any_param_busy_indiscator.running
        font.pixelSize: text_font_pixel_size
        //font.family: settings.font_text
        //style: Text.Outline
        //styleColor: "green"//settings.color_glow
        color: "green"
        smooth: true
    }
    // This indicates a busy camera
    BusyIndicator{
        id: cam_busy_indicator
        width: busy_indicator_size
        height: busy_indicator_size
        anchors.centerIn: parent
        running: !any_param_busy_indiscator.running && (_cameraStreamModelPrimary.camera_status>0 && _cameraStreamModelPrimary.camera_status==2 && _ohdSystemAir.is_alive) && !settings_panel.visible
    }
    Text{
        id: cam_busy_description
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.top: cam_busy_indicator.bottom
        text: "Restarting Camera ..."
        visible: cam_busy_indicator.running
        font.pixelSize: text_font_pixel_size
        color: "green"
        smooth: true
    }
}


