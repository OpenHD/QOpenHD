import QtQuick 2.12
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.12
import QtGraphicalEffects 1.12
import Qt.labs.settings 1.0

import OpenHD 1.0

BaseWidget {
    id: groundPowerWidget
    width: 96
    height: 55

    visible: settings.show_ground_battery

    widgetIdentifier: "ground_battery_widget"
    bw_verbose_name: "GROUND BATTERY"

    defaultAlignment: 2
    defaultXOffset: 188
    defaultYOffset: 0
    defaultHCenter: false
    defaultVCenter: false

    hasWidgetDetail: true

    widgetDetailComponent: ScrollView {
        contentHeight: idBaseWidgetDefaultUiControlElements.height
        ScrollBar.horizontal.policy: ScrollBar.AlwaysOff
        clip: true

        BaseWidgetDefaultUiControlElements {
            id: idBaseWidgetDefaultUiControlElements
            Item {
                width: 230
                height: 32
                Text {
                    text: qsTr("Show single cell voltage")
                    color: "white"
                    height: parent.height
                    font.bold: true
                    font.pixelSize: detailPanelFontPixels
                    anchors.left: parent.left
                    verticalAlignment: Text.AlignVCenter
                }
                Switch {
                    width: 32
                    height: parent.height
                    anchors.rightMargin: 6
                    anchors.right: parent.right
                    checked: settings.ground_battery_show_single_cell
                    onCheckedChanged: settings.ground_battery_show_single_cell = checked
                }
            }
            Item {
                width: 230
                height: 32

                Text {
                    text: qsTr("Battery Type")
                    color: "white"
                    height: parent.height
                    font.bold: true
                    font.pixelSize: detailPanelFontPixels
                    anchors.left: parent.left
                    verticalAlignment: Text.AlignVCenter
                }

                ComboBox {
                    id: batteryComboBox
                    width: 100
                    height: parent.height
                    anchors.rightMargin: 6
                    anchors.right: parent.right
                    model: ["Lipo", "LiIon", "LiFe"]
                    onCurrentIndexChanged: {
                        switch (batteryComboBox.currentIndex) {
                            case 0:
                                settings.ground_battery_type = 0;
                                settings.ground_battery_low = 35;
                                settings.ground_battery_mid = 39;
                                settings.ground_battery_full = 42;
                                break;
                            case 1:
                                settings.ground_battery_type = 1;
                                settings.ground_battery_low = 31;
                                settings.ground_battery_mid = 36;
                                settings.ground_battery_full = 42;
                                break;
                            case 2:
                                settings.ground_battery_type = 2;
                                settings.ground_battery_low = 30;
                                settings.ground_battery_mid = 35;
                                settings.ground_battery_full = 40;
                                break;
                        }
                    }
                }
            }
        }
    }

    function calculateBatteryPercentage(currentVoltage) {
            var currentVoltage2 = ((currentVoltage/settings.ground_battery_cells) / 100).toFixed(0);
            var fullVoltage = settings.ground_battery_full;
            var midVoltage = settings.ground_battery_mid;
            var emptyVoltage = settings.ground_battery_low;
            var percentage;

        if (currentVoltage2 >= fullVoltage) {
            percentage = 100;
        } else if (currentVoltage2 <= emptyVoltage) {
            percentage = 0;
        } else {
            var voltageRange = fullVoltage - emptyVoltage;
            var voltageProgress = currentVoltage2 - emptyVoltage;
            percentage = (voltageProgress / voltageRange) * 100;

            if (percentage >= 100) {
                percentage = 100;
            } else if (percentage <= 0) {
                percentage = 0;
            }
        }
            return percentage; // Ensure the percentage is within [0, 100]

        }


    Item {
        id: widgetInner

        anchors.fill: parent
        opacity: bw_current_opacity
        scale: bw_current_scale

        Text {
            id: gndTag
            y: 0
            rotation: -90
            color: settings.color_text
            text: "gnd"
            anchors.verticalCenter: parent.verticalCenter
            anchors.left: parent.left
            anchors.leftMargin: -2
            clip: true
            verticalAlignment: Text.AlignVCenter
            elide: Text.ElideRight
            horizontalAlignment: Text.AlignLeft
            font.pixelSize: 14
            font.family: settings.font_text
            style: Text.Outline
            styleColor: settings.color_glow
        }

        Text {
            id: battery_percent
            y: 0
            color: settings.color_text
            text: settings.ground_voltage_in_percent + "%"
            anchors.verticalCenter: parent.verticalCenter
            anchors.left: batteryGauge.right
            anchors.leftMargin: 0
            clip: true
            verticalAlignment: Text.AlignVCenter
            elide: Text.ElideRight
            horizontalAlignment: Text.AlignLeft
            font.pixelSize: 14
            font.family: settings.font_text
            style: Text.Outline
            styleColor: settings.color_glow

            Timer {
                interval: 1000 // Interval of 1000 milliseconds (1 second)
                running: true // Start the timer immediately
                repeat: true // Repeat the timer indefinitely

                onTriggered: {
                    var currentVoltage = _ohdSystemGround.ina219_voltage_millivolt;
                    var percentage = calculateBatteryPercentage(currentVoltage);
                    settings.ground_voltage_in_percent = percentage;
                }
            }
        }

        Text {
            id: battery_amp_text
            visible: true
            y: 0
            text: _ohdSystemGround.ina219_current_milliamps + "mA"
            color: settings.color_text
            anchors.bottom: battery_percent.top
            anchors.left: batteryGauge.right
            anchors.leftMargin: 0
            clip: true
            verticalAlignment: Text.AlignVCenter
            elide: Text.ElideRight
            horizontalAlignment: Text.AlignLeft
            font.pixelSize: 14
            font.family: settings.font_text
            style: Text.Outline
            styleColor: settings.color_glow
        }

        Text {
            id: battery_volt_text
            visible: true
            text: {
                if (settings.ground_battery_show_single_cell) {
                    return (_ohdSystemGround.ina219_voltage_millivolt / settings.ground_battery_cells / 1000) + "mVpC";
                } else {
                    return (_ohdSystemGround.ina219_voltage_millivolt / 1000).toFixed(2) + "V";
                }
            }
            color: settings.color_text
            anchors.top: battery_percent.bottom
            anchors.left: batteryGauge.right
            anchors.leftMargin: 0
            clip: true
            verticalAlignment: Text.AlignVCenter
            elide: Text.ElideRight
            horizontalAlignment: Text.AlignLeft
            font.pixelSize: 14
            font.family: settings.font_text
            style: Text.Outline
            styleColor: settings.color_glow
        }

        Text {
            id: batteryGauge
            y: 8
            width: 36
            height: 48
            // @disable-check M223
            color: {
                var percent = settings.ground_voltage_in_percent;

                // 20% warning, 15% critical
                return percent < 50 ? (percent < 10 ? "#ff0000" : "#fbfd15") : settings.color_shape;
            }
            opacity: bw_current_opacity
            text: settings.ground_voltage_in_percent
            anchors.left: parent.left
            anchors.leftMargin: 12
            fontSizeMode: Text.VerticalFit
            anchors.verticalCenter: parent.verticalCenter
            clip: true
            elide: Text.ElideMiddle
            font.family: "Material Design Icons"
            verticalAlignment: Text.AlignVCenter
            horizontalAlignment: Text.AlignHCenter
            font.pixelSize: 36
            style: Text.Outline
            styleColor: settings.color_glow
        }
    }
}
