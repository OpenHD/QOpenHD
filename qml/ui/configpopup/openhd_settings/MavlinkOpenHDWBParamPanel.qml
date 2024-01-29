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

// This is an extra screen for changing the frequency / channel width -
// They both need to match !
Rectangle{
    id: main_background
    width: parent.width
    height: parent.height
    //property color m_background_color: "#8cbfd7f3"
    //property color m_background_color: "#ADD8E6"
    property color m_background_color: "#8cbfd7f3"

    property int m_small_width: 200

    function user_quidance_animate_channel_scan(){
        console.log("User guidance animate channel scan");
        anim_find_air_unit.start()
    }

    // https://stackoverflow.com/questions/41991438/how-do-i-find-a-particular-listelement-inside-a-listmodel-in-qml
    // For the models above (model with value) try to find the index of the first  item where model[i].value===value
    function find_index(model,value){
        for(var i = 0; i < model.count; ++i) if (model.get(i).value===value) return i
        return -1
    }

    function fc_is_armed(){
        return _fcMavlinkSystem.armed
    }

    ListModel{
        id: frequencies_model_all
        ListElement {title: "Unknown"; value_frequency_mhz:-1}
    }
    ListModel{
        id: frequencies_model_openhd_channels_only
        ListElement {title: "Unknown"; value_frequency_mhz:-1}
    }

    function create_list_models_frequency(){
        frequencies_model_all.clear();
        const frequencies_all=_frequencyHelper.get_frequencies(false);
        for(var i=0;i<frequencies_all.length;i++){
            const frequency=frequencies_all[i];
            const text=_frequencyHelper.get_frequency_description(frequency)
            frequencies_model_all.append({title: text, value_frequency_mhz: frequency});
        }
        frequencies_model_openhd_channels_only.clear();
        const frequencies_openhd=_frequencyHelper.get_frequencies(true);
        for(var i=0;i<frequencies_openhd.length;i++){
            const frequency=frequencies_openhd[i];
            const text=_frequencyHelper.get_frequency_description(frequency)
            frequencies_model_openhd_channels_only.append({title: text, value_frequency_mhz: frequency});
        }
    }

    property bool m_simplify_enable:true
    function update_frequency_combobox(){
        if(m_simplify_enable){
            comboBoxFreq.model=frequencies_model_openhd_channels_only;
        }else{
            comboBoxFreq.model=frequencies_model_all;
        }
        if(_wbLinkSettingsHelper.curr_channel_mhz>0){
            var index=find_index(comboBoxFreq.model,_wbLinkSettingsHelper.curr_channel_mhz);
            if(index>=0){
                comboBoxFreq.currentIndex=index;
            }else{
                comboBoxFreq.currentIndex=0;
                console.log("Seems not to be a valid channel "+_wbLinkSettingsHelper.curr_channel_mhz)
            }
        }else{
            comboBoxFreq.currentIndex=-1;
        }
    }

    // We get notified every time we should re-build the model(s) and their current selection
    property int m_ui_rebuild_models : _wbLinkSettingsHelper.ui_rebuild_models
    onM_ui_rebuild_modelsChanged: {
        console.log(" onM_ui_rebuild_modelsChanged: "+_wbLinkSettingsHelper.ui_rebuild_models);
        function_rebuild_ui()
    }

    function function_rebuild_ui(){
        update_frequency_combobox();
        console.log("function_rebuild_ui:"+_wbLinkSettingsHelper.ui_rebuild_models);
        if(_wbLinkSettingsHelper.ui_rebuild_models<=0)return
        popup_analyze_channels.update();
    }

    //
    function close_all_dialoques(){
        popup_analyze_channels.close()
        popup_scan_channels.close();
        popup_change_tx_power.close();
        dialoqueFreqChangeGndOnly.close();
        dialoqueFreqChangeAirGnd.close();
        popup_enable_stbc_ldpc.close();
    }

    function get_text_stbc_ldpc(air){
        if(air){
            if(!_ohdSystemAir.is_alive)return "N/A";
            return ""+(_ohdSystemAir.wb_stbc_enabled ? "YES" : "NO")+"/"+(_ohdSystemAir.wb_lpdc_enabled ? "YES" : "NO");
        }
        if(!_ohdSystemGround.is_alive)return "N/A";
        return ""+(_ohdSystemGround.wb_stbc_enabled ? "YES" : "NO")+"/"+(_ohdSystemGround.wb_lpdc_enabled ? "YES" : "NO");
    }

    Component.onCompleted: {
        close_all_dialoques();
        create_list_models_frequency();
        update_frequency_combobox();
    }

    function get_text_wifi_tx_power(air){
        if(air){
            if(!_wifi_card_air.alive) return "N/A";
            return ""+_wifi_card_air.tx_power+" "+_wifi_card_air.tx_power_unit;
        }
        if(!_wifi_card_gnd0.alive) return "N/A";
        return ""+_wifi_card_gnd0.tx_power+" "+_wifi_card_gnd0.tx_power_unit;
    }

    ScrollView {
        id: main_scroll_view
        width: parent.width
        height: parent.height
        anchors.centerIn: parent
        contentHeight: main_column_layout.height
        contentWidth: main_column_layout.width
        //ScrollBar.vertical.policy: ScrollBar.AlwaysOn
        ScrollBar.vertical.interactive: true
        visible: (!popup_analyze_channels.visible && !popup_enable_stbc_ldpc.visible && !popup_change_tx_power.visible && !popup_scan_channels.visible)

        ColumnLayout{
            Layout.fillWidth: true
            Layout.fillHeight: true
            id: main_column_layout


            Rectangle {
                id: frequency_area_layout_background
                color: m_background_color
                implicitWidth: main_scroll_view.width
                implicitHeight: frequency_area_layout.implicitHeight+5
                radius: 10

                ColumnLayout {
                    id: frequency_area_layout
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    Layout.margins: 10

                    Text{
                        Layout.row: 0
                        Layout.column: 0
                        text: "FREQUENCY / TOOLKIT"
                        font.bold: true
                    }

                    RowLayout{
                        ComboBox {
                            id: comboBoxFreq
                            //model: supported_frequencies_model
                            //model: frequencies_model_openhd_channels_only
                            textRole: "title"
                            implicitWidth:  elementComboBoxWidth
                            currentIndex: 0
                            delegate: ItemDelegate {
                                width: comboBoxFreq.width
                                contentItem: FreqComboBoxRow{
                                    m_main_text: title
                                    m_selection_tpye: (value_frequency_mhz===_wbLinkSettingsHelper.curr_channel_mhz) ? 1 : 0
                                    m_is_2G: value_frequency_mhz < 3000 && value_frequency_mhz > 100
                                    m_show_radar: _frequencyHelper.get_frequency_radar(value_frequency_mhz)
                                    m_openhd_race_band: _frequencyHelper.get_frequency_openhd_race_band(value_frequency_mhz)
                                    m_pollution_pps: _pollutionHelper.pollution_get_last_scan_pollution_for_frequency(value_frequency_mhz)
                                }
                                highlighted: comboBoxFreq.highlightedIndex === index
                            }
                            Layout.row: 1
                            Layout.column: 0
                            displayText: {
                                if(!_ohdSystemGround.is_alive)return "GND NOT ALIVE";
                                if(_ohdSystemGround.wb_gnd_operating_mode==1){
                                    return "SCANNING";
                                }
                                if(_ohdSystemGround.wb_gnd_operating_mode==2){
                                    return "ANALYZING";
                                }
                                if(!_ohdSystemAir.is_alive){
                                    return _wbLinkSettingsHelper.curr_channel_mhz+"@"+"N/A"+" Mhz (NO AIR)";
                                }
                                return _wbLinkSettingsHelper.curr_channel_mhz+"@"+_wbLinkSettingsHelper.curr_channel_width_mhz+" Mhz";
                            }
                            onActivated: {
                                console.log("onActivated:"+currentIndex);
                                if(currentIndex<0)return;
                                const frequency_mhz=comboBoxFreq.model.get(currentIndex).value_frequency_mhz
                                console.log("Selected frequency: "+frequency_mhz);
                                if(!_frequencyHelper.hw_supports_frequency_threadsafe(frequency_mhz)){
                                    _qopenhd.show_toast("your HW does not support "+frequency_mhz+" Mhz");
                                    return;
                                }
                                if(_wbLinkSettingsHelper.curr_channel_mhz==frequency_mhz){
                                    console.log("Already at frequency "+frequency_mhz);
                                    return;
                                }
                                if(!_ohdSystemAir.is_alive){
                                    var error_message_not_alive="AIR Unit not alive -"
                                    dialoqueFreqChangeGndOnly.initialize_and_show_frequency(frequency_mhz,error_message_not_alive);
                                    return;
                                }
                                // Change the freuquency
                                dialoqueFreqChangeAirGnd.initialize_and_show_frequency(frequency_mhz);
                            }
                            enabled: _ohdSystemGround.is_alive && _ohdSystemGround.wb_gnd_operating_mode==0;
                        }
                        Switch{
                            Layout.row: 1
                            Layout.column: 1
                            Layout.columnSpan: 1
                            text: "SIMPLIFY"
                            checked: true
                            onCheckedChanged: {
                                if(m_simplify_enable!=checked){
                                    m_simplify_enable=checked;
                                    function_rebuild_ui();
                                }
                            }
                        }
                        ButtonIconInfo{
                            Layout.row: 1
                            Layout.column: 2
                            onClicked: {
                                var text="Please select a channel / frequency free of noise and interference. The current loss / pollution / throttle stats below can help,"+
                                        "as well as the analyze channels feature or a frequency analyzer on your phone. SIMPLIFY: Show OpenHD standard channels [1-5] only - they "+
                                        " often are free of wifi pollution and should be used. Only disable SIMPLIFY if you know exactly why."
                                _messageBoxInstance.set_text_and_show(text)
                            }
                        }
                    }



                    RowLayout{
                        Layout.row: 2
                        Layout.column: 0
                        Layout.columnSpan: 3
                        Item{ // FILLER
                            Layout.preferredWidth: 30
                            Layout.minimumWidth: 0
                        }
                        Button{
                            Layout.preferredWidth: 150
                            id: b_find_air_unit
                            text: "SCAN"
                            enabled: _ohdSystemGround.is_alive
                            onClicked: {
                                close_all_dialoques();
                                popup_scan_channels.open()
                            }
                            SequentialAnimation {
                                running: false
                                loops: 4
                                id: anim_find_air_unit
                                // Expand the button
                                PropertyAnimation {
                                    target: b_find_air_unit
                                    property: "scale"
                                    to: 1.5
                                    duration: 200
                                    easing.type: Easing.InOutQuad
                                }
                                // Shrink back to normal
                                PropertyAnimation {
                                    target: b_find_air_unit
                                    property: "scale"
                                    to: 1.0
                                    duration: 200
                                    easing.type: Easing.InOutQuad
                                }
                            }
                        }
                        Item{ // FILLER
                            Layout.preferredWidth: 30
                            Layout.minimumWidth: 0
                        }
                        Button{
                            Layout.preferredWidth: 150
                            text: "ANALYZE"
                            enabled: _ohdSystemGround.is_alive
                            onClicked: {
                                close_all_dialoques();
                                popup_analyze_channels.open()
                            }
                        }
                        Item{ // FILLER
                            Layout.preferredWidth: 30
                            Layout.minimumWidth: 0
                        }
                        ButtonIconInfo{
                            onClicked: {
                                var text="SCAN: Similar to analoque channel scan, find a running air unit by checking all possible channels (frequencies).\n\n"+
                                        "ANALYZE: Analyze channels for WiFi pollution. Read the wiki for more info.";
                                _messageBoxInstance.set_text_and_show(text)
                            }
                        }
                    }
                    RowLayout{
                        Text{
                            Layout.preferredHeight: 50
                            Layout.preferredWidth: 120
                            text:{
                                "LOSS:\n"+_ohdSystemGround.curr_rx_packet_loss_perc+"%"
                            }
                            color: _ohdSystemGround.curr_rx_packet_loss_perc > 5 ? "red" : "black"
                            verticalAlignment: Qt.AlignVCenter
                            horizontalAlignment: Qt.AlignHCenter
                            font.bold: true
                        }
                        Text{
                            Layout.preferredHeight: 50
                            Layout.preferredWidth: 120
                            text: {
                                return "POLLUTION:\n"+_ohdSystemGround.wb_link_curr_foreign_pps+"pps"
                            }
                            color: _ohdSystemGround.wb_link_curr_foreign_pps > 20 ? "red" : "black"
                            verticalAlignment: Qt.AlignVCenter
                            horizontalAlignment: Qt.AlignHCenter
                            font.bold: true
                        }
                        Text{
                            Layout.preferredHeight: 50
                            Layout.preferredWidth: 120
                            text: {
                                return "THROTTLE:\n"+_ohdSystemAir.curr_n_rate_adjustments
                            }
                            color: _ohdSystemAir.curr_n_rate_adjustments > 0 ? "red" : "black"
                            verticalAlignment: Qt.AlignVCenter
                            horizontalAlignment: Qt.AlignHCenter
                            font.bold: true
                        }
                        ButtonIconInfo{
                            onClicked: {
                                var text="High Loss / Pollution / active throttle hint at a polluted channel."
                                _messageBoxInstance.set_text_and_show(text)
                            }
                        }
                        ButtonIconWarning{
                            visible: /*_ohdSystemAir.is_alive &&*/ (_ohdSystemGround.curr_rx_packet_loss_perc > 5 || _ohdSystemGround.wb_link_curr_foreign_pps > 20 || _ohdSystemAir.curr_n_rate_adjustments > 0)
                            onClicked: {
                                var text="On the bench, if you encounter issues like a high loss , high pollution or throttling, make sure:\n"+
                                        "1) You are using a channel free of noise and interference (OHD channel 1-5 are a good bet)\n"+
                                        "2) (RARELY,RTL8812AU only): Your TX card(s) aren't overamplifying the signal and have adequate cooling.";
                                _messageBoxInstance.set_text_and_show(text)
                            }
                        }
                    }
                }
            }
            Rectangle {
                implicitWidth: main_scroll_view.width
                implicitHeight: tx_power_layout.implicitHeight
                id: tx_power_layout_background
                color: m_background_color
                radius: 10

                RowLayout {
                    id: tx_power_layout
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    Text{
                        text: "TX POWER"
                        font.bold: true
                    }
                    Text{
                        Layout.preferredWidth: 120
                        text: "AIR:\n "+get_text_wifi_tx_power(true)
                        verticalAlignment: Qt.AlignVCenter
                        horizontalAlignment: Qt.AlignHCenter
                        font.bold: true
                    }
                    Button{
                        text: "EDIT"
                        enabled: _ohdSystemAir.is_alive
                        onClicked: {
                            close_all_dialoques();
                            popup_change_tx_power.m_is_air=true;
                            popup_change_tx_power.open()
                        }
                    }
                    Text{
                        Layout.preferredWidth: 120
                        text: "GND:\n"+get_text_wifi_tx_power(false)
                        verticalAlignment: Qt.AlignVCenter
                        horizontalAlignment: Qt.AlignHCenter
                        font.bold: true
                    }
                    Button{
                        text: "EDIT"
                        enabled: _ohdSystemGround.is_alive
                        onClicked: {
                            close_all_dialoques();
                            popup_change_tx_power.m_is_air=false;
                            popup_change_tx_power.open()
                        }
                    }
                }
            }
            Rectangle {
                implicitWidth: main_scroll_view.width
                implicitHeight: stbc_ldpc_layout.implicitHeight
                id: stbc_ldpc_background
                color: m_background_color
                radius: 10

                RowLayout {
                    id: stbc_ldpc_layout
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    // STBC / LDPC
                    Text{
                        width: 200
                        text: "ADVANCED (STBC,LDPC)"
                        font.bold: true
                        horizontalAlignment: Qt.AlignHCenter
                    }
                    Text{
                        Layout.preferredWidth: 120
                        text: "AIR:\n"+get_text_stbc_ldpc(true);
                        verticalAlignment: Qt.AlignVCenter
                        horizontalAlignment: Qt.AlignHCenter
                        font.bold: true
                    }
                    Text{
                        Layout.preferredWidth: 120
                        text: "GND:\n"+get_text_stbc_ldpc(false);
                        verticalAlignment: Qt.AlignVCenter
                        horizontalAlignment: Qt.AlignHCenter
                        font.bold: true
                    }

                    Button{
                        text: "EDIT";
                        //enabled: true
                        enabled: _ohdSystemAir.is_alive && _ohdSystemGround.is_alive && (_wbLinkSettingsHelper.ui_rebuild_models>=0) &&
                                (_ohdSystemGround.wb_stbc_enabled!=true || _ohdSystemGround.wb_lpdc_enabled!=true || _ohdSystemAir.wb_stbc_enabled!=true || _ohdSystemAir.wb_lpdc_enabled!=true);
                        onClicked: {
                            close_all_dialoques();
                            popup_enable_stbc_ldpc.open()
                        }
                    }
                    ButtonIconInfo{
                        Layout.row: 1
                        Layout.column: 4
                        onClicked: {
                            _messageBoxInstance.set_text_and_show("STBC / LDPC : Greatly increases range, but requires 2 RF paths (2 Antennas) on BOTH your air and ground station."+
                                                                  "WARNING: Enabling STBC with the wrong hardware (only 1 antenna / only one rf path) results in no connectivity "+
                                                                  "and you need to re-flash your air / ground unit to recover !");
                        }
                    }
                }
            }
        }
    }

    PopupAnalyzeChannels{
        id: popup_analyze_channels
    }

    PopupScanChannels{
        id: popup_scan_channels
    }

    PopupTxPowerEditor{
        id: popup_change_tx_power
    }
    PopupEnableSTBCLDPC{
        id: popup_enable_stbc_ldpc
    }

    DialoqueFreqChangeGndOnly{
        id: dialoqueFreqChangeGndOnly
    }
    DialoqueFreqChangeAirGnd{
        id: dialoqueFreqChangeAirGnd
    }
}
