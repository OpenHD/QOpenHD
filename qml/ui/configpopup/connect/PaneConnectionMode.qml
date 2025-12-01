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
    color: "#f5f7fb"
    border.color: "#dfe3e8"

    property bool m_is_air_or_ground_connected: _ohdSystemAir.is_alive || _ohdSystemGround.is_alive

    property int m_prefered_width: 230

    property bool isScanning: false
    property int scanProgress: 0
    property int scanIndex: 1
    property int scanMax: 254
    property string scanPrefix: "192.168.0"

    ListModel {
        id: scanResultsModel
    }

    Timer {
        id: scanTimer
        interval: 120
        repeat: true
        running: false
        onTriggered: {
            if (scanIndex > scanMax) {
                isScanning = false
                scanProgress = 100
                stop()
                return
            }
            var candidateIp = scanPrefix + "." + scanIndex
            var reachable = _qopenhd.ping_ip(candidateIp)
            scanProgress = Math.min(100, Math.round((scanIndex / scanMax) * 100))
            if (reachable) {
                scanResultsModel.append({ ip: candidateIp })
            }
            scanIndex++
        }
    }

    function derivePrefix() {
        var currentIp = settings.qopenhd_mavlink_connection_manual_tcp_ip
        var parts = currentIp.split(".")
        if (parts.length === 4) {
            return parts[0] + "." + parts[1] + "." + parts[2]
        }
        return "192.168.0"
    }

    function startScan() {
        if (isScanning) {
            return
        }
        scanPrefix = derivePrefix()
        scanResultsModel.clear()
        scanIndex = 1
        scanProgress = 0
        isScanning = true
        scanTimer.start()
    }

    function applyTcpTarget(ip) {
        if (!_qopenhd.is_valid_ip(ip)) {
            _qopenhd.show_toast("Please enter a valid ip")
            return
        }
        textFieldip.text = ip
        settings.qopenhd_mavlink_connection_manual_tcp_ip = ip
        _mavlinkTelemetry.change_manual_tcp_ip(ip)
        if (connection_mode_dropdown.currentIndex !== 2) {
            _mavlinkTelemetry.change_telemetry_connection_mode(2)
            settings.qopenhd_mavlink_connection_mode = 2
            connection_mode_dropdown.currentIndex = 2
        }
    }

    ScrollView {
        id: main_item
        width: parent.width
        height: parent.height
        contentHeight: main_layout.height
        contentWidth: main_layout.width
        clip: true
        ScrollBar.vertical.interactive: true
        ScrollBar.horizontal.interactive: true

        ColumnLayout {
            id: main_layout
            width: main_item.width
            anchors.left: parent.left
            anchors.leftMargin: 12
            anchors.right: parent.right
            anchors.rightMargin: 12
            spacing: 12

            Text {
                Layout.fillWidth: true
                id: info_text
                text: {
                    if (m_is_air_or_ground_connected) {
                        return "You are already connected to your OpenHD GND or AIR unit.\n" +
                                " Nothing to do here - use the status view for more info."
                    }
                    return "Connect QOpenHD (this ground controll aplication) to your ground station.\n" +
                            "AUTO: Works for all recommended networking setups\n" +
                            "MANUAL: For developers / advanced networking only. Read the wiki for more Info.";
                }
                wrapMode: Text.WordWrap
                color: m_is_air_or_ground_connected ? "#c0392b" : "#2c3e50"
                verticalAlignment: Qt.AlignVCenter
                horizontalAlignment: Qt.AlignLeft
                font.pixelSize: settings.qopenhd_general_font_pixel_size + 2
                font.bold: true
            }

            CardBasic {
                Layout.fillWidth: true
                radius: 10
                color: "white"
                border.color: "#dde2e6"

                ColumnLayout {
                    anchors.fill: parent
                    anchors.margins: 14
                    spacing: 10

                    RowLayout {
                        Layout.fillWidth: true
                        spacing: 8
                        Text {
                            text: "Connection mode"
                            font.pixelSize: settings.qopenhd_general_font_pixel_size + 2
                            font.bold: true
                            color: "#2d3436"
                        }
                        Rectangle {
                            height: 18
                            width: 18
                            radius: 9
                            color: m_is_air_or_ground_connected ? "#2ecc71" : "#e67e22"
                        }
                        Text {
                            text: _mavlinkTelemetry.telemetry_connection_status
                            font.pixelSize: settings.qopenhd_general_font_pixel_size
                            color: "#576574"
                            Layout.fillWidth: true
                        }
                    }

                    ComboBox {
                        Layout.fillWidth: true
                        id: connection_mode_dropdown
                        model: ListModel {
                            id: font_text
                            ListElement { text: "AUTO" }
                            ListElement { text: "MANUAL UDP" }
                            ListElement { text: "MANUAL TCP" }
                        }
                        onActivated: {
                            if (currentIndex === 0 || currentIndex === 1 || currentIndex === 2) {
                                if (settings.qopenhd_mavlink_connection_mode !== currentIndex) {
                                    _mavlinkTelemetry.change_telemetry_connection_mode(currentIndex)
                                    settings.qopenhd_mavlink_connection_mode = currentIndex
                                    if (currentIndex !== 2 && isScanning) {
                                        scanTimer.stop()
                                        isScanning = false
                                        scanProgress = 0
                                    }
                                }
                            }
                        }
                        currentIndex: settings.qopenhd_mavlink_connection_mode
                    }

                    Text {
                        Layout.fillWidth: true
                        wrapMode: Text.WordWrap
                        text: connection_mode_dropdown.currentIndex === 0 ?
                                  "Automatic mode configures the recommended connection for you." :
                                  (connection_mode_dropdown.currentIndex === 1 ?
                                       "UDP listen mode expects telemetry on localhost:5600." :
                                       "Manual TCP lets you target a specific ground station IP.")
                        color: "#7f8c8d"
                        font.pixelSize: settings.qopenhd_general_font_pixel_size
                    }
                }
            }

            CardBasic {
                Layout.fillWidth: true
                visible: connection_mode_dropdown.currentIndex === 0
                radius: 10
                color: "white"
                border.color: "#dde2e6"

                ColumnLayout {
                    anchors.fill: parent
                    anchors.margins: 14
                    spacing: 10

                    Text {
                        text: "Recommended setup"
                        font.pixelSize: settings.qopenhd_general_font_pixel_size + 2
                        font.bold: true
                        color: "#2d3436"
                    }

                    Text {
                        Layout.fillWidth: true
                        wrapMode: Text.WordWrap
                        text: "Pick the networking method that matches how your device is linked to the ground station."
                        color: "#7f8c8d"
                        font.pixelSize: settings.qopenhd_general_font_pixel_size
                    }

                    RowLayout {
                        Layout.fillWidth: true
                        spacing: 10
                        Button {
                            text: "Android Tethering"
                            Layout.preferredWidth: m_prefered_width
                            Layout.alignment: Qt.AlignCenter
                            onClicked: {
                                if (_qopenhd.is_android()) {
                                    _qopenhd.android_open_tethering_settings()
                                } else {
                                    _messageBoxInstance.set_text_and_show("This feature is only available on android")
                                }
                            }
                        }
                        ButtonIconInfoText {
                            m_info_text: "1) Connect via USB to ground station\n" +
                                         "2) Enable tethering on your phone\n" +
                                         "3) Open this app and start your ground station"
                        }
                    }

                    RowLayout {
                        Layout.fillWidth: true
                        spacing: 10
                        Button {
                            text: "ETHERNET FORWARD+INTERNET"
                            Layout.preferredWidth: m_prefered_width
                            Layout.alignment: Qt.AlignCenter
                            onClicked: {
                                _qopenhd.show_toast("Please read info")
                            }
                        }
                        ButtonIconInfoText {
                            m_info_text: "1) Set ETHERNET to FORWARD+INTERNET\n" +
                                         "2) Reboot ground\n" +
                                         "3) Connect your external device (phone) to your ground station via ethernet.\n\n" +
                                         "4) Select 'share my internet with ...' when the (android) connection setup pops up\n\n" +
                                         "Video and telemetry forwarding is started automatically, internet will be forwarded from your phone."
                        }
                    }

                    RowLayout {
                        Layout.fillWidth: true
                        spacing: 10
                        Button {
                            text: "ETHERNET HOTSPOT"
                            Layout.preferredWidth: m_prefered_width
                            Layout.alignment: Qt.AlignCenter
                            onClicked: {
                                _qopenhd.show_toast("Please read info")
                            }
                        }
                        ButtonIconInfoText {
                            m_info_text: "1) Set ETHERNET to HOTSPOT\n" +
                                         "2) Reboot ground\n" +
                                         "3) Connect your external device to your ground station via ethernet.\n\n" +
                                         "You might need to disable wifi and cellular on your phone\n\n" +
                                         "Video and telemetry forwarding should start automatically, internet will not be available."
                        }
                    }
                }
            }

            CardBasic {
                Layout.fillWidth: true
                visible: connection_mode_dropdown.currentIndex === 1
                radius: 10
                color: "white"
                border.color: "#dde2e6"

                ColumnLayout {
                    anchors.fill: parent
                    anchors.margins: 14
                    spacing: 8

                    Text {
                        text: "Manual UDP"
                        font.pixelSize: settings.qopenhd_general_font_pixel_size + 2
                        font.bold: true
                        color: "#2d3436"
                    }

                    Text {
                        Layout.fillWidth: true
                        wrapMode: Text.WordWrap
                        text: "Listening on localhost:5600"
                        font.pixelSize: settings.qopenhd_general_font_pixel_size
                        color: "#7f8c8d"
                    }
                }
            }

            CardBasic {
                Layout.fillWidth: true
                visible: connection_mode_dropdown.currentIndex === 2
                radius: 10
                color: "white"
                border.color: "#dde2e6"

                ColumnLayout {
                    anchors.fill: parent
                    anchors.margins: 14
                    spacing: 10

                    Text {
                        text: "Manual TCP"
                        font.pixelSize: settings.qopenhd_general_font_pixel_size + 2
                        font.bold: true
                        color: "#2d3436"
                    }

                    Text {
                        Layout.fillWidth: true
                        wrapMode: Text.WordWrap
                        text: "Target a specific ground station IP over Ethernet. Use the scan tool to find responsive devices on your local network."
                        font.pixelSize: settings.qopenhd_general_font_pixel_size
                        color: "#7f8c8d"
                    }

                    RowLayout {
                        Layout.fillWidth: true
                        spacing: 8
                        TextField {
                            Layout.fillWidth: true
                            id: textFieldip
                            validator: RegularExpressionValidator{
                                regularExpression: /^((?:[0-1]?[0-9]?[0-9]|2[0-4][0-9]|25[0-5])\.){0,3}(?:[0-1]?[0-9]?[0-9]|2[0-4][0-9]|25[0-5])$/
                            }
                            inputMethodHints: Qt.ImhFormattedNumbersOnly
                            text: settings.qopenhd_mavlink_connection_manual_tcp_ip
                            placeholderText: "192.168.x.x"
                        }
                        Button {
                            text: "Save"
                            onClicked: applyTcpTarget(textFieldip.text)
                        }
                    }

                    Text {
                        Layout.fillWidth: true
                        text: "TCP PORT: 5760"
                        font.pixelSize: settings.qopenhd_general_font_pixel_size
                        color: "#576574"
                    }

                    Rectangle {
                        Layout.fillWidth: true
                        height: 1
                        color: "#ecf0f1"
                    }

                    RowLayout {
                        Layout.fillWidth: true
                        spacing: 8
                        Button {
                            text: isScanning ? "Scanning..." : "Scan Ethernet for devices"
                            enabled: !isScanning
                            Layout.preferredWidth: m_prefered_width + 40
                            onClicked: startScan()
                        }
                        Text {
                            text: "Subnet: " + scanPrefix + ".x"
                            color: "#7f8c8d"
                            font.pixelSize: settings.qopenhd_general_font_pixel_size
                        }
                    }

                    Item {
                        Layout.fillWidth: true
                        Layout.preferredHeight: 12
                        SimpleProgressBar {
                            anchors.fill: parent
                            impl_curr_progress_perc: scanProgress
                            impl_curr_color: "#39a2f7"
                            impl_show_progress_text: false
                            visible: isScanning || scanProgress > 0
                        }
                    }

                    Text {
                        Layout.fillWidth: true
                        wrapMode: Text.WordWrap
                        text: scanResultsModel.count === 0 ?
                                  (isScanning ? "Scanning for responsive hosts..." : "No devices discovered yet. Start a scan to look for ground stations.") :
                                  "Tap an IP below to connect via TCP."
                        color: "#7f8c8d"
                        font.pixelSize: settings.qopenhd_general_font_pixel_size
                    }

                    ListView {
                        Layout.fillWidth: true
                        Layout.preferredHeight: 200
                        clip: true
                        model: scanResultsModel
                        delegate: Rectangle {
                            width: ListView.view.width
                            height: 48
                            color: index % 2 === 0 ? "#f8f9fb" : "#ffffff"
                            radius: 6
                            border.color: "#e0e3e8"
                            RowLayout {
                                anchors.fill: parent
                                anchors.margins: 10
                                spacing: 10
                                Text {
                                    text: ip
                                    font.pixelSize: settings.qopenhd_general_font_pixel_size + 1
                                    color: "#2d3436"
                                    Layout.fillWidth: true
                                }
                                Button {
                                    text: "Connect"
                                    onClicked: applyTcpTarget(ip)
                                }
                            }
                        }
                        visible: scanResultsModel.count > 0
                    }
                }
            }

            Item {
                Layout.fillHeight: true
                Layout.fillWidth: true
            }
        }
    }
}
