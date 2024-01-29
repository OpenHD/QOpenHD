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

Rectangle{
    //width: parent.width-12
    //height: parent.height*2/3;
    width: parent.width - 20
    height: parent.height -20
    anchors.centerIn: parent
    color: "#333c4c"

    property int m_margin: 10

    property bool m_is_air: false

    property int m_user_selected_card_manufacturer: -1;
    property int left_text_minimum_width: 100
    property int left_text_preferred_width: 100
    property bool isSynced:false

    function open(){
        if(_fcMavlinkSystem.is_alive && _fcMavlinkSystem.armed){
            _qopenhd.show_toast("WARNING: Changing TX power while armed is not recommended !");
        }
        var card_chipset_type=get_chipset_type();
        if(!(card_chipset_type==0 || card_chipset_type==1)){
            _messageBoxInstance.set_text_and_show("Changing tx power is only possible on openhd supported cards.");
            return;
        }
        // The user has to enter the card type every time - otherwise, we have issues with air and ground
        comboBoxCardSelectManufacturer.currentIndex=0;
        combo_box_txpower_disarmed.currentIndex=0;
        combo_box_txpower_armed.currentIndex=0;
        m_user_selected_card_manufacturer=-1;
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
        ListElement {title: "Not Enabled"; value: -1}
    }

    ListModel{
        id: model_rtl8812au_manufacturers
        ListElement {title: "Wifi Card [RTL88XXAU]"; value: -1}
        ListElement {title: "AC56/AWUS036ACH [RTL88XXAU]"; value: 0}
        ListElement {title: "AC180 [RTL88XXAU]"; value: 1}
        ListElement {title: "OpenHD HW [RTL88XXAU]"; value: 2}
        ListElement {title: "OTHER [RTL88XXAU]"; value: 3}
    }
    ListModel{
        id: model_rtl8812bu_manufacturers
        ListElement {title: "Wifi Card [RTL88XXBU]"; value: -1}
        ListElement {title: "COMFAST [RTL88XXBU]"; value: 0}
        ListElement {title: "OTHER [RTL88XXBU]"; value: 1}
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
        ListElement {title: "LOW    [10] ~5mW (DEFAULT)  "; value: 10}
        ListElement {title: "LOW    [22] ~20mW           "; value: 22}
        ListElement {title: "MEDIUM [37] ~100mW          "; value: 37}
        ListElement {title: "HIGH   [53] ~320mW          "; value: 53}
        ListElement {title: "MAX1   [58] ~420mW (MCS<=2!)"; value: 58}
        ListElement {title: "MAX2   [63] ~500mW (MCS<=2!)"; value: 63}
    }
    ListModel{
        id: model_rtl8812au_manufacturer_aliexpress_hp
        ListElement {title: "Please select"; value: -1}
        ListElement {title: "LOW    [10]"; value: 10}
        ListElement {title: "LOW    [16]"; value: 16}
        ListElement {title: "MEDIUM [22]"; value: 22}
        ListElement {title: "HIGH   [24]"; value: 24}
        ListElement {title: "MAX    [26]"; value: 26}
    }
    ListModel{
        id: model_rtl8812au_manufacturer_openhd
        ListElement {title: "Please select"; value: -1}
        ListElement {title: "LOW    [3]   ~25mW"; value: 3}
        ListElement {title: "MEDIUM [5]   ~200mW"; value: 5}
        ListElement {title: "HIGH   [14]  ~800mW"; value: 14}
        ListElement {title: "MAX1   [18]   >1W"; value: 18}
        ListElement {title: "MAX2   [20]   >1W"; value: 20}
    }
    ListModel{
        id: model_rtl8812au_manufacturer_generic
        ListElement {title: "Please select"; value: -1}
        ListElement {title: "[10] (TX Power Level)"; value: 10}
        ListElement {title: "[22] (TX Power Level)"; value: 22}
        ListElement {title: "[30] (TX Power Level)"; value: 30}
        ListElement {title: "[37] (TX Power Level)"; value: 37}
        ListElement {title: "[53] (TX Power Level)"; value: 53}
        ListElement {title: "[58] (TX Power Level)"; value: 58}
        ListElement {title: "[63] (TX Power Level)"; value: 63}
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

    // Such that we can copy and add the extra value for "NOT ENABLED"
    ListModel{
        id: model_txpower_for_chip_type_manufacturer_armed
    }


    function get_model_txpower_for_chip_type_manufacturer(add_selection_disable){
        var chip_type=get_chipset_type();
        var manufacturer=m_user_selected_card_manufacturer;
        if(manufacturer<0){
            return model_error;
        }
        var ret;
        if(chip_type==0){
            // RTL8812AU
            if(manufacturer==0){
                ret=model_rtl8812au_manufacturer_asus_txpower;
            }else if(manufacturer==1){
                ret=model_rtl8812au_manufacturer_aliexpress_hp;
            }else if(manufacturer==2){
                ret=model_rtl8812au_manufacturer_openhd;
            }else{
                ret=model_rtl8812au_manufacturer_generic;
            }
        }else if(chip_type==1){
            // RTL8812BU
            if(manufacturer==0){
                ret= model_rtl8812bu_manufacturer_comfast;
            }else{
                ret = model_rtl8812bu_manufacturer_generic;
            }
        }else{
            ret = model_error;
        }
        // Armed has the extra option of tx power==0, which means the disarmed tx power is applied regardless if armed or not
        if(add_selection_disable){
            model_txpower_for_chip_type_manufacturer_armed.clear();
            for(var i = 0; i < ret.count; ++i){
                model_txpower_for_chip_type_manufacturer_armed.insert(i,ret.get(i));
            }
            model_txpower_for_chip_type_manufacturer_armed.insert(1,{title: "Snyncronised with Disarmed", value: 0});
            return model_txpower_for_chip_type_manufacturer_armed;
        }
        return ret;
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
        id: main_row_layout
        anchors.fill: parent
        anchors.leftMargin: 10
        anchors.rightMargin: 5

        BaseHeaderItem{
            m_text: "Transmit Power"+" " + (m_is_air ? "Air" : "Ground")
        }

        Item {
            id:closeButtonWrapper
            Layout.alignment: Qt.AlignTop | Qt.AlignRight
            Layout.rightMargin: closeButton.width-main_row_layout.anchors.rightMargin
            Layout.topMargin: (closeButtonWrapper.height-closeButton.height)-1

            Button {
                id:closeButton
                text: "X"
                height:42
                width:42
                background: Rectangle {
                    Layout.fillHeight: parent
                    Layout.fillWidth: parent
                    color: closeButton.hovered ? "darkgrey" : "lightgrey"
                }
                onClicked: {
                    close()
                }
            }
        }

        Rectangle {
            width: parent.width
            height: mainColumn.height
            Layout.alignment: Qt.AlignHCenter | Qt.AlignVCenter
            color: "#333c4c"

            ColumnLayout {
                id:mainColumn
                anchors.centerIn: parent

                RowLayout {
                    Layout.fillWidth: true
                    ComboBox {
                        id: comboBoxCardSelectManufacturer
                        Layout.minimumWidth: 180
                        Layout.preferredWidth: 480
                        model: get_model_manufacturer_for_chip_type()
                        textRole: "title"
                        onCurrentIndexChanged: {
                            var manufacturer = comboBoxCardSelectManufacturer.model.get(comboBoxCardSelectManufacturer.currentIndex).value;
                            m_user_selected_card_manufacturer = manufacturer;
                        }
                        font.pixelSize: 14
                    }
                }

                RowLayout {
                    Layout.fillWidth: true
                    Button {
                        id:saveButton
                        width:200
                        text: "SAVE Disarmed "
                        enabled: m_user_selected_card_manufacturer >= 0;
                        onClicked: {
                            var tx_power_index_or_mw = combo_box_txpower_disarmed.model.get(combo_box_txpower_disarmed.currentIndex).value;
                            if (tx_power_index_or_mw < 0) {
                                _qopenhd.show_toast("Please select a valid tx power", false);
                                return;
                            }
                            var is_tx_power_index_unit = get_chipset_type() == 0;
                            var success = _wbLinkSettingsHelper.set_param_tx_power(!m_is_air, is_tx_power_index_unit, false, tx_power_index_or_mw)
                            if (success == true) {
                                _qopenhd.show_toast("SUCCESS");
                            } else {
                                _qopenhd.show_toast("Cannot change TX power, please try again", true);
                            }
                        }
                        font.pixelSize: 14
                    }
                    ComboBox {
                        Layout.minimumWidth: 100
                        Layout.preferredWidth: 350
                        id: combo_box_txpower_disarmed
                        model: get_model_txpower_for_chip_type_manufacturer(false)
                        textRole: "title"
                        enabled: m_user_selected_card_manufacturer >= 0;
                        font.pixelSize: 14
                        onActivated: {
                            console.log("onActivated: index:" + currentIndex + " level:" + currentValue);
                        }
                    }
                }

                RowLayout {
                    Layout.fillWidth: true
                    Button {
                        text: "    SAVE Armed    "
                        enabled: m_user_selected_card_manufacturer >= 0;
                        onClicked: {
                            isSynced=true;
                            var tx_power_index_or_mw = combo_box_txpower_armed.model.get(combo_box_txpower_armed.currentIndex).value;
                            if (tx_power_index_or_mw < 0) {
                                _qopenhd.show_toast("Please select a valid tx power", false);
                                return;
                            }
                            var is_tx_power_index_unit = get_chipset_type() == 0;
                            var success = _wbLinkSettingsHelper.set_param_tx_power(!m_is_air, is_tx_power_index_unit, true, tx_power_index_or_mw)
                            if (success == true) {
                                _qopenhd.show_toast("SUCCESS");
                            } else {
                                _qopenhd.show_toast("Cannot change TX power, please try again", true);
                            }
                        }
                        font.pixelSize: 14
                    }
                    ComboBox {
                        Layout.minimumWidth: 100
                        Layout.preferredWidth: 350
                        id: combo_box_txpower_armed
                        model: get_model_txpower_for_chip_type_manufacturer(true)
                        textRole: "title"
                        enabled: m_user_selected_card_manufacturer >= 0;
                        font.pixelSize: 14
                    }
                }
                Rectangle {
                    width: comboBoxCardSelectManufacturer.width + 5
                    height: comboBoxCardSelectManufacturer.height * 0.8
                    color: "white"
                    RowLayout{
                        anchors.centerIn: parent
                        Text {
                            Layout.fillWidth: true
                            Layout.minimumHeight: 50
                            text: "Tx-Power Disarmed: ";
                            color: "black"
                            wrapMode: Text.WordWrap
                            verticalAlignment: Qt.AlignVCenter
                        }
                        Text {
                            Layout.fillWidth: true
                            Layout.minimumHeight: 50
                            text: get_current_tx_power_int(1)+" "+get_tx_power_unit();
                            color: "black"
                            font.bold: true
                            wrapMode: Text.WordWrap
                            verticalAlignment: Qt.AlignVCenter
                        }
                        Text {
                            Layout.fillWidth: true
                            Layout.minimumHeight: 50
                            text: "      ";
                            color: "black"
                            wrapMode: Text.WordWrap
                            verticalAlignment: Qt.AlignVCenter
                        }
                        Text {
                            Layout.fillWidth: true
                            Layout.minimumHeight: 50
                            text: "Tx-Power Armed: ";
                            color: "black"
                            wrapMode: Text.WordWrap
                            verticalAlignment: Qt.AlignVCenter
                        }
                        Text {
                            Layout.fillWidth: true
                            Layout.minimumHeight: 50
                            text: {
                                                var power_int=get_current_tx_power_int(2);
                                                if(power_int==0) return get_current_tx_power_int(1) +" "+get_tx_power_unit();
                                                return get_current_tx_power_int(2)+" "+get_tx_power_unit();
                                            }
                            color: "black"
                            font.bold: true
                            wrapMode: Text.WordWrap
                            verticalAlignment: Qt.AlignVCenter
                        }

                    }
                }
            }
        }
        Item{ // Filler
            Layout.fillWidth: true
            Layout.fillHeight: true
        }
        Text{
            Layout.fillWidth: true
            Layout.minimumHeight: 50
            text: "Caution: Not all cards are designed to handle high power levels.\n Excessive power may lead to card damage";
            color: "white"
            //style: Text.Outline
            //styleColor: "black"
            wrapMode: Text.WordWrap
            font.pixelSize: 18
            verticalAlignment: Qt.AlignVCenter
            horizontalAlignment: Qt.AlignHCenter
        }
        Text{
            Layout.fillWidth: true
            text: "WARNING: ARMING WILL REDUCE YOUR TX POWER"
            //visible: true
            visible: {
                var txpower_disarmed=get_current_tx_power_int(1);
                var txpower_armed=get_current_tx_power_int(2);
                if(txpower_armed==0)return false;
                return txpower_armed<txpower_disarmed;
            }
            color: "white"
            font.pixelSize: 18
            verticalAlignment: Qt.AlignVCenter
            horizontalAlignment: Qt.AlignHCenter
            style: Text.Outline
            styleColor: "black"
        }
        Item{ // Filler
            Layout.fillWidth: true
            Layout.fillHeight: true
        }
        // ----------------
    }
}

