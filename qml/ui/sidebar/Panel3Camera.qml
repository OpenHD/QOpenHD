import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.12

import QtQuick.Shapes 1.0
import QtQuick.Controls.Material 2.0

import Qt.labs.settings 1.0

import OpenHD 1.0

import "../elements"

SideBarBasePanel{
    override_title: "Camera"

    property int air_settings_update_count: _ohdSystemAirSettingsModel.update_count
    property bool camera_plugin_active: {
        var unused = air_settings_update_count
        if (!_ohdSystemAirSettingsModel.has_params_fetched) return false
        return (_ohdSystemAirSettingsModel.param_int_exists("CAM_CTRL_ACTIVE")
                && _ohdSystemAirSettingsModel.get_cached_int("CAM_CTRL_ACTIVE") === 1)
                || (_ohdSystemAirSettingsModel.param_int_exists("TOPOTEK_ACTIVE")
                    && _ohdSystemAirSettingsModel.get_cached_int("TOPOTEK_ACTIVE") === 1)
                || (_ohdSystemAirSettingsModel.param_int_exists("SIYI_ACTIVE")
                    && _ohdSystemAirSettingsModel.get_cached_int("SIYI_ACTIVE") === 1)
    }

    function takeover_control(){
        brightness.takeover_control();
    }

    Column {
        anchors.top: parent.top
        anchors.topMargin: 0
        spacing: 5
        MavlinkChoiceElement2{
            id: brightness
            m_title: "Brightness"
            m_param_id: "BRIGHTNESS"
            m_settings_model: _airCameraSettingsModel
            onGoto_previous: {
                sidebar.regain_control_on_sidebar_stack()
            }
            onGoto_next: {
                saturation.takeover_control();
            }
        }
        MavlinkChoiceElement2{
            id: saturation
            m_title: "Saturation"
            m_param_id: "SATURATION"
            m_settings_model: _airCameraSettingsModel
            onGoto_previous: {
               brightness.takeover_control();
            }
            onGoto_next: {
                contrast.takeover_control();
            }
        }
        MavlinkChoiceElement2{
            id: contrast
            m_title: "Contrast"
            m_param_id: "CONTRAST"
            m_settings_model: _airCameraSettingsModel
            onGoto_previous: {
               saturation.takeover_control();
            }
            onGoto_next: {
                sharpness.takeover_control();
            }
        }
        MavlinkChoiceElement2{
            id: sharpness
            m_title: "Sharpness"
            m_param_id: "SHARPNESS"
            m_settings_model: _airCameraSettingsModel
            onGoto_previous: {
               contrast.takeover_control();
            }
            onGoto_next: {
                sidebar.regain_control_on_sidebar_stack()
            }
        }

        ColumnLayout {
            visible: camera_plugin_active
            width: secondaryUiWidth
            spacing: 4

            Label {
                Layout.fillWidth: true
                text: qsTr("IP camera controls")
                color: "white"
                font.bold: true
                horizontalAlignment: Text.AlignHCenter
                topPadding: 8
            }

            GridLayout {
                Layout.alignment: Qt.AlignHCenter
                columns: 3
                rowSpacing: 3
                columnSpacing: 3

                Item { width: 72; height: 36 }
                Button {
                    text: "Up"
                    onPressed: _ohdAction.siyi_gimbal_rate(45, 0)
                    onReleased: _ohdAction.siyi_gimbal_rate(0, 0)
                    onCanceled: _ohdAction.siyi_gimbal_rate(0, 0)
                }
                Item { width: 72; height: 36 }
                Button {
                    text: "Left"
                    onPressed: _ohdAction.siyi_gimbal_rate(0, -45)
                    onReleased: _ohdAction.siyi_gimbal_rate(0, 0)
                    onCanceled: _ohdAction.siyi_gimbal_rate(0, 0)
                }
                Button {
                    text: qsTr("Center")
                    onClicked: _ohdAction.siyi_gimbal_center()
                }
                Button {
                    text: "Right"
                    onPressed: _ohdAction.siyi_gimbal_rate(0, 45)
                    onReleased: _ohdAction.siyi_gimbal_rate(0, 0)
                    onCanceled: _ohdAction.siyi_gimbal_rate(0, 0)
                }
                Item { width: 72; height: 36 }
                Button {
                    text: "Down"
                    onPressed: _ohdAction.siyi_gimbal_rate(-45, 0)
                    onReleased: _ohdAction.siyi_gimbal_rate(0, 0)
                    onCanceled: _ohdAction.siyi_gimbal_rate(0, 0)
                }
                Item { width: 72; height: 36 }
            }

            RowLayout {
                Layout.alignment: Qt.AlignHCenter
                Button {
                    text: qsTr("Zoom -")
                    onPressed: _ohdAction.siyi_zoom(-1)
                    onReleased: _ohdAction.siyi_zoom(0)
                    onCanceled: _ohdAction.siyi_zoom(0)
                }
                Button {
                    text: qsTr("Zoom +")
                    onPressed: _ohdAction.siyi_zoom(1)
                    onReleased: _ohdAction.siyi_zoom(0)
                    onCanceled: _ohdAction.siyi_zoom(0)
                }
            }

            RowLayout {
                Layout.alignment: Qt.AlignHCenter
                Button {
                    text: qsTr("Focus -")
                    onPressed: _ohdAction.siyi_focus(-1)
                    onReleased: _ohdAction.siyi_focus(0)
                    onCanceled: _ohdAction.siyi_focus(0)
                }
                Button {
                    text: qsTr("AF")
                    onClicked: _ohdAction.siyi_autofocus()
                }
                Button {
                    text: qsTr("Focus +")
                    onPressed: _ohdAction.siyi_focus(1)
                    onReleased: _ohdAction.siyi_focus(0)
                    onCanceled: _ohdAction.siyi_focus(0)
                }
            }

            RowLayout {
                Layout.alignment: Qt.AlignHCenter
                Button {
                    text: qsTr("Photo")
                    onClicked: _ohdAction.siyi_take_photo()
                }
                Button {
                    text: qsTr("Rec")
                    onClicked: _ohdAction.siyi_set_recording(true)
                }
                Button {
                    text: qsTr("Stop")
                    onClicked: _ohdAction.siyi_set_recording(false)
                }
            }
        }

    }
}
