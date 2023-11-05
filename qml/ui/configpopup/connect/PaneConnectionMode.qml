import QtQuick 2.12
import QtQuick.Controls 2.12
import QtQuick.Layouts 1.12
import QtQuick.Dialogs 1.0
import QtQuick.Controls.Material 2.12

import Qt.labs.settings 1.0

import OpenHD 1.0

import "../../../ui" as Ui
import "../../elements"

Rectangle{
    id: background
    width: parent.width
    height: parent.height
    color: "white"
    border.color: "black"

    property bool m_is_air_or_ground_connected: _ohdSystemAir.is_alive || _ohdSystemGround.is_alive

    ScrollView {
        id: main_item
        width: parent.width
        height: parent.height
        contentHeight: main_layout.height
        contentWidth: main_layout.width
        clip: true
        //ScrollBar.vertical.policy: ScrollBar.AlwaysOn
        ScrollBar.vertical.interactive: true
        ScrollBar.horizontal.interactive: true


        /*Rectangle{
            color: "white"
            implicitWidth: parent.width
            implicitHeight: parent.height
        }*/

        ColumnLayout{
            id: main_layout
            width: main_item.width
            anchors.left: parent.left
            anchors.leftMargin: 4
            //Layout.fillWidth: true
            Layout.fillHeight: true
            Text{
                Layout.fillWidth: true
                Layout.fillHeight: true
                id: info_text
                text: {
                    if(m_is_air_or_ground_connected){
                        return "You are already connected to your OpenHD GND or AIR unit.\n"+
                                " Nothing to do here - use the status view for more info."
                    }
                    return "Connect QOpenHD (this ground controll aplication) to your ground station.\n"+
                            "AUTO: Works for all recommended networking setups\n"+
                            "MANUAL: For developers / advanced networking only. Read the wiki for more Info.";
                }
                wrapMode: Text.WordWrap
                color: m_is_air_or_ground_connected ? "red" : "black"
            }
            ComboBox {
                Layout.fillWidth: false
                Layout.fillHeight: true;
                Layout.preferredWidth: 200

                id: connection_mode_dropdown
                model: ListModel {
                    id: font_text
                    ListElement { text: "AUTO" }
                    ListElement { text: "MANUAL UDP" }
                    ListElement { text: "MANUAL TCP" }
                }
                onCurrentIndexChanged: {
                    if(currentIndex==0 || currentIndex==1 || currentIndex==2){
                        _mavlinkTelemetry.change_telemetry_connection_mode(currentIndex);
                    }
                }
                currentIndex: settings.qopenhd_mavlink_connection_mode
            }
            Text{
                Layout.fillWidth: true
                Layout.fillHeight: true;
                id: connection_status
                text: _mavlinkTelemetry.telemetry_connection_status
            }

            // Visible when auto mode is enabled ------------------------------------------------------------------------------------------
            ColumnLayout {
                spacing: 6
                Layout.fillWidth: true
                Layout.fillHeight: true
                visible: connection_mode_dropdown.currentIndex==0;

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
                        text: "Wifi tethering"
                        Layout.preferredWidth: 180
                        //TODO enable hotspot
                    }
                    ButtonIconInfoText {
                        m_info_text: "1) Check status if your air / ground unit supports WiFi hotspot\n\n"+
                                     "2) Make sure your FC is disarmed\n\n"+
                                     "3) Connect this device to your AIR / GND unit wifi hotspot.\n\n"+
                                     "NOTE: It is not recommended to use WiFi hotspot during flight (automatically disabled on arm by default)"
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
                // padding to bottom
                Item {
                    Layout.fillHeight: true
                    Layout.fillWidth: true
                }
            }

            // Visible when manual UDP mode is enabled ------------------------------------------------------------------------------------------
            GridLayout{
                Layout.fillWidth: true
                Layout.fillHeight: true
                visible: connection_mode_dropdown.currentIndex==1;
                Text{
                    text: "Listening on localhost:5600"
                }
            }
            // Visible when manual TCP mode is enabled ------------------------------------------------------------------------------------------
            GridLayout {
                Layout.fillWidth: true
                Layout.fillHeight: true
                visible: connection_mode_dropdown.currentIndex==2;
                columns: 2
                TextField {
                    id: textFieldip
                    validator: RegExpValidator {
                        regExp:  /^((?:[0-1]?[0-9]?[0-9]|2[0-4][0-9]|25[0-5])\.){0,3}(?:[0-1]?[0-9]?[0-9]|2[0-4][0-9]|25[0-5])$/
                    }
                    inputMethodHints: Qt.ImhFormattedNumbersOnly
                    text: settings.qopenhd_mavlink_connection_manual_tcp_ip
                }
                Button{
                    text: "SAVE"
                    onClicked: {
                        if(!_mavlinkTelemetry.change_manual_tcp_ip(textFieldip.text)){
                            _qopenhd.toast_text("Please enter a valid ip");
                        }else{
                            settings.qopenhd_mavlink_connection_manual_tcp_ip=textFieldip.text
                        }
                    }
                }
                Text{
                    Layout.columnSpan: 2
                    text: "TCP PORT: 5760"
                }
            }
        }


    }
}


