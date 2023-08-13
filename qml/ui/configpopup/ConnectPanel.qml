import QtQuick 2.12
import QtQuick.Controls 2.12
import QtQuick.Layouts 1.12
import QtQuick.Dialogs 1.0
import QtQuick.Controls.Material 2.12

import Qt.labs.settings 1.0

import OpenHD 1.0

import "../../ui" as Ui
import "../elements"

// This panel is only for users that run QOpenHD on an external device,e.g. android not on the ground station itself
Item {
    Layout.fillHeight: true
    Layout.fillWidth: true

    property int rowHeight: 64
    property int elementHeight: 48
    property int elementComboBoxWidth: 300

    // Tab bar for selecting items in stack layout
    TabBar {
        id: selectItemInStackLayoutBar
        width: parent.width
        TabButton {
            text: qsTr("INFO")
        }
        TabButton {
            text: qsTr("USB Tether")
        }
        TabButton {
            text: qsTr("Ethernet (USB Eth) passive")
        }
        TabButton {
            text: qsTr("Ethernet (USB Eth) active")
        }
        TabButton {
            text: qsTr("WiFi")
        }
    }

    // placed right below the top bar
    StackLayout {
        width: parent.width
        height: parent.height-selectItemInStackLayoutBar.height
        anchors.top: selectItemInStackLayoutBar.bottom
        anchors.left: selectItemInStackLayoutBar.left
        anchors.bottom: parent.bottom
        currentIndex: selectItemInStackLayoutBar.currentIndex

        Pane {
            width: parent.width
            height: parent.height
            ColumnLayout{
                Layout.fillWidth: true
                Layout.minimumHeight: 30
                spacing: 6
                Text{
                    width:parent.width
                    height: 600
                    wrapMode: Text.WordWrap
                    text: "When running QOpenHD on an external device (e.g. android phone)\nyou have to use one of the given choices to connect the device to the OpenHD ground station"
                }
            }
        }

        Pane {
            width: parent.width
            height: parent.height
            ColumnLayout{
                Layout.fillWidth: true
                Layout.minimumHeight: 30
                spacing: 6
                Text{
                    width:parent.width
                    height: 600
                    wrapMode: Text.WordWrap
                    text: "1) Connect your phone via high quality USB cable to your ground station.\n
2) enable USB Tethering on your phone.\n
Requires a phone and cellular contract that allows USB tethering."
                }
                Button{
                    text: "Open settings"
                    onClicked: _qopenhd.android_open_tethering_settings()
                }
            }
        }
        Pane {
            width: parent.width
            height: parent.height
            Text{
                width:parent.width
                height: 600
                wrapMode: Text.WordWrap
                text: "1) Make sure ETH_HOTSPOT_E is disabled\n
2) Enable ETH_PASSIVE_F on your openhd ground unit\n
3) Connect your external device running QOpenHD to your ground station via ethernet\n(e.g. ethernet port on rpi 4).\n
4) Make sure to select 'share my internet with ...' when the android connection setup pops up\n
Video and telemetry forwarding should start automatically, and your GCS can get internet from your phone."
            }
        }
        Pane {
            width: parent.width
            height: parent.height
            Text{
                width:parent.width
                height: 600
                wrapMode: Text.WordWrap
                text: "
1) Make sure ETH_PASSIVE_F is disabled\n
2) Enable ETH_HOTSPOT_E on your openhd ground unit\n
3) Connect your external device running QOpenHD to your ground station via ethernet\n(e.g. ethernet port on rpi 4).\n
You might have to disable wifi and cellular on your phone !.\n
Video and telemetry forwarding should start automatically."
            }
        }
        Pane {
            width: parent.width
            height: parent.height
            Flickable {
                width: parent.width;
                height: parent.height
                contentWidth: 1280;
                contentHeight: 720

                Rectangle{
                    color: "green"
                    width: 1280
                    height: 720

                    ColumnLayout{
                        width:parent.width
                        height:parent.height

                        Text{
                            width:parent.width
                            height: 400
                            wrapMode: Text.WordWrap
                            text: "
            1) Make sure WIFI_HOTSPOT_E is enabled (on air or ground unit)\n
            2) Connect to openhd pw openhdopenhd\n
            3) Press button.
            NOTE: You cannot use WIFI hotspot during flight (while armed)"
                        }
                        Button{
                            text: "Connect Air/Ground Hotspot"
                            onClicked: _mavlinkTelemetry.add_tcp_connection_handler()
                        }
                        /*Button{
                            text: "Connect Ground Hotspot"
                        }*/
                    }

                }
            }
        }
    }
}
