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

    property string m_info_text: "Use this mode if you are running QOpenHD on your ground station itself - e.g. if you are using a RPI as ground station and connected
a display via HDMI to your ground station, or x86 and running OpenHD Core and QOpenHD on the same system."+
"In this mode, QOpenHD uses UDP localhost to communicate with OpenHD core via mavlink (lowest latency and best performance).
However, if you are running QOpenHD as an app on an external device (e.g. your android phone) you have to use the appropiate connection page and its description to
connect QOpenHD to your ground station."

    property bool m_local_mode_enabled: _mavlinkTelemetry.udp_localhost_mode_enabled

    ColumnLayout{
        anchors.fill: parent

        spacing: 6
        Text{
            Layout.fillWidth: true
            Layout.preferredHeight: 200
            //Layout.alignment: Qt.AlignTop
            //width:parent.width
            wrapMode: Text.WordWrap
            text: m_info_text
        }
        Button{
            text: m_local_mode_enabled ? "LOCAL MODE ACTIVE" : "ENABLE LOCAL MODE"
            onClicked: {
                _mavlinkTelemetry.enable_udp()
            }
            enabled: !m_local_mode_enabled
        }
        // filler
        Item{
            Layout.fillWidth: true
            Layout.fillHeight: true
        }
    }
}
