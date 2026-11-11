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

SideBarBasePanel {
    override_title: "Air recording"
    headerIcon: "\uf0c7"

    function takeover_control(){
        recording_mode.takeover_control();
    }

    Column {
        anchors.top: parent.top
        anchors.topMargin: 0
        spacing: 5

        Rectangle {
            color: "transparent"
            height: recording_mode.height
            width: recording_mode.width
            MavlinkChoiceElement2 {
                id: recording_mode
                anchors.centerIn: parent
                anchors.leftMargin: 40
                m_title: "Recording"
                m_param_id: "AIR_RECORDING_E"
                m_settings_model: _airCameraSettingsModel
                onGoto_previous: {
                    sidebar.regain_control_on_sidebar_stack()
                }
                onGoto_next: {
                    // Do nothing
                }
            }
        }
        Rectangle {
            color: sidebar.controlColor("#333c4c", 0.72)
            opacity: 0.3
            height: recording_mode.height
            width: recording_mode.width
            Text {
                width: parent.width / 2
                height: parent.height
                text: qsTr("Status")
                verticalAlignment: Qt.AlignVCenter
                horizontalAlignment: Qt.AlignHCenter
                font.pixelSize: 18
                color: sidebar.textColor("white")
                smooth: true
            }
            Text {
                width: parent.width / 2
                height: parent.height
                anchors.right: parent.right
                text: {
                    if (!_ohdSystemAir.is_alive) {
                        return qsTr("disabled");
                    }
                    return _cameraStreamModelPrimary.camera_recording_mode_to_string(
                        _cameraStreamModelPrimary.air_recording_active
                    );
                }
                verticalAlignment: Qt.AlignVCenter
                horizontalAlignment: Qt.AlignHCenter
                font.pixelSize: 15
                color: sidebar.textColor("white")
                smooth: true
            }
        }
        Item {
            height: recording_mode.height + 120
            width: recording_mode.width
        }
    }
}
