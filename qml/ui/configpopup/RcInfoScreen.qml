import QtQuick 2.12
import QtQuick.Controls 2.12
import QtQuick.Layouts 1.12
import QtQuick.Dialogs 1.0
import QtQuick.Controls.Material 2.12

import Qt.labs.settings 1.0

import OpenHD 1.0

import "../../ui" as Ui
import "../elements"

Item {
    width: parent.width
    height: parent.height

    Rectangle{
        width:parent.width
        height:parent.height
        color: "#eaeaea"
    }

    ColumnLayout{
        width: parent.width
        Layout.minimumHeight: 30
        spacing: 6
        Layout.topMargin: 15

        Card {
            id: infoBox
            height: 120
            Layout.topMargin: 15
            Layout.leftMargin: 15
            Layout.rightMargin: 15
            Layout.fillWidth: true
            cardName: qsTr("About")
            cardBody:
                Text {
                text: qsTr("To enable RC over wifibroadcast change OpenHD / Ground(TMP) / ENABLE_JOY_RC=ENABLED,\nconnect a joystick (or a RC in joystick mode) and reboot.\n
You can use the other screens to validate/debug your setup.")
                height: 24
                font.pixelSize: 14
                leftPadding: 12
            }
        }
    }
}
