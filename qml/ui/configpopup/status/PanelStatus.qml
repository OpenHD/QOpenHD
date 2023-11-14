import QtQuick 2.12
import QtQuick.Controls 2.12
import QtQuick.Layouts 1.12
import QtQuick.Controls.Material 2.12

import Qt.labs.settings 1.0

import OpenHD 1.0

import "../../../ui" as Ui
import "../../elements"

Rectangle {
    id:mainRect
    width: parent.width
    height: parent.height

    color: "#eaeaea"

    function voltage_as_string(voltage_mv){
        if(voltage_mv===0)return "N/A";
        return voltage_mv+" mV"
    }
    function current_as_string(current_ma){
        if(current_ma===0) return "N/A"
        return current_ma+" mA"
    }

    function open_power_action_dialoque(system,reboot){
        powerDialog.open_dialoque(system,reboot)
    }

    TabBar {
        // This screen doesn't tab, but we use the tab bar element for a consistent style
        id: selectItemInStackLayoutBar
        width: parent.width
        TabButton {
            text: qsTr("SYSTEM STATUS")
        }
    }

    ScrollView {
        /*id:mavlinkExtraWBParamPanel
        width: parent.width
        height: parent.height
        contentHeight: mainItem.height
        contentWidth: mainItem.width
        clip: true
        //ScrollBar.vertical.policy: ScrollBar.AlwaysOn
        ScrollBar.vertical.interactive: true*/
        width: parent.width
        anchors.top: selectItemInStackLayoutBar.bottom
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.bottom: parent.bottom
        clip: true
        ScrollBar.vertical.interactive: true
        contentHeight: mainItem.height

        Item{
            id: mainItem
            width: mainRect.width
            height: 350+80

            // The 3 status cards (OpenHD AIR & GND, FC)
            // next to each other
            StatusCardsColumn{
                id: statuscardscolumn
                width: parent.width
                height: 350

                anchors.leftMargin: 4
                anchors.topMargin: 4

                anchors.left: parent.left
               // anchors.top: qopenhdversioncard.bottom
            }


            PingUtilColumn {
                id:actionsButtonMenu
                width: parent.width
                height: 80
                anchors.top: statuscardscolumn.bottom

            }
        }
    }
    PowerActionDialoque{
        id: powerDialog
    }
    DialoqueNotAlive{
        id: dialoqueNotAlive
    }
}
