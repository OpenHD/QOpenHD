import QtQuick 2.12
import QtQuick.Window 2.0
import QtQuick.Controls 2.12
import QtQuick.Layouts 1.12
import QtGraphicalEffects 1.12

import Qt.labs.settings 1.0

import OpenHD 1.0

import "../../../ui" as Ui
import "../../elements"

ScrollView {
    clip:true
    //contentHeight: 850
    width: parent.width
    height: parent.height
    background: Rectangle { color: "#eaeaea" }

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
            width:parent.width
            cardName: qsTr("Info")
            cardBody:
                Text {
                text: qsTr("Enable OpenHD-RC: \n\n1. OpenHD GND: Set 'ENABLE_JOY_RC' to 'ENABLED',\n2.Connect a joystick via USB to GND Station\n3.Optionally reboot\n\nYou can use the other screens to validate/debug your setup.\n"+
                           "NOTE: Using a seperate RC link (e.g. ExpressLRS) is recommended !\n"
                           )
                height: 24
                font.pixelSize: 14
                leftPadding: 12
            }
        }
        Card {
            id: infoBox2
            height: 100
            Layout.topMargin: 15
            Layout.leftMargin: 15
            Layout.rightMargin: 15
            Layout.fillWidth: true
            width:parent.width
            cardName: qsTr("Channel mapping")
            cardBody:
                Text {
                text: qsTr("Channel mapping is not intuitive, but it works when done correctly.\nIf you cannot make it work, any proper RC controller (e.g. running EdgeTX / OpenTX)\nsupports more advanced channel mapping and works via USB !")
                height: 24
                font.pixelSize: 14
                leftPadding: 12
            }
        }

    }
}
