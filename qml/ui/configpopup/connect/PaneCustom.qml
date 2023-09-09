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
    //color: "green"

    property string m_info_text: "CUSTOM"

    ColumnLayout{
        anchors.fill: parent

        spacing: 6
        Text{
            Layout.alignment: Qt.AlignTop
            width:parent.width
            wrapMode: Text.WordWrap
            text: m_info_text
        }
        RowLayout{
            TextField {
                id: textFieldip
                validator: RegExpValidator {
                    regExp:  /^((?:[0-1]?[0-9]?[0-9]|2[0-4][0-9]|25[0-5])\.){0,3}(?:[0-1]?[0-9]?[0-9]|2[0-4][0-9]|25[0-5])$/
                }
                inputMethodHints: Qt.ImhFormattedNumbersOnly
                text: "192.168.178.36" //settings.dev_mavlink_tcp_ip
            }
            ButtonIconInfoText{
                m_info_text: "Enter your grund station IP, then click 'CONNECT TCP'"
            }
        }

        Button{
            Layout.alignment: Qt.AlignTop
            text: "CONNECT TCP"
            onClicked: {
                var ip_address=textFieldip.text
                if(_qopenhd.is_valid_ip(ip_address)){
                    _mavlinkTelemetry.add_tcp_connection_handler(ip_address)
                }else{
                    _messageBoxInstance.set_text_and_show("Please enter a valid ip");
                }
            }
        }
        Button{
            text: "RE-ENABLE UDP"
            onClicked: {
                _mavlinkTelemetry.enable_udp()
            }
        }
        // padding to bottom
        Item{
            Layout.fillHeight: true
            Layout.fillWidth: true
        }

    }
}
