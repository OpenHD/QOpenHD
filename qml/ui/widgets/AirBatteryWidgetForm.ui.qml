import QtQuick 2.12
import QtQuick.Controls 2.12
import QtQuick.Layouts 1.12
import QtGraphicalEffects 1.12
import Qt.labs.settings 1.0

import OpenHD 1.0

BaseWidget {
    id: airBatteryWidget
    width: 96
    height: 48

    visible: settings.show_air_battery

    widgetIdentifier: "air_battery_widget"

    defaultAlignment: 3
    defaultXOffset: 0
    defaultYOffset: 0
    defaultHCenter: false
    defaultVCenter: false

    hasWidgetDetail: true
    widgetDetailComponent: Column {
        Item {
            width: parent.width
            height: 32
            Text {
                text: "Voltage:"
                color: "white"
                font.bold: true
                height: parent.height
                font.pixelSize: detailPanelFontPixels
                anchors.left: parent.left
                verticalAlignment: Text.AlignVCenter
            }
            Text {
                text: Number(OpenHD.battery_voltage).toLocaleString(Qt.locale(), 'f', 1) + "V";
                color: "white";
                font.bold: true;
                height: parent.height
                font.pixelSize: detailPanelFontPixels;
                anchors.right: parent.right
                verticalAlignment: Text.AlignVCenter
            }
        }
        Item {
            width: parent.width
            height: 32
            Text {
                text: "Current:"
                color: "white"
                font.bold: true
                height: parent.height
                font.pixelSize: detailPanelFontPixels
                anchors.left: parent.left
                verticalAlignment: Text.AlignVCenter
            }
            Text {
                text: Number(OpenHD.battery_current/100.0).toLocaleString(Qt.locale(), 'f', 1) + "A";
                color: "white";
                font.bold: true;
                height: parent.height
                font.pixelSize: detailPanelFontPixels;
                anchors.right: parent.right
                verticalAlignment: Text.AlignVCenter
            }
        }
        Item {
            width: parent.width
            height: 32
            Text {
                id: opacityTitle
                text: "Opacity"
                color: "white"
                height: parent.height
                font.bold: true
                font.pixelSize: detailPanelFontPixels
                anchors.left: parent.left
                verticalAlignment: Text.AlignVCenter
            }
            Slider {
                id: air_battery_opacity_Slider
                orientation: Qt.Horizontal
                height: parent.height
                from: .1
                value: settings.air_battery_opacity
                to: 1
                stepSize: .1
                anchors.rightMargin: 0
                anchors.right: parent.right
                width: parent.width - 96

                onValueChanged: {
                    settings.air_battery_opacity = air_battery_opacity_Slider.value
                }
            }
        }
        Item {
            width: parent.width
            height: 32
            Text {
                text: "Show all data (No) / (Yes)"
                color: "white"
                height: parent.height
                font.bold: true
                font.pixelSize: detailPanelFontPixels;
                anchors.left: parent.left
                verticalAlignment: Text.AlignVCenter
            }
            Switch {
                width: 32
                height: parent.height
                anchors.rightMargin: 12
                anchors.right: parent.right
                checked: settings.air_battery_showall
                onCheckedChanged: settings.air_battery_showall = checked
            }
        }
    }

    Item {
        id: widgetInner

        anchors.fill: parent
        opacity: settings.air_battery_opacity

        Text {
            id: battery_percent
            y: 0
            color: settings.color_text            
            text: qsTr("%L1%").arg(OpenHD.battery_percent)
            anchors.verticalCenter: parent.verticalCenter
            anchors.left: batteryGauge.right
            anchors.leftMargin: 0
            clip: true
            verticalAlignment: Text.AlignVCenter
            elide: Text.ElideRight
            horizontalAlignment: Text.AlignLeft
            font.pixelSize: 14
        }
        Text {
            id: battery_amp_text
            visible: settings.air_battery_showall ? true : false
            text: Number(OpenHD.battery_current/100.0).toLocaleString(Qt.locale(), 'f', 1) + "A";
            color: settings.color_text
            anchors.bottom: battery_percent.top
            anchors.left: batteryGauge.right
            anchors.leftMargin: 0
            clip: true
            verticalAlignment: Text.AlignVCenter
            elide: Text.ElideRight
            horizontalAlignment: Text.AlignLeft
            font.pixelSize: 14
        }
        Text {
            id: battery_volt_text
            visible: settings.air_battery_showall ? true : false
            text: Number(OpenHD.battery_voltage).toLocaleString(Qt.locale(), 'f', 1) + "V";
            color: settings.color_text
            anchors.top: battery_percent.bottom
            anchors.left: batteryGauge.right
            anchors.leftMargin: 0
            clip: true
            verticalAlignment: Text.AlignVCenter
            elide: Text.ElideRight
            horizontalAlignment: Text.AlignLeft
            font.pixelSize: 14
        }
        Text {
            id: batteryGauge
            y: 8
            width: 36
            height: 48
            // @disable-check M223
            color: {
                /* todo: expose battery_voltage_to_percent to QML instead of using cell levels here
                   @disable-check M222
                */
                var cells = settings.value("show_ground_status", true);
                var cellVoltage = OpenHD.battery_voltage / cells;
                // 20% warning, 15% critical
                return cellVoltage < 3.73 ? (cellVoltage < 3.71 ? "#ff0000" : "#fbfd15") :  settings.color_shape
            }
            opacity: settings.air_battery_opacity
            text: OpenHD.battery_gauge
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
        }
    }
}
