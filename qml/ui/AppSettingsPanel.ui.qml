import QtQuick 2.12
import QtQuick.Controls 2.12
import QtQuick.Layouts 1.12
import QtQuick.Controls.Material 2.12

import QtQuick.Dialogs 1.0

import Qt.labs.settings 1.0

import OpenHD 1.0

import "../ui" as Ui
import "elements";


/*
 * This file should be refactored in a way that isn't so fragile and verbose. The rows are
 * all manually defined and every one of them has a manually vertical offset to position it
 * inside the scroll view.
 *
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
            width: implicitWidth
            height: 48
            font.pixelSize: 13
        }


        /*TabButton {
            text: qsTr("Joystick")
            width: implicitWidth
            height: 48
            font.pixelSize: 13
        }*/
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
                            text: qsTr("Battery Cells")
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
                        visible: false

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
            id: widgetsView
            width: parent.width
            height: parent.height
            contentHeight: widgetColumn.height

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

                        ComboBox {
                            height: elementHeight
                            anchors.right: parent.right
                            anchors.rightMargin: Qt.inputMethod.visible ? 96 : 36
                            anchors.verticalCenter: parent.verticalCenter
                            anchors.horizontalCenter: parent.horizonatalCenter
                            model: ListModel {
                                id: color_shape
                                ListElement { text: "White"; color: "white" }
                                ListElement { text: "Black"; color: "black" }
                                ListElement { text: "Green"; color: "green" }
                                ListElement { text: "Drk Green"; color: "darkGreen" }
                                ListElement { text: "Yellow"; color: "yellow" }
                                ListElement { text: "Drk Yellow"; color: "darkYellow" }
                                ListElement { text: "Grey"; color: "grey" }
                                ListElement { text: "Lgt Grey"; color: "lightGrey" }
                                ListElement { text: "Drk Grey"; color: "darkGrey" }
                                ListElement { text: "Blue"; color: "blue" }
                                ListElement { text: "Red"; color: "red" }
                                ListElement { text: "Cyan"; color: "cyan" }
                            }
                            textRole: "text"
                            // @disable-check M223
                            Component.onCompleted: {
                                // @disable-check M223
                                for (var i = 0; i < model.count; i++) {
                                    // @disable-check M222
                                    var choice = model.get(i);
                                    // @disable-check M223
                                    if (choice.color == settings.color_shape) {
                                        currentIndex = i;
                                    }
                                }
                            }
                            onCurrentIndexChanged: {
                                    settings.color_shape = color_shape.get(currentIndex).color
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
                        
                        ComboBox {
                            height: elementHeight
                            anchors.right: parent.right
                            anchors.rightMargin: Qt.inputMethod.visible ? 96 : 36
                            anchors.verticalCenter: parent.verticalCenter
                            anchors.horizontalCenter: parent.horizonatalCenter
                            model: ListModel {
                                id: color_glow
                                ListElement { text: "Black"; color: "black" }
                                ListElement { text: "White"; color: "white" }
                                ListElement { text: "Green"; color: "green" }
                                ListElement { text: "Drk Green"; color: "darkGreen" }
                                ListElement { text: "Yellow"; color: "yellow" }
                                ListElement { text: "Drk Yellow"; color: "darkYellow" }
                                ListElement { text: "Grey"; color: "grey" }
                                ListElement { text: "Lgt Grey"; color: "lightGrey" }
                                ListElement { text: "Drk Grey"; color: "darkGrey" }
                                ListElement { text: "Blue"; color: "blue" }
                                ListElement { text: "Red"; color: "red" }
                                ListElement { text: "Cyan"; color: "cyan" }
                            }
                            textRole: "text"
                            // @disable-check M223
                            Component.onCompleted: {
                                // @disable-check M223
                                for (var i = 0; i < model.count; i++) {
                                    // @disable-check M222
                                    var choice = model.get(i);
                                    // @disable-check M223
                                    if (choice.color == settings.color_glow) {
                                        currentIndex = i;
                                    }
                                }
                            }
                            onCurrentIndexChanged: {
                                    settings.color_glow = color_glow.get(currentIndex).color
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

                        ComboBox {
                            height: elementHeight
                            anchors.right: parent.right
                            anchors.rightMargin: Qt.inputMethod.visible ? 96 : 36
                            anchors.verticalCenter: parent.verticalCenter
                            anchors.horizontalCenter: parent.horizonatalCenter
                            model: ListModel {
                                id: color_text
                                ListElement { text: "White"; color: "white" }
                                ListElement { text: "Black"; color: "black" }
                                ListElement { text: "Green"; color: "green" }
                                ListElement { text: "Drk Green"; color: "darkGreen" }
                                ListElement { text: "Yellow"; color: "yellow" }
                                ListElement { text: "Drk Yellow"; color: "darkYellow" }
                                ListElement { text: "Grey"; color: "grey" }
                                ListElement { text: "Lgt Grey"; color: "lightGrey" }
                                ListElement { text: "Drk Grey"; color: "darkGrey" }
                                ListElement { text: "Blue"; color: "blue" }
                                ListElement { text: "Red"; color: "red" }
                                ListElement { text: "Cyan"; color: "cyan" }
                            }
                            textRole: "text"
                            // @disable-check M223
                            Component.onCompleted: {
                                // @disable-check M223
                                for (var i = 0; i < model.count; i++) {
                                    // @disable-check M222
                                    var choice = model.get(i);
                                    // @disable-check M223
                                    if (choice.color == settings.color_text) {
                                        currentIndex = i;
                                    }
                                }
                            }
                            onCurrentIndexChanged: {
                                    settings.color_text = color_text.get(currentIndex).color
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
                                ListElement { text: "Hide" ; behavior: "none" }
                                ListElement { text: "Transparent black" ; behavior: "black" }
                                ListElement { text: "Hide when drone armed" ; behavior: "disappear" }
                                ListElement { text: "Turn red when drone armed" ; behavior: "red" }

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
                            text: qsTr("Show Flight Controller Temperature")
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
                            checked: settings.show_fc_temp
                            onCheckedChanged: settings.show_fc_temp = checked
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
                        visible: EnableADSB

                        Text {
                            text: "Show ADS-B Traffic"
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
                            checked: settings.show_adsb
                            onCheckedChanged: {
                                settings.show_adsb = checked;
                            }
                        }
                    }
                    Rectangle {
                        width: parent.width
                        height: rowHeight
                        color: (Positioner.index % 2 == 0) ? "#8cbfd7f3" : "#00000000"
                        visible: EnableBlackbox


                        Text {
                            text: "Show BlackBox"
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
                            checked: settings.show_blackbox
                            onCheckedChanged: {
                                settings.show_blackbox = checked;
                            }
                        }
                    }

                    Rectangle {
                        width: parent.width
                        height: rowHeight
                        color: (Positioner.index % 2 == 0) ? "#8cbfd7f3" : "#00000000"
                        visible: EnableExampleWidget

                        Text {
                            text: qsTr("Show example widget")
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
                            checked: settings.show_example_widget
                            onCheckedChanged: settings.show_example_widget = checked
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

                        Rectangle {
                            width: parent.width
                            height: rowHeight
                            color: (Positioner.index % 2 == 0) ? "#8cbfd7f3" : "#00000000"
                            visible: false

                            Text {
                                text: qsTr("Stereo OSD mode")
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
                                model: ListModel {
                                    id: stereo_list_model
                                    ListElement { text: "Off"; mode: 0 }
                                    ListElement { text: "Aspect Fit"; mode: 1  }
                                }
                                textRole: "text"
                                // @disable-check M223
                                Component.onCompleted: {
                                    // @disable-check M223
                                    for (var i = 0; i < model.count; i++) {
                                        // @disable-check M222
                                        var choice = model.get(i);
                                        // @disable-check M223
                                        if (choice.mode == settings.stereo_mode) {
                                            currentIndex = i;
                                        }
                                    }
                                }
                                onActivated: {
                                        settings.stereo_mode = stereo_list_model.get(currentIndex).mode
                                }
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
            visible: EnableMainVideo || EnablePiP


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
                }
            }
        }

        ScrollView {
            id: manageView
            width: parent.width
            height: parent.height
            contentHeight: manageColumn.height

            clip: true

            Item {
                anchors.fill: parent

                Column {
                    id: manageColumn
                    spacing: 0
                    anchors.left: parent.left
                    anchors.right: parent.right

                    Rectangle {
                        width: parent.width
                        height: rowHeight
                        color: (Positioner.index % 2 == 0) ? "#8cbfd7f3" : "#00000000"
                        visible: !IsRaspPi

                        Text {
                            text: qsTr("Load settings from file")
                            font.weight: Font.Bold
                            font.pixelSize: 13
                            anchors.leftMargin: 8
                            verticalAlignment: Text.AlignVCenter
                            anchors.verticalCenter: parent.verticalCenter
                            width: 224
                            height: elementHeight
                            anchors.left: parent.left
                        }

                        Button {
                            width: 128
                            height: elementHeight
                            anchors.rightMargin: Qt.inputMethod.visible ? 96 : 36

                            anchors.right: parent.right
                            anchors.verticalCenter: parent.verticalCenter
                            text: qsTr("Load")
                            onClicked: {
                                fileDialog.open();
                            }
                        }

                        FileDialog {
                            id: fileDialog
                            title: qsTr("Select settings file")
                            folder: shortcuts.home
                            selectMultiple: false
                            selectFolder: false
                            defaultSuffix: "conf"
                            onAccepted: {
                                ManageSettings.loadSettingsFile(fileDialog.fileUrl);
                                settings.sync();
                            }
                            onRejected: {
                                console.log("Canceled")
                            }
                        }
                    }

                    Rectangle {
                        width: parent.width
                        height: rowHeight
                        color: (Positioner.index % 2 == 0) ? "#8cbfd7f3" : "#00000000"
                        visible: !IsRaspPi

                        Text {
                            text: qsTr("Save settings to file")
                            font.weight: Font.Bold
                            font.pixelSize: 13
                            anchors.leftMargin: 8
                            verticalAlignment: Text.AlignVCenter
                            anchors.verticalCenter: parent.verticalCenter
                            width: 224
                            height: elementHeight
                            anchors.left: parent.left
                        }

                        Button {
                            width: 128
                            height: elementHeight
                            anchors.rightMargin: Qt.inputMethod.visible ? 96 : 36

                            anchors.right: parent.right
                            anchors.verticalCenter: parent.verticalCenter
                            text: qsTr("Save")
                            onClicked: {
                                saveDialog.open();
                            }
                        }

                        FileDialog {
                            id: saveDialog
                            title: qsTr("Select location")
                            folder: shortcuts.home + "/qopenhd.conf";
                            selectMultiple: false
                            selectFolder: false
                            selectExisting: false

                            onAccepted: {
                                console.log("Sa: " + saveDialog.fileUrl);
                                settings.sync();
                                // this is a folder path, the ManualSettings class chooses a filename to put there
                                ManageSettings.saveSettingsFile(saveDialog.fileUrl);
                            }
                            onRejected: {
                                console.log("Canceled")
                            }
                        }
                    }

                    Rectangle {
                        width: parent.width
                        height: rowHeight
                        color: (Positioner.index % 2 == 0) ? "#8cbfd7f3" : "#00000000"
                        visible: false

                        Text {
                            text: qsTr("Reset all settings")
                            font.weight: Font.Bold
                            font.pixelSize: 13
                            anchors.leftMargin: 8
                            verticalAlignment: Text.AlignVCenter
                            anchors.verticalCenter: parent.verticalCenter
                            width: 224
                            height: elementHeight
                            anchors.left: parent.left
                        }

                        Button {
                            id: resetButton
                            width: 128
                            height: elementHeight
                            anchors.rightMargin: Qt.inputMethod.visible ? 96 : 36

                            anchors.right: parent.right
                            anchors.verticalCenter: parent.verticalCenter
                            text: qsTr("Reset")
                            Material.accent: Material.Red
                            highlighted: true

                            ToolTip.delay: 250
                            ToolTip.timeout: 5000
                            ToolTip.visible: pressed
                            ToolTip.text: qsTr("Settings reset")

                            onClicked: {
                                //settings.clear()
                            }
                        }
                    }
                }
            }
        }

        /*Item {
              id: joystickTab
              width: parent.width
              height: parent.height
          }*/
    }
}
