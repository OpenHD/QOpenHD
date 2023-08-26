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

    property string m_info_text: "1) Connect your phone via high quality USB cable to your ground station.\n\n"+
                                 "2) enable USB Tethering on your phone.\n\n"+
                                 "3) Telemetry and video forwarding is started automatically \n\n"+
                                 " ! Requires a phone and cellular contract that allows USB tethering. !"

    ColumnLayout{
        anchors.fill: parent
        anchors.top: parent.top
        spacing: 6

        Text{
            Layout.alignment: Qt.AlignTop
            width:parent.width
            wrapMode: Text.WordWrap
            text: m_info_text
        }
        Button{
            Layout.alignment: Qt.AlignTop
            text: "Open settings"
            onClicked: _qopenhd.android_open_tethering_settings()
        }
        // padding to bottom
        Item{
            Layout.fillHeight: true
            Layout.fillWidth: true
        }
    }
}
