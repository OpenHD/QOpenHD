import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.12

import QtQuick.Shapes 1.0
import QtQuick.Controls.Material 2.0

import Qt.labs.settings 1.0

import OpenHD 1.0

import "../elements"

SideBarBasePanel{
    override_title: "Misc"

    function takeover_control(){
        air_wifi_hs.takeover_control();
    }

    Column {
        anchors.top: parent.top
        anchors.topMargin: secondaryUiHeight/8
        spacing: 5
        MavlinkChoiceElement{
            id: air_wifi_hs
            m_title: "AIR WIFI HS"
            m_param_id: "WIFI_HOTSPOT_E"
            m_settings_model: _ohdSystemAirSettingsModel
            onGoto_previous: {
                sidebar.regain_control_on_sidebar_stack()
            }
            onGoto_next: {
                gnd_wifi_hs.takeover_control();
            }
        }
        MavlinkChoiceElement{
            id: gnd_wifi_hs
            m_title: "GND WIFI HS"
            m_param_id: "WIFI_HOTSPOT_E"
            m_settings_model: _ohdSystemGroundSettings
            onGoto_previous: {
                air_wifi_hs.takeover_control();
            }
            onGoto_next: {
                sidebar.regain_control_on_sidebar_stack()
            }
        }
    }
}

