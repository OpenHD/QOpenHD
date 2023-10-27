import QtQuick 2.12
import QtQuick.Controls 2.12
import QtQuick.Layouts 1.12
import QtQuick.Dialogs 1.0
import QtQuick.Controls.Material 2.12

import Qt.labs.settings 1.0

import OpenHD 1.0

import "../../../ui" as Ui
import "../../elements"

// Parent panel for OpenHD Mavlink air and ground settings (!!!! NOT QOPENHD SETTINGS !!!)
Rectangle {
    width: parent.width
    height: parent.height

    //Layout.fillHeight: true
    //Layout.fillWidth: true

    property int rowHeight: 64
    property int elementHeight: 48
    property int elementComboBoxWidth: 300

    //color: "green"
    color: "transparent"


    function user_quidance_animate_channel_scan(){
        selectItemInStackLayoutBar.currentIndex=0;
        mavlink_openhd_wb_param_panel.user_quidance_animate_channel_scan();
    }

    // Tab bar for selecting items in stack layout
    TabBar {
        id: selectItemInStackLayoutBar
        width: parent.width
        TabButton {
            text: qsTr("LINK/QUICK")
        }
        TabButton {
            text: qsTr("AIR CAM 1")
        }
        TabButton {
            text: qsTr("AIR CAM 2")
            enabled: settings.dev_qopenhd_n_cameras>1
        }
        TabButton {
            text: qsTr("AIR")
        }
        TabButton {
            text: qsTr("GROUND")
        }
    }

    // placed right below the top bar
    StackLayout {
        width: parent.width
        height: parent.height-selectItemInStackLayoutBar.height
        anchors.top: selectItemInStackLayoutBar.bottom
        anchors.left: selectItemInStackLayoutBar.left
        anchors.bottom: parent.bottom
        currentIndex: selectItemInStackLayoutBar.currentIndex

        MavlinkOpenHDWBParamPanel{
            id: mavlink_openhd_wb_param_panel
        }
        MavlinkParamPanel{
            id: x1_AirCameraSettingsPanel
            m_name: "CAMERA1"
            m_instanceMavlinkSettingsModel: _airCameraSettingsModel
            m_instanceCheckIsAvlie: _ohdSystemAir
        }
        MavlinkParamPanel{
            id: x1_AirCameraSettingsPanel2
            m_name: "CAMERA2"
            m_instanceMavlinkSettingsModel: _airCameraSettingsModel2
            m_instanceCheckIsAvlie: _ohdSystemAir
        }
        MavlinkParamPanel{
            id: x2_AirSettingsPanel
            m_name: "AIR"
            m_instanceMavlinkSettingsModel: _ohdSystemAirSettingsModel
            m_instanceCheckIsAvlie: _ohdSystemAir
        }
        MavlinkParamPanel{
            id: x3_GroundSettingsPanel
            m_name: "GROUND"
            m_instanceMavlinkSettingsModel: _ohdSystemGroundSettings
            m_instanceCheckIsAvlie: _ohdSystemGround
        }
    }

}
