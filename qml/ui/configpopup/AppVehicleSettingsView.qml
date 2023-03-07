import QtQuick 2.12
import QtQuick.Controls 2.12
import QtQuick.Layouts 1.12
import QtQuick.Dialogs 1.0
import QtQuick.Controls.Material 2.12

import Qt.labs.settings 1.0

import OpenHD 1.0

import "../../ui" as Ui
import "../elements"

ScrollView {
    id: appVehicleSettingsView
    width: parent.width
    height: parent.height
    contentHeight: vehicleColumn.height
    visible: appSettingsBar.currentIndex == 1

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
                SpinBox {
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
                Switch {
                    width: 32
                    height: elementHeight
                    anchors.rightMargin: Qt.inputMethod.visible ? 96 : 36
                    anchors.right: parent.right
                    anchors.verticalCenter: parent.verticalCenter
                    checked: settings.show_fc_messages_in_hud
                    onCheckedChanged: settings.show_fc_messages_in_hud = checked
                }
            }
        }
    }
}
