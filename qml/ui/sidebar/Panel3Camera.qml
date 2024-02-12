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
    id: cameraUI
    override_title: "Camera"
    Column {
        anchors.top: parent.top
        anchors.topMargin: secondaryUiHeight/8
        spacing: 5
        MavlinkIntChoiceElement{
            m_title: "BRIGHTNESS"
            m_param_id: "BRIGHTNESS"
            m_settings_model: _airCameraSettingsModel
        }
        MavlinkIntChoiceElement{
            m_title: "SATURATION"
            m_param_id: "SATURATION"
            m_settings_model: _airCameraSettingsModel
        }
        MavlinkIntChoiceElement{
            m_title: "CONTRAST"
            m_param_id: "CONTRAST"
            m_settings_model: _airCameraSettingsModel
        }
        MavlinkIntChoiceElement{
            m_title: "SHARPNESS"
            m_param_id: "SHARPNESS"
            m_settings_model: _airCameraSettingsModel
        }
    }
}
