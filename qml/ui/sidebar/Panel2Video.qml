import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.12

import QtQuick.Shapes 1.0
import QtQuick.Controls.Material 2.0

import Qt.labs.settings 1.0

import OpenHD 1.0

import "../elements"

SideBarBasePanel{
    override_title: "Video"

    function takeover_control(){
        edit_resolution_element.takeover_control();
    }

    Column {
        anchors.top: parent.top
        anchors.topMargin: secondaryUiHeight/8
        spacing: 5

        MavlinkChoiceElement2{
            id: edit_resolution_element
            m_title: "Resolution"
            m_param_id: "RESOLUTION_FPS"
            m_settings_model: _airCameraSettingsModel
            override_takes_string_param: true;
            onGoto_previous: {
                sidebar.regain_control_on_sidebar_stack()
            }
            onGoto_next: {
               //sidebar.regain_control_on_sidebar_stack()
                rotation_flip.takeover_control();
            }
        }
        MavlinkChoiceElement2{
            id: rotation_flip
            m_title: "ROTATION/FLIP"
            m_param_id: "ROTATION_FLIP"
            m_settings_model: _airCameraSettingsModel
            onGoto_previous: {
               edit_resolution_element.takeover_control();
            }
            onGoto_next: {
                sidebar.regain_control_on_sidebar_stack()
            }
        }
    }
}

