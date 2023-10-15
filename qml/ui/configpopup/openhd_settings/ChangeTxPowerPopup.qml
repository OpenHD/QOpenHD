import QtQuick 2.0

import QtQuick 2.12
import QtQuick.Controls 2.12
import QtQuick.Layouts 1.12
import QtQuick.Dialogs 1.0
import QtQuick.Controls.Material 2.12
import QtQuick.Controls.Styles 1.4

import Qt.labs.settings 1.0

import OpenHD 1.0

import "../../../ui" as Ui
import "../../elements"

import QtCharts 2.0

Rectangle{
    width: parent.width
    height: parent.height /2
    anchors.bottom: parent.bottom
    anchors.left: parent.left
    color: "#8cbfd7f3"

    property bool m_is_air: false

    property int m_user_selected_card_manufacturer: -1;

    function open(){
        if(_fcMavlinkSystem.is_alive && _fcMavlinkSystem.armed){
            _qopenhd.show_toast("WARNING: Changing TX power while armed is not recommended !");
        }
        var card_chipset_type=get_chipset_type();
        if(!card_chipset_type==0 || card_chipset_type==1){
            _messageBoxInstance.set_text_and_show("Changing tx power is only possible on openhd supported cards.");
            return;
        }
        visible=true;
        enabled=true;
    }

    function close(){
        visible=false;
        enabled=false;
    }

    function get_chipset_type(){
        if(m_is_air){
            return _wifi_card_air.card_type;
        }
        return _wifi_card_gnd0.card_type;
    }

    function get_card_chipset_str(){
        var chipset=get_chipset_type();
        if(chipset==0){
            return "RTL88XXAU";
        }else if(chipset==1){
            return "RTL88XXBU";
        }
        return "ERROR";
    }
    // Should never show up !
    ListModel{
        id: model_error
        ListElement {title: "ERROR"; value: -1}
    }

    ListModel{
        id: model_rtl8812au_manufacturers
        ListElement {title: "SELECT MANUFACTURER"; value: -1}
        ListElement {title: "ASUS"; value: 0}
        ListElement {title: "ALIEXPRESS"; value: 1}
        ListElement {title: "OTHER"; value: 2}
    }
    ListModel{
        id: model_rtl8812bu_manufacturers
        ListElement {title: "SELECT MANUFACTURER"; value: -1}
        ListElement {title: "COMFAST"; value: 0}
        ListElement {title: "OTHER"; value: 1}
    }

    function get_model_manufacturer_for_chip_type(){
        var chip_type=get_chipset_type();
        if(chip_type==0){
            return model_rtl8812au_manufacturers;
        }else if(chip_type==1){
            return model_rtl8812bu_manufacturers;
        }
        return model_error;
    }

    // TX power choices for each chipset / manufacturer
    ListModel{
        id: model_rtl8812au_manufacturer_asus_txpower
        ListElement {title: "Please select"; value: -1}
        ListElement {title: "LOW    [22] ~20mW (DEFAULT) "; value: 22}
        ListElement {title: "MEDIUM [37] ~100mW          "; value: 37}
        ListElement {title: "HIGH   [53] ~320mW          "; value: 53}
        ListElement {title: "MAX1   [58] ~420mW (MCS<=2!)"; value: 58}
        ListElement {title: "MAX2   [63] ~500mW (MCS<=2!)"; value: 63}
    }
    ListModel{
        id: model_rtl8812au_manufacturer_aliexpress_hp
        ListElement {title: "Please select"; value: -1}
        ListElement {title: "LOW    [16]"; value: 16}
        ListElement {title: "MEDIUM [22]"; value: 22}
        ListElement {title: "HIGH   [24]"; value: 24}
        ListElement {title: "MAX    [26]"; value: 26}
    }
    ListModel{
        id: model_rtl8812au_manufacturer_generic
        ListElement {title: "Please select"; value: -1}
        ListElement {title: "[22] (DANGER,ARBITRARY)"; value: 22}
        ListElement {title: "[37] (DANGER,ARBITRARY)"; value: 37}
        ListElement {title: "[53] (DANGER,ARBITRARY)"; value: 53}
        ListElement {title: "[58] (DANGER,ARBITRARY)"; value: 58}
        ListElement {title: "[63] (DANGER,ARBITRARY)"; value: 63}
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
        ListElement {title: "25mW (maybe)"; value: 25}
        ListElement {title: "100mW (maybe)"; value: 100}
        ListElement {title: "<=300mW (maybe)"; value: 300}
        ListElement {title: "<=1000mW (maybe)"; value: 1000}
        ListElement {title: "<=20000mW (maybe)"; value: 2000}
    }

    function get_model_txpower_for_chip_type_manufacturer(){
        var chip_type=get_chipset_type();
        var manufacturer=m_user_selected_card_manufacturer;
        if(manufacturer<0){
            return model_error;
        }
        if(chip_type==0){
            // RTL8812AU
            if(manufacturer==0){
                return model_rtl8812au_manufacturer_asus_txpower;
            }else if(manufacturer==1){
                return model_rtl8812au_manufacturer_aliexpress_hp;
            }
            return model_rtl8812au_manufacturer_generic;
        }else if(chip_type==1){
            // RTL8812BU
            if(m_card_manufacturer_type==0){
                return model_rtl8812bu_manufacturer_comfast;
            }
            return model_rtl8812bu_manufacturer_generic;
        }
        return model_error;
    }


    function get_text_wifi_tx_power(){
        // "99 TPI DISARM: XX ARM: XX";
        if(m_is_air){
            if(!_wifi_card_air.alive) return "N/A";
            return ""+_wifi_card_air.tx_power+" "+_wifi_card_air.tx_power_unit+" DISARM:"+_wifi_card_air.tx_power_disarmed+" ARM:"+_wifi_card_air.tx_power_armed
        }
        if(!_wifi_card_gnd0.alive) return "N/A";
        return ""+_wifi_card_gnd0.tx_power+" "+_wifi_card_gnd0.tx_power_unit+" DISARM:"+_wifi_card_gnd0.tx_power_disarmed+" ARM:"+_wifi_card_gnd0.tx_power_armed
    }

    // state 0: current state 1: disarmed state 2: armed
    //
    function get_current_tx_power_int(state){
        var card = m_is_air ? _wifi_card_air : _wifi_card_gnd0;
        if(state==0){
            return card.tx_power;
        }else if(state==1){
            return card.tx_power_disarmed;
        }
        return card.tx_power_armed;
    }
    function get_tx_power_unit(){
        if(m_is_air) return _wifi_card_air.tx_power_unit;
        return _wifi_card_gnd0.tx_power_unit;
    }

    ColumnLayout{
        id: bla1
        width: parent.width /3
        anchors.top: parent.top
        anchors.left: parent.left
        Text{
            text: m_is_air ? "AIR TX Power" : "GND TX power";
        }
        Text{
            text: "YOUR CHIPSET:" +get_card_chipset_str()
        }

        ComboBox {
            Layout.fillWidth: true
            leftPadding: 12
            rightPadding: 12
            id: comboBoxCardSelectManufacturer
            model: get_model_manufacturer_for_chip_type()
            textRole: "title"
            onCurrentIndexChanged: {
                var manufacturer=comboBoxCardSelectManufacturer.model.get(comboBoxCardSelectManufacturer.currentIndex).value;
                m_user_selected_card_manufacturer=manufacturer;
            }
        }
        Text{
            text: "CURRENT:"+get_current_tx_power_int(0)+" "+get_tx_power_unit();
        }
    }

    ColumnLayout{
        id: bla2
        width: parent.width /3
        anchors.left: bla1.right
        anchors.top: parent.top
        Text{
            text: "DISARMED"
        }
        Text{
            text: ""+get_current_tx_power_int(1)+" "+get_tx_power_unit();
        }
        ComboBox {
            Layout.fillWidth: true
            leftPadding: 12
            rightPadding: 12
            id: combo_box_txpower_disarmed
            model: get_model_txpower_for_chip_type_manufacturer()
            textRole: "title"
            enabled: m_user_selected_card_manufacturer>=0;
        }
        Button{
            text: "APPLY"
            enabled: m_user_selected_card_manufacturer>=0;
        }
    }
    ColumnLayout{
        width: parent.width /3
        anchors.right: parent.right
        anchors.top: parent.top
        Text{
            text: "ARMED"
        }
        Text{
            text: {
                var power_int=get_current_tx_power_int(2);
                if(power_int==0) return "DISABLED";
                return ""+get_current_tx_power_int(2)+" "+get_tx_power_unit();
            }
        }
        ComboBox {
            Layout.fillWidth: true
            leftPadding: 12
            rightPadding: 12
            id: combo_box_txpower_armed
            model: get_model_txpower_for_chip_type_manufacturer()
            textRole: "title"
            enabled: m_user_selected_card_manufacturer>=0;
        }

        Button{
            text: "APPLY"
            enabled: m_user_selected_card_manufacturer>=0;
        }
    }

    Button{
        text: "CLOSE"
        anchors.top: parent.top
        anchors.right: parent.right
        onClicked: {
            close()
        }
    }
    Text{
        width: parent.width
        height: parent.height / 2;
        anchors.bottom: parent.bottom
        anchors.left: parent.left
        text: "WARNING: Selecting the wrong manufacturer and applying a tx power can destroy your card !";
        color: "red"
        // Only on rtl8812au
        //visible: get_chipset_type()==0;
        fontSizeMode: Text.Fit
        minimumPointSize: 10
        font.pointSize: 60
    }

}
