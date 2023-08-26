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

    property string m_info_text: "1) Make sure WIFI_HOTSPOT_E is enabled (on air or ground unit)\n\n"+
                                 "2) Connect to WiFi: openhd pw openhdopenhd\n\n"+
                                 "3) Press 'Connect' button.\n\n"+
                                 "NOTE: You cannot use WIFI hotspot during flight (while armed)"

    ColumnLayout{
        anchors.fill: parent

        spacing: 6
        Text{
            Layout.alignment: Qt.AlignTop
            width:parent.width
            wrapMode: Text.WordWrap
            text: m_info_text
        }
        Button{
            Layout.alignment: Qt.AlignTop
            text: "Connect Air/Ground Hotspot"
            onClicked: _mavlinkTelemetry.add_tcp_connection_handler("192.168.3.1") // ground / air pi address in hotspot mode
        }
        // padding to bottom
        Item{
            Layout.fillHeight: true
            Layout.fillWidth: true
        }
    }
}
