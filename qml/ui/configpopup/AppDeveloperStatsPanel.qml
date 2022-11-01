import QtQuick 2.12
import QtQuick.Controls 2.12
import QtQuick.Layouts 1.12
import QtGraphicalEffects 1.12

import Qt.labs.settings 1.0

import OpenHD 1.0

import "../../ui" as Ui
import "../elements"

// Dirty here i place stuff that can be usefaully during development
Rectangle {
    id: elementAppDeveloperStats
    Layout.fillHeight: true
    Layout.fillWidth: true

    property int rowHeight: 64
    property int text_minHeight: 20

    color: "#eaeaea"

    ColumnLayout{
        Layout.fillWidth: true
        Layout.minimumHeight: 30
        spacing: 6
        anchors.top: parent.top
        anchors.left: parent.left
        anchors.margins: 10

        Button{
            height: 24
            text: "Restart local OHD service"
            onClicked:{
                _qopenhd.restart_local_oenhd_service()
            }
        }

        Button{
            height: 24
            text: "Run dhclient eth0 (might block UI for N seconds)"
            onClicked:{
                _qopenhd.run_dhclient_eth0()
            }
        }
    }
}
