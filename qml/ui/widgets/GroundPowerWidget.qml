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

        BaseWidgetDefaultUiControlElements{
            id: idBaseWidgetDefaultUiControlElements
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
                    checked: settings.ground_battery_show_voltage_current
                    onCheckedChanged: settings.ground_battery_show_voltage_current = checked
                }
            }
            Item {
                width: 230
                height: 32
                visible: settings.ground_battery_show_voltage_current
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
        }
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
            text: qsTr("%L1%").arg(_ohdSystemGround.battery_percent)
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
            visible: settings.ground_battery_show_voltage_current
            text: Number(
                      (_ohdSystemGround.ground_iout < 0 ? 0 : _ohdSystemGround.ground_iout) / 1000.0).toLocaleString(
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
            visible: settings.ground_battery_show_voltage_current
            text: settings.ground_battery_show_single_cell ? Number(
                                                                 ((_ohdSystemGround.ground_vbat < 0 ? 0 : _ohdSystemGround.ground_vbat / 1000.0)) / settings.ground_battery_cells).toLocaleString(Qt.locale(), 'f', 1) + "V" : Number((_ohdSystemGround.ground_vbat < 0 ? 0 : _ohdSystemGround.ground_vbat / 1000.0)).toLocaleString(
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
                var percent = _ohdSystemGround.battery_percent

                // 20% warning, 15% critical
                return percent < 20 ? (percent < 15 ? "#ff0000" : "#fbfd15") : settings.color_shape
            }
            opacity: bw_current_opacity
            text: _ohdSystemGround.battery_gauge
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
