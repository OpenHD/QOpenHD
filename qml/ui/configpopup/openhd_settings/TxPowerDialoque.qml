import QtQuick 2.12
import QtQuick.Controls 2.12
import QtQuick.Layouts 1.12
import QtQuick.Dialogs 1.0
import QtQuick.Controls.Material 2.12

import "../../elements"

// I fucking hate writing UIs in QT
Card {
    id: dialoqueTxPower
    width: 360
    height: 340
    z: 5.0
    anchors.centerIn: parent
    cardName: qsTr("Change TX PWR "+get_is_ground_as_string())
    cardNameColor: "black"
    visible: false

    // check if all ground cards use the same chipset - otherwise, this wizard cannot be used
    function gnd_check_all_active_cards_are_same_type(){
        var card0_type=_wifi_card_gnd0.card_type;
        if(_wifi_card_gnd1.alive && (_wifi_card_gnd1.card_type != card0_type)){
            return false;
        }
        if(_wifi_card_gnd2.alive && (_wifi_card_gnd2.card_type != card0_type)){
            return false;
        }
        if(_wifi_card_gnd3.alive && (_wifi_card_gnd3.card_type != card0_type)){
            return false;
        }
        return true;
    }

    function open_tx_power_dialoque(ground){
        if(_fcMavlinkSystem.is_alive && _fcMavlinkSystem.armed){
            _messageBoxInstance.set_text_and_show("Cannot change while armed",3);
            return;
        }
        m_curr_index=0;
        m_is_ground=ground;
        m_card_chip_type=-1;
        m_card_manufacturer_type=-1
        comboBoxSelectedArmedDisarmed.currentIndex=0
        comboBoxCardSelectTxPower.currentIndex=0
        comboBoxCardSelectManufacturer.currentIndex=0;
        // We figure out the chip type automatcally (info from openhd)
         var wifi_card_chip_type=-1;
        if(m_is_ground){
            // Check if all cards are of the same type
            if(!gnd_check_all_active_cards_are_same_type()){
                _messageBoxInstance.set_text_and_show("This wizard is only available when you use the same card(s) on ground. Please unify your gnd station cards.
You can still use the RAW OpenHD AIR / GROUND Parameters to change your tx power.");
                return;
            }
            wifi_card_chip_type=_wifi_card_gnd0.card_type;
        }else{
           wifi_card_chip_type=_wifi_card_air.card_type;
        }
        if(wifi_card_chip_type<=0){
            _messageBoxInstance.set_text_and_show("Card type unknown - please use a supported card. You can still change the tx power manually via the param set, but probably
the card driver doesn't support changing it.");
            return;
        }
        // OpenHD has 0 for unknown, we do not allow 0
        m_card_chip_type=wifi_card_chip_type-1;
        //m_card_chip_type=0; // RTL8812AU
        dialoqueTxPower.visible=true
    }

    property int m_curr_index: 0

    property bool m_is_ground: true
    function get_is_ground_as_string(){
        return m_is_ground ? "GND" : "AIR";
    }

    ListModel{
        id: armed_or_disarmed_model
        ListElement {title: "NOT SELECTED"; value: -1}
        ListElement {title: "DISARMED"; value: 0}
        ListElement {title: "ARMED (RECOMMENDED)"; value: 0}
    }
    property bool m_change_armed: false
    function get_change_armed_as_string(){
        return m_change_armed ? "ARMED" : "DISARMED";
    }

    // Chip type is automatically refered from OpenHD
    property int m_card_chip_type: -1;
    function get_card_chip_type_as_string(){
        if(m_card_chip_type==0) return "RTL8812AU";
        if(m_card_chip_type==1) return "RTL8812BU";
        return "UNKNOWN";
    }

    // Manufacturer the user has to select
    property int m_card_manufacturer_type: -1
    function get_card_manufacturer_type_as_string(){
        if(m_card_chip_type==0){
            // RTL8812AU
            if(m_card_manufacturer_type==0)return "ASUS";
            if(m_card_manufacturer_type==1)return "ALIEXPRESS";
            if(m_card_manufacturer_type==2)return "OTHER";
        }else{
            // RTL8812BU
            if(m_card_manufacturer_type==0)return "COMFAST";
            if(m_card_manufacturer_type==1)return "OTHER";
        }
        return "UNKNWON";
    }

    ListModel{
        id: plcaeholder_model
        ListElement {title: "I should never appear"; value: -1}
    }

    ListModel{
        id: model_rtl8812au_manufacturers
        ListElement {title: "NOT SELECTED"; value: -1}
        ListElement {title: "ASUS"; value: 0}
        ListElement {title: "ALIEXPRESS"; value: 1}
        ListElement {title: "OTHER"; value: 2}
    }
    ListModel{
        id: model_rtl8812bu_manufacturers
        ListElement {title: "NOT SELECTED"; value: -1}
        ListElement {title: "COMFAST"; value: 0}
        ListElement {title: "OTHER"; value: 1}
    }

    function get_model_manufacturer_for_chip_type(){
        if(m_card_chip_type==0){
            return model_rtl8812au_manufacturers;
        }else if(m_card_chip_type==1){
            return model_rtl8812bu_manufacturers;
        }
        return plcaeholder_model;
    }

    property int tx_power_index_or_mw: -1

    ListModel{
        id: model_rtl8812au_manufacturer_asus_txpower
        ListElement {title: "Please select"; value: -1}
        ListElement {title: "LOW(~25mW)[22]"; value: 22}
        ListElement {title: "MEDIUM [37]"; value: 37}
        ListElement {title: "HIGH [53]"; value: 53}
        ListElement {title: "MAX1(<=MCS2 only)[58]"; value: 58}
        ListElement {title: "MAX2(<=MCS2 only)[63]"; value: 63}
    }
    ListModel{
        id: model_rtl8812au_manufacturer_aliexpress_hp
        ListElement {title: "Please select"; value: -1}
        ListElement {title: "LOW [16]"; value: 16}
        ListElement {title: "MEDIUM [22]"; value: 22}
        ListElement {title: "HIGH [24]"; value: 24}
        ListElement {title: "MAX [26]"; value: 26}
    }
    ListModel{
        id: model_rtl8812au_manufacturer_generic
        ListElement {title: "Please select"; value: -1}
        ListElement {title: "[22] (DANGER)"; value: 22}
        ListElement {title: "[37] (DANGER)"; value: 37}
        ListElement {title: "[53] (DANGER)"; value: 53}
        ListElement {title: "[58] (DANGER)"; value: 58}
        ListElement {title: "[63] (DANGER)"; value: 63}
    }
    // RTL8812BU begin
    ListModel{
        id: model_rtl8812bu_manufacturer_comfast
        ListElement {title: "Please select"; value: -1}
        ListElement {title: "~25mW"; value: 25}
        ListElement {title: "~100mW"; value: 100}
        ListElement {title: "~200mW"; value: 200}
        ListElement {title: "~300mW"; value: 300}
    }
    ListModel{
        id: model_rtl8812bu_manufacturer_generic
        ListElement {title: "Please select"; value: -1}
        ListElement {title: "25mW"; value: 25}
        ListElement {title: "100mW"; value: 100}
        ListElement {title: "<=300mW"; value: 300}
        ListElement {title: "<=1000mW"; value: 1000}
        ListElement {title: "<=20000mW"; value: 2000}
    }

    function get_model_select_tx_power_index_for_card_chip_type_and_manufacturer(){
        if(m_card_chip_type==0){
            // RTL8812AU
            if(m_card_manufacturer_type==0){
                return model_rtl8812au_manufacturer_asus_txpower;
            }else if(m_card_manufacturer_type==1){
                return model_rtl8812au_manufacturer_aliexpress_hp;
            }
            return model_rtl8812au_manufacturer_generic;
        }else if(m_card_chip_type==1){
            // RTL8812BU
            if(m_card_manufacturer_type==0){
                return model_rtl8812bu_manufacturer_comfast;
            }
            return model_rtl8812bu_manufacturer_generic;
        }
        return plcaeholder_model;
    }

    cardBody: Item{
        height: 200
        width: 320
        Item{
            id: item1
            width: parent.width
            height: parent.height
            visible: m_curr_index==0

            Text{
                id: card_select_armed_disarmed_description
                text: "Do you want to change the TX power in armed / disarmed state ?
(RECOMMENDED: ONly change armed tx power, such that your card(s) do not overheat on the bench)"
                width: parent.width
                height: parent.height / 2
                leftPadding: 12
                rightPadding: 12
                wrapMode: Text.WordWrap
            }
            ComboBox {
                id: comboBoxSelectedArmedDisarmed
                width: parent.width
                //height: 100
                anchors.top: card_select_armed_disarmed_description.bottom
                model: armed_or_disarmed_model
                textRole: "title"
                onCurrentIndexChanged: {
                    if(comboBoxSelectedArmedDisarmed.currentIndex==1)m_change_armed=false;
                    if(comboBoxSelectedArmedDisarmed.currentIndex==2)m_change_armed=true;
                }
            }
        }
        Item{
            id: item2
            width: parent.width
            height: parent.height
            visible: m_curr_index==1

            Text{
                id: card_select_manufcturer_description
                text: "Select your card manufacturer from the list below"
                width: parent.width
                height: (parent.height-100) / 2
                leftPadding: 12
                rightPadding: 12
                wrapMode: Text.WordWrap
            }
            ComboBox {
                id: comboBoxCardSelectManufacturer
                width: parent.width
                //height: 100
                anchors.top: card_select_manufcturer_description.bottom
                model: get_model_manufacturer_for_chip_type()
                textRole: "title"
                onCurrentIndexChanged: {
                    var manufacturer=comboBoxCardSelectManufacturer.model.get(comboBoxCardSelectManufacturer.currentIndex).value;
                    console.log("Selected manufacturerer "+get_card_chip_type_as_string()+" :"+manufacturer);
                    m_card_manufacturer_type=manufacturer;
                }
            }
        }

        Item{
            id: item3
            width: parent.width
            height: parent.height
            visible: m_curr_index==2

            Text{
                id: card_select_txpower_description
                text: "Please select your TX power for:\n"+get_change_armed_as_string()+" state"+"\n"+get_card_chip_type_as_string()+"\n"+get_card_manufacturer_type_as_string()+"\n";
                width: parent.width
                height: parent.height / 2
                leftPadding: 12
                rightPadding: 12
                wrapMode: Text.WordWrap
            }
            ComboBox {
                id: comboBoxCardSelectTxPower
                width: parent.width
                //height: 100
                anchors.top: card_select_txpower_description.bottom
                model: get_model_select_tx_power_index_for_card_chip_type_and_manufacturer()
                textRole: "title"
                onCurrentIndexChanged: {
                    var tx_power=comboBoxCardSelectTxPower.model.get(comboBoxCardSelectTxPower.currentIndex).value;
                    tx_power_index_or_mw=tx_power;
                    console.log("Selected TX power (mW or index)"+tx_power_index_or_mw);
                }
            }
        }
    }
    hasFooter: true
    cardFooter: Item {
        anchors.fill: parent
        Item{
            id: itemFooter1
            anchors.fill: parent
            visible: m_curr_index==0
            RowLayout{
                Button{
                    text: "CANCEL"
                    onClicked: {
                        txPowerDialoque.visible=false;
                    }
                }
                Button{
                    text: "Continue"
                    onClicked: {
                        if(comboBoxSelectedArmedDisarmed.currentIndex<=0){
                            _messageBoxInstance.set_text_and_show("Please specify armed / disarmed",5);
                        }else{
                            m_curr_index=1;
                        }
                    }
                }
            }
        }
        Item{
            id: itemFooter2
            anchors.fill: parent
            visible: m_curr_index==1
            RowLayout{
                Button{
                    text: "CANCEL"
                    onClicked: {
                        txPowerDialoque.visible=false;
                    }
                }
                Button{
                    text: "Continue"
                    onClicked: {
                        if(m_card_manufacturer_type<0){
                            _messageBoxInstance.set_text_and_show("Please select your card manufacturer",5);
                        }else{
                            m_curr_index=2;
                        }
                    }
                }
            }
        }
        Item{
            id: itemFooter3
            anchors.fill: parent
            visible: m_curr_index==2
            RowLayout{
                Button{
                    text: "CANCEL"
                    onClicked: {
                        txPowerDialoque.visible=false;
                    }
                }
                Button{
                    text: "APPLY"
                    onClicked: {
                        if(tx_power_index_or_mw<0){
                            _messageBoxInstance.set_text_and_show("Please select a valid tx power",5);
                            return;
                        }
                        var success=false
                        var is_tx_power_index_unit = m_card_chip_type==0;

                        success = _wbLinkSettingsHelper.set_param_tx_power(m_is_ground,is_tx_power_index_unit,m_change_armed,tx_power_index_or_mw)
                        if(success==true){
                            txPowerDialoque.visible=false;
                            var message = "Set TX POWER "+get_change_armed_as_string()+" to ";
                            if(is_tx_power_index_unit){
                                message += ""+tx_power_index_or_mw+" tx power index (unitless)"
                            }else{
                                message += ""+tx_power_index_or_mw+" mW"
                            }
                            if(m_change_armed){
                                message += "\nNOTE: Only applied once you arm your FC !";
                            }
                            _messageBoxInstance.set_text_and_show(message, 10);
                        }else{
                            _messageBoxInstance.set_text_and_show("Cannot change TX power, please try again",5);
                        }
                    }
                }
            }

        }
    }
}
