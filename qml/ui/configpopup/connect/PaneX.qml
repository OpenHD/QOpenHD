import QtQuick 2.12
import QtQuick.Controls 2.12
import QtQuick.Layouts 1.12
import QtQuick.Dialogs 1.0
import QtQuick.Controls.Material 2.12

import Qt.labs.settings 1.0

import OpenHD 1.0

import "../../../ui" as Ui
import "../../elements"

Item {
    id: main_item
    width: parent.width
    height: parent.height

    Rectangle{
        color: "white"
        implicitWidth: main_item.width
        implicitHeight: main_item.height
    }

    Text{
        id: info_text
        width: parent.width
        height: 200
        anchors.top: parent.top;
        anchors.left: parent.left;
        text: {
            return "Connect QOpenHD (this ground controll aplication) to your ground station."+
                   "AUTO: Works for all recommended networking setups\n"+
                   "MANUAL: For developers / advanced networking only. Read the wiki for more Info.";
        }
    }

    ComboBox {
        id: connection_mode_dropdown
        anchors.top: info_text.bottom;

        width: parent.width
        height: 60

        model: ListModel {
            id: font_text
            ListElement { text: "AUTO" }
            ListElement { text: "MANUAL UDP" }
            ListElement { text: "MANUAL TCP" }
        }
    }
    Text{
        id: connection_status
        width: parent.width
        height: 30
        text: _mavlinkTelemetry.telemetry_connection_status
        anchors.top: connection_mode_dropdown.bottom
        anchors.left: parent.left
    }

    Rectangle{
        width: parent.width
        height: 400
        anchors.top: connection_status.bottom
        anchors.left: parent.left

        visible: connection_mode_dropdown.currentIndex==0;

        ColumnLayout {
            spacing: 6
            Layout.fillWidth: true
            Layout.fillHeight: true

            RowLayout {
                Button{
                    text: "Android Tethering"
                    Layout.preferredWidth: 180
                    onClicked: _qopenhd.android_open_tethering_settings()
                }
                ButtonIconInfoText {
                    m_info_text: "1) Connect your phone via high quality USB cable to your ground station.\n\n"+
                                 "2) enable USB Tethering on your phone.\n\n"+
                                 "3) Telemetry and video forwarding is started automatically \n\n"+
                                 " ! Requires a phone and cellular contract that allows USB tethering. !"
                }
            }
            RowLayout {
                Button{
                    text: "Passive Eth tethering"
                    Layout.preferredWidth: 180
                    //TODO disable active tethering and enable passive when clicking the button
                }
                ButtonIconInfoText {
                    m_info_text: "1) Disable ETH_HOTSPOT_E and Enable ETH_PASSIVE_F\n\n"+
                                 "2) Connect your external device to your ground station via ethernet.\n\n"+
                                 "3) Select 'share my internet with ...' when the android connection setup pops up\n\n"+
                                 "Video and telemetry forwarding should start automatically, internet will be forwarded from your phone."
                }
            }
            RowLayout {
                Button{
                    text: "Active Eth tethering"
                    Layout.preferredWidth: 180
                    //TODO disable passive tethering and enable active when clicking the button
                }
                ButtonIconInfoText {
                    m_info_text: "1) Disable ETH_PASSIVE_F and Enable ETH_HOTSPOT_E\n\n"+
                                 "2) Connect your external device to your ground station via ethernet.\n\n"+
                                 "You might need to disable wifi and cellular on your phone\n\n"+
                                 "Video and telemetry forwarding should start automatically, internet will not be available."
                }
            }
            RowLayout {
                Button{
                    text: "Wifi tethering"
                    Layout.preferredWidth: 180
                    //TODO enable hotspot
                }
                ButtonIconInfoText {
                    m_info_text: "1) Enable WIFI_HOTSPOT_E\n\n"+
                                 "2) Connect to WiFi: openhd pw openhdopenhd\n\n"+
                                 "3) Press 'Connect' button.\n\n"+
                                 "NOTE: You cannot use WIFI hotspot during flight (while armed)"
                }
            }
            // padding to bottom
            Item {
                Layout.fillHeight: true
                Layout.fillWidth: true
            }
        }
    }
    Rectangle{
        width:parent.width
        height: 200
        anchors.top: connection_status.bottom
        anchors.left: parent.left
        visible: connection_mode_dropdown.currentIndex==1;

    }
    Rectangle{
        width: parent.width
        height: 200
        anchors.top: connection_status.bottom
        anchors.left: parent.left
        visible: connection_mode_dropdown.currentIndex==2;
        GridLayout {
            columns: 2
            TextField {
                id: textFieldip
                validator: RegExpValidator {
                    regExp:  /^((?:[0-1]?[0-9]?[0-9]|2[0-4][0-9]|25[0-5])\.){0,3}(?:[0-1]?[0-9]?[0-9]|2[0-4][0-9]|25[0-5])$/
                }
                inputMethodHints: Qt.ImhFormattedNumbersOnly
                text: "192.168.178.36" //settings.dev_mavlink_tcp_ip
            }
            Button{
                text: "SAVE"
                onClicked: {

                }
            }

        }
    }

}
