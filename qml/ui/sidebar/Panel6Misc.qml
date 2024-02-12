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
    override_title: "Misc"

    Column {
        anchors.top: parent.top
        anchors.topMargin: secondaryUiHeight/8
        spacing: 5
        MavlinkIntChoiceElement{
            m_title: "AIR WIFI HS"
            m_param_id: "WIFI_HOTSPOT_E"
            m_settings_model: _ohdSystemAirSettingsModel
        }
        MavlinkIntChoiceElement{
            m_title: "GND WIFI HS"
            m_param_id: "WIFI_HOTSPOT_E"
            m_settings_model: _ohdSystemGroundSettings
        }
    }
}

