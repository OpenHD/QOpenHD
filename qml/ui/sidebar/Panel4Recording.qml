import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.12
import QtGraphicalEffects 1.12
import QtQuick.Shapes 1.0
import QtQuick.Controls.Material 2.0

import Qt.labs.settings 1.0

import OpenHD 1.0

import "../elements"

SideBarBasePanel{
    id: recordingUI
    override_title: "Air recording"

    Column {
        anchors.top: parent.top
        anchors.topMargin: secondaryUiHeight/8
        spacing: 5

        MavlinkIntChoiceElement{
            m_title: "RECORDING MODE"
            m_param_id: "AIR_RECORDING_E"
            m_settings_model: _airCameraSettingsModel
        }
        Text{
            text: {
                var tmp="CAM1 AIR RECORDING:";
                if(!_ohdSystemAir.is_alive){
                    return tmp+" N/A";
                }
                return tmp+_cameraStreamModelPrimary.camera_recording_mode_to_string(_cameraStreamModelPrimary.air_recording_active)
            }
            font.pixelSize: 14
            font.family: "AvantGarde-Medium"
            color: "#ffffff"
            smooth: true
        }

    }

}
