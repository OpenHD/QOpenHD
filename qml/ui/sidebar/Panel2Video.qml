import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.12

import QtQuick.Shapes 1.0
import QtQuick.Controls.Material 2.0

import Qt.labs.settings 1.0

import OpenHD 1.0

import "../elements"

SideBarBasePanel{
    id: videoPanel
    override_title: "Video"
    property int cameraParamUpdates: _airCameraSettingsModel.update_count
    property bool hasReadoutModes: cameraParamUpdates >= 0 &&
                                  _airCameraSettingsModel.param_int_exists("RK_CAM_MODE")

    property bool hasArducamHdr: cameraParamUpdates >= 0 &&
                                _airCameraSettingsModel.param_int_exists("ARDUCAM_HDR")

    function takeover_control(){
        if (hasReadoutModes) readout_mode.takeover_control();
        else if (hasArducamHdr) arducam_hdr.takeover_control();
        else edit_resolution_element.takeover_control();
    }

    Column {
        anchors.top: parent.top
        anchors.topMargin: 0
        spacing: 5

        MavlinkChoiceElement2 {
            id: readout_mode
            visible: videoPanel.hasReadoutModes
            m_title: "Sensor mode"
            m_param_id: "RK_CAM_MODE"
            m_settings_model: _airCameraSettingsModel
            onGoto_previous: sidebar.regain_control_on_sidebar_stack()
            onGoto_next: edit_resolution_element.takeover_control()
        }
        Label {
            visible: videoPanel.hasReadoutModes
            width: secondaryUiWidth - 12
            leftPadding: 6
            wrapMode: Text.WordWrap
            color: "white"
            font.pixelSize: 12
            text: videoPanel.cameraParamUpdates >= 0 && _airCameraSettingsModel.param_int_exists("RK_FPS_LOCK") &&
                  _airCameraSettingsModel.get_cached_int("RK_FPS_LOCK") === 1 ?
                  qsTr("Exposure is limited by FPS. Lower FPS allows a brighter image.") :
                  qsTr("Sensor mode options supplied by the air unit.")
        }
        MavlinkChoiceElement2 {
            id: arducam_hdr
            visible: videoPanel.hasArducamHdr
            m_title: qsTr("Arducam HDR")
            m_param_id: "ARDUCAM_HDR"
            m_settings_model: _airCameraSettingsModel
            onGoto_previous: sidebar.regain_control_on_sidebar_stack()
            onGoto_next: edit_resolution_element.takeover_control()
        }
        Label {
            visible: videoPanel.hasArducamHdr
            width: secondaryUiWidth - 12
            leftPadding: 6
            wrapMode: Text.WordWrap
            color: "white"
            font.pixelSize: 12
            text: qsTr("HDR uses three exposures, the full field of view and 30 fps. Manual exposure; experimental ISP tuning.")
        }
        MavlinkChoiceElement2{
            id: edit_resolution_element
            m_title: "Resolution/\nframerate"
            m_param_id: "RESOLUTION_FPS"
            m_settings_model: _airCameraSettingsModel
            override_takes_string_param: true;
            onGoto_previous: {
                if (videoPanel.hasReadoutModes) readout_mode.takeover_control();
                else if (videoPanel.hasArducamHdr) arducam_hdr.takeover_control();
                else sidebar.regain_control_on_sidebar_stack()
            }
            onGoto_next: {
               //sidebar.regain_control_on_sidebar_stack()
                rotation_flip.takeover_control();
            }
        }
        MavlinkChoiceElement2{
            id: rotation_flip
            m_title: "Rotation"
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

