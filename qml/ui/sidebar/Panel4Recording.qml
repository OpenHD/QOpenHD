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
            color: "#333c4c"
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
                color: "white"
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
                color: "white"
                smooth: true
            }
        }
        Item {
            height: recording_mode.height + 120
            width: recording_mode.width
        }
    }
}
