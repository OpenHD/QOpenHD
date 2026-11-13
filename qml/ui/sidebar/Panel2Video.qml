/******************************************************************************
 * OpenHD
 *
 * Licensed under the GNU General Public License (GPL) Version 3.
 *
 * This software is provided "as-is," without warranty of any kind, express or
 * implied, including but not limited to the warranties of merchantability,
 * fitness for a particular purpose, and non-infringement. For details, see the
 * full license in the LICENSE file provided with this source code.
 *
 * Non-Military Use Only:
 * This software and its associated components are explicitly intended for
 * civilian and non-military purposes. Use in any military or defense
 * applications is strictly prohibited unless explicitly and individually
 * licensed otherwise by the OpenHD Team.
 *
 * Contributors:
 * A full list of contributors can be found at the OpenHD GitHub repository:
 * https://github.com/OpenHD
 *
 * © OpenHD, All Rights Reserved.
 ******************************************************************************/

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
    headerIcon: "\uf03d"
    property int cameraParamUpdates: _airCameraSettingsModel.update_count
    property bool hasReadoutModes: cameraParamUpdates >= 0 &&
                                  _airCameraSettingsModel.param_int_exists("RK_CAM_MODE")

    property bool hasArducamHdr: cameraParamUpdates >= 0 &&
                                _airCameraSettingsModel.param_int_exists("ARDUCAM_HDR")
    readonly property int airPlatform: _ohdSystemAir.ohd_platform_type
    readonly property bool hasStreamingFormat: cameraParamUpdates >= 0 &&
        !(airPlatform >= 10 && airPlatform <= 13) &&
        _airCameraSettingsModel.param_int_exists("VIDEO_CODEC") &&
        _airCameraSettingsModel.get_ui_metadata("VIDEO_CODEC").cameraSupported === true
    readonly property bool hasRotation: cameraParamUpdates >= 0 &&
        _airCameraSettingsModel.param_int_exists("ROTATION_DEG") &&
        _airCameraSettingsModel.get_ui_metadata("ROTATION_DEG").cameraSupported === true
    readonly property bool hasFlip: cameraParamUpdates >= 0 &&
        _airCameraSettingsModel.param_int_exists("ROTATION_FLIP")

    function focusAfterStreamSettings() {
        if (hasRotation) rotation_degree.takeover_control()
        else if (hasFlip) rotation_flip.takeover_control()
        else sidebar.regain_control_on_sidebar_stack()
    }

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
            color: sidebar.textColor("white")
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
            onGoto_next: camera_controls.takeover_control()
        }
        Label {
            visible: videoPanel.hasArducamHdr
            width: secondaryUiWidth - 12
            leftPadding: 6
            wrapMode: Text.WordWrap
            color: sidebar.textColor("white")
            font.pixelSize: 12
            text: qsTr("HDR uses three exposures, the full field of view and 30 fps. Manual exposure; experimental ISP tuning.")
        }
        ActionElement {
            id: camera_controls
            visible: videoPanel.hasArducamHdr
            m_title: qsTr("Exposure & color")
            m_displayed_value: qsTr("Open controls")
            function open_controls() {
                sidebar.update_stack_index(3);
                sidebar.handover_joystick_control_to_panel(3);
            }
            onBase_joy_edit_element_clicked: open_controls()
            Keys.onPressed: {
                if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter || event.key === Qt.Key_Right) {
                    open_controls(); event.accepted = true;
                } else if (event.key === Qt.Key_Up) {
                    arducam_hdr.takeover_control(); event.accepted = true;
                } else if (event.key === Qt.Key_Down) {
                    edit_resolution_element.takeover_control(); event.accepted = true;
                } else if (event.key === Qt.Key_Left) {
                    sidebar.regain_control_on_sidebar_stack(); event.accepted = true;
                }
            }
        }
        MavlinkChoiceElement2{
            id: edit_resolution_element
            m_title: "Resolution/\nframerate"
            m_param_id: "RESOLUTION_FPS"
            m_settings_model: _airCameraSettingsModel
            override_takes_string_param: true;
            onGoto_previous: {
                if (videoPanel.hasReadoutModes) readout_mode.takeover_control();
                else if (videoPanel.hasArducamHdr) camera_controls.takeover_control();
                else sidebar.regain_control_on_sidebar_stack()
            }
            onGoto_next: {
                if (videoPanel.hasStreamingFormat) streaming_format.takeover_control()
                else videoPanel.focusAfterStreamSettings()
            }
        }
        MavlinkChoiceElement2 {
            id: streaming_format
            visible: videoPanel.hasStreamingFormat
            m_title: qsTr("Streaming format")
            m_param_id: "VIDEO_CODEC"
            m_settings_model: _airCameraSettingsModel
            onGoto_previous: edit_resolution_element.takeover_control()
            onGoto_next: videoPanel.focusAfterStreamSettings()
        }
        MavlinkChoiceElement2{
            id: rotation_degree
            visible: videoPanel.hasRotation
            m_title: qsTr("Rotation")
            m_param_id: "ROTATION_DEG"
            m_settings_model: _airCameraSettingsModel
            onGoto_previous: {
                if (videoPanel.hasStreamingFormat) streaming_format.takeover_control()
                else edit_resolution_element.takeover_control()
            }
            onGoto_next: {
                if (videoPanel.hasFlip) rotation_flip.takeover_control()
                else sidebar.regain_control_on_sidebar_stack()
            }
        }
        MavlinkChoiceElement2{
            id: rotation_flip
            visible: videoPanel.hasFlip
            m_title: qsTr("Mirror / flip")
            m_param_id: "ROTATION_FLIP"
            m_settings_model: _airCameraSettingsModel
            onGoto_previous: {
                if (videoPanel.hasRotation) rotation_degree.takeover_control()
                else if (videoPanel.hasStreamingFormat) streaming_format.takeover_control()
                else edit_resolution_element.takeover_control()
            }
            onGoto_next: {
                sidebar.regain_control_on_sidebar_stack()
            }
        }
    }
}

