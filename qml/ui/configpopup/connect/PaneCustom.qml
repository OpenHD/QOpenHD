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

    Rectangle {
        id: innerRect
        width: 300
        height: 300
        anchors.centerIn: parent
        anchors.horizontalCenterOffset: 70
        ColumnLayout {
            spacing: 6

            RowLayout {
                TextField {
                    id: textFieldip
                    validator: RegExpValidator {
                        regExp:  /^((?:[0-1]?[0-9]?[0-9]|2[0-4][0-9]|25[0-5])\.){0,3}(?:[0-1]?[0-9]?[0-9]|2[0-4][0-9]|25[0-5])$/
                    }
                    inputMethodHints: Qt.ImhFormattedNumbersOnly
                    text: "192.168.178.36" //settings.dev_mavlink_tcp_ip
                }
                ButtonIconInfoText {
                    m_info_text: "Connect with a OpenHD Ground Station, via TCP, this will still stream video va UDP for lower latency, after a successful conneciton."
                }
            }

            Button {
                Layout.alignment: Qt.AlignTop
                text: "CONNECT TCP"
                onClicked: {
                    var ip_address = textFieldip.text
                    if (_qopenhd.is_valid_ip(ip_address)) {
                        _mavlinkTelemetry.add_tcp_connection_handler(ip_address)
                    } else {
                        _qopenhd.show_toast("Please enter a valid ip")
                    }
                }
            }

            Button {
                text: "RE-ENABLE UDP"
                onClicked: {
                    _mavlinkTelemetry.enable_udp()
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
