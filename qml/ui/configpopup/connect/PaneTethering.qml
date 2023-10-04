import QtQuick 2.12
import QtQuick.Controls 2.12
import QtQuick.Layouts 1.12
import QtQuick.Dialogs 1.0
import QtQuick.Controls.Material 2.12

import Qt.labs.settings 1.0

import OpenHD 1.0

import "../../../ui" as Ui
import "../../elements"
Rectangle {
    width: parent.width
    height: parent.height
    property bool m_local_mode_enabled: _mavlinkTelemetry.udp_localhost_mode_enabled


    Rectangle {
        id: innerRect
        width: 300
        height: 300
        anchors.centerIn: parent
        anchors.horizontalCenterOffset: 40
        ColumnLayout {
            spacing: 6

            RowLayout {
                Button{
                    text: m_local_mode_enabled ? "LOCAL MODE ACTIVE" : "ENABLE LOCAL MODE"
                    Layout.preferredWidth: 180
                    onClicked: {
                        _mavlinkTelemetry.enable_udp()
                    }
                    enabled: !m_local_mode_enabled
                }
                ButtonIconInfoText {
                    m_info_text: "Use this if you are running QOpenHD on your ground station itself and don't use it as a secondary device."+
                                 "\n\nIt uses UDP localhost to communicate with OpenHD core via mavlink (best performance and latency)."
                }
            }
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
}
