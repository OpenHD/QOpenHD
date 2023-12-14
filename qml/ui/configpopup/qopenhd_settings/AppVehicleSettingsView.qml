import QtQuick 2.12
import QtQuick.Controls 2.12
import QtQuick.Layouts 1.12
import QtQuick.Dialogs 1.0
import QtQuick.Controls.Material 2.12

import Qt.labs.settings 1.0

import OpenHD 1.0

import "../../../ui" as Ui
import "../../elements"

ScrollView {
    id: appVehicleSettingsView
    width: parent.width
    height: parent.height
    contentHeight: vehicleColumn.height

    clip: true

    Item {
        anchors.fill: parent

        Column {
            id: vehicleColumn
            spacing: 0
            anchors.left: parent.left
            anchors.right: parent.right

            SettingBaseElement{
                m_short_description: "Vehicle Battery Cells"
                m_long_description: "When show voltage per cell is selected (off by dfault) in the HUD, set this to the N of cells your air battery has."
                GgSpinBox {
                    height: elementHeight
                    width: 210
                    font.pixelSize: 14
                    anchors.right: parent.right
                    anchors.verticalCenter: parent.verticalCenter
                    from: 1
                    to: 32
                    stepSize: 1
                    anchors.rightMargin: Qt.inputMethod.visible ? 78 : 18

                    value: settings.vehicle_battery_n_cells
                    onValueChanged: {
                        settings.vehicle_battery_n_cells=value
                    }
                }
            }

            SettingBaseElement{
                m_short_description: "Show FC Messages in HUD"
                m_long_description: "When enabled, FC log messages are shown in the HUD log messages element,e.g. they might apear before,during and after flight"
                GgSwitch {
                    width: 32
                    height: elementHeight
                    anchors.rightMargin: Qt.inputMethod.visible ? 96 : 36
                    anchors.right: parent.right
                    anchors.verticalCenter: parent.verticalCenter
                    checked: settings.show_fc_messages_in_hud
                    onCheckedChanged: settings.show_fc_messages_in_hud = checked
                }
            }
            SettingBaseElement{
                m_short_description: "Set mavlink message rates"
                m_long_description: "Set mavlink message rate(s) that should work for most users. NOTE: When disabling this feature, you have to manually set the mavlink message rate(s)
 via mission planner for your autpilot running ardupilot/ PX4 ! After disabling, a reboot of the FC is required."
                GgSwitch {
                    width: 32
                    height: elementHeight
                    anchors.rightMargin: Qt.inputMethod.visible ? 96 : 36
                    anchors.right: parent.right
                    anchors.verticalCenter: parent.verticalCenter
                    checked: settings.set_mavlink_message_rates
                    onCheckedChanged: {
                        settings.set_mavlink_message_rates = checked
                    }
                }
            }
            SettingBaseElement{
                m_short_description: "High mavlink message rates"
                m_long_description: "Doubles the rates for all mavlink messages - this requires more telemetry bandwidth, but results in an even smoother OSD."
                GgSwitch {
                    width: 32
                    height: elementHeight
                    anchors.rightMargin: Qt.inputMethod.visible ? 96 : 36
                    anchors.right: parent.right
                    anchors.verticalCenter: parent.verticalCenter
                    checked: settings.mavlink_message_rates_high_speed
                    onCheckedChanged: {
                        if(settings.mavlink_message_rates_high_speed != checked){
                            settings.mavlink_message_rates_high_speed = checked
                            _mavlinkTelemetry.re_apply_rates()
                        }
                    }
                }
            }
            SettingBaseElement{
                m_short_description: "High mavlink message rates RC"
                m_long_description: "Increases the rate for mavlink down rc channel messages (This does not affect your RC over openhd latency !)"
                GgSwitch {
                    width: 32
                    height: elementHeight
                    anchors.rightMargin: Qt.inputMethod.visible ? 96 : 36
                    anchors.right: parent.right
                    anchors.verticalCenter: parent.verticalCenter
                    checked: settings.mavlink_message_rates_high_speed_rc_channels
                    onCheckedChanged: {
                        if(settings.mavlink_message_rates_high_speed_rc_channels != checked){
                            settings.mavlink_message_rates_high_speed_rc_channels = checked
                            _mavlinkTelemetry.re_apply_rates()
                        }
                    }
                }
            }
            SettingBaseElement{
                m_short_description: "Log quiet FC warning"
                m_long_description: "Log a warning when we get heartbeats from the FC, but not proper data"
                GgSwitch {
                    width: 32
                    height: elementHeight
                    anchors.rightMargin: Qt.inputMethod.visible ? 96 : 36
                    anchors.right: parent.right
                    anchors.verticalCenter: parent.verticalCenter
                    checked: settings.log_quiet_fc_warning_to_hud
                    onCheckedChanged: settings.log_quiet_fc_warning_to_hud = checked
                }
            }
        }
    }
}
