import QtQuick 2.12
import QtQuick.Controls 2.12
import QtQuick.Layouts 1.12
import QtQuick.Controls.Material 2.12

import Qt.labs.settings 1.0

import OpenHD 1.0

import "../../../ui" as Ui
import "../../elements"

Rectangle {
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

    function open_power_action_dialoque(power_action_type){
        powerDialog.powerAction=power_action_type
        powerDialog.visible=true
    }

    ScrollView {
        id:mavlinkExtraWBParamPanel
        width: parent.width
        height: parent.height
        contentHeight: mainItem.height
        clip: true
        //ScrollBar.vertical.policy: ScrollBar.AlwaysOn
        ScrollBar.vertical.interactive: true

        Item {
            id: mainItem
            width: parent.width
            height: 500

            QOpenHDVersionCard{
                id: qopenhdversioncard
                height: 80
                //anchors.top: airBox.bottom
            }

            OpenHDAndFCStatusColumn{
                width: parent.width
                height: 300

                anchors.leftMargin: 12
                anchors.rightMargin: 12
                anchors.topMargin: 12

                id: status_openhd_fc
                anchors.top: qopenhdversioncard.bottom
            }

            ActionsColumn{
                width:parent.width
                height: 80
                anchors.top: status_openhd_fc.bottom
                anchors.topMargin: 2
            }
        }
    }
    PowerActionDialoque{
        id: powerDialog
    }
}