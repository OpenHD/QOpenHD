import QtQuick 2.13
import QtQuick.Controls 2.13
import QtQuick.Layouts 1.13

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
            text: qsTr("Video")
            width: implicitWidth
            height: 48
            font.pixelSize: 13
        }

        TabButton {
            text: qsTr("Screen")
            width: implicitWidth
            height: 48
            font.pixelSize: 13
            visible: OpenHDPi.is_raspberry_pi
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
            contentHeight: 3 * 64

            clip: true

            Rectangle {
                width: parent.width
                height: 64
                color: "#8cbfd7f3"
                y: 0

                Text {
                    text: "Enable Speech"
                    font.weight: Font.Bold
                    font.pixelSize: 13
                    anchors.leftMargin: 8
                    verticalAlignment: Text.AlignVCenter
                    width: 224
                    height: parent.height
                    anchors.left: parent.left
                }

                Switch {
                    width: 32
                    height: parent.height
                    anchors.rightMargin: 12
                    anchors.right: parent.right
                    // @disable-check M222
                    Component.onCompleted: checked = settings.value(
                                               "enable_speech", true)
                    // @disable-check M222
                    onCheckedChanged: settings.setValue("enable_speech",
                                                        checked)
                }
            }

            Rectangle {
                width: parent.width
                height: 64
                color: "#00000000"
                y: 64

                Text {
                    text: "Battery Cells"
                    font.weight: Font.Bold
                    font.pixelSize: 13
                    anchors.leftMargin: 8
                    verticalAlignment: Text.AlignVCenter
                    width: 224
                    height: parent.height
                    anchors.left: parent.left
                }

                SpinBox {
                    id: batteryCellspinBox
                    height: parent.height
                    width: 212
                    font.pixelSize: 14
                    anchors.right: parent.right
                    from: 1
                    to: 6
                    stepSize: 1
                    anchors.rightMargin: 0
                    // @disable-check M222
                    Component.onCompleted: value = settings.value(
                                               "battery_cells", 3)
                    // @disable-check M223
                    onValueChanged: {
                        // @disable-check M222
                        settings.setValue("battery_cells", value)
                    }
                }
            }

            Rectangle {
                width: parent.width
                height: 64
                color: "#8cbfd7f3"
                y: 128

                Text {
                    text: "Imperial units"
                    font.weight: Font.Bold
                    font.pixelSize: 13
                    anchors.leftMargin: 8
                    verticalAlignment: Text.AlignVCenter
                    width: 224
                    height: parent.height
                    anchors.left: parent.left
                }

                Switch {
                    width: 32
                    height: parent.height
                    anchors.rightMargin: 12
                    anchors.right: parent.right
                    // @disable-check M222
                    Component.onCompleted: checked = settings.value(
                                               "enable_imperial", false)
                    // @disable-check M222
                    onCheckedChanged: settings.setValue("enable_imperial",
                                                        checked)
                }
            }

            Rectangle {
                width: parent.width
                height: 64
                color: "#8cbfd7f3"
                y: 192
                visible: EnableRC

                Text {
                    text: "Enable RC"
                    font.weight: Font.Bold
                    font.pixelSize: 13
                    anchors.leftMargin: 8
                    verticalAlignment: Text.AlignVCenter
                    width: 224
                    height: parent.height
                    anchors.left: parent.left
                }

                Switch {
                    width: 32
                    height: parent.height
                    anchors.rightMargin: 12
                    anchors.right: parent.right
                    // @disable-check M222
                    Component.onCompleted: checked = settings.value(
                                               "enable_rc", false)
                    // @disable-check M222
                    onCheckedChanged: settings.setValue("enable_rc", checked)
                }
            }
        }

        ScrollView {
            id: widgetsView
            width: parent.width
            height: parent.height
        //must increment if adding more options-------------->
            contentHeight: 19 * 64

            clip: true

            Rectangle {
                width: parent.width
                height: 64
                color: "#8cbfd7f3"
                y: 0

                Text {
                    text: "Show Downlink RSSI"
                    font.weight: Font.Bold
                    font.pixelSize: 13
                    anchors.leftMargin: 8
                    verticalAlignment: Text.AlignVCenter
                    width: 224
                    height: parent.height
                    anchors.left: parent.left
                }

                Switch {
                    width: 32
                    height: parent.height
                    anchors.rightMargin: 12
                    anchors.right: parent.right
                    // @disable-check M222
                    Component.onCompleted: checked = settings.value(
                                               "show_downlink_rssi", true)
                    // @disable-check M222
                    onCheckedChanged: settings.setValue("show_downlink_rssi",
                                                        checked)
                }
            }

            Rectangle {
                width: parent.width
                height: 64
                color: "#00000000"
                y: 64

                Text {
                    text: "Show Uplink RSSI"
                    font.weight: Font.Bold
                    font.pixelSize: 13
                    anchors.leftMargin: 8
                    verticalAlignment: Text.AlignVCenter
                    width: 224
                    height: parent.height
                    anchors.left: parent.left
                }

                Switch {
                    width: 32
                    height: parent.height
                    anchors.rightMargin: 12
                    anchors.right: parent.right
                    // @disable-check M222
                    Component.onCompleted: checked = settings.value(
                                               "show_uplink_rssi", true)
                    // @disable-check M222
                    onCheckedChanged: settings.setValue("show_uplik_rssi",
                                                        checked)
                }
            }

            Rectangle {
                width: parent.width
                height: 64
                color: "#8cbfd7f3"
                y: 128

                Text {
                    text: "Show Bitrate"
                    font.weight: Font.Bold
                    font.pixelSize: 13
                    anchors.leftMargin: 8
                    verticalAlignment: Text.AlignVCenter
                    width: 224
                    height: parent.height
                    anchors.left: parent.left
                }

                Switch {
                    width: 32
                    height: parent.height
                    anchors.rightMargin: 12
                    anchors.right: parent.right
                    // @disable-check M222
                    Component.onCompleted: checked = settings.value(
                                               "show_bitrate", true)
                    // @disable-check M222
                    onCheckedChanged: settings.setValue("show_bitrate", checked)
                }
            }

            Rectangle {
                width: parent.width
                height: 64
                color: "#00000000"
                y: 192

                Text {
                    text: "Show GPS"
                    font.weight: Font.Bold
                    font.pixelSize: 13
                    anchors.leftMargin: 8
                    verticalAlignment: Text.AlignVCenter
                    width: 224
                    height: parent.height
                    anchors.left: parent.left
                }

                Switch {
                    width: 32
                    height: parent.height
                    anchors.rightMargin: 12
                    anchors.right: parent.right
                    // @disable-check M222
                    Component.onCompleted: checked = settings.value("show_gps",
                                                                    true)
                    // @disable-check M222
                    onCheckedChanged: settings.setValue("show_gps", checked)
                }
            }

            Rectangle {
                width: parent.width
                height: 64
                color: "#8cbfd7f3"
                y: 256

                Text {
                    text: "Show Home Distance"
                    font.weight: Font.Bold
                    font.pixelSize: 13
                    anchors.leftMargin: 8
                    verticalAlignment: Text.AlignVCenter
                    width: 224
                    height: parent.height
                    anchors.left: parent.left
                }

                Switch {
                    width: 32
                    height: parent.height
                    anchors.rightMargin: 12
                    anchors.right: parent.right
                    // @disable-check M222
                    Component.onCompleted: checked = settings.value(
                                               "show_home_distance", true)
                    // @disable-check M222
                    onCheckedChanged: settings.setValue("show_home_distance",
                                                        checked)
                }
            }

            Rectangle {
                width: parent.width
                height: 64
                color: "#00000000"
                y: 320

                Text {
                    text: "Show Flight Timer"
                    font.weight: Font.Bold
                    font.pixelSize: 13
                    anchors.leftMargin: 8
                    verticalAlignment: Text.AlignVCenter
                    width: 224
                    height: parent.height
                    anchors.left: parent.left
                }

                Switch {
                    width: 36
                    height: parent.height
                    anchors.rightMargin: 12
                    anchors.right: parent.right
                    // @disable-check M222
                    Component.onCompleted: checked = settings.value(
                                               "show_flight_timer", true)
                    // @disable-check M222
                    onCheckedChanged: settings.setValue("show_flight_timer",
                                                        checked)
                }
            }

            Rectangle {
                width: parent.width
                height: 64
                color: "#8cbfd7f3"
                y: 384

                Text {
                    text: "Show Flight Mode"
                    font.weight: Font.Bold
                    font.pixelSize: 13
                    anchors.leftMargin: 8
                    verticalAlignment: Text.AlignVCenter
                    width: 224
                    height: parent.height
                    anchors.left: parent.left
                }

                Switch {
                    width: 32
                    height: parent.height
                    anchors.rightMargin: 12
                    anchors.right: parent.right
                    // @disable-check M222
                    Component.onCompleted: checked = settings.value(
                                               "show_flight_mode", true)
                    // @disable-check M222
                    onCheckedChanged: settings.setValue("show_flight_mode",
                                                        checked)
                }
            }

            Rectangle {
                width: parent.width
                height: 64
                color: "#00000000"
                y: 448

                Text {
                    text: "Show Ground Status"
                    font.weight: Font.Bold
                    font.pixelSize: 13
                    anchors.leftMargin: 8
                    verticalAlignment: Text.AlignVCenter
                    width: 224
                    height: parent.height
                    anchors.left: parent.left
                }

                Switch {
                    width: 32
                    height: parent.height
                    anchors.rightMargin: 12
                    anchors.right: parent.right
                    // @disable-check M222
                    Component.onCompleted: checked = settings.value(
                                               "show_ground_status", true)
                    // @disable-check M222
                    onCheckedChanged: settings.setValue("show_ground_status",
                                                        checked)
                }
            }

            Rectangle {
                width: parent.width
                height: 64
                color: "#8cbfd7f3"
                y: 512

                Text {
                    text: "Show Air Status"
                    font.weight: Font.Bold
                    font.pixelSize: 13
                    anchors.leftMargin: 8
                    verticalAlignment: Text.AlignVCenter
                    width: 224
                    height: parent.height
                    anchors.left: parent.left
                }

                Switch {
                    width: 32
                    height: parent.height
                    anchors.rightMargin: 12
                    anchors.right: parent.right
                    // @disable-check M222
                    Component.onCompleted: checked = settings.value(
                                               "show_air_status", true)
                    // @disable-check M222
                    onCheckedChanged: settings.setValue("show_air_status",
                                                        checked)
                }
            }

            Rectangle {
                width: parent.width
                height: 64
                color: "#00000000"
                y: 576

                Text {
                    text: "Show Air Battery"
                    font.weight: Font.Bold
                    font.pixelSize: 13
                    anchors.leftMargin: 8
                    verticalAlignment: Text.AlignVCenter
                    width: 224
                    height: parent.height
                    anchors.left: parent.left
                }

                Switch {
                    width: 32
                    height: parent.height
                    anchors.rightMargin: 12
                    anchors.right: parent.right
                    // @disable-check M222
                    Component.onCompleted: checked = settings.value(
                                               "show_air_battery", true)
                    // @disable-check M222
                    onCheckedChanged: settings.setValue("show_air_battery",
                                                        checked)
                }
            }

            Rectangle {
                width: parent.width
                height: 64
                color: "#8cbfd7f3"
                y: 640

                Text {
                    text: "Show log messages on-screen"
                    font.weight: Font.Bold
                    font.pixelSize: 13
                    anchors.leftMargin: 8
                    verticalAlignment: Text.AlignVCenter
                    width: 224
                    height: parent.height
                    anchors.left: parent.left
                }

                Switch {
                    width: 32
                    height: parent.height
                    anchors.rightMargin: 12
                    anchors.right: parent.right
                    // @disable-check M222
                    Component.onCompleted: checked = settings.value(
                                               "show_log_onscreen", true)
                    // @disable-check M222
                    onCheckedChanged: settings.setValue("show_log_onscreen",
                                                        checked)
                }
            }

            Rectangle {
                width: parent.width
                height: 64
                color: "#00000000"
                y: 704

                Text {
                    text: "Show Horizon"
                    font.weight: Font.Bold
                    font.pixelSize: 13
                    anchors.leftMargin: 8
                    verticalAlignment: Text.AlignVCenter
                    width: 224
                    height: parent.height
                    anchors.left: parent.left
                }

                Switch {
                    width: 32
                    height: parent.height
                    anchors.rightMargin: 12
                    anchors.right: parent.right
                    // @disable-check M222
                    Component.onCompleted: checked = settings.value(
                                               "show_horizon", true)
                    // @disable-check M222
                    onCheckedChanged: settings.setValue("show_horizon", checked)
                }
            }

            Rectangle {
                width: parent.width
                height: 64
                color: "#8cbfd7f3"
                y: 768

                Text {
                    text: "Show Flight Path Vector"
                    font.weight: Font.Bold
                    font.pixelSize: 13
                    anchors.leftMargin: 8
                    verticalAlignment: Text.AlignVCenter
                    width: 224
                    height: parent.height
                    anchors.left: parent.left
                }

                Switch {
                    width: 32
                    height: parent.height
                    anchors.rightMargin: 12
                    anchors.right: parent.right
                    // @disable-check M222
                    Component.onCompleted: checked = settings.value("show_fpv",
                                                                    true)
                    // @disable-check M222
                    onCheckedChanged: settings.setValue("show_fpv", checked)
                }
            }

            Rectangle {
                width: parent.width
                height: 64
                color: "#00000000"
                y: 832

                Text {
                    text: "Show Altitude"
                    font.weight: Font.Bold
                    font.pixelSize: 13
                    anchors.leftMargin: 8
                    verticalAlignment: Text.AlignVCenter
                    width: 224
                    height: parent.height
                    anchors.left: parent.left
                }

                Switch {
                    width: 32
                    height: parent.height
                    anchors.rightMargin: 12
                    anchors.right: parent.right
                    // @disable-check M222
                    Component.onCompleted: checked = settings.value("show_altitude",
                                                                    true)
                    // @disable-check M222
                    onCheckedChanged: settings.setValue("show_altitude", checked)
                }
            }

            Rectangle {
                width: parent.width
                height: 64
                color: "#8cbfd7f3"
                y: 896

                Text {
                    text: "Show Speed"
                    font.weight: Font.Bold
                    font.pixelSize: 13
                    anchors.leftMargin: 8
                    verticalAlignment: Text.AlignVCenter
                    width: 224
                    height: parent.height
                    anchors.left: parent.left
                }

                Switch {
                    width: 32
                    height: parent.height
                    anchors.rightMargin: 12
                    anchors.right: parent.right
                    // @disable-check M222
                    Component.onCompleted: checked = settings.value("show_speed",
                                                                    true)
                    // @disable-check M222
                    onCheckedChanged: settings.setValue("show_speed", checked)
                }
            }

            Rectangle {
                width: parent.width
                height: 64
                color: "#00000000"
                y: 960

                Text {
                    text: "Show Heading"
                    font.weight: Font.Bold
                    font.pixelSize: 13
                    anchors.leftMargin: 8
                    verticalAlignment: Text.AlignVCenter
                    width: 224
                    height: parent.height
                    anchors.left: parent.left
                }

                Switch {
                    width: 32
                    height: parent.height
                    anchors.rightMargin: 12
                    anchors.right: parent.right
                    // @disable-check M222
                    Component.onCompleted: checked = settings.value("show_heading",
                                                                    true)
                    // @disable-check M222
                    onCheckedChanged: settings.setValue("show_heading", checked)
                }
            }

            Rectangle {
                width: parent.width
                height: 64
                color: "#8cbfd7f3"
                y: 1024

                Text {
                    text: "Show Second Altitude"
                    font.weight: Font.Bold
                    font.pixelSize: 13
                    anchors.leftMargin: 8
                    verticalAlignment: Text.AlignVCenter
                    width: 224
                    height: parent.height
                    anchors.left: parent.left
                }

                Switch {
                    width: 32
                    height: parent.height
                    anchors.rightMargin: 12
                    anchors.right: parent.right
                    // @disable-check M222
                    Component.onCompleted: checked = settings.value("show_second_alt",
                                                                    true)
                    // @disable-check M222
                    onCheckedChanged: settings.setValue("show_second_alt", checked)
                }
            }

            Rectangle {
                width: parent.width
                height: 64
                color: "#00000000"
                y: 1084

                Text {
                    text: "Show Home Arrow"
                    font.weight: Font.Bold
                    font.pixelSize: 13
                    anchors.leftMargin: 8
                    verticalAlignment: Text.AlignVCenter
                    width: 224
                    height: parent.height
                    anchors.left: parent.left
                }

                Switch {
                    width: 32
                    height: parent.height
                    anchors.rightMargin: 12
                    anchors.right: parent.right
                    // @disable-check M222
                    Component.onCompleted: checked = settings.value("show_arrow",
                                                                    true)
                    // @disable-check M222
                    onCheckedChanged: settings.setValue("show_arrow", checked)
                }
            }

            Rectangle {
                width: parent.width
                height: 64
                color: "#8cbfd7f3"
                y: 1148

                Text {
                    text: "Show Map"
                    font.weight: Font.Bold
                    font.pixelSize: 13
                    anchors.leftMargin: 8
                    verticalAlignment: Text.AlignVCenter
                    width: 224
                    height: parent.height
                    anchors.left: parent.left
                }

                Switch {
                    width: 32
                    height: parent.height
                    anchors.rightMargin: 12
                    anchors.right: parent.right
                    // @disable-check M222
                    Component.onCompleted: checked = settings.value("show_map",
                                                                    true)
                    // @disable-check M222
                    onCheckedChanged: settings.setValue("show_map", checked)
                }
            }



        }

        ScrollView {
            id: videoView
            width: parent.width
            height: parent.height
            contentHeight: 3 * 64

            clip: true

            Rectangle {
                width: parent.width
                height: 64
                color: "#8cbfd7f3"
                y: 0

                Text {
                    text: "Main video port"
                    font.weight: Font.Bold
                    font.pixelSize: 13
                    anchors.leftMargin: 8
                    verticalAlignment: Text.AlignVCenter
                    width: 224
                    height: parent.height
                    anchors.left: parent.left
                }

                SpinBox {
                    id: mainVideoPortSpinBox
                    height: parent.height
                    width: 212
                    font.pixelSize: 14
                    anchors.right: parent.right
                    from: 5600
                    to: 5610
                    stepSize: 1
                    anchors.rightMargin: 0
                    // @disable-check M222
                    Component.onCompleted: value = settings.value("main_video_port",
                                                                  5600)
                    // @disable-check M223
                    onValueChanged: {
                        // @disable-check M222
                        settings.setValue("main_video_port", value)
                    }
                }
            }

            Rectangle {
                width: parent.width
                height: 64
                color: "#00000000"
                y: 64

                Text {
                    text: "Enable PiP"
                    font.weight: Font.Bold
                    font.pixelSize: 13
                    anchors.leftMargin: 8
                    verticalAlignment: Text.AlignVCenter
                    width: 224
                    height: parent.height
                    anchors.left: parent.left
                }

                Switch {
                    width: 32
                    height: parent.height
                    anchors.rightMargin: 12
                    anchors.right: parent.right
                    // @disable-check M222
                    Component.onCompleted: checked = settings.value("show_pip_video",
                                                                    false)
                    // @disable-check M222
                    onCheckedChanged: settings.setValue("show_pip_video", checked)
                }
            }

            Rectangle {
                width: parent.width
                height: 64
                color: "#8cbfd7f3"
                y: 128

                Text {
                    text: "PiP video port"
                    font.weight: Font.Bold
                    font.pixelSize: 13
                    anchors.leftMargin: 8
                    verticalAlignment: Text.AlignVCenter
                    width: 224
                    height: parent.height
                    anchors.left: parent.left
                }

                SpinBox {
                    id: pipVideoPortSpinBox
                    height: parent.height
                    width: 212
                    font.pixelSize: 14
                    anchors.right: parent.right
                    from: 5600
                    to: 5610
                    stepSize: 1
                    anchors.rightMargin: 0
                    // @disable-check M222
                    Component.onCompleted: value = settings.value("pip_video_port",
                                                                  5601)
                    // @disable-check M223
                    onValueChanged: {
                        // @disable-check M222
                        settings.setValue("pip_video_port", value)
                    }
                }
            }
        }

        ScrollView {
            id: screenView
            width: parent.width
            height: parent.height
            contentHeight: 3 * 64

            clip: true

            visible: OpenHDPi.is_raspberry_pi

            Rectangle {
                width: parent.width
                height: 64
                color: "#8cbfd7f3"
                y: 0

                Text {
                    text: "Brightness"
                    font.weight: Font.Bold
                    font.pixelSize: 13
                    anchors.leftMargin: 8
                    verticalAlignment: Text.AlignVCenter
                    width: 224
                    height: parent.height
                    anchors.left: parent.left
                }

                SpinBox {
                    id: screenBrightnessSpinBox
                    height: parent.height
                    width: 212
                    font.pixelSize: 14
                    anchors.right: parent.right
                    from: 0
                    to: 255
                    stepSize: 5
                    anchors.rightMargin: 0
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

