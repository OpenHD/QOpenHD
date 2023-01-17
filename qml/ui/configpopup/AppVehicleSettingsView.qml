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

            Rectangle {

                width: parent.width
                height: rowHeight
                color: (Positioner.index % 2 == 0) ? "#8cbfd7f3" : "#00000000"
                visible: true

                Text {
                    text: qsTr("Vehicle Battery Cells")
                    font.weight: Font.Bold
                    font.pixelSize: 13
                    anchors.leftMargin: 8
                    verticalAlignment: Text.AlignVCenter
                    anchors.verticalCenter: parent.verticalCenter
                    width: 224
                    height: elementHeight
                    anchors.left: parent.left
                }

                SpinBox {
                    id: vehicle_attery_n_cellsSpinBox
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
                    onValueChanged: settings.vehicle_battery_n_cells = value
                }
            }
        }
    }
}
