//import QtQuick 2.12
import QtQuick 2.15
import QtQuick.Controls 2.12
import QtQuick.Layouts 1.12

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

    property int m_prefered_width: 230

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
                verticalAlignment: Qt.AlignVCenter
                horizontalAlignment: Qt.AlignHCenter
                font.pixelSize: settings.qopenhd_general_font_pixel_size
            }
            ComboBox {
                Layout.fillWidth: false
                Layout.fillHeight: true;
                Layout.preferredWidth: 200
                Layout.alignment: Qt.AlignCenter

                id: connection_mode_dropdown
                model: ListModel {
                    id: font_text
                    ListElement { text: "AUTO" }
                    ListElement { text: "MANUAL UDP" }
                    ListElement { text: "MANUAL TCP" }
                }
                onActivated: {
                    if(currentIndex==0 || currentIndex==1 || currentIndex==2){
                        if(settings.qopenhd_mavlink_connection_mode!=currentIndex){
                            _mavlinkTelemetry.change_telemetry_connection_mode(currentIndex);
                            settings.qopenhd_mavlink_connection_mode=currentIndex;
                        }
                        if(currentIndex===2){
                            _openhdDiscovery.refresh();
                        }
                    }
                }
                onCurrentIndexChanged: {
                    if(currentIndex===2){
                        _openhdDiscovery.refresh();
                    }
                }
                Component.onCompleted: {
                    if(currentIndex===2){
                        _openhdDiscovery.refresh();
                    }
                }
                currentIndex: settings.qopenhd_mavlink_connection_mode
            }
            Text{
                Layout.preferredWidth: 200
                Layout.alignment: Qt.AlignCenter
                id: connection_status
                text: _mavlinkTelemetry.telemetry_connection_status
                verticalAlignment: Qt.AlignVCenter
                horizontalAlignment: Qt.AlignHCenter
                font.pixelSize: settings.qopenhd_general_font_pixel_size
            }

            // Visible when auto mode is enabled ------------------------------------------------------------------------------------------
            ColumnLayout {
                spacing: 6
                Layout.fillWidth: true
                Layout.fillHeight: true
                visible: connection_mode_dropdown.currentIndex==0;

                RowLayout {
                    Layout.fillWidth: true
                    Item{ // filler
                        Layout.fillWidth: true
                    }
                    Button{
                        text: "Android Tethering"
                        Layout.preferredWidth: m_prefered_width
                        Layout.alignment: Qt.AlignCenter
                        onClicked: {
                            if(_qopenhd.is_android()){
                                _qopenhd.android_open_tethering_settings()
                            }else{
                                _qopenhd.show_toast("Only available on android");
                            }
                        }
                    }
                    ButtonIconInfoText {
                        Layout.alignment: Qt.AlignCenter
                        m_info_text: "1) Connect your phone via high quality USB cable to your ground station.\n\n"+
                                     "2) enable USB Tethering on your phone.\n\n"+
                                     "3) Telemetry and video forwarding is started automatically \n\n"+
                                     " ! Requires a phone and cellular contract that allows USB tethering. !"
                    }
                    Item{ // filler
                        Layout.fillWidth: true
                    }
                }
                RowLayout {
                    Layout.fillWidth: true
                    Item{ // filler
                        Layout.fillWidth: true
                    }
                    Button{
                        text: "Wifi Hotspot"
                        Layout.preferredWidth: m_prefered_width
                        Layout.alignment: Qt.AlignCenter
                        //TODO enable hotspot
                        onClicked: {
                            _messageBoxInstance.set_text_and_show("Please connect:\nWiFi Name: openhd_air/openhd_ground.\n PW: openhdopenhd")
                        }
                    }
                    ButtonIconInfoText {
                        m_info_text: "1) Check status if your air / ground unit supports WiFi hotspot\n\n"+
                                     "2) Make sure your FC is disarmed\n\n"+
                                     "3) Connect this device to your AIR / GND unit wifi hotspot.\n\n"+
                                     "NOTE: It is not recommended to use WiFi hotspot during flight (automatically disabled on arm by default)"
                    }
                    Item{ // filler
                        Layout.fillWidth: true
                    }
                }
                RowLayout {
                    Item{ // filler
                        Layout.fillWidth: true
                    }
                    Button{
                        text: "ETHERNET FORWARD+INTERNET"
                        Layout.preferredWidth: m_prefered_width
                        Layout.alignment: Qt.AlignCenter
                        //TODO disable active tethering and enable passive when clicking the button
                        onClicked: {
                            _qopenhd.show_toast("Please read info");
                        }
                    }
                    ButtonIconInfoText {
                        m_info_text: "1) Set ETHERNET to FORWARD+INTERNET\n"+
                                     "2) Reboot ground\n"+
                                     "3) Connect your external device (phone) to your ground station via ethernet.\n\n"+
                                     "4) Select 'share my internet with ...' when the (android) connection setup pops up\n\n"+
                                     "Video and telemetry forwarding is started automatically, internet will be forwarded from your phone."
                    }
                    Item{ // filler
                        Layout.fillWidth: true
                    }
                }
                RowLayout {
                    Item{ // filler
                        Layout.fillWidth: true
                    }
                    Button{
                        text: "ETHERNET HOTSPOT"
                        Layout.preferredWidth: m_prefered_width
                        Layout.alignment: Qt.AlignCenter
                        //TODO disable passive tethering and enable active when clicking the button
                        onClicked: {
                            _qopenhd.show_toast("Please read info");
                        }
                    }
                    ButtonIconInfoText {
                        m_info_text: "1) Set ETHERNET to HOTSPOT\n"+
                                     "2) Reboot ground\n"+
                                     "3) Connect your external device to your ground station via ethernet.\n\n"+
                                     "You might need to disable wifi and cellular on your phone\n\n"+
                                     "Video and telemetry forwarding should start automatically, internet will not be available."
                    }
                    Item{ // filler
                        Layout.fillWidth: true
                    }
                }
                // padding to bottom
                Item {
                    Layout.fillHeight: true
                    Layout.fillWidth: true
                }
            }

            // Visible when manual UDP mode is enabled ------------------------------------------------------------------------------------------
            RowLayout{
                Layout.fillWidth: true
                Layout.fillHeight: true
                visible: connection_mode_dropdown.currentIndex==1;
                Item{ // filler
                    Layout.fillWidth: true
                }
                Text{
                    Layout.alignment: Qt.AlignCenter
                    text: "Listening on localhost:5600"
                    font.pixelSize: settings.qopenhd_general_font_pixel_size
                }
                Item{ // filler
                    Layout.fillWidth: true
                }
            }
            // Visible when manual TCP mode is enabled ------------------------------------------------------------------------------------------
            ColumnLayout {
                id: manualTcpLayout
                Layout.fillWidth: true
                Layout.fillHeight: true
                visible: connection_mode_dropdown.currentIndex==2;
                spacing: 8

                Component.onCompleted: {
                    if(connection_mode_dropdown.currentIndex===2){
                        _openhdDiscovery.refresh();
                    }
                }

                RowLayout {
                    Layout.fillWidth: true
                    Text {
                        Layout.fillWidth: true
                        text: qsTr("Select an OpenHD device to connect via TCP")
                        wrapMode: Text.WordWrap
                        horizontalAlignment: Qt.AlignLeft
                        font.pixelSize: settings.qopenhd_general_font_pixel_size
                    }
                    Button {
                        text: qsTr("Refresh")
                        enabled: !_openhdDiscovery.scanning
                        onClicked: _openhdDiscovery.refresh()
                    }
                }

                BusyIndicator {
                    Layout.alignment: Qt.AlignHCenter
                    running: _openhdDiscovery.scanning
                    visible: running
                }

                ListView {
                    id: discoveredDevices
                    visible: count > 0
                    Layout.fillWidth: true
                    Layout.preferredHeight: Math.min(contentHeight, 280)
                    clip: true
                    interactive: contentHeight > height
                    boundsBehavior: Flickable.StopAtBounds
                    ScrollBar.vertical: ScrollBar { policy: ScrollBar.AsNeeded }
                    model: _openhdDiscovery.devices
                    delegate: Rectangle {
                        required property int index
                        required property var modelData
                        width: discoveredDevices.width
                        height: 48
                        radius: 4
                        color: (discoveredDevices.currentIndex === index) ? "#33007ACC" : (hoverHandler.hovered ? "#11000000" : "transparent")
                        border.color: "#1F000000"
                        border.width: 1

                        property string hostName: modelData.hostname ? modelData.hostname : ""
                        property string ipAddress: modelData.ip
                        property string displayText: hostName.length > 0 ? hostName + " (" + ipAddress + ")" : ipAddress

                        Text {
                            anchors.verticalCenter: parent.verticalCenter
                            anchors.left: parent.left
                            anchors.leftMargin: 12
                            anchors.right: parent.right
                            anchors.rightMargin: 12
                            text: displayText
                            font.pixelSize: settings.qopenhd_general_font_pixel_size
                            elide: Text.ElideRight
                        }

                        HoverHandler {
                            id: hoverHandler
                        }

                        TapHandler {
                            onTapped: {
                                discoveredDevices.currentIndex = index;
                                settings.qopenhd_mavlink_connection_manual_tcp_ip = ipAddress;
                                _mavlinkTelemetry.change_manual_tcp_ip(ipAddress);
                                const readable = hostName.length > 0 ? hostName : ipAddress;
                                _qopenhd.show_toast(qsTr("Connecting to %1").arg(readable));
                            }
                        }
                    }
                }

                Text {
                    Layout.fillWidth: true
                    wrapMode: Text.WordWrap
                    horizontalAlignment: Qt.AlignHCenter
                    visible: !_openhdDiscovery.scanning && _openhdDiscovery.devices.length === 0
                    text: qsTr("No OpenHD devices found. Ensure your device is on the same network and broadcasting an OpenHD hostname.")
                    font.pixelSize: settings.qopenhd_general_font_pixel_size
                }

                Text {
                    Layout.fillWidth: true
                    horizontalAlignment: Qt.AlignHCenter
                    text: qsTr("TCP PORT: 5760")
                    font.pixelSize: settings.qopenhd_general_font_pixel_size
                }
            }
        }


    }
}


