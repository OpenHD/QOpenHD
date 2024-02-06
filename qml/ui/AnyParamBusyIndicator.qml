
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


    BusyIndicator{
        id: any_param_busy_indiscator
        width: 96
        height: 96
        anchors.centerIn: parent
        running: _airCameraSettingsModel.ui_is_busy || _airCameraSettingsModel2.ui_is_busy || _ohdSystemAirSettingsModel.ui_is_busy || _ohdSystemGroundSettings.ui_is_busy ||
                 _qopenhd.is_busy
        //visible: _xParamUI.is_busy
    }
    Text{
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.top: any_param_busy_indiscator.bottom
        text: {
            if(_qopenhd.is_busy){
                return _qopenhd.busy_reason;
            }
            return "FETCHING PARAMETERS.."
        }
        visible: any_param_busy_indiscator.running
        font.pixelSize: 15
        font.family: settings.font_text
        style: Text.Outline
        styleColor: settings.color_glow
    }
}


