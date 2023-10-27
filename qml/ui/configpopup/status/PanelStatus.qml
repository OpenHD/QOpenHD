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

    ScrollView {
        id:mavlinkExtraWBParamPanel
        width: parent.width
        height: parent.height
        contentHeight: mainItem.height
        contentWidth: mainItem.width
        clip: true
        //ScrollBar.vertical.policy: ScrollBar.AlwaysOn
        ScrollBar.vertical.interactive: true

        Item{
            id: mainItem
            width: 800
            height: 40+350+80

            QOpenHDVersionCard{
                id: qopenhdversioncard
                height: 40
            }

            // The 3 status cards (OpenHD AIR & GND, FC)
            // next to each other
            StatusCardsColumn{
                id: statuscardscolumn
                width: parent.width
                height: 350


                anchors.leftMargin: 4
                anchors.topMargin: 4

                anchors.left: parent.left
                anchors.top: qopenhdversioncard.bottom
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
