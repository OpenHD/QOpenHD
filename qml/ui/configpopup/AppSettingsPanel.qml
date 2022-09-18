import QtQuick 2.12
import QtQuick.Controls 2.12
import QtQuick.Layouts 1.12
import QtQuick.Dialogs 1.0
import QtQuick.Controls.Material 2.12

import Qt.labs.settings 1.0

import OpenHD 1.0

import "../../ui" as Ui
import "../elements"


/*
 * @brief QOpenHD settings (Application-specific settings)
 * !!!! Note that OpenHD-Specific settings should not make it into here. !!!
 * @Stephen: This file should be refactored in a way that isn't so fragile and verbose. The rows are
 * all manually defined and every one of them has a manually vertical offset to position it
 * inside the scroll view.
 */
Item {
    Layout.fillHeight: true
    Layout.fillWidth: true

    property int rowHeight: 64
    property int elementHeight: 48

    TabBar {
        id: appSettingsBar
        height: 48
        anchors.right: parent.right
        anchors.rightMargin: 0
        anchors.left: parent.left
        anchors.leftMargin: 0
        anchors.top: parent.top
        clip: true

        TabButton {
            y: 0
            text: qsTr("General")
            width: implicitWidth
            height: 48
            font.pixelSize: 13
        }

        TabButton {
            y: 0
            text: qsTr("Vehicle")
            width: implicitWidth
            height: 48
            font.pixelSize: 13
        }

        TabButton {
            text: qsTr("Widgets")
            width: implicitWidth
            height: 48
            font.pixelSize: 13
        }

        TabButton {
            text: qsTr("Screen")
            width: implicitWidth
            height: 48
            font.pixelSize: 13
        }

        TabButton {
            text: qsTr("Video")
            width: (EnableMainVideo || EnablePiP) ? implicitWidth : 0
            height: 48
            font.pixelSize: 13
            visible: (EnableMainVideo || EnablePiP)
        }

        TabButton {
            text: qsTr("Manage")
            width: (!IsRaspPi && !IsiOS) ? implicitWidth : 0
            height: 48
            font.pixelSize: 13
            visible: !IsRaspPi && !IsiOS

        }
    }

    StackLayout {
        id: appSettings
        anchors.top: appSettingsBar.bottom
        anchors.topMargin: 0
        anchors.right: parent.right
        anchors.rightMargin: 0
        anchors.left: parent.left
        anchors.leftMargin: 0
        anchors.bottom: parent.bottom
        anchors.bottomMargin: 0

        currentIndex: appSettingsBar.currentIndex

        ScrollView {
            id: generalView
            width: parent.width
            height: parent.height
            contentHeight: generalColumn.height
            visible: appSettingsBar.currentIndex == 0

            clip: true

            Item {
                anchors.fill: parent

                Column {
                    id: generalColumn
                    spacing: 0
                    anchors.left: parent.left
                    anchors.right: parent.right

                    Rectangle {
                        width: parent.width
                        height: rowHeight
                        color: (Positioner.index % 2 == 0) ? "#8cbfd7f3" : "#00000000"

                        Text {
                            text: qsTr("Mavlink SysID")
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
                            id: mavlinkSysIDSpinBox
                            height: elementHeight
                            width: 210
                            font.pixelSize: 14
                            anchors.right: parent.right
                            anchors.verticalCenter: parent.verticalCenter
                            from: 1
                            to: 255
                            stepSize: 1
                            anchors.rightMargin: Qt.inputMethod.visible ? 78 : 18

                            value: settings.mavlink_sysid
                            onValueChanged: settings.mavlink_sysid = value
                        }
                    }

                    Rectangle {
                        width: parent.width
                        height: rowHeight
                        color: (Positioner.index % 2 == 0) ? "#8cbfd7f3" : "#00000000"

                        //color: "#8cbfd7f3"
                        Text {
                            text: qsTr("Enable Speech")
                            font.weight: Font.Bold
                            font.pixelSize: 13
                            anchors.leftMargin: 8
                            verticalAlignment: Text.AlignVCenter
                            anchors.verticalCenter: parent.verticalCenter
                            width: 224
                            height: elementHeight
                            anchors.left: parent.left
                        }

                        Switch {
                            width: 32
                            height: elementHeight
                            anchors.rightMargin: Qt.inputMethod.visible ? 96 : 36
                            anchors.right: parent.right
                            anchors.verticalCenter: parent.verticalCenter
                            checked: settings.enable_speech
                            onCheckedChanged: settings.enable_speech = checked
                        }
                    }

                    Rectangle {
                        width: parent.width
                        height: rowHeight
                        color: (Positioner.index % 2 == 0) ? "#8cbfd7f3" : "#00000000"

                        Text {
                            text: qsTr("Log Level")
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
                            id: logLevelspinBox
                            height: elementHeight
                            width: 210
                            font.pixelSize: 14
                            anchors.right: parent.right
                            anchors.verticalCenter: parent.verticalCenter
                            from: 0
                            to: 7
                            stepSize: 1
                            anchors.rightMargin: Qt.inputMethod.visible ? 78 : 18

                            value: settings.log_level
                            onValueChanged: settings.log_level = value
                        }
                    }

                    Rectangle {
                        width: parent.width
                        height: rowHeight
                        color: (Positioner.index % 2 == 0) ? "#8cbfd7f3" : "#00000000"

                        Text {
                            text: qsTr("Imperial units")
                            font.weight: Font.Bold
                            font.pixelSize: 13
                            anchors.leftMargin: 8
                            verticalAlignment: Text.AlignVCenter
                            anchors.verticalCenter: parent.verticalCenter
                            width: 224
                            height: elementHeight
                            anchors.left: parent.left
                        }

                        Switch {
                            width: 32
                            height: elementHeight
                            anchors.rightMargin: Qt.inputMethod.visible ? 96 : 36

                            anchors.right: parent.right
                            anchors.verticalCenter: parent.verticalCenter
                            checked: settings.enable_imperial
                            onCheckedChanged: settings.enable_imperial = checked
                        }
                    }

                    Rectangle {

                        width: parent.width
                        height: rowHeight
                        color: (Positioner.index % 2 == 0) ? "#8cbfd7f3" : "#00000000"
                        visible: true

                        Text {
                            text: qsTr("Ground Battery Cells")
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
                            id: gndBatteryCellspinBox
                            height: elementHeight
                            width: 210
                            font.pixelSize: 14
                            anchors.right: parent.right
                            anchors.verticalCenter: parent.verticalCenter
                            from: 1
                            to: 6
                            stepSize: 1
                            anchors.rightMargin: Qt.inputMethod.visible ? 78 : 18

                            value: settings.ground_battery_cells
                            onValueChanged: settings.ground_battery_cells = value
                        }
                    }

                    Rectangle {
                        width: parent.width
                        height: rowHeight
                        color: (Positioner.index % 2 == 0) ? "#8cbfd7f3" : "#00000000"

                        Text {
                            text: qsTr("Language / Locale")
                            font.weight: Font.Bold
                            font.pixelSize: 13
                            anchors.leftMargin: 8
                            verticalAlignment: Text.AlignVCenter
                            anchors.verticalCenter: parent.verticalCenter
                            width: 224
                            height: elementHeight
                            anchors.left: parent.left
                        }

                        LanguageSelect {
                            id: languageSelectBox
                            height: elementHeight
                            width: 210
                            anchors.right: parent.right
                            anchors.rightMargin: Qt.inputMethod.visible ? 96 : 36
                            anchors.verticalCenter: parent.verticalCenter
                            anchors.horizontalCenter: parent.horizonatalCenter
                        }
                    }
                }
            }
        }

        ScrollView {
            id: vehicleView
            width: parent.width
            height: parent.height
            contentHeight: generalColumn.height
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

                        Text {
                            text: qsTr("Air Battery Cells")
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
                            id: batteryCellspinBox
                            height: elementHeight
                            width: 210
                            font.pixelSize: 14
                            anchors.right: parent.right
                            anchors.verticalCenter: parent.verticalCenter
                            from: 1
                            to: 6
                            stepSize: 1
                            anchors.rightMargin: Qt.inputMethod.visible ? 78 : 18

                            value: settings.battery_cells
                            onValueChanged: settings.battery_cells = value
                        }
                    }

                    Rectangle {
                        width: parent.width
                        height: rowHeight
                        color: (Positioner.index % 2 == 0) ? "#8cbfd7f3" : "#00000000"
                        visible: EnableRC

                        Text {
                            text: qsTr("Enable RC")
                            font.weight: Font.Bold
                            font.pixelSize: 13
                            anchors.leftMargin: 8
                            verticalAlignment: Text.AlignVCenter
                            anchors.verticalCenter: parent.verticalCenter
                            width: 224
                            height: elementHeight
                            anchors.left: parent.left
                        }

                        Switch {
                            width: 32
                            height: elementHeight
                            anchors.rightMargin: Qt.inputMethod.visible ? 96 : 36

                            anchors.right: parent.right
                            anchors.verticalCenter: parent.verticalCenter
                            checked: settings.enable_rc
                            onCheckedChanged: settings.enable_rc = checked
                        }
                    }

                    Rectangle {
                        width: parent.width
                        height: rowHeight
                        color: (Positioner.index % 2 == 0) ? "#8cbfd7f3" : "#00000000"

                        Text {
                            text: qsTr("Filter by Mavlink SysID")
                            font.weight: Font.Bold
                            font.pixelSize: 13
                            anchors.leftMargin: 8
                            verticalAlignment: Text.AlignVCenter
                            anchors.verticalCenter: parent.verticalCenter
                            width: 224
                            height: elementHeight
                            anchors.left: parent.left
                        }

                        Switch {
                            width: 32
                            height: elementHeight
                            anchors.rightMargin: Qt.inputMethod.visible ? 96 : 36

                            anchors.right: parent.right
                            anchors.verticalCenter: parent.verticalCenter
                            checked: settings.filter_mavlink_telemetry
                            onCheckedChanged: settings.filter_mavlink_telemetry = checked
                        }
                    }

                    Rectangle {
                        width: parent.width
                        height: rowHeight
                        color: (Positioner.index % 2 == 0) ? "#8cbfd7f3" : "#00000000"
                        visible: settings.filter_mavlink_telemetry

                        Text {
                            text: qsTr("Flight Controller Mavlink SysID")
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
                            id: fcMavlinkSysIDSpinBox
                            height: elementHeight
                            width: 210
                            font.pixelSize: 14
                            anchors.right: parent.right
                            anchors.verticalCenter: parent.verticalCenter
                            from: 1
                            to: 255
                            stepSize: 1
                            anchors.rightMargin: Qt.inputMethod.visible ? 78 : 18

                            value: settings.fc_mavlink_sysid
                            onValueChanged: settings.fc_mavlink_sysid = value
                        }
                    }
                }
            }
        }

        ScrollView {
            id: widgetsView
            width: parent.width
            height: parent.height
            contentHeight: widgetColumn.height
            visible: appSettingsBar.currentIndex == 2

            clip: true
            
            Item {
                anchors.fill: parent

                Column {
                    id: widgetColumn
                    spacing: 0
                    anchors.left: parent.left
                    anchors.right: parent.right

                    Rectangle {
                        width: parent.width
                        height: rowHeight
                        color: (Positioner.index % 2 == 0) ? "#8cbfd7f3" : "#00000000"

                        Text {
                            text: qsTr("Shape Color")
                            font.weight: Font.Bold
                            font.pixelSize: 13
                            anchors.leftMargin: 8
                            verticalAlignment: Text.AlignVCenter
                            anchors.verticalCenter: parent.verticalCenter
                            width: 224
                            height: elementHeight
                            anchors.left: parent.left
                        }

                        RoundButton {
                            //text: "Open"

                            height: elementHeight
                            anchors.right: parent.right
                            anchors.rightMargin: Qt.inputMethod.visible ? 96 : 36
                            anchors.verticalCenter: parent.verticalCenter
                            anchors.horizontalCenter: parent.horizonatalCenter
                            onClicked: {
                                colorPicker.previousColor = settings.color_shape
                                colorPicker.currentColorType = ColorPicker.ColorType.ShapeColor
                                colorPicker.visible = true
                            }

                            Rectangle {
                                anchors.centerIn: parent
                                width: ((parent.width<parent.height?parent.width:parent.height))-20
                                height: width
                                radius: width*0.5
                                color: settings.color_shape
                            }

                        }
                    }


                    Rectangle {
                        width: parent.width
                        height: rowHeight
                        color: (Positioner.index % 2 == 0) ? "#8cbfd7f3" : "#00000000"

                        Text {
                            text: qsTr("Glow Color")
                            font.weight: Font.Bold
                            font.pixelSize: 13
                            anchors.leftMargin: 8
                            verticalAlignment: Text.AlignVCenter
                            anchors.verticalCenter: parent.verticalCenter
                            width: 224
                            height: elementHeight
                            anchors.left: parent.left
                        }

                        RoundButton {
                            //text: "Open"

                            height: elementHeight
                            anchors.right: parent.right
                            anchors.rightMargin: Qt.inputMethod.visible ? 96 : 36
                            anchors.verticalCenter: parent.verticalCenter
                            anchors.horizontalCenter: parent.horizonatalCenter
                            onClicked: {
                                colorPicker.previousColor = settings.color_glow
                                colorPicker.currentColorType = ColorPicker.ColorType.GlowColor
                                colorPicker.visible = true
                            }

                            Rectangle {
                                anchors.centerIn: parent
                                width: ((parent.width<parent.height?parent.width:parent.height))-20
                                height: width
                                radius: width*0.5
                                color: settings.color_glow
                            }
                        }
                    }

                    Rectangle {
                        width: parent.width
                        height: rowHeight
                        color: (Positioner.index % 2 == 0) ? "#8cbfd7f3" : "#00000000"

                        Text {
                            text: qsTr("Text Color")
                            font.weight: Font.Bold
                            font.pixelSize: 13
                            anchors.leftMargin: 8
                            verticalAlignment: Text.AlignVCenter
                            anchors.verticalCenter: parent.verticalCenter
                            width: 224
                            height: elementHeight
                            anchors.left: parent.left
                        }

                        RoundButton {
                            //text: "Open"

                            height: elementHeight
                            anchors.right: parent.right
                            anchors.rightMargin: Qt.inputMethod.visible ? 96 : 36
                            anchors.verticalCenter: parent.verticalCenter
                            anchors.horizontalCenter: parent.horizonatalCenter
                            onClicked: {
                                colorPicker.previousColor = settings.color_text
                                colorPicker.currentColorType = ColorPicker.ColorType.TextColor
                                colorPicker.visible = true
                            }

                            Rectangle {
                                anchors.centerIn: parent
                                width: ((parent.width<parent.height?parent.width:parent.height))-20
                                height: width
                                radius: width*0.5
                                color: settings.color_text
                            }
                        }
                    }



                    Rectangle {
                        width: parent.width
                        height: rowHeight
                        color: (Positioner.index % 2 == 0) ? "#8cbfd7f3" : "#00000000"

                        Text {
                            text: qsTr("Text font")
                            font.weight: Font.Bold
                            font.pixelSize: 13
                            anchors.leftMargin: 8
                            verticalAlignment: Text.AlignVCenter
                            anchors.verticalCenter: parent.verticalCenter
                            width: 224
                            height: elementHeight
                            anchors.left: parent.left
                        }

                        FontSelect {
                            id: fontSelectBox
                            height: elementHeight
                            width: 320
                            anchors.right: parent.right
                            anchors.rightMargin: Qt.inputMethod.visible ? 96 : 36
                            anchors.verticalCenter: parent.verticalCenter
                            anchors.horizontalCenter: parent.horizonatalCenter
                        }
                    }


                    Rectangle {
                        width: parent.width
                        height: rowHeight
                        color: (Positioner.index % 2 == 0) ? "#8cbfd7f3" : "#00000000"

                        Text {
                            text: qsTr("Animation Smoothing")
                            font.weight: Font.Bold
                            font.pixelSize: 13
                            anchors.leftMargin: 8
                            verticalAlignment: Text.AlignVCenter
                            anchors.verticalCenter: parent.verticalCenter
                            width: 224
                            height: elementHeight
                            anchors.left: parent.left
                        }


                        Text {
                            text: Number(settings.smoothing).toLocaleString(Qt.locale(), 'f', 0) + "x";
                            font.pixelSize: 16
                            anchors.right: smoothing_Slider.left
                            anchors.rightMargin: 12
                            verticalAlignment: Text.AlignVCenter
                            anchors.verticalCenter: parent.verticalCenter
                            width: 32
                            height: elementHeight

                        }

                        Slider {
                            id: smoothing_Slider
                            height: elementHeight
                            width: 210
                            font.pixelSize: 14
                            anchors.right: parent.right
                            anchors.verticalCenter: parent.verticalCenter
                            to : 1000
                            from : 0
                            stepSize: 25
                            anchors.rightMargin: Qt.inputMethod.visible ? 78 : 18
                            value: settings.smoothing

                            // @disable-check M223
                            onValueChanged: {
                                // @disable-check M222
                                settings.smoothing = smoothing_Slider.value
                            }
                        }


                    }

                    Rectangle {
                        width: parent.width
                        height: rowHeight
                        color: (Positioner.index % 2 == 0) ? "#8cbfd7f3" : "#00000000"

                        Text {
                            text: qsTr("Top/bottom bars")
                            font.weight: Font.Bold
                            font.pixelSize: 13
                            anchors.leftMargin: 8
                            verticalAlignment: Text.AlignVCenter
                            anchors.verticalCenter: parent.verticalCenter
                            width: 224
                            height: elementHeight
                            anchors.left: parent.left
                        }

                        ComboBox {
                            height: elementHeight
                            anchors.right: parent.right
                            anchors.rightMargin: Qt.inputMethod.visible ? 96 : 36
                            anchors.verticalCenter: parent.verticalCenter
                            anchors.horizontalCenter: parent.horizonatalCenter
                            width: 320
                            model: ListModel {
                                id: bar_behavior
                                ListElement { text: qsTr("Hide") ; behavior: "none" }
                                ListElement { text: qsTr("Transparent black") ; behavior: "black" }
                                ListElement { text: qsTr("Hide when drone armed") ; behavior: "disappear" }
                                ListElement { text: qsTr("Turn red when drone armed") ; behavior: "red" }

                            }
                            textRole: "text"
                            // @disable-check M223
                            Component.onCompleted: {
                                // @disable-check M223
                                for (var i = 0; i < model.count; i++) {
                                    // @disable-check M222
                                    var choice = model.get(i);
                                    // @disable-check M223
                                    if (choice.behavior == settings.bar_behavior) {
                                        currentIndex = i;
                                    }
                                }
                            }
                            onCurrentIndexChanged: {
                                    settings.bar_behavior = bar_behavior.get(currentIndex).behavior
                            }
                        }
                    }

                    Rectangle {
                        width: parent.width
                        height: rowHeight
                        color: (Positioner.index % 2 == 0) ? "#8cbfd7f3" : "#00000000"

                        Text {
                            text: qsTr("Show Downlink RSSI")
                            font.weight: Font.Bold
                            font.pixelSize: 13
                            anchors.leftMargin: 8
                            verticalAlignment: Text.AlignVCenter
                            anchors.verticalCenter: parent.verticalCenter
                            width: 224
                            height: elementHeight
                            anchors.left: parent.left
                        }

                        Switch {
                            width: 32
                            height: elementHeight
                            anchors.rightMargin: Qt.inputMethod.visible ? 96 : 36

                            anchors.right: parent.right
                            anchors.verticalCenter: parent.verticalCenter
                            checked: settings.show_downlink_rssi
                            onCheckedChanged: settings.show_downlink_rssi = checked
                        }
                    }

                    Rectangle {
                        width: parent.width
                        height: rowHeight
                        color: (Positioner.index % 2 == 0) ? "#8cbfd7f3" : "#00000000"

                        Text {
                            text: qsTr("Show Uplink RSSI")
                            font.weight: Font.Bold
                            font.pixelSize: 13
                            anchors.leftMargin: 8
                            verticalAlignment: Text.AlignVCenter
                            anchors.verticalCenter: parent.verticalCenter
                            width: 224
                            height: elementHeight
                            anchors.left: parent.left
                        }

                        Switch {
                            width: 32
                            height: elementHeight
                            anchors.rightMargin: Qt.inputMethod.visible ? 96 : 36

                            anchors.right: parent.right
                            anchors.verticalCenter: parent.verticalCenter
                            checked: settings.show_uplink_rssi
                            onCheckedChanged: settings.show_uplink_rssi = checked
                        }
                    }

                    Rectangle {
                        width: parent.width
                        height: rowHeight
                        color: (Positioner.index % 2 == 0) ? "#8cbfd7f3" : "#00000000"

                        Text {
                            text: qsTr("Show RC RSSI (not OpenHD RC)")
                            font.weight: Font.Bold
                            font.pixelSize: 13
                            anchors.leftMargin: 8
                            verticalAlignment: Text.AlignVCenter
                            anchors.verticalCenter: parent.verticalCenter
                            width: 224
                            height: elementHeight
                            anchors.left: parent.left
                        }

                        Switch {
                            width: 32
                            height: elementHeight
                            anchors.rightMargin: Qt.inputMethod.visible ? 96 : 36

                            anchors.right: parent.right
                            anchors.verticalCenter: parent.verticalCenter
                            checked: settings.show_rc_rssi
                            onCheckedChanged: settings.show_rc_rssi = checked
                        }
                    }

                    Rectangle {
                        width: parent.width
                        height: rowHeight
                        color: (Positioner.index % 2 == 0) ? "#8cbfd7f3" : "#00000000"

                        Text {
                            text: qsTr("Show Bitrate")
                            font.weight: Font.Bold
                            font.pixelSize: 13
                            anchors.leftMargin: 8
                            verticalAlignment: Text.AlignVCenter
                            anchors.verticalCenter: parent.verticalCenter
                            width: 224
                            height: elementHeight
                            anchors.left: parent.left
                        }

                        Switch {
                            width: 32
                            height: elementHeight
                            anchors.rightMargin: Qt.inputMethod.visible ? 96 : 36

                            anchors.right: parent.right
                            anchors.verticalCenter: parent.verticalCenter
                            checked: settings.show_bitrate
                            onCheckedChanged: settings.show_bitrate = checked
                        }
                    }

                    Rectangle {
                        width: parent.width
                        height: rowHeight
                        color: (Positioner.index % 2 == 0) ? "#8cbfd7f3" : "#00000000"

                        Text {
                            text: qsTr("Show GPS")
                            font.weight: Font.Bold
                            font.pixelSize: 13
                            anchors.leftMargin: 8
                            verticalAlignment: Text.AlignVCenter
                            anchors.verticalCenter: parent.verticalCenter
                            width: 224
                            height: elementHeight
                            anchors.left: parent.left
                        }

                        Switch {
                            width: 32
                            height: elementHeight
                            anchors.rightMargin: Qt.inputMethod.visible ? 96 : 36

                            anchors.right: parent.right
                            anchors.verticalCenter: parent.verticalCenter
                            checked: settings.show_gps
                            onCheckedChanged: settings.show_gps = checked
                        }
                    }

                    Rectangle {
                        width: parent.width
                        height: rowHeight
                        color: (Positioner.index % 2 == 0) ? "#8cbfd7f3" : "#00000000"

                        Text {
                            text: qsTr("Show Home Distance")
                            font.weight: Font.Bold
                            font.pixelSize: 13
                            anchors.leftMargin: 8
                            verticalAlignment: Text.AlignVCenter
                            anchors.verticalCenter: parent.verticalCenter
                            width: 224
                            height: elementHeight
                            anchors.left: parent.left
                        }

                        Switch {
                            width: 32
                            height: elementHeight
                            anchors.rightMargin: Qt.inputMethod.visible ? 96 : 36

                            anchors.right: parent.right
                            anchors.verticalCenter: parent.verticalCenter
                            checked: settings.show_home_distance
                            onCheckedChanged: settings.show_home_distance = checked
                        }
                    }

                    Rectangle {
                        width: parent.width
                        height: rowHeight
                        color: (Positioner.index % 2 == 0) ? "#8cbfd7f3" : "#00000000"

                        Text {
                            text: qsTr("Show Flight Timer")
                            font.weight: Font.Bold
                            font.pixelSize: 13
                            anchors.leftMargin: 8
                            verticalAlignment: Text.AlignVCenter
                            anchors.verticalCenter: parent.verticalCenter
                            width: 224
                            height: elementHeight
                            anchors.left: parent.left
                        }

                        Switch {
                            width: 32
                            height: elementHeight
                            anchors.rightMargin: Qt.inputMethod.visible ? 96 : 36

                            anchors.right: parent.right
                            anchors.verticalCenter: parent.verticalCenter
                            checked: settings.show_flight_timer
                            onCheckedChanged: settings.show_flight_timer = checked
                        }
                    }

                    Rectangle {
                        width: parent.width
                        height: rowHeight
                        color: (Positioner.index % 2 == 0) ? "#8cbfd7f3" : "#00000000"

                        Text {
                            text: qsTr("Show Flight Mode")
                            font.weight: Font.Bold
                            font.pixelSize: 13
                            anchors.leftMargin: 8
                            verticalAlignment: Text.AlignVCenter
                            anchors.verticalCenter: parent.verticalCenter
                            width: 224
                            height: elementHeight
                            anchors.left: parent.left
                        }

                        Switch {
                            width: 32
                            height: elementHeight
                            anchors.rightMargin: Qt.inputMethod.visible ? 96 : 36

                            anchors.right: parent.right
                            anchors.verticalCenter: parent.verticalCenter
                            checked: settings.show_flight_mode
                            onCheckedChanged: settings.show_flight_mode = checked
                        }
                    }

                    Rectangle {
                        width: parent.width
                        height: rowHeight
                        color: (Positioner.index % 2 == 0) ? "#8cbfd7f3" : "#00000000"

                        Text {
                            text: qsTr("Show IMU Sensor Temperature")
                            font.weight: Font.Bold
                            font.pixelSize: 13
                            anchors.leftMargin: 8
                            verticalAlignment: Text.AlignVCenter
                            anchors.verticalCenter: parent.verticalCenter
                            width: 224
                            height: elementHeight
                            anchors.left: parent.left
                        }

                        Switch {
                            width: 32
                            height: elementHeight
                            anchors.rightMargin: Qt.inputMethod.visible ? 96 : 36

                            anchors.right: parent.right
                            anchors.verticalCenter: parent.verticalCenter
                            checked: settings.show_imu_temp
                            onCheckedChanged: settings.show_imu_temp = checked
                        }
                    }

                    Rectangle {
                        width: parent.width
                        height: rowHeight
                        color: (Positioner.index % 2 == 0) ? "#8cbfd7f3" : "#00000000"

                        Text {
                            text: qsTr("Show Pressure Sensor Temperature")
                            font.weight: Font.Bold
                            font.pixelSize: 13
                            anchors.leftMargin: 8
                            verticalAlignment: Text.AlignVCenter
                            anchors.verticalCenter: parent.verticalCenter
                            width: 224
                            height: elementHeight
                            anchors.left: parent.left
                        }

                        Switch {
                            width: 32
                            height: elementHeight
                            anchors.rightMargin: Qt.inputMethod.visible ? 96 : 36

                            anchors.right: parent.right
                            anchors.verticalCenter: parent.verticalCenter
                            checked: settings.show_press_temp
                            onCheckedChanged: settings.show_press_temp = checked
                        }
                    }

                    Rectangle {
                        width: parent.width
                        height: rowHeight
                        color: (Positioner.index % 2 == 0) ? "#8cbfd7f3" : "#00000000"

                        Text {
                            text: qsTr("Show Esc Temperature")
                            font.weight: Font.Bold
                            font.pixelSize: 13
                            anchors.leftMargin: 8
                            verticalAlignment: Text.AlignVCenter
                            anchors.verticalCenter: parent.verticalCenter
                            width: 224
                            height: elementHeight
                            anchors.left: parent.left
                        }

                        Switch {
                            width: 32
                            height: elementHeight
                            anchors.rightMargin: Qt.inputMethod.visible ? 96 : 36

                            anchors.right: parent.right
                            anchors.verticalCenter: parent.verticalCenter
                            checked: settings.show_esc_temp
                            onCheckedChanged: settings.show_esc_temp = checked
                        }
                    }

                    Rectangle {
                        width: parent.width
                        height: rowHeight
                        color: (Positioner.index % 2 == 0) ? "#8cbfd7f3" : "#00000000"

                        Text {
                            text: qsTr("Show Ground Status")
                            font.weight: Font.Bold
                            font.pixelSize: 13
                            anchors.leftMargin: 8
                            verticalAlignment: Text.AlignVCenter
                            anchors.verticalCenter: parent.verticalCenter
                            width: 224
                            height: elementHeight
                            anchors.left: parent.left
                        }

                        Switch {
                            width: 32
                            height: elementHeight
                            anchors.rightMargin: Qt.inputMethod.visible ? 96 : 36

                            anchors.right: parent.right
                            anchors.verticalCenter: parent.verticalCenter
                            checked: settings.show_ground_status
                            onCheckedChanged: settings.show_ground_status = checked
                        }
                    }

                    Rectangle {
                        width: parent.width
                        height: rowHeight
                        color: (Positioner.index % 2 == 0) ? "#8cbfd7f3" : "#00000000"

                        Text {
                            text: qsTr("Show Ground Battery")
                            font.weight: Font.Bold
                            font.pixelSize: 13
                            anchors.leftMargin: 8
                            verticalAlignment: Text.AlignVCenter
                            anchors.verticalCenter: parent.verticalCenter
                            width: 224
                            height: elementHeight
                            anchors.left: parent.left
                        }

                        Switch {
                            width: 32
                            height: elementHeight
                            anchors.rightMargin: Qt.inputMethod.visible ? 96 : 36

                            anchors.right: parent.right
                            anchors.verticalCenter: parent.verticalCenter
                            checked: settings.show_ground_battery
                            onCheckedChanged: settings.show_ground_battery = checked
                        }
                    }

                    Rectangle {
                        width: parent.width
                        height: rowHeight
                        color: (Positioner.index % 2 == 0) ? "#8cbfd7f3" : "#00000000"

                        Text {
                            text: qsTr("Show Air Status")
                            font.weight: Font.Bold
                            font.pixelSize: 13
                            anchors.leftMargin: 8
                            verticalAlignment: Text.AlignVCenter
                            anchors.verticalCenter: parent.verticalCenter
                            width: 224
                            height: elementHeight
                            anchors.left: parent.left
                        }

                        Switch {
                            width: 32
                            height: elementHeight
                            anchors.rightMargin: Qt.inputMethod.visible ? 96 : 36

                            anchors.right: parent.right
                            anchors.verticalCenter: parent.verticalCenter
                            checked: settings.show_air_status
                            onCheckedChanged: settings.show_air_status = checked
                        }
                    }

                    Rectangle {
                        width: parent.width
                        height: rowHeight
                        color: (Positioner.index % 2 == 0) ? "#8cbfd7f3" : "#00000000"

                        Text {
                            text: qsTr("Show Air Battery")
                            font.weight: Font.Bold
                            font.pixelSize: 13
                            anchors.leftMargin: 8
                            verticalAlignment: Text.AlignVCenter
                            anchors.verticalCenter: parent.verticalCenter
                            width: 224
                            height: elementHeight
                            anchors.left: parent.left
                        }

                        Switch {
                            width: 32
                            height: elementHeight
                            anchors.rightMargin: Qt.inputMethod.visible ? 96 : 36

                            anchors.right: parent.right
                            anchors.verticalCenter: parent.verticalCenter
                            checked: settings.show_air_battery
                            onCheckedChanged: settings.show_air_battery = checked
                        }
                    }

                    Rectangle {
                        width: parent.width
                        height: rowHeight
                        color: (Positioner.index % 2 == 0) ? "#8cbfd7f3" : "#00000000"

                        Text {
                            text: qsTr("Show mAh")
                            font.weight: Font.Bold
                            font.pixelSize: 13
                            anchors.leftMargin: 8
                            verticalAlignment: Text.AlignVCenter
                            anchors.verticalCenter: parent.verticalCenter
                            width: 224
                            height: elementHeight
                            anchors.left: parent.left
                        }

                        Switch {
                            width: 32
                            height: elementHeight
                            anchors.rightMargin: Qt.inputMethod.visible ? 96 : 36

                            anchors.right: parent.right
                            anchors.verticalCenter: parent.verticalCenter
                            checked: settings.show_flight_mah
                            onCheckedChanged: settings.show_flight_mah = checked
                        }
                    }

                    Rectangle {
                        width: parent.width
                        height: rowHeight
                        color: (Positioner.index % 2 == 0) ? "#8cbfd7f3" : "#00000000"

                        Text {
                            text: qsTr("Show Efficiency in mAh/km")
                            font.weight: Font.Bold
                            font.pixelSize: 13
                            anchors.leftMargin: 8
                            verticalAlignment: Text.AlignVCenter
                            anchors.verticalCenter: parent.verticalCenter
                            width: 224
                            height: elementHeight
                            anchors.left: parent.left
                        }

                        Switch {
                            width: 32
                            height: elementHeight
                            anchors.rightMargin: Qt.inputMethod.visible ? 96 : 36

                            anchors.right: parent.right
                            anchors.verticalCenter: parent.verticalCenter
                            checked: settings.show_flight_mah_km
                            onCheckedChanged: settings.show_flight_mah_km = checked
                        }
                    }

                    Rectangle {
                        width: parent.width
                        height: rowHeight
                        color: (Positioner.index % 2 == 0) ? "#8cbfd7f3" : "#00000000"

                        Text {
                            text: qsTr("Show Total Flight Distance")
                            font.weight: Font.Bold
                            font.pixelSize: 13
                            anchors.leftMargin: 8
                            verticalAlignment: Text.AlignVCenter
                            anchors.verticalCenter: parent.verticalCenter
                            width: 224
                            height: elementHeight
                            anchors.left: parent.left
                        }

                        Switch {
                            width: 32
                            height: elementHeight
                            anchors.rightMargin: Qt.inputMethod.visible ? 96 : 36

                            anchors.right: parent.right
                            anchors.verticalCenter: parent.verticalCenter
                            checked: settings.show_flight_distance
                            onCheckedChanged: settings.show_flight_distance = checked
                        }
                    }

                    Rectangle {
                        width: parent.width
                        height: rowHeight
                        color: (Positioner.index % 2 == 0) ? "#8cbfd7f3" : "#00000000"

                        Text {
                            text: qsTr("Show log messages on-screen")
                            font.weight: Font.Bold
                            font.pixelSize: 13
                            anchors.leftMargin: 8
                            verticalAlignment: Text.AlignVCenter
                            anchors.verticalCenter: parent.verticalCenter
                            width: 224
                            height: elementHeight
                            anchors.left: parent.left
                        }

                        Switch {
                            width: 32
                            height: elementHeight
                            anchors.rightMargin: Qt.inputMethod.visible ? 96 : 36

                            anchors.right: parent.right
                            anchors.verticalCenter: parent.verticalCenter
                            checked: settings.show_message_hud
                            onCheckedChanged: settings.show_message_hud = checked
                        }
                    }

                    Rectangle {
                        width: parent.width
                        height: rowHeight
                        color: (Positioner.index % 2 == 0) ? "#8cbfd7f3" : "#00000000"

                        Text {
                            text: qsTr("Show Horizon")
                            font.weight: Font.Bold
                            font.pixelSize: 13
                            anchors.leftMargin: 8
                            verticalAlignment: Text.AlignVCenter
                            anchors.verticalCenter: parent.verticalCenter
                            width: 224
                            height: elementHeight
                            anchors.left: parent.left
                        }

                        Switch {
                            width: 32
                            height: elementHeight
                            anchors.rightMargin: Qt.inputMethod.visible ? 96 : 36

                            anchors.right: parent.right
                            anchors.verticalCenter: parent.verticalCenter
                            checked: settings.show_horizon
                            onCheckedChanged: settings.show_horizon = checked
                        }
                    }

                    Rectangle {
                        width: parent.width
                        height: rowHeight
                        color: (Positioner.index % 2 == 0) ? "#8cbfd7f3" : "#00000000"

                        Text {
                            text: qsTr("Show Flight Path Vector")
                            font.weight: Font.Bold
                            font.pixelSize: 13
                            anchors.leftMargin: 8
                            verticalAlignment: Text.AlignVCenter
                            anchors.verticalCenter: parent.verticalCenter
                            width: 224
                            height: elementHeight
                            anchors.left: parent.left
                        }

                        Switch {
                            width: 32
                            height: elementHeight
                            anchors.rightMargin: Qt.inputMethod.visible ? 96 : 36

                            anchors.right: parent.right
                            anchors.verticalCenter: parent.verticalCenter
                            checked: settings.show_fpv
                            onCheckedChanged: settings.show_fpv = checked
                        }
                    }

                    Rectangle {
                        width: parent.width
                        height: rowHeight
                        color: (Positioner.index % 2 == 0) ? "#8cbfd7f3" : "#00000000"

                        Text {
                            text: qsTr("Show Altitude")
                            font.weight: Font.Bold
                            font.pixelSize: 13
                            anchors.leftMargin: 8
                            verticalAlignment: Text.AlignVCenter
                            anchors.verticalCenter: parent.verticalCenter
                            width: 224
                            height: elementHeight
                            anchors.left: parent.left
                        }

                        Switch {
                            width: 32
                            height: elementHeight
                            anchors.rightMargin: Qt.inputMethod.visible ? 96 : 36

                            anchors.right: parent.right
                            anchors.verticalCenter: parent.verticalCenter
                            checked: settings.show_altitude
                            onCheckedChanged: settings.show_altitude = checked
                        }
                    }

                    Rectangle {
                        width: parent.width
                        height: rowHeight
                        color: (Positioner.index % 2 == 0) ? "#8cbfd7f3" : "#00000000"

                        Text {
                            text: qsTr("Show Speed")
                            font.weight: Font.Bold
                            font.pixelSize: 13
                            anchors.leftMargin: 8
                            verticalAlignment: Text.AlignVCenter
                            anchors.verticalCenter: parent.verticalCenter
                            width: 224
                            height: elementHeight
                            anchors.left: parent.left
                        }

                        Switch {
                            width: 32
                            height: elementHeight
                            anchors.rightMargin: Qt.inputMethod.visible ? 96 : 36

                            anchors.right: parent.right
                            anchors.verticalCenter: parent.verticalCenter
                            checked: settings.show_speed
                            onCheckedChanged: settings.show_speed = checked
                        }
                    }

                    Rectangle {
                        width: parent.width
                        height: rowHeight
                        color: (Positioner.index % 2 == 0) ? "#8cbfd7f3" : "#00000000"

                        Text {
                            text: qsTr("Show Second Speed")
                            font.weight: Font.Bold
                            font.pixelSize: 13
                            anchors.leftMargin: 8
                            verticalAlignment: Text.AlignVCenter
                            anchors.verticalCenter: parent.verticalCenter
                            width: 224
                            height: elementHeight
                            anchors.left: parent.left
                        }

                        Switch {
                            width: 32
                            height: elementHeight
                            anchors.rightMargin: Qt.inputMethod.visible ? 96 : 36

                            anchors.right: parent.right
                            anchors.verticalCenter: parent.verticalCenter
                            checked: settings.show_speed_second
                            onCheckedChanged: settings.show_speed_second = checked
                        }
                    }

                    Rectangle {
                        width: parent.width
                        height: rowHeight
                        color: (Positioner.index % 2 == 0) ? "#8cbfd7f3" : "#00000000"

                        Text {
                            text: qsTr("Show Heading")
                            font.weight: Font.Bold
                            font.pixelSize: 13
                            anchors.leftMargin: 8
                            verticalAlignment: Text.AlignVCenter
                            anchors.verticalCenter: parent.verticalCenter
                            width: 224
                            height: elementHeight
                            anchors.left: parent.left
                        }

                        Switch {
                            width: 32
                            height: elementHeight
                            anchors.rightMargin: Qt.inputMethod.visible ? 96 : 36

                            anchors.right: parent.right
                            anchors.verticalCenter: parent.verticalCenter
                            checked: settings.show_heading
                            onCheckedChanged: settings.show_heading = checked
                        }
                    }

                    Rectangle {
                        width: parent.width
                        height: rowHeight
                        color: (Positioner.index % 2 == 0) ? "#8cbfd7f3" : "#00000000"

                        Text {
                            text: qsTr("Show Second Altitude")
                            font.weight: Font.Bold
                            font.pixelSize: 13
                            anchors.leftMargin: 8
                            verticalAlignment: Text.AlignVCenter
                            anchors.verticalCenter: parent.verticalCenter
                            width: 224
                            height: elementHeight
                            anchors.left: parent.left
                        }

                        Switch {
                            width: 32
                            height: elementHeight
                            anchors.rightMargin: Qt.inputMethod.visible ? 96 : 36

                            anchors.right: parent.right
                            anchors.verticalCenter: parent.verticalCenter
                            checked: settings.show_altitude_second
                            onCheckedChanged: settings.show_altitude_second = checked
                        }
                    }

                    Rectangle {
                        width: parent.width
                        height: rowHeight
                        color: (Positioner.index % 2 == 0) ? "#8cbfd7f3" : "#00000000"

                        Text {
                            text: qsTr("Show Bank Angle Indicator")
                            font.weight: Font.Bold
                            font.pixelSize: 13
                            anchors.leftMargin: 8
                            verticalAlignment: Text.AlignVCenter
                            anchors.verticalCenter: parent.verticalCenter
                            width: 224
                            height: elementHeight
                            anchors.left: parent.left
                        }

                        Switch {
                            width: 32
                            height: elementHeight
                            anchors.rightMargin: Qt.inputMethod.visible ? 96 : 36

                            anchors.right: parent.right
                            anchors.verticalCenter: parent.verticalCenter
                            checked: settings.show_roll
                            onCheckedChanged: settings.show_roll = checked
                        }
                    }

                    Rectangle {
                        width: parent.width
                        height: rowHeight
                        color: (Positioner.index % 2 == 0) ? "#8cbfd7f3" : "#00000000"

                        Text {
                            text: qsTr("Show Home Arrow")
                            font.weight: Font.Bold
                            font.pixelSize: 13
                            anchors.leftMargin: 8
                            verticalAlignment: Text.AlignVCenter
                            anchors.verticalCenter: parent.verticalCenter
                            width: 224
                            height: elementHeight
                            anchors.left: parent.left
                        }

                        Switch {
                            width: 32
                            height: elementHeight
                            anchors.rightMargin: Qt.inputMethod.visible ? 96 : 36

                            anchors.right: parent.right
                            anchors.verticalCenter: parent.verticalCenter
                            checked: settings.show_arrow
                            onCheckedChanged: settings.show_arrow = checked
                        }
                    }

                    Rectangle {
                        width: parent.width
                        height: rowHeight
                        color: (Positioner.index % 2 == 0) ? "#8cbfd7f3" : "#00000000"

                        Text {
                            text: qsTr("Show Map")
                            font.weight: Font.Bold
                            font.pixelSize: 13
                            anchors.leftMargin: 8
                            verticalAlignment: Text.AlignVCenter
                            anchors.verticalCenter: parent.verticalCenter
                            width: 224
                            height: elementHeight
                            anchors.left: parent.left
                        }

                        Switch {
                            width: 32
                            height: elementHeight
                            anchors.rightMargin: Qt.inputMethod.visible ? 96 : 36

                            anchors.right: parent.right
                            anchors.verticalCenter: parent.verticalCenter
                            checked: settings.show_map
                            onCheckedChanged: settings.show_map = checked
                        }
                    }

                    Rectangle {
                        width: parent.width
                        height: rowHeight
                        color: (Positioner.index % 2 == 0) ? "#8cbfd7f3" : "#00000000"

                        Text {
                            text: qsTr("Show Throttle")
                            font.weight: Font.Bold
                            font.pixelSize: 13
                            anchors.leftMargin: 8
                            verticalAlignment: Text.AlignVCenter
                            anchors.verticalCenter: parent.verticalCenter
                            width: 224
                            height: elementHeight
                            anchors.left: parent.left
                        }

                        Switch {
                            width: 32
                            height: elementHeight
                            anchors.rightMargin: Qt.inputMethod.visible ? 96 : 36

                            anchors.right: parent.right
                            anchors.verticalCenter: parent.verticalCenter
                            checked: settings.show_throttle
                            onCheckedChanged: settings.show_throttle = checked
                        }
                    }

                    Rectangle {
                        width: parent.width
                        height: rowHeight
                        color: (Positioner.index % 2 == 0) ? "#8cbfd7f3" : "#00000000"

                        Text {
                            text: qsTr("Show Control Inputs")
                            font.weight: Font.Bold
                            font.pixelSize: 13
                            anchors.leftMargin: 8
                            verticalAlignment: Text.AlignVCenter
                            anchors.verticalCenter: parent.verticalCenter
                            width: 224
                            height: elementHeight
                            anchors.left: parent.left
                        }

                        Switch {
                            width: 32
                            height: elementHeight
                            anchors.rightMargin: Qt.inputMethod.visible ? 96 : 36

                            anchors.right: parent.right
                            anchors.verticalCenter: parent.verticalCenter
                            checked: settings.show_control
                            onCheckedChanged: settings.show_control = checked
                        }
                    }

                    Rectangle {
                        width: parent.width
                        height: rowHeight
                        color: (Positioner.index % 2 == 0) ? "#8cbfd7f3" : "#00000000"

                        Text {
                            text: qsTr("Show GPIO")
                            font.weight: Font.Bold
                            font.pixelSize: 13
                            anchors.leftMargin: 8
                            verticalAlignment: Text.AlignVCenter
                            anchors.verticalCenter: parent.verticalCenter
                            width: 224
                            height: elementHeight
                            anchors.left: parent.left
                        }

                        Switch {
                            width: 32
                            height: elementHeight
                            anchors.rightMargin: Qt.inputMethod.visible ? 96 : 36

                            anchors.right: parent.right
                            anchors.verticalCenter: parent.verticalCenter
                            checked: settings.show_gpio
                            onCheckedChanged: settings.show_gpio = checked
                        }
                    }

                    Rectangle {
                        width: parent.width
                        height: rowHeight
                        color: (Positioner.index % 2 == 0) ? "#8cbfd7f3" : "#00000000"

                        Text {
                            text: qsTr("Show Vibration")
                            font.weight: Font.Bold
                            font.pixelSize: 13
                            anchors.leftMargin: 8
                            verticalAlignment: Text.AlignVCenter
                            anchors.verticalCenter: parent.verticalCenter
                            width: 224
                            height: elementHeight
                            anchors.left: parent.left
                        }

                        Switch {
                            width: 32
                            height: elementHeight
                            anchors.rightMargin: Qt.inputMethod.visible ? 96 : 36

                            anchors.right: parent.right
                            anchors.verticalCenter: parent.verticalCenter
                            checked: settings.show_vibration
                            onCheckedChanged: settings.show_vibration = checked
                        }
                    }

                    Rectangle {
                        width: parent.width
                        height: rowHeight
                        color: (Positioner.index % 2 == 0) ? "#8cbfd7f3" : "#00000000"

                        Text {
                            text: qsTr("Show Vertical Speed")
                            font.weight: Font.Bold
                            font.pixelSize: 13
                            anchors.leftMargin: 8
                            verticalAlignment: Text.AlignVCenter
                            anchors.verticalCenter: parent.verticalCenter
                            width: 224
                            height: elementHeight
                            anchors.left: parent.left
                        }

                        Switch {
                            width: 32
                            height: elementHeight
                            anchors.rightMargin: Qt.inputMethod.visible ? 96 : 36

                            anchors.right: parent.right
                            anchors.verticalCenter: parent.verticalCenter
                            checked: settings.show_vsi
                            onCheckedChanged: settings.show_vsi = checked
                        }
                    }
                    Rectangle {
                        width: parent.width
                        height: rowHeight
                        color: (Positioner.index % 2 == 0) ? "#8cbfd7f3" : "#00000000"

                        Text {
                            text: qsTr("Show Wind (Experimental)")
                            font.weight: Font.Bold
                            font.pixelSize: 13
                            anchors.leftMargin: 8
                            verticalAlignment: Text.AlignVCenter
                            anchors.verticalCenter: parent.verticalCenter
                            width: 224
                            height: elementHeight
                            anchors.left: parent.left
                        }

                        Switch {
                            width: 32
                            height: elementHeight
                            anchors.rightMargin: Qt.inputMethod.visible ? 96 : 36

                            anchors.right: parent.right
                            anchors.verticalCenter: parent.verticalCenter
                            checked: settings.show_wind
                            onCheckedChanged: settings.show_wind = checked
                        }
                    }

                    Rectangle {
                        width: parent.width
                        height: rowHeight
                        color: (Positioner.index % 2 == 0) ? "#8cbfd7f3" : "#00000000"

                        Text {
                            text: qsTr("Show Missions")
                            font.weight: Font.Bold
                            font.pixelSize: 13
                            anchors.leftMargin: 8
                            verticalAlignment: Text.AlignVCenter
                            anchors.verticalCenter: parent.verticalCenter
                            width: 224
                            height: elementHeight
                            anchors.left: parent.left
                        }

                        Switch {
                            width: 32
                            height: elementHeight
                            anchors.rightMargin: Qt.inputMethod.visible ? 96 : 36

                            anchors.right: parent.right
                            anchors.verticalCenter: parent.verticalCenter
                            checked: settings.show_mission
                            onCheckedChanged: {
                                settings.show_mission = checked;
                            }
                        }
                    }
                    Rectangle {
                        width: parent.width
                        height: rowHeight
                        color: (Positioner.index % 2 == 0) ? "#8cbfd7f3" : "#00000000"

                        Text {
                            text: qsTr("Show QT Render stats")
                            font.weight: Font.Bold
                            font.pixelSize: 13
                            anchors.leftMargin: 8
                            verticalAlignment: Text.AlignVCenter
                            anchors.verticalCenter: parent.verticalCenter
                            width: 224
                            height: elementHeight
                            anchors.left: parent.left
                        }

                        Switch {
                            width: 32
                            height: elementHeight
                            anchors.rightMargin: Qt.inputMethod.visible ? 96 : 36

                            anchors.right: parent.right
                            anchors.verticalCenter: parent.verticalCenter
                            checked: settings.qrenderstats_show
                            onCheckedChanged: {
                                settings.qrenderstats_show = checked;
                            }
                        }
                    }
                }
            }
        }

        ScrollView {
            id: screenView
            width: parent.width
            height: parent.height
            contentHeight: piColumn.height
            visible: appSettingsBar.currentIndex == 3

            clip: true

            Item {
                anchors.fill: parent

                Column {
                    id: piColumn
                    spacing: 0
                    anchors.left: parent.left
                    anchors.right: parent.right

                    Rectangle {
                        width: parent.width
                        height: rowHeight
                        color: (Positioner.index % 2 == 0) ? "#8cbfd7f3" : "#00000000"

                        Text {
                            text: qsTr("Screen Scale")
                            font.weight: Font.Bold
                            font.pixelSize: 13
                            anchors.leftMargin: 8
                            verticalAlignment: Text.AlignVCenter
                            anchors.verticalCenter: parent.verticalCenter
                            width: 224
                            height: elementHeight
                            anchors.left: parent.left
                        }

                        Text {
                            text: Number(settings.global_scale).toLocaleString(Qt.locale(), 'f', 1) + "x";
                            font.pixelSize: 16
                            anchors.right: screenScaleSpinBox.left
                            anchors.rightMargin: 12
                            verticalAlignment: Text.AlignVCenter
                            anchors.verticalCenter: parent.verticalCenter
                            width: 32
                            height: elementHeight

                        }

                        Slider {
                            id: screenScaleSpinBox
                            height: elementHeight
                            width: 210
                            font.pixelSize: 14
                            anchors.right: parent.right
                            anchors.verticalCenter: parent.verticalCenter
                            to : 2.0
                            from : 1.0

                            anchors.rightMargin: Qt.inputMethod.visible ? 78 : 18
                            value: settings.global_scale

                            // @disable-check M223
                            onValueChanged: {
                                // @disable-check M222
                                settings.global_scale = value
                            }
                        }
                    }

                    Rectangle {
                        width: parent.width
                        height: rowHeight
                        color: (Positioner.index % 2 == 0) ? "#8cbfd7f3" : "#00000000"
                        visible: OpenHDPi.is_raspberry_pi

                        Text {
                            text: qsTr("Brightness")
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
                            id: screenBrightnessSpinBox
                            height: elementHeight
                            width: 210
                            font.pixelSize: 14
                            anchors.right: parent.right
                            anchors.verticalCenter: parent.verticalCenter
                            from: 0
                            to: 255
                            stepSize: 5
                            anchors.rightMargin: Qt.inputMethod.visible ? 78 : 18

                            Component.onCompleted: value = OpenHDPi.brightness
                            // @disable-check M223
                            onValueChanged: {
                                OpenHDPi.brightness = value
                                // @disable-check M222
                                settings.setValue("brightness", value)
                            }
                        }


                    }
                }
            }
        }

        ScrollView {
            id: videoView
            width: parent.width
            height: parent.height
            contentHeight: videoColumn.height

            clip: true
            visible: (EnableMainVideo || EnablePiP) && appSettingsBar.currentIndex == 4


            Item {
                anchors.fill: parent

                Column {
                    id: videoColumn
                    spacing: 0
                    anchors.left: parent.left
                    anchors.right: parent.right

                    Rectangle {
                        width: parent.width
                        height: rowHeight
                        color: (Positioner.index % 2 == 0) ? "#8cbfd7f3" : "#00000000"
                        visible: EnableGStreamer

                        Text {
                            text: qsTr("Always use software video decoder")
                            font.weight: Font.Bold
                            font.pixelSize: 13
                            anchors.leftMargin: 8
                            verticalAlignment: Text.AlignVCenter
                            anchors.verticalCenter: parent.verticalCenter
                            width: 224
                            height: elementHeight
                            anchors.left: parent.left
                        }

                        Switch {
                            width: 32
                            height: elementHeight
                            anchors.rightMargin: Qt.inputMethod.visible ? 96 : 36

                            anchors.right: parent.right
                            anchors.verticalCenter: parent.verticalCenter
                            checked: settings.enable_software_video_decoder
                            onCheckedChanged: settings.enable_software_video_decoder = checked
                        }
                    }

                    Rectangle {
                        width: parent.width
                        height: rowHeight
                        color: (Positioner.index % 2 == 0) ? "#8cbfd7f3" : "#00000000"
                        visible: true
                        Text {
                            text: qsTr("Video Codec")
                            font.weight: Font.Bold
                            font.pixelSize: 13
                            anchors.leftMargin: 8
                            verticalAlignment: Text.AlignVCenter
                            anchors.verticalCenter: parent.verticalCenter
                            width: 224
                            height: elementHeight
                            anchors.left: parent.left
                        }

                        ComboBox {
                          id: selectVideoCodecPrimary
                          width: 320
                          height: elementHeight
                          anchors.right: parent.right
                          anchors.rightMargin: Qt.inputMethod.visible ? 96 : 36
                          anchors.verticalCenter: parent.verticalCenter
                          anchors.horizontalCenter: parent.horizonatalCenter
                          model: ListModel {
                           id: cbItems
                           ListElement { text: "H264"; }
                           ListElement { text: "H265";  }
                           ListElement { text: "MJPEG"; }
                         }
                          Component.onCompleted: {
                              // out of bounds checking
                              if(settings.selectedVideoCodecPrimary>2 || settings.selectedVideoCodecPrimary<0){
                                  settings.selectedVideoCodecPrimary=0;
                              }
                              currentIndex = settings.selectedVideoCodecPrimary;
                          }
                         onCurrentIndexChanged:{
                             console.debug("VideoCodec:"+cbItems.get(currentIndex).text + ", "+currentIndex)
                             settings.selectedVideoCodecPrimary=currentIndex;
                         }
                        }
                    }

                    Rectangle {
                        width: parent.width
                        height: rowHeight
                        color: (Positioner.index % 2 == 0) ? "#8cbfd7f3" : "#00000000"
                        visible: EnablePiP

                        Text {
                            text: qsTr("Enable PiP")
                            font.weight: Font.Bold
                            font.pixelSize: 13
                            anchors.leftMargin: 8
                            verticalAlignment: Text.AlignVCenter
                            anchors.verticalCenter: parent.verticalCenter
                            width: 224
                            height: elementHeight
                            anchors.left: parent.left
                        }

                        Switch {
                            width: 32
                            height: elementHeight
                            anchors.rightMargin: Qt.inputMethod.visible ? 96 : 36

                            anchors.right: parent.right
                            anchors.verticalCenter: parent.verticalCenter
                            checked: settings.show_pip_video
                            onCheckedChanged: settings.show_pip_video = checked
                        }
                    }

                    Rectangle {
                        width: parent.width
                        height: rowHeight
                        color: (Positioner.index % 2 == 0) ? "#8cbfd7f3" : "#00000000"

                        Text {
                            text: qsTr("Enable LTE")
                            font.weight: Font.Bold
                            font.pixelSize: 13
                            anchors.leftMargin: 8
                            verticalAlignment: Text.AlignVCenter
                            anchors.verticalCenter: parent.verticalCenter
                            width: 224
                            height: elementHeight
                            anchors.left: parent.left
                        }

                        Switch {
                            width: 32
                            height: elementHeight
                            anchors.rightMargin: Qt.inputMethod.visible ? 96 : 36

                            anchors.right: parent.right
                            anchors.verticalCenter: parent.verticalCenter
                            checked: settings.enable_lte_video
                            onCheckedChanged: settings.enable_lte_video = checked
                        }
                    }

                    Rectangle {
                        width: parent.width
                        height: rowHeight
                        color: (Positioner.index % 2 == 0) ? "#8cbfd7f3" : "#00000000"
                        visible: EnableMainVideo

                        Text {
                            text: qsTr("Hide warning watermark")
                            font.weight: Font.Bold
                            font.pixelSize: 13
                            anchors.leftMargin: 8
                            verticalAlignment: Text.AlignVCenter
                            anchors.verticalCenter: parent.verticalCenter
                            width: 224
                            height: elementHeight
                            anchors.left: parent.left
                        }

                        Switch {
                            width: 32
                            height: elementHeight
                            anchors.rightMargin: Qt.inputMethod.visible ? 96 : 36

                            anchors.right: parent.right
                            anchors.verticalCenter: parent.verticalCenter
                            checked: settings.hide_watermark
                            onCheckedChanged: settings.hide_watermark = checked
                        }
                    }

                    Rectangle {
                        width: parent.width
                        height: rowHeight
                        color: (Positioner.index % 2 == 0) ? "#8cbfd7f3" : "#00000000"
                        visible: true

                        Text {
                            text: qsTr("Background Transparent")
                            font.weight: Font.Bold
                            font.pixelSize: 13
                            anchors.leftMargin: 8
                            verticalAlignment: Text.AlignVCenter
                            anchors.verticalCenter: parent.verticalCenter
                            width: 224
                            height: elementHeight
                            anchors.left: parent.left
                        }

                        Switch {
                            width: 32
                            height: elementHeight
                            anchors.rightMargin: Qt.inputMethod.visible ? 96 : 36

                            anchors.right: parent.right
                            anchors.verticalCenter: parent.verticalCenter
                            checked: settings.app_background_transparent
                            onCheckedChanged: settings.app_background_transparent = checked
                        }
                    }

                    Rectangle {
                        width: parent.width
                        height: rowHeight
                        color: (Positioner.index % 2 == 0) ? "#8cbfd7f3" : "#00000000"

                        Text {
                            text: qsTr("DEV_TEST_VIDEO_MODE")
                            font.weight: Font.Bold
                            font.pixelSize: 13
                            anchors.leftMargin: 8
                            verticalAlignment: Text.AlignVCenter
                            anchors.verticalCenter: parent.verticalCenter
                            width: 224
                            height: elementHeight
                            anchors.left: parent.left
                        }
                        ComboBox {
                          width: 320
                          height: elementHeight
                          anchors.right: parent.right
                          anchors.rightMargin: Qt.inputMethod.visible ? 96 : 36
                          anchors.verticalCenter: parent.verticalCenter
                          anchors.horizontalCenter: parent.horizonatalCenter
                          model: ListModel {
                           ListElement { text: "DISABLE"; }
                           ListElement { text: "RAW_VIDEO";  }
                           ListElement { text: "RAW_DECODE_ENCODE"; }
                         }
                          Component.onCompleted: {
                              // out of bounds checking
                              if(settings.dev_test_video_mode>2 || settings.dev_test_video_mode<0){
                                  settings.dev_test_video_mode=0;
                              }
                              currentIndex = settings.dev_test_video_mode;
                          }
                         onCurrentIndexChanged:{
                             console.debug("Dev video testing::"+cbItems.get(currentIndex).text + ", "+currentIndex)
                             settings.dev_test_video_mode=currentIndex;
                         }
                        }
                    }
                    // temporary
                    Rectangle {
                        width: parent.width
                        height: rowHeight
                        color: (Positioner.index % 2 == 0) ? "#8cbfd7f3" : "#00000000"

                        Text {
                            text: qsTr("DEV_JETSON")
                            font.weight: Font.Bold
                            font.pixelSize: 13
                            anchors.leftMargin: 8
                            verticalAlignment: Text.AlignVCenter
                            anchors.verticalCenter: parent.verticalCenter
                            width: 224
                            height: elementHeight
                            anchors.left: parent.left
                        }
                        Switch {
                            width: 32
                            height: elementHeight
                            anchors.rightMargin: Qt.inputMethod.visible ? 96 : 36
                            anchors.right: parent.right
                            anchors.verticalCenter: parent.verticalCenter
                            checked: settings.dev_jetson
                            onCheckedChanged: settings.dev_jetson = checked
                        }
                    }
                    Rectangle {
                        width: parent.width
                        height: rowHeight
                        color: (Positioner.index % 2 == 0) ? "#8cbfd7f3" : "#00000000"

                        Text {
                            text: qsTr("dev_limit_fps_on_test_file")
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
                            id: dev_limit_fps_on_test_fileSpinBox
                            height: elementHeight
                            width: 210
                            font.pixelSize: 14
                            anchors.right: parent.right
                            anchors.verticalCenter: parent.verticalCenter
                            from: -1
                            to: 240
                            stepSize: 1
                            editable: true
                            anchors.rightMargin: Qt.inputMethod.visible ? 78 : 18
                            value: settings.dev_limit_fps_on_test_file
                            onValueChanged: settings.dev_limit_fps_on_test_file = value
                        }
                    }
                    Rectangle {
                        width: parent.width
                        height: rowHeight
                        color: (Positioner.index % 2 == 0) ? "#8cbfd7f3" : "#00000000"

                        Text {
                            text: qsTr("dev_draw_alternating_rgb_dummy_frames")
                            font.weight: Font.Bold
                            font.pixelSize: 13
                            anchors.leftMargin: 8
                            verticalAlignment: Text.AlignVCenter
                            anchors.verticalCenter: parent.verticalCenter
                            width: 224
                            height: elementHeight
                            anchors.left: parent.left
                        }
                        Switch {
                            width: 32
                            height: elementHeight
                            anchors.rightMargin: Qt.inputMethod.visible ? 96 : 36
                            anchors.right: parent.right
                            anchors.verticalCenter: parent.verticalCenter
                            checked: settings.dev_draw_alternating_rgb_dummy_frames
                            onCheckedChanged: settings.dev_draw_alternating_rgb_dummy_frames = checked
                        }
                    }
                    // temporary end
                }
            }
        }

        ScrollView {
            id: manageView
            width: parent.width
            height: parent.height
            contentHeight: manageColumn.height
            visible: appSettingsBar.currentIndex == 5

            clip: true

            Item {
                anchors.fill: parent

                Column {
                    id: manageColumn
                    spacing: 0
                    anchors.left: parent.left
                    anchors.right: parent.right

                    //
                    Rectangle {
                        width: parent.width
                        height: rowHeight
                        color: (Positioner.index % 2 == 0) ? "#8cbfd7f3" : "#00000000"
                        visible: true
                        Text {
                            text: qsTr("DEV_SHOW_WHITELISTED_PARAMS")
                            font.weight: Font.Bold
                            font.pixelSize: 13
                            anchors.leftMargin: 8
                            verticalAlignment: Text.AlignVCenter
                            anchors.verticalCenter: parent.verticalCenter
                            width: 224
                            height: elementHeight
                            anchors.left: parent.left
                        }
                        Switch {
                            width: 32
                            height: elementHeight
                            anchors.rightMargin: Qt.inputMethod.visible ? 96 : 36

                            anchors.right: parent.right
                            anchors.verticalCenter: parent.verticalCenter
                            checked: settings.dev_show_whitelisted_params
                            onCheckedChanged: settings.dev_show_whitelisted_params = checked
                        }
                    }


                }
            }
        }
    }
}
