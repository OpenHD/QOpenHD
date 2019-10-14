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

    Settings {
        property alias battery_cells: batteryCellspinBox.value
        property alias enable_speech: enableSpeechSwitch.checked
        property alias enable_rc: enableRCSwitch.checked
        property alias show_downlink_rssi: showDownlinkRSSISwitch.checked
        property alias show_uplink_rssi: showUplinkRSSISwitch.checked
        property alias show_bitrate: showBitrateSwitch.checked
        property alias show_gps: showGPSSwitch.checked
        property alias show_home_distance: showHomeDistanceSwitch.checked
        property alias show_flight_timer: showFlightTimerSwitch.checked

        property alias show_flight_mode: showFlightModeSwitch.checked
        property alias show_ground_status: showGroundStatusSwitch.checked
        property alias show_air_status: showAirStatusSwitch.checked
        property alias show_air_battery: showAirBatterySwitch.checked
        property alias show_log_onscreen: showLogOnscreenSwitch.checked
    }

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
                    id: enableSpeechSwitch
                    width: 32
                    height: parent.height
                    anchors.rightMargin: 12
                    anchors.right: parent.right
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
                }
            }


            Rectangle {
                width: parent.width
                height: 64
                color: "#8cbfd7f3"
                y: 128
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
                    id: enableRCSwitch
                    width: 32
                    height: parent.height
                    anchors.rightMargin: 12
                    anchors.right: parent.right
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
                    id: showDownlinkRSSISwitch
                    width: 32
                    height: parent.height
                    anchors.rightMargin: 12
                    anchors.right: parent.right
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
                    id: showUplinkRSSISwitch
                    width: 32
                    height: parent.height
                    anchors.rightMargin: 12
                    anchors.right: parent.right
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
                    id: showBitrateSwitch
                    width: 32
                    height: parent.height
                    anchors.rightMargin: 12
                    anchors.right: parent.right
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
                    id: showGPSSwitch
                    width: 32
                    height: parent.height
                    anchors.rightMargin: 12
                    anchors.right: parent.right
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
                    id: showHomeDistanceSwitch
                    width: 32
                    height: parent.height
                    anchors.rightMargin: 12
                    anchors.right: parent.right
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
                    id: showFlightTimerSwitch
                    width: 36
                    height: parent.height
                    anchors.rightMargin: 12
                    anchors.right: parent.right
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
                    id: showFlightModeSwitch
                    width: 32
                    height: parent.height
                    anchors.rightMargin: 12
                    anchors.right: parent.right
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
                    id: showGroundStatusSwitch
                    width: 32
                    height: parent.height
                    anchors.rightMargin: 12
                    anchors.right: parent.right
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
                    id: showAirStatusSwitch
                    width: 32
                    height: parent.height
                    anchors.rightMargin: 12
                    anchors.right: parent.right
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
                    id: showAirBatterySwitch
                    width: 32
                    height: parent.height
                    anchors.rightMargin: 12
                    anchors.right: parent.right
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
                    id: showLogOnscreenSwitch
                    width: 32
                    height: parent.height
                    anchors.rightMargin: 12
                    anchors.right: parent.right
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
