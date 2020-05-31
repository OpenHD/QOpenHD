import QtQuick 2.12
import QtQuick.Controls 2.12
import QtQuick.Controls.Styles 1.4

import QtQuick.Layouts 1.12
import QtGraphicalEffects 1.12
import Qt.labs.settings 1.0

import OpenHD 1.0

import "../elements"

BaseWidget {
    id: gpioWidget
    width: 64
    height: 64

    visible: settings.show_gpio

    widgetIdentifier: "gpio_widget"

    defaultAlignment: 0

    defaultXOffset: 0
    defaultYOffset: 48
    defaultHCenter: false
    defaultVCenter: false

    widgetDetailWidth: 120
    widgetDetailHeight: 320

    hasWidgetDetail: true

    widgetDetailComponent: Column {
        spacing: 6
        Connections {
            target: OpenHD
            function onAir_gpio_changed(air_gpio) {
                gpio1.checked = air_gpio[0] === 1;
                gpio1.unknownState = false;
                gpio2.checked = air_gpio[1] === 1;
                gpio2.unknownState = false;
                gpio3.checked = air_gpio[2] === 1;
                gpio3.unknownState = false;
                gpio4.checked = air_gpio[3] === 1;
                gpio4.unknownState = false;
                gpio5.checked = air_gpio[4] === 1;
                gpio5.unknownState = false;
                gpio6.checked = air_gpio[5] === 1;
                gpio6.unknownState = false;
                gpio7.checked = air_gpio[6] === 1;
                gpio7.unknownState = false;
                gpio8.checked = air_gpio[7] === 1;
                gpio8.unknownState = false;
            }
        }

        ColoredCheckbox {
            id: gpio1
            width: parent.width
            height: 32
            text: "GPIO5"
            boxColor: "white"
            textColor: "white"
            checkColor: "black"
            unknownState: true
            enabled: !OpenHD.air_gpio_busy
            onCheckedChanged: OpenHD.setAirGPIO(0, checked);
        }

        ColoredCheckbox {
            id: gpio2
            width: parent.width
            height: 32
            text: "GPIO6"
            boxColor: "white"
            textColor: "white"
            checkColor: "black"
            unknownState: true
            enabled: !OpenHD.air_gpio_busy
            onCheckedChanged: OpenHD.setAirGPIO(1, checked);
        }

        ColoredCheckbox {
            id: gpio3
            width: parent.width
            height: 32
            text: "GPIO12"
            boxColor: "white"
            textColor: "white"
            checkColor: "black"
            unknownState: true
            enabled: !OpenHD.air_gpio_busy
            onCheckedChanged: OpenHD.setAirGPIO(2, checked);
        }

        ColoredCheckbox {
            id: gpio4
            width: parent.width
            height: 32
            text: "GPIO13"
            boxColor: "white"
            textColor: "white"
            checkColor: "black"
            unknownState: true
            enabled: !OpenHD.air_gpio_busy
            onCheckedChanged: OpenHD.setAirGPIO(3, checked);
        }

        ColoredCheckbox {
            id: gpio5
            width: parent.width
            height: 32
            text: "GPIO16"
            boxColor: "white"
            textColor: "white"
            checkColor: "black"
            unknownState: true
            enabled: !OpenHD.air_gpio_busy
            onCheckedChanged: OpenHD.setAirGPIO(4, checked);
        }

        ColoredCheckbox {
            id: gpio6
            width: parent.width
            height: 32
            text: "GPIO19"
            boxColor: "white"
            textColor: "white"
            checkColor: "black"
            unknownState: true
            enabled: !OpenHD.air_gpio_busy
            onCheckedChanged: OpenHD.setAirGPIO(5, checked);
        }

        ColoredCheckbox {
            id: gpio7
            width: parent.width
            height: 32
            text: "GPIO26"
            boxColor: "white"
            textColor: "white"
            checkColor: "black"
            unknownState: true
            enabled: !OpenHD.air_gpio_busy
            onCheckedChanged: OpenHD.setAirGPIO(6, checked);
        }

        ColoredCheckbox {
            id: gpio8
            width: parent.width
            height: 32
            text: "GPIO32"
            boxColor: "white"
            textColor: "white"
            checkColor: "black"
            unknownState: true
            enabled: !OpenHD.air_gpio_busy
            onCheckedChanged: OpenHD.setAirGPIO(7, checked);
        }
    }

    Item {
        id: widgetInner

        anchors.fill: parent

        Text {
            id: gpioIcon
            width: 64
            height: 64
            text: "G"
            color: "white"
            anchors.left: parent.left
            anchors.leftMargin: 12
            fontSizeMode: Text.VerticalFit
            anchors.fill: parent
            clip: true
            elide: Text.ElideMiddle
            font.family: "Material Design Icons"
            verticalAlignment: Text.AlignVCenter
            horizontalAlignment: Text.AlignHCenter
            font.pixelSize: 36
        }
    }
}
