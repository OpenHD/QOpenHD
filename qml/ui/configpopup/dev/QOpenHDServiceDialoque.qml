import QtQuick 2.12
import QtQuick.Controls 2.12
import QtQuick.Layouts 1.12
import QtQuick.Dialogs 1.1
import QtQuick.Controls.Material 2.12

import Qt.labs.settings 1.0

import OpenHD 1.0

import "../../../ui" as Ui
import "../../elements"


// Dialoque for interacting with the QOpenHD service (depending on platform)
Card {
    id: qopenhdpowerdialoque
    height: 240
    width: 400
    z: 5.0
    anchors.centerIn: parent
    cardNameColor: "black"
    hasHeaderImage: true

    Component.onCompleted: visible = false

    property bool stateVisible: visible

    function open_dialoque(type){
        qopenhdpowerdialoque.m_type=type
        qopenhdpowerdialoque.visible=true
    }

    property int m_type : 0

    function get_info_text(){
        if(m_type==0){
            return "Only for RPI - Stops QOpenHD and lets the autostart service restart it."
        }
        return "Only for RPI - Stops QOpenHD and disables the autostart service until the next reboot. Can be used to get into terminal on rpi."
    }

    function get_button_text(){
        if(m_type==0){
            return "Restart QOpenHD"
        }
        return "Terminate QOpenHD"
    }

    cardName: qsTr("QOpenHD")
    cardBody: Column {
        height: qopenhdpowerdialoque.height
        width: qopenhdpowerdialoque.width

        Text {
            text: get_info_text()
            width: parent.width
            leftPadding: 12
            rightPadding: 12
            wrapMode: Text.WordWrap
        }
    }

    hasFooter: true
    cardFooter: Item {
        anchors.fill: parent
        Button {
            width: 96
            height: 48
            text: qsTr("Cancel")
            anchors.left: parent.left
            anchors.leftMargin: 12
            anchors.bottom: parent.bottom
            anchors.bottomMargin: 6
            font.pixelSize: 14
            font.capitalization: Font.MixedCase
            onPressed: {
                qopenhdpowerdialoque.visible=false;
            }
        }

        Button {
            width: 140
            height: 48
            anchors.right: parent.right
            anchors.rightMargin: 12
            anchors.bottom: parent.bottom
            anchors.bottomMargin: 6
            font.pixelSize: 14
            font.capitalization: Font.MixedCase
            Material.accent: Material.Red
            highlighted: true

            text:  get_button_text()

            onPressed: {
                if(m_type==0){
                    _qopenhd.quit_qopenhd()
                }else{
                    _qopenhd.disable_service_and_quit()
                }
            }
        }
    }
}

