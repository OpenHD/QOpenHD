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
            text: qsTr("Ethernet (USB Eth) active")
        }
        TabButton {
            text: qsTr("Ethernet (USB Eth) passive")
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
                    text: "1) Connect your phone via high quality USB cable to your ground station.\n2) enable USB Tethering on your phone.\nRequires a phone and cellular contract that allows USB tethering."
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
                text: "
                1) Make sure I_ETH_PASSIVE_F is disabled
                2) Enable I_ETH_HOTSPOT_E on your openhd ground unit\n
                3) Connect your external device running QOpenHD to your ground station via ethernet\n(e.g. ethernet port on rpi 4).\n
                You might have to disable wifi and cellular on your phone !.
                Video and telemetry forwarding should start automatically."
            }
        }
        Pane {
            width: parent.width
            height: parent.height
            Text{
                width:parent.width
                height: 600
                wrapMode: Text.WordWrap
                text: "1) Make sure I_ETH_HOTSPOT_E is disabled\n
                2) Enable I_ETH_PASSIVE_F on your openhd ground unit
                3) Connect your external device running QOpenHD to your ground station via ethernet\n(e.g. ethernet port on rpi 4).\n
                4) Make sure to select TODO when the android connection setup pops up
                Video and telemetry forwarding should start automatically."
            }
        }
    }
}
