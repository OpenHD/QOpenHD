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
    override_title: "Camera"

    function takeover_control(){
        brightness.takeover_control();
    }

    Column {
        anchors.top: parent.top
        anchors.topMargin: secondaryUiHeight/8
        spacing: 5
        MavlinkChoiceElement{
            id: brightness
            m_title: "BRIGHTNESS"
            m_param_id: "BRIGHTNESS"
            m_settings_model: _airCameraSettingsModel
            onGoto_previous: {
                sidebar.regain_control_on_sidebar_stack()
            }
            onGoto_next: {
                saturation.takeover_control();
            }
        }
        MavlinkChoiceElement{
            id: saturation
            m_title: "SATURATION"
            m_param_id: "SATURATION"
            m_settings_model: _airCameraSettingsModel
            onGoto_previous: {
               brightness.takeover_control();
            }
            onGoto_next: {
                contrast.takeover_control();
            }
        }
        MavlinkChoiceElement{
            id: contrast
            m_title: "CONTRAST"
            m_param_id: "CONTRAST"
            m_settings_model: _airCameraSettingsModel
            onGoto_previous: {
               saturation.takeover_control();
            }
            onGoto_next: {
                sharpness.takeover_control();
            }
        }
        MavlinkChoiceElement{
            id: sharpness
            m_title: "SHARPNESS"
            m_param_id: "SHARPNESS"
            m_settings_model: _airCameraSettingsModel
            onGoto_previous: {
               contrast.takeover_control();
            }
            onGoto_next: {
                sidebar.regain_control_on_sidebar_stack()
            }
        }
    }
}
