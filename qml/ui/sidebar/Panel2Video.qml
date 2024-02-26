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

        MavlinkChoiceElement{
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
        MavlinkChoiceElement{
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
        /*ComboBox {
                id:raspberryCams3
                visible: true
                width: 200
                model: [ "IMX708","IMX462","IMX477" ]
            }
            ComboBox {
                id:rock5Cams3
                visible: false
                width: 200
                model: [ "IMX415","IMX462","IMX708" ]
            }
            Text{
                text: "Camera Mode"+ "   (" + "1080p,60fps" + ")"
                font.pixelSize: 14
                font.family: "AvantGarde-Medium"
                color: "#ffffff"
                smooth: true
            }
            Slider {
                id: resolutionSlider3
                from: 0
                to: 2
                stepSize: 1
                //snapMode: Slider.SnapToStep
                value: 0 // Initial value
                Material.accent: Material.Grey
                onValueChanged: {
                    console.log("Resolution Slider:", value)
                }
            }
            Text{
                text: "Switch Cameras"
                font.pixelSize: 14
                font.family: "AvantGarde-Medium"
                color: "#ffffff"
                smooth: true
            }
            Switch {
            }
            TabBar {
                id: cameraSwitch
                Material.accent: "#fff"
                Material.foreground: "white"
                background: Rectangle {
                    implicitWidth: 100
                    implicitHeight: 40
                    color: secondaryUiColor
                }
                TabButton {
                    text: qsTr("Cam1")
                }
                TabButton {
                    text: qsTr("Cam2")
                }
            }*/
    }
}

