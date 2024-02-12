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
    id: displayUI
    override_title: "OpenHD RC"

    property int m_control_yaw : settings.control_widget_use_fc_channels ? _rcchannelsmodelfc.control_yaw : _rcchannelsmodelground.control_yaw
    property int m_control_roll: settings.control_widget_use_fc_channels ? _rcchannelsmodelfc.control_roll : _rcchannelsmodelground.control_roll
    property int m_control_pitch: settings.control_widget_use_fc_channels ? _rcchannelsmodelfc.control_pitch : _rcchannelsmodelground.control_pitch
    property int m_control_throttle: settings.control_widget_use_fc_channels ? _rcchannelsmodelfc.control_throttle : _rcchannelsmodelground.control_throttle

    Column {
        anchors.top: parent.top
        anchors.topMargin: secondaryUiHeight/8
        spacing: 5


        MavlinkIntChoiceElement{
            m_title: "JOY RC"
            m_param_id: "ENABLE_JOY_RC";
            m_settings_model: _ohdSystemGroundSettings
        }

        Text{
            text: "Channel 1"
            font.pixelSize: 14
            font.family: "AvantGarde-Medium"
            color: "#ffffff"
            smooth: true
        }
        ProgressBar {
            id: progressBar1
            from: 1000
            to: 2000
            value: m_control_yaw
            Material.accent: Material.Grey
        }
        Text{
            text: "Channel 2"
            font.pixelSize: 14
            font.family: "AvantGarde-Medium"
            color: "#ffffff"
            smooth: true
        }
        ProgressBar {
            id: progressBar2
            from: 1000
            to: 2000
            value: m_control_yaw
            Material.accent: Material.Grey
        }
        Text{
            text: "Channel 3"
            font.pixelSize: 14
            font.family: "AvantGarde-Medium"
            color: "#ffffff"
            smooth: true
        }
        ProgressBar {
            id: progressBar3
            from: 1000
            to: 2000
            value: m_control_yaw
            Material.accent: Material.Grey
        }
        Text{
            text: "Channel 4"
            font.pixelSize: 14
            font.family: "AvantGarde-Medium"
            color: "#ffffff"
            smooth: true
        }
        ProgressBar {
            id: progressBar4
            from: 1000
            to: 2000
            value: m_control_yaw
            Material.accent: Material.Grey
        }
    }

}
