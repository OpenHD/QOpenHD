import QtQuick 2.12
import QtQuick.Controls 2.12
import QtQuick.Layouts 1.12
import QtQuick.Dialogs 1.0
import QtQuick.Controls.Material 2.12

import Qt.labs.settings 1.0

import OpenHD 1.0

import "../../../ui" as Ui
import "../../elements"

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
            height: 200
            Layout.topMargin: 15
            Layout.leftMargin: 15
            Layout.rightMargin: 15
            Layout.fillWidth: true
            cardName: qsTr("About")
            cardBody:
                Text {
                width: parent.width
                height: parent.height
                text: qsTr("To enable RC over wifibroadcast go to OpenHD / Ground (Ground parameters set) and set 'ENABLE_JOY_RC' to 'ENABLED',"+
"connect a joystick (or a RC in joystick mode) and (optionally) reboot.\n"+
"You can use the other screens to validate/debug your setup.\n"+
"INFO: Channel mapping is not intuitive, but it works when done correctly.\n"+
"If you cannot make it work, any proper RC controller (e.g. running EdgeTX / OpenTX)\n"+
"supports more advanced channel mapping and works via USB !")
                font.pixelSize: 14
                wrapMode: Text.WordWrap
            }
        }
    }
}
