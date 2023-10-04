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
        //contentWidth: mainItem.width
        clip: true
        //ScrollBar.vertical.policy: ScrollBar.AlwaysOn
        ScrollBar.vertical.interactive: true

        Item {
            id: mainItem
            //width: 1024
            width: parent.width
            height: 500

            QOpenHDVersionCard{
                id: qopenhdversioncard
                height: 80

                StatusCardsColumn{
                    width: parent.width
                    height: 250

                    anchors.leftMargin: 12
                    anchors.rightMargin: 12
                    anchors.topMargin: 12

                    id: status_openhd_fc
                    anchors.top: qopenhdversioncard.bottom
                }

                ActionsColumn {
                    id:actionsButtonMenu
                    width: parent.width
                    height: 80
                    y: (applicationWindow.height-(actionsButtonMenu.height*1.5))

                }
            }
        }
        PowerActionDialoque{
            id: powerDialog
        }
    }
}
