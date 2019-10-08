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
        width: 504
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
                    Component.onCompleted: checked = settings.value("enable_speech", true)
                    // @disable-check M222
                    onCheckedChanged: settings.setValue("enable_speech", checked)
                }
            }

            /*Rectangle {
                width: parent.width
                height: 64
                color: "#00000000"
                y: 128

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
                    Component.onCompleted: checked = settings.value("enable_rc", false)
                    onCheckedChanged: settings.setValue("enable_rc", checked)
                }
            }*/

            Rectangle {
                width: parent.width
                height: 64
                color: "#8cbfd7f3"
                y: 64
                visible: OpenHDPi.is_raspberry_pi

                Text {
                    text: "Screen Brightness"
                    font.weight: Font.Bold
                    font.pixelSize: 13
                    anchors.leftMargin: 8
                    verticalAlignment: Text.AlignVCenter
                    width: 224
                    height: parent.height
                    anchors.left: parent.left
                }

                SpinBox {
                    id: spinBox
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

            Rectangle {
                width: parent.width
                height: 64
                color: "#8cbfd7f3"
                y: 128

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
                    Component.onCompleted: value = settings.value("battery_cells", 3)
                    // @disable-check M223
                    onValueChanged: {
                        // @disable-check M222
                        settings.setValue("battery_cells", value)
                    }
                }
            }
        }




        ScrollView {
            id: widgetsView
            width: parent.width
            height: parent.height
            contentHeight: 11 * 64

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
                    Component.onCompleted: checked = settings.value("show_downlink_rssi", true)
                    onCheckedChanged: settings.setValue("show_downlink_rssi", checked)
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
                    Component.onCompleted: checked = settings.value("show_uplink_rssi", true)
                    onCheckedChanged: settings.setValue("show_uplik_rssi", checked)
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
                    Component.onCompleted: checked = settings.value("show_bitrate", true)
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
                    Component.onCompleted: checked = settings.value("show_gps", true)
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
                    Component.onCompleted: checked = settings.value("show_home_distance", true)
                    onCheckedChanged: settings.setValue("show_home_distance", checked)
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
                    Component.onCompleted: checked = settings.value("show_flight_timer", true)
                    onCheckedChanged: settings.setValue("show_flight_timer", checked)
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
                    Component.onCompleted: checked = settings.value("show_flight_mode", true)
                    onCheckedChanged: settings.setValue("show_flight_mode", checked)
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
                    Component.onCompleted: checked = settings.value("show_ground_status", true)
                    onCheckedChanged: settings.setValue("show_ground_status", checked)
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
                    Component.onCompleted: checked = settings.value("show_air_status", true)
                    onCheckedChanged: settings.setValue("show_air_status", checked)
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
                    Component.onCompleted: checked = settings.value("show_air_battery", true)
                    onCheckedChanged: settings.setValue("show_air_battery", checked)
                }
            }

            Rectangle {
                width: parent.width
                height: 64
                color: "#00000000"
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
                    Component.onCompleted: checked = settings.value("show_log_onscreen", true)
                    onCheckedChanged: settings.setValue("show_log_onscreen", checked)
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
