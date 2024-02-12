import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.12
import QtGraphicalEffects 1.12
import QtQuick.Shapes 1.0
import QtQuick.Controls.Material 2.0

import Qt.labs.settings 1.0

import OpenHD 1.0

import "../elements"

SideBarBasePanel{
    id: miscUI
    override_title: "Status / Advanced"

    Column {
        anchors.top: parent.top
        anchors.topMargin: secondaryUiHeight/8
        spacing: 5

        RowLayout {
            Text {
                text: "Status:"
                font.pixelSize: 14
                font.bold: true
                font.family: "AvantGarde-Medium"
                color: "#ffffff"
                smooth: true
            }

            Text {
                text: "Connected"
                font.pixelSize: 14
                font.family: "AvantGarde-Medium"
                color: "#ffffff"
                smooth: true

            }
        }
        RowLayout {
            Text {
                text: "Screen:"
                font.pixelSize: 14
                font.bold: true
                font.family: "AvantGarde-Medium"
                color: "#ffffff"
                smooth: true
            }

            Text {
                text: applicationWindow.width + "x" + applicationWindow.height
                font.pixelSize: 14
                font.family: "AvantGarde-Medium"
                color: "#ffffff"
                smooth: true

            }
        }

        RowLayout {
            Text {
                text: "Frequency:"
                font.pixelSize: 14
                font.bold: true
                font.family: "AvantGarde-Medium"
                color: "#ffffff"
                smooth: true
            }

            Text {
                text: _ohdSystemGround.curr_channel_mhz + "Mhz"
                font.pixelSize: 14
                font.family: "AvantGarde-Medium"
                color: "#ffffff"
                smooth: true

            }
        }
        RowLayout {
            Text {
                text: "Wifi-Adapter:"
                font.pixelSize: 14
                font.bold: true
                font.family: "AvantGarde-Medium"
                color: "#ffffff"
                smooth: true
            }

            Text {
                id: wifiMessage
                property int wifiCode: _ohdSystemAir.ohd_wifi_type

                function wifiName(code) {
                    switch (code) {
                    case 11: return "Asus AC56";
                    case 12: return "8812AU CUSTOM";
                    case 21: return "88XXBU";
                    default: return "unknown";
                    }
                }

                text: wifiName(wifiCode) + "("+_ohdSystemAir.ohd_wifi_type+")"
                Layout.leftMargin: 12
            }
        }
        RowLayout {
            Text {
                text: "Format:"
                font.pixelSize: 14
                font.bold: true
                font.family: "AvantGarde-Medium"
                color: "#ffffff"
                smooth: true
            }

            Text {
                text: "1080p 60fps"
                font.pixelSize: 14
                font.family: "AvantGarde-Medium"
                color: "#ffffff"
                smooth: true

            }
        }
        RowLayout {
            Text {
                text: "Version:"
                font.pixelSize: 14
                font.bold: true
                font.family: "AvantGarde-Medium"
                color: "#ffffff"
                smooth: true
            }

            Text {
                text: "Todo"
                font.pixelSize: 14
                font.family: "AvantGarde-Medium"
                color: "#ffffff"
                smooth: true

            }
        }
        RowLayout {
            Text {
                text: "Hardware Air:"
                font.pixelSize: 14
                font.bold: true
                font.family: "AvantGarde-Medium"
                color: "#ffffff"
                smooth: true
            }

            Text {
                id: platformMessage
                property int platformCode: _ohdSystemAir.ohd_platform_type

                function platformName(code) {
                    switch (code) {
                    case 0: return "unknown";
                    case 10: return "X20";
                    case 20: return "x86";
                    case 30: return "rpi";
                    case 31: return "rpi 4";
                    case 32: return "rpi 3";
                    case 33: return "rpi 2";
                    case 34: return "rpi 1";
                    case 35: return "rpi 0";
                    case 40: return "rock";
                    case 41: return "rk3566";
                    case 42: return "rock5a";
                    case 43: return "rock5b";
                    default: return "unknown";
                    }
                }

                text: platformName(platformCode) + "("+_ohdSystemAir.ohd_platform_type+")"
                Layout.leftMargin: 12
            }
        }
        RowLayout {
            Text {
                text: "Hardware Ground:"
                font.pixelSize: 14
                font.bold: true
                font.family: "AvantGarde-Medium"
                color: "#ffffff"
                smooth: true
            }

            Text {
                text: "Todo"
                font.pixelSize: 14
                font.family: "AvantGarde-Medium"
                color: "#ffffff"
                smooth: true

            }
        }

        Button {
            id: button
            text: "Advanced Menu"

            onClicked: {
                settings_panel.visible = true
            }
        }
    }
}
