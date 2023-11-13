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
        //contentWidth: main_column_layout.width
        //ScrollBar.vertical.policy: ScrollBar.AlwaysOn
        ScrollBar.vertical.interactive: true
        visible: (!popup_analyze_channels.visible && !popup_enable_stbc_ldpc.visible && !popup_change_tx_power.visible && !popup_scan_channels.visible)

        Column{
            width: parent.width
            height: 900
            id: main_column_layout

            Text{
                width: parent.width
                height: 50
                text: "FREQUENCY / TOOLKIT"
                font.bold: true
                horizontalAlignment: Qt.AlignHCenter
                verticalAlignment: Qt.AlignVCenter
            }

            Row{
                width: parent.width
                height: 50
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
                        if(!_ohdSystemGround.is_alive)return "NO FREQUENCY"; // GND NOT ALIVE
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
            }

            Row{
                width: parent.width
                height: 50
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
                Button{
                    Layout.preferredWidth: 150
                    text: "ANALYZE"
                    enabled: _ohdSystemGround.is_alive
                    onClicked: {
                        close_all_dialoques();
                        popup_analyze_channels.open()
                    }
                }
            }

            Row{
                width: parent.width
                height: 50
                Text{
                    text: "TX POWER AIR"
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
