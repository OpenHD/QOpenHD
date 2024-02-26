import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.12

import QtQuick.Shapes 1.0
import QtQuick.Controls.Material 2.0

import Qt.labs.settings 1.0

import OpenHD 1.0

import "../elements"

SideBarBasePanel{
    override_title: "Status / Advanced"

    Column {
        anchors.top: parent.top
        anchors.topMargin: secondaryUiHeight/8 + 20
        anchors.leftMargin: 10
        spacing: 10

        InfoElement2{
            override_text_left: "Connection:"
            override_text_right: {
                if(_ohdSystemAir.is_alive && _ohdSystemGround.is_alive){
                    return "Connected";
                }
                if(_ohdSystemAir.is_alive){
                    return "AIR only";
                }
                if(_ohdSystemGround.is_alive){
                    return "GND only"
                }
                return "NOT CONNECTED";
            }
        }
        /*InfoElement2{
            override_text_left: "TODO"
            override_text_right:"TODO"
        }*/

        Button {
            id: button
            text: "Advanced Menu"

            onClicked: {
                settings_panel.visible = true
            }
        }
    }
}
