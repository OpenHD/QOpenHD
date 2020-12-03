import QtQuick 2.12
import QtQuick.Controls 2.12
import QtQuick.Layouts 1.12
import QtGraphicalEffects 1.12
import Qt.labs.settings 1.0

import OpenHD 1.0

BaseWidget {
    id: groundPowerWidget
    width: 96
    height: 55

    visible: settings.show_gnd_battery

    widgetIdentifier: "gnd_battery_widget"

    defaultAlignment: 2
    defaultXOffset: 296
    defaultYOffset: 24
    defaultHCenter: false
    defaultVCenter: false

    hasWidgetDetail: true
    widgetDetailComponent: ScrollView {

        contentHeight: gndBatterySettingsColumn.height
        ScrollBar.horizontal.policy: ScrollBar.AlwaysOff
        clip: true

        ColumnLayout {
            id: gndBatterySettingsColumn
            spacing: 0
            clip: true

            Item {
                width: 230
                height: 32
                Text {
                    text: qsTr("Voltage:")
                    color: "white"
                    font.bold: true
                    height: parent.height
                    font.pixelSize: detailPanelFontPixels
                    anchors.left: parent.left
                    verticalAlignment: Text.AlignVCenter
                }
                Text {
                    text: Number(OpenHD.battery_voltage).toLocaleString(
                              Qt.locale(), 'f', 1) + "V"
                    color: "white"
                    font.bold: true
                    height: parent.height
                    font.pixelSize: detailPanelFontPixels
                    anchors.right: parent.right
                    verticalAlignment: Text.AlignVCenter
                }
            }
            Item {
                width: 230
                height: 32
                Text {
                    text: qsTr("Current:")
                    color: "white"
                    font.bold: true
                    height: parent.height
                    font.pixelSize: detailPanelFontPixels
                    anchors.left: parent.left
                    verticalAlignment: Text.AlignVCenter
                }
                Text {
                    text: Number(OpenHD.battery_current / 100.0).toLocaleString(
                              Qt.locale(), 'f', 1) + "A"
                    color: "white"
                    font.bold: true
                    height: parent.height
                    font.pixelSize: detailPanelFontPixels
                    anchors.right: parent.right
                    verticalAlignment: Text.AlignVCenter
                }
            }
            Item {
                width: 230
                height: 32
                Text {
                    id: opacityTitle
                    text: qsTr("Transparency")
                    color: "white"
                    height: parent.height
                    font.bold: true
                    font.pixelSize: detailPanelFontPixels
                    anchors.left: parent.left
                    verticalAlignment: Text.AlignVCenter
                }
                Slider {
                    id: gnd_battery_opacity_Slider
                    orientation: Qt.Horizontal
                    height: parent.height
                    from: .1
                    value: settings.gnd_battery_opacity
                    to: 1
                    stepSize: .1
                    anchors.rightMargin: 0
                    anchors.right: parent.right
                    width: parent.width - 96

                    onValueChanged: {
                        settings.gnd_battery_opacity = gnd_battery_opacity_Slider.value
                    }
                }
            }
            Item {
                width: 230
                height: 32
                Text {
                    text: qsTr("Size")
                    color: "white"
                    height: parent.height
                    font.bold: true
                    font.pixelSize: detailPanelFontPixels
                    anchors.left: parent.left
                    verticalAlignment: Text.AlignVCenter
                }
                Slider {
                    id: gnd_battery_size_Slider
                    orientation: Qt.Horizontal
                    from: .5
                    value: settings.gnd_battery_size
                    to: 3
                    stepSize: .1
                    height: parent.height
                    anchors.rightMargin: 0
                    anchors.right: parent.right
                    width: parent.width - 96

                    onValueChanged: {
                        settings.gnd_battery_size = gnd_battery_size_Slider.value
                    }
                }
            }
            Item {
                width: 230
                height: 32
                Text {
                    text: qsTr("Show volts and amps")
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
                    checked: settings.gnd_battery_show_voltage_current
                    onCheckedChanged: settings.gnd_battery_show_voltage_current = checked
                }
            }
            Item {
                width: 230
                height: 32
                visible: settings.gnd_battery_show_voltage_current
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
                    checked: settings.gnd_battery_show_single_cell
                    onCheckedChanged: settings.gnd_battery_show_single_cell = checked
                }
            }
            Item {
                width: 230
                height: 32
                Text {
                    text: qsTr("Use telemetry percentege")
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
                    checked: settings.gnd_battery_show_fc_percent
                    onCheckedChanged: settings.gnd_battery_show_fc_percent = checked
                }
            }
        }
    }

    Item {
        id: widgetInner

        anchors.fill: parent
        opacity: settings.gnd_battery_opacity
        scale: settings.gnd_battery_size

        Text {
            id: battery_percent
            y: 0
            color: settings.color_text
            text: qsTr("%L1%").arg(
                       OpenHD.gnd_battery_percent)
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
        }
        Text {
            id: battery_amp_text
            visible: settings.gnd_battery_show_voltage_current
            text: Number(OpenHD.ground_iout / 100.0).toLocaleString(
                      Qt.locale(), 'f', 1) + "A"
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
            visible: settings.gnd_battery_show_voltage_current
            text: settings.gnd_battery_show_single_cell ? Number(
                                                              (OpenHD.ground_vbat) / settings.gnd_battery_cells).toLocaleString(
                                                              Qt.locale(),
                                                              'f', 1) + "V" : Number(OpenHD.ground_vbat).toLocaleString(
                                                              Qt.locale(),
                                                              'f', 1) + "V"
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
                var percent = OpenHD.gnd_battery_percent;

                // 20% warning, 15% critical
                return percent < 20 ? (percent < 15 ? "#ff0000" : "#fbfd15") : settings.color_shape
            }
            opacity: settings.gnd_battery_opacity
            text: OpenHD.gnd_battery_gauge
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
