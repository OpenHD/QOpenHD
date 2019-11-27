import QtQuick 2.12
import QtQuick.Controls 2.12
import QtQuick.Layouts 1.12

import Qt.labs.settings 1.0

import OpenHD 1.0

import "../ui" as Ui


/*
 * This file should be refactored in a way that isn't so fragile and verbose. The rows are
 * all manually defined and every one of them has a manually vertical offset to position it
 * inside the scroll view.
 *
 */
Item {
    width: 504
    height: 300

    property int rowHeight: 64
    property int elementHeight: 48

    TabBar {
        id: appSettingsBar
        width: parent.width
        height: 48
        anchors.right: parent.right
        anchors.rightMargin: 0
        anchors.left: parent.left
        anchors.leftMargin: 0
        anchors.top: parent.top

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
            width: OpenHDPi.is_raspberry_pi ? implicitWidth : 0
            height: 48
            font.pixelSize: 13
            visible: OpenHDPi.is_raspberry_pi
        }

        TabButton {
            text: qsTr("Video")
            width: EnableVideo ? implicitWidth : 0
            height: 48
            font.pixelSize: 13
            visible: EnableVideo
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
            contentHeight: 3 * rowHeight

            clip: true

            Rectangle {
                width: parent.width
                height: rowHeight
                color: "#8cbfd7f3"
                y: 0 * rowHeight

                Text {
                    text: "Enable Speech"
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
                color: "#00000000"
                y: 1 * rowHeight

                Text {
                    text: "Battery Cells"
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
                color: "#8cbfd7f3"
                y: 2 * rowHeight

                Text {
                    text: "Imperial units"
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
                color: "#8cbfd7f3"
                y: 3 * rowHeight
                visible: EnableRC

                Text {
                    text: "Enable RC"
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
        }

        ScrollView {
            id: widgetsView
            width: parent.width
            height: parent.height
        //must increment if adding more options-------------->
            contentHeight: 20 * rowHeight

            clip: true

            Rectangle {
                width: parent.width
                height: rowHeight
                color: "#8cbfd7f3"
                y: 0 * rowHeight

                Text {
                    text: "Show Downlink RSSI"
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
                color: "#00000000"
                y: 1 * rowHeight

                Text {
                    text: "Show Uplink RSSI"
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
                color: "#8cbfd7f3"
                y: 2 * rowHeight

                Text {
                    text: "Show Bitrate"
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
                color: "#00000000"
                y: 3 * rowHeight

                Text {
                    text: "Show GPS"
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
                color: "#8cbfd7f3"
                y: 4 * rowHeight

                Text {
                    text: "Show Home Distance"
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
                color: "#00000000"
                y: 5 * rowHeight

                Text {
                    text: "Show Flight Timer"
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
                color: "#8cbfd7f3"
                y: 6 * rowHeight

                Text {
                    text: "Show Flight Mode"
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
                color: "#00000000"
                y: 7 * rowHeight

                Text {
                    text: "Show Ground Status"
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
                color: "#8cbfd7f3"
                y: 8 * rowHeight

                Text {
                    text: "Show Air Status"
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
                color: "#00000000"
                y: 9 * rowHeight

                Text {
                    text: "Show Air Battery"
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
                color: "#8cbfd7f3"
                y: 10 * rowHeight

                Text {
                    text: "Show log messages on-screen"
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
                    checked: settings.show_log_onscreen
                    onCheckedChanged: settings.show_log_onscreen = checked
                }
            }

            Rectangle {
                width: parent.width
                height: rowHeight
                color: "#00000000"
                y: 11 * rowHeight

                Text {
                    text: "Show Horizon"
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
                color: "#8cbfd7f3"
                y: 12 * rowHeight

                Text {
                    text: "Show Flight Path Vector"
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
                color: "#00000000"
                y: 13 * rowHeight

                Text {
                    text: "Show Altitude"
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
                color: "#8cbfd7f3"
                y: 14 * rowHeight

                Text {
                    text: "Show Speed"
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
                color: "#00000000"
                y: 15 * rowHeight

                Text {
                    text: "Show Heading"
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
                color: "#8cbfd7f3"
                y: 16 * rowHeight

                Text {
                    text: "Show Second Altitude"
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
                    checked: settings.show_second_alt
                    onCheckedChanged: settings.show_second_alt = checked
                }
            }

            Rectangle {
                width: parent.width
                height: rowHeight
                color: "#00000000"
                y: 17 * rowHeight

                Text {
                    text: "Show Home Arrow"
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
                color: "#8cbfd7f3"
                y: 18 * rowHeight

                Text {
                    text: "Show Map"
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
                color: "#00000000"
                y: 19 * rowHeight

                Text {
                    text: "Show throttle"
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

        }

        ScrollView {
            id: screenView
            width: parent.width
            height: parent.height
            contentHeight: 1 * rowHeight

            clip: true

            visible: OpenHDPi.is_raspberry_pi

            Rectangle {
                width: parent.width
                height: rowHeight
                color: "#8cbfd7f3"
                y: 0 * rowHeight

                Text {
                    text: "Brightness"
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

        ScrollView {
            id: videoView
            width: parent.width
            height: parent.height
            contentHeight: 4 * rowHeight

            clip: true
            visible: EnableVideo

            Rectangle {
                width: parent.width
                height: rowHeight
                color: "#8cbfd7f3"
                y: 0 * rowHeight

                Text {
                    text: "Use hardware video decoder"
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
                    checked: settings.enable_hardware_video_decoder
                    onCheckedChanged: settings.enable_hardware_video_decoder = checked
                }
            }

            Rectangle {
                width: parent.width
                height: rowHeight
                color: "#00000000"
                y: 1 * rowHeight

                Text {
                    text: "Main video port"
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
                    id: mainVideoPortSpinBox
                    height: elementHeight
                    width: 210
                    font.pixelSize: 14
                    anchors.right: parent.right
                    anchors.verticalCenter: parent.verticalCenter
                    from: 5600
                    to: 5610
                    stepSize: 1
                    anchors.rightMargin: Qt.inputMethod.visible ? 78 : 18

                    value: settings.main_video_port
                    onValueChanged: settings.main_video_port = value
                }
            }

            Rectangle {
                width: parent.width
                height: rowHeight
                color: "#8cbfd7f3"
                y: 2 * rowHeight
                visible: EnablePiP

                Text {
                    text: "Enable PiP"
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
                color: "#00000000"
                y: 3 * rowHeight
                visible: EnablePiP

                Text {
                    text: "PiP video port"
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
                    id: pipVideoPortSpinBox
                    height: elementHeight
                    width: 210
                    font.pixelSize: 14
                    anchors.right: parent.right
                    anchors.verticalCenter: parent.verticalCenter
                    from: 5600
                    to: 5610
                    stepSize: 1
                    anchors.rightMargin: Qt.inputMethod.visible ? 78 : 18

                    value: settings.pip_video_port
                    onValueChanged: settings.pip_video_port = value
                }
            }
        }

        //Item {
        //    id: joystickTab
        //    width: parent.width
        //    height: parent.height
        //}
    }
}

/*##^##
Designer {
    D{i:14;invisible:true}D{i:15;invisible:true}
}
##^##*/

