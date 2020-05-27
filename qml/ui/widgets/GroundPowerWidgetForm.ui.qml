import QtQuick 2.12
import QtQuick.Controls 2.12
import QtQuick.Layouts 1.12
import QtGraphicalEffects 1.12
import Qt.labs.settings 1.0

import OpenHD 1.0

BaseWidget {
    id: groundPowerWidget
    width: 96
    height: 48

    //visible: settings.show_ground_power

    widgetIdentifier: "ground_power_widget"

    defaultAlignment: 3
    defaultXOffset: 96
    defaultYOffset: 0
    defaultHCenter: false
    defaultVCenter: false

    hasWidgetDetail: true
    widgetDetailComponent: Column {
        Item {
            width: parent.width
            height: 32
            visible: (OpenHDPower.vin !== -1);
            Text { text: "Voltage in:";  color: "white"; height: parent.height; font.bold: true; font.pixelSize: detailPanelFontPixels; anchors.left: parent.left; verticalAlignment: Text.AlignVCenter }
            Text { text: OpenHDPower.vin; color: "white"; height: parent.height; font.bold: true; font.pixelSize: detailPanelFontPixels; anchors.right: parent.right; verticalAlignment: Text.AlignVCenter }
        }
        Item {
            width: parent.width
            height: 32
            visible: (OpenHDPower.vout !== -1);
            Text { text: "Voltage out:";  color: "white"; height: parent.height; font.bold: true; font.pixelSize: detailPanelFontPixels; anchors.left: parent.left; verticalAlignment: Text.AlignVCenter }
            Text { text: OpenHDPower.vout; color: "white"; height: parent.height; font.bold: true; font.pixelSize: detailPanelFontPixels; anchors.right: parent.right; verticalAlignment: Text.AlignVCenter }
        }
        Item {
            width: parent.width
            height: 32
            visible: (OpenHDPower.iout !== -1);
            Text { text: "Current out:";  color: "white"; height: parent.height; font.bold: true; font.pixelSize: detailPanelFontPixels; anchors.left: parent.left; verticalAlignment: Text.AlignVCenter }
            Text { text: OpenHDPower.iout; color: "white"; height: parent.height; font.bold: true; font.pixelSize: detailPanelFontPixels; anchors.right: parent.right; verticalAlignment: Text.AlignVCenter }
        }
        Item {
            width: parent.width
            height: 32
            visible: (OpenHDPower.vbat !== -1);
            Text { text: "Voltage bat:";  color: "white"; height: parent.height; font.bold: true; font.pixelSize: detailPanelFontPixels; anchors.left: parent.left; verticalAlignment: Text.AlignVCenter }
            Text { text: OpenHDPower.vbat; color: "white"; height: parent.height; font.bold: true; font.pixelSize: detailPanelFontPixels; anchors.right: parent.right; verticalAlignment: Text.AlignVCenter }
        }
        Item {
            width: parent.width
            height: 32
            Text {
                id: opacityTitle
                text: "Transparency"
                color: "white"
                height: parent.height
                font.bold: true
                font.pixelSize: detailPanelFontPixels
                anchors.left: parent.left
                verticalAlignment: Text.AlignVCenter
            }
            Slider {
                id: ground_power_opacity_Slider
                orientation: Qt.Horizontal
                from: .1
                value: settings.ground_power_opacity
                to: 1
                stepSize: .1
                height: parent.height
                anchors.rightMargin: 0
                anchors.right: parent.right
                width: parent.width - 96

                onValueChanged: {
                    settings.ground_power_opacity = ground_power_opacity_Slider.value
                }
            }
        }
    }

    Item {
        id: widgetInner

        anchors.fill: parent
        Text {
            id: battery_percent
            y: 0
            width: 48
            height: 24
            color: settings.color_text
            opacity: settings.ground_power_opacity
            text: OpenHDPower.battery_percent
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
            id: batteryGauge
            y: 8
            width: 36
            height: 48
            // @disable-check M223
            color: {
                // todo: expose battery_voltage_to_percent to QML instead of using cell levels here
                var cellVoltage = OpenHDPower.vbat;
                // 20% warning, 15% critical
                return cellVoltage < 3.15 ? (cellVoltage < 3.00 ? "#ff0000" : "#fbfd15") : "#ffffff"
            }
            opacity: settings.ground_power_opacity
            text: OpenHDPower.battery_gauge
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
