import QtQuick 2.12
import QtQuick.Controls 2.12
import QtQuick.Layouts 1.12
import QtQuick.Dialogs 1.0
import QtQuick.Controls.Material 2.12

import Qt.labs.settings 1.0

import OpenHD 1.0

import "../../../ui" as Ui
import "../../elements"

// This panel is only for users that run QOpenHD on an external device,e.g. android not on the ground station itself
Item {
    Layout.fillHeight: true
    Layout.fillWidth: true

    property int rowHeight: 64
    property int elementHeight: 48
    property int elementComboBoxWidth: 300

    property bool m_is_connected_gnd: _ohdSystemGround.is_alive

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
            text: qsTr("(USB) Ethernet passive")
        }
        TabButton {
            text: qsTr("(USB) Ethernet active")
        }
        TabButton {
            text: qsTr("WiFi")
        }
        TabButton {
            text: qsTr("Custom (TCP)")
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

        Rectangle{
            width: parent.width
            height: parent.height
            ColumnLayout{
                anchors.fill: parent
                spacing: 6
                Text{
                    Layout.fillWidth: true
                    Layout.alignment: Qt.AlignTop
                    Layout.preferredHeight: 50
                    //width:parent.width
                    wrapMode: Text.WordWrap
                    verticalAlignment: Text.AlignTop
                    text: "When running QOpenHD on an external device (e.g. android phone)\n"+
                          "you have to use one of the given choices to connect the device to the OpenHD ground station"
                }
                Text{
                    Layout.preferredHeight: 50
                    text: "You are already connected to your ground station - nothing to do."
                    color: "#706F1D" // dark green
                    visible: m_is_connected_gnd
                }
                Text{
                    Layout.preferredHeight: 50
                    text: "Looks like you are not connected to your ground station - please use one of the given choices to connect."
                    color: "red"
                    visible: !m_is_connected_gnd
                }
                Item{
                    Layout.fillHeight: true
                    // filler
                }
            }
        }

        /*InfoPane{
            m_info_text: {
                return "When running QOpenHD on an external device (e.g. android phone)\n"+
                        "you have to use one of the given choices to connect the device to the OpenHD ground station"
            }
        }*/

        PaneUSBTether{
            id: pane_usb_tether
        }

        InfoPane{
            m_info_text: {
                return"1) Make sure ETH_HOTSPOT_E is disabled (Ground param)\n\n"+
                        "2) Enable ETH_PASSIVE_F on your openhd ground unit (Ground param)\n\n"+
                        "3) Connect your external device running QOpenHD to your ground station via ethernet\n(e.g. ethernet port on rpi 4).\n\n"+
                        "4) Make sure to select 'share my internet with ...' when the android connection setup pops up\n\n"+
                        "Video and telemetry forwarding should start automatically, and your GCS can get internet from your phone."
            }
        }
        InfoPane{
            m_info_text: {
                return "1) Make sure ETH_PASSIVE_F is disabled (Ground param)\n\n"+
                        "2) Enable ETH_HOTSPOT_E on your openhd ground unit (Ground param)\n\n"+
                        "3) Connect your external device running QOpenHD to your ground station via ethernet\n(e.g. ethernet port on rpi 4).\n\n"+
                        "You might have to disable wifi and cellular on your phone !.\n\n"+
                        "Video and telemetry forwarding should start automatically."
            }
        }

        PaneWIFI{
            id:  wifi
        }

        PaneCustom{
            id: pane_custom
        }
    }
}
