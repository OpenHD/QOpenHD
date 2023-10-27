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
    // try and update the combobox to the retrieved value(value != index)
    function update_combobox(_combobox,_value){
        var _index=find_index(_combobox.model,_value)
        if(_index >= 0){
            _combobox.currentIndex=_index;
        }
    }

    function fc_is_armed(){
        return _fcMavlinkSystem.armed
    }

    ListModel{
        id: supported_frequencies_model
        ListElement {title: "Unknown"; value:-1; radar: false; recommended: false; openhd_raceband_nr: -1}
    }

    function show_popup_message(message){
        _messageBoxInstance.set_text_and_show(message)
    }

    property bool m_simplify_enable:true
    function create_list_model_supported(){
        supported_frequencies_model.clear()
        //supported_frequencies_model.append({title: "Unknown", value: -1})
        const supported_frequencies=_wbLinkSettingsHelper.get_supported_frequencies();
        for(var i=0;i<supported_frequencies.length;i++){
            const frequency=supported_frequencies[i];
            const text=_wbLinkSettingsHelper.get_frequency_description(frequency)
            const simple=_wbLinkSettingsHelper.get_frequency_simplify(frequency)
            const radar=_wbLinkSettingsHelper.get_frequency_radar(frequency)
            const recommended=_wbLinkSettingsHelper.get_frequency_reccommended(frequency)
            const openhd_raceband=_wbLinkSettingsHelper.get_frequency_openhd_race_band(frequency)
            var append_this_value=true;
            if(m_simplify_enable){
                // only add if it is a "simple" channel
                //append_this_value = simple;
                append_this_value = openhd_raceband >= 0;
            }else{
                append_this_value=true;
            }
            if(append_this_value){
                supported_frequencies_model.append({title: text, value: frequency, radar:radar, recommended: recommended, openhd_raceband_nr: openhd_raceband})
            }
        }
        var index=find_index(supported_frequencies_model,_wbLinkSettingsHelper.curr_channel_mhz);
        comboBoxFreq.model=supported_frequencies_model
        if(index>=0){
            comboBoxFreq.currentIndex=index;
        }else{
            comboBoxFreq.currentIndex=0;
            console.log("Seems not to be a valid channel "+_wbLinkSettingsHelper.curr_channel_mhz)
        }
    }

    // We get notified every time we should re-build the model(s) and their current selection
    property int m_ui_rebuild_models : _wbLinkSettingsHelper.ui_rebuild_models
    onM_ui_rebuild_modelsChanged: {
        console.log(" onM_ui_rebuild_modelsChanged: "+_wbLinkSettingsHelper.ui_rebuild_models);
        function_rebuild_ui()
    }

    function function_rebuild_ui(){
        console.log("function_rebuild_ui:"+_wbLinkSettingsHelper.ui_rebuild_models);
        if(_wbLinkSettingsHelper.ui_rebuild_models<=0)return
        create_list_model_supported();
        //update_pollution_graph();
        pollution_chart_view.update();
    }

    //
    function close_all_dialoques(){
        pollution_chart_view.close()
        channel_scan_progress_view.close();
        change_tx_power_popup.close();
        dialoqueFreqChangeGndOnly.close();
        dialoqueFreqChangeArmed.close();
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
    }
    //

    // ------------------- PART HELPER FOR CURRENT LOSS / POLLUTION / THROTTLE BEGIN -------------------
    // ------------------- PART HELPER FOR CURRENT LOSS / POLLUTION / THROTTLE END -------------------


    // Changes either the frequency or channel width
    // This one need to be synced, so we have ( a bit complicated, but quite natural for the user) dialoque for the cases where we need to handle errors / show a warning
    function change_frequency_sync_otherwise_handle_error(frequency_mhz,ignore_armed_state){
        console.log("change_frequency_sync_otherwise_handle_error: "+"FREQ:"+frequency_mhz+"Mhz");
        // Ground needs to be alive and well
        if(!_ohdSystemGround.is_alive){
            _messageBoxInstance.set_text_and_show("Ground unit not alive",5);
            return;
        }
        // Air needs to be alive and well - otherwise we show the "do you want to change gnd only" dialoque
        if(!_ohdSystemAir.is_alive){
            var error_message_not_alive="AIR Unit not alive -"
            dialoqueFreqChangeGndOnly.initialize_and_show_frequency(frequency_mhz,error_message_not_alive);
            return;
        }
        // FC needs to be disarmed - otherwise show warning
        const fc_currently_armed = (_fcMavlinkSystem.is_alive && _fcMavlinkSystem.armed)// || true;
        if(fc_currently_armed && ignore_armed_state===false){
            dialoqueFreqChangeArmed.initialize_and_show_frequency(frequency_mhz)
            return;
        }
        var result= _wbLinkSettingsHelper.change_param_air_and_ground_frequency(frequency_mhz);
        if(result==0){
            var message="Succesfully set air and ground to FREQUENCY: "+frequency_mhz+"Mhz";
            _messageBoxInstance.set_text_and_show(message,5);
            return;
        }else if(result==-1){
            // Air unit rejected
            _messageBoxInstance.set_text_and_show("Air unit does not support this value",5);
            return;
        }else if(result==-2){
            // Couldn't reach air unit
            var error_message_not_reachable="Couldn't reach air unit -"
            dialoqueFreqChangeGndOnly.initialize_and_show_frequency(frequency_mhz,error_message_not_reachable);
            return;
        }
        // Really really bad
        _messageBoxInstance.set_text_and_show("Something went wrong - please use 'FIND AIR UNIT' to fix");
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

                GridLayout {
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

                    ComboBox {
                        id: comboBoxFreq
                        model: supported_frequencies_model
                        textRole: "title"
                        implicitWidth:  elementComboBoxWidth
                        currentIndex: 0
                        delegate: ItemDelegate {
                            width: comboBoxFreq.width
                            contentItem: FreqComboBoxRow{
                                m_main_text: title
                                m_selection_tpye: (value===_wbLinkSettingsHelper.curr_channel_mhz) ? 1 : 0
                                m_is_2G: value < 3000 && value > 100
                                m_show_radar: radar
                                m_openhd_race_band: openhd_raceband_nr
                            }
                            highlighted: comboBoxFreq.highlightedIndex === index
                        }
                        Layout.row: 1
                        Layout.column: 0
                    }
                    Button{
                        text: "APPLY"
                        id: buttonSwitchFreq
                        //enabled: false
                        onClicked: {
                            var selectedValue=supported_frequencies_model.get(comboBoxFreq.currentIndex).value
                            if(selectedValue<=100){
                                _messageBoxInstance.set_text_and_show("Please select a valid frequency",5);
                                return;
                            }
                            change_frequency_sync_otherwise_handle_error(selectedValue,-1,false);
                        }
                        //Material.background: fc_is_armed() ? Material.Red : Material.Normal;
                        enabled: _wbLinkSettingsHelper.ui_rebuild_models>=0 && (_ohdSystemGround.is_alive && _ohdSystemGround.wb_gnd_operating_mode==0);
                        Layout.row: 1
                        Layout.column: 1
                    }
                    Switch{
                        Layout.row: 1
                        Layout.column: 2
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
                        Layout.column: 3
                        onClicked: {
                            var text="SIMPLIFY: Show recommended channels only. These channels usually have the least amount of pollution by WiFi APs and most FPV antennas are tuned to those Frequncies.\n"+
                                    "OpenHD works best on them in most scenarios,and you can use 20Mhz and 40Mhz dynamically without issues (40Mhz spacing by default).\n"+
                                    "Otherwise, show all channels supported by harware (ADVANCED USERS ONLY).\n";
                            _messageBoxInstance.set_text_and_show(text)
                        }
                    }
                    RowLayout{
                        Layout.row: 2
                        Layout.column: 0
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        id: gnd_op_mode_status
                        //SimpleProgressBar{
                        //}
                        Text{
                            text: {
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
                            Layout.row: 1
                            Layout.column: 0
                            verticalAlignment: Text.AlignVCenter
                        }
                    }
                    Button{
                        Layout.row: 2
                        Layout.column: 1
                        id: b_find_air_unit
                        text: "SCAN"
                        enabled: _ohdSystemGround.is_alive
                        onClicked: {
                            close_all_dialoques();
                            channel_scan_progress_view.open()
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
                    Button{
                        Layout.row: 2
                        Layout.column: 2
                        text: "ANALYZE"
                        enabled: _ohdSystemGround.is_alive
                        onClicked: {
                            close_all_dialoques();
                            pollution_chart_view.open()
                        }
                    }
                    ButtonIconInfo{
                        Layout.row: 2
                        Layout.column: 3
                        onClicked: {
                            var text="SCAN: Scan for a running openhd air unit (required if you switch between different air / ground stations or re-flash the image.)\n"+
                                    "ANALYZE: Analyze all channels for WiFi pollution. If any of the default openhd channels is not polluted, they should be used."+
                                    "NOTE: Analogue FPV or other digital FPV systems won't show up during analyze - read the wiki for more info.";
                            _messageBoxInstance.set_text_and_show(text)
                        }
                    }
                    // Row 3
                    RowLayout{
                        Layout.row: 3
                        Layout.column: 0
                        Layout.columnSpan: 3
                        Text{
                            text:{
                                "LOSS %:"+_ohdSystemGround.curr_rx_packet_loss_perc
                            }
                            color: _ohdSystemGround.curr_rx_packet_loss_perc > 5 ? "red" : "black"
                            verticalAlignment: Qt.AlignVCenter
                        }
                        Text{
                            text: {
                                return "POLLUTION pps:"+_ohdSystemGround.wb_link_curr_foreign_pps
                            }
                            color: _ohdSystemGround.wb_link_curr_foreign_pps > 20 ? "red" : "black"
                        }
                        Text{
                            text: {
                                return "THROTTLE:"+_ohdSystemAir.curr_n_rate_adjustments
                            }
                            color: _ohdSystemAir.curr_n_rate_adjustments > 0 ? "red" : "black"
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

                GridLayout {
                    id: tx_power_layout
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    Text{
                        Layout.row: 0
                        Layout.column: 0
                        Layout.columnSpan: 2
                        text: "TX POWER"
                        font.bold: true
                    }
                    Text{
                        Layout.row: 1
                        Layout.column: 0
                        text: "AIR:\n "+get_text_wifi_tx_power(true)
                    }
                    Button{
                        Layout.row: 1
                        Layout.column: 1
                        text: "CHANGE"
                        enabled: _ohdSystemAir.is_alive
                        onClicked: {
                            close_all_dialoques();
                            change_tx_power_popup.m_is_air=true;
                            change_tx_power_popup.open()
                        }
                    }
                    Text{
                        Layout.row: 2
                        Layout.column: 0
                        text: "GND:\n"+get_text_wifi_tx_power(false)
                    }
                    Button{
                        Layout.row: 2
                        Layout.column: 1
                        text: "CHANGE"
                        enabled: _ohdSystemGround.is_alive
                        onClicked: {
                            close_all_dialoques();
                            change_tx_power_popup.m_is_air=false;
                            change_tx_power_popup.open()
                        }
                    }
                    // STBC / LDPC
                    Text{
                        width: 200
                        Layout.row: 0
                        Layout.column: 3
                        Layout.columnSpan: 2
                        text: "ADVANCED (STBC,LDPC)"
                        font.bold: true
                        horizontalAlignment: Qt.AlignHCenter
                    }
                    Text{
                        Layout.row: 1
                        Layout.column: 3
                        text: "AIR:\n"+get_text_stbc_ldpc(true);
                        horizontalAlignment: Qt.AlignHCenter
                    }
                    Text{
                        Layout.row: 2
                        Layout.column: 3
                        text: "GND:\n"+get_text_stbc_ldpc(false);
                        horizontalAlignment: Qt.AlignHCenter
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
                    Button{
                        Layout.row: 2
                        Layout.column: 4
                        text: "EDIT";
                        //enabled: true
                        enabled: _ohdSystemAir.is_alive && _ohdSystemGround.is_alive && (_wbLinkSettingsHelper.ui_rebuild_models>=0) &&
                                (_ohdSystemGround.wb_stbc_enabled!=true || _ohdSystemGround.wb_lpdc_enabled!=true || _ohdSystemAir.wb_stbc_enabled!=true || _ohdSystemAir.wb_lpdc_enabled!=true);
                        onClicked: {
                            popup_enable_stbc_ldpc.open()
                        }
                    }
                }
            }
            //
            /*Rectangle {
                implicitWidth: main_scroll_view.width
                implicitHeight: tx_power_layout.implicitHeight
                id: rpi_cam_selector_layout_background
                color: m_background_color
                radius: 10

                GridLayout {
                    id: rpi_cam_selector_layout
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    Text{
                        Layout.row: 0
                        Layout.column: 0
                        Layout.columnSpan: 2
                        text: "RPI CAM SELECTOR"
                        font.bold: true
                    }
                    Button{
                        Layout.row: 1
                        Layout.column: 0
                        text: "EDIT"
                    }
                }
            }*/
        }
    }

    PopupAnalyzeChannels{
        id: pollution_chart_view
    }

    PopupScanChannels{
        id: channel_scan_progress_view
    }

    PopupTxPowerEditor{
        id: change_tx_power_popup
    }
    PopupEnableSTBCLDPC{
        id: popup_enable_stbc_ldpc
    }

    DialoqueFreqChangeGndOnly{
        id: dialoqueFreqChangeGndOnly
    }
    DialoqueFreqChangeArmed{
        id: dialoqueFreqChangeArmed
    }
}
