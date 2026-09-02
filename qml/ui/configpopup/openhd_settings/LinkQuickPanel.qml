import QtQuick 2.0

import QtQuick 2.12
import QtQuick.Controls 2.12
import QtQuick.Layouts 1.12

import QtQuick.Controls.Material 2.12


import Qt.labs.settings 1.0

import OpenHD 1.0

import "../../../ui" as Ui
import "../../elements"

// This is an extra screen for changing the frequency / channel width -
// They both need to match !
Rectangle{
    id: main_background
    width: parent.width
    height: parent.height
    //property color m_background_color: "#8cbfd7f3"
    //property color m_background_color: "#ADD8E6"
    property color m_background_color: "#8cbfd7f3"

    property int m_small_height: 50
    property int m_small_width: 120
    property bool m_block_retransmission_update: false
    property bool m_retrans_video_enabled: false
    property bool m_retrans_telemetry_enabled: false
    property bool m_retrans_rc_enabled: false
    property int m_retrans_history_video_ms: 10
    property int m_retrans_history_telemetry_ms: 10
    property int m_retrans_history_rc_ms: 10
    property int m_retrans_request_retries: 1
    property int m_retrans_update_count: _ohdSystemGroundSettings.update_count + _ohdSystemAirSettingsModel.update_count
    property bool m_block_adaptive_update: false
    property bool m_adaptive_available: false
    property bool m_adaptive_enabled: false
    property bool m_fhss_available: false
    property bool m_fhss_enabled: false
    property int m_fhss_slot_ms: 50
    property bool m_block_fhss_update: false

    ListModel {
        id: fhss_slot_model
        ListElement { title: "25 ms"; value: 25 }
        ListElement { title: "50 ms"; value: 50 }
        ListElement { title: "100 ms"; value: 100 }
    }
    Timer {
        id: fhssSecondEndpointTimer
        interval: 700
        repeat: false
        property bool enabling: false
        onTriggered: {
            if (enabling)
                _ohdSystemAirSettingsModel.try_set_param_int_async("WB_FHSS", 1);
            else
                _ohdSystemGroundSettings.try_set_param_int_async("WB_FHSS", 0);
        }
    }

    ListModel {
        id: power_target_model
        ListElement { title: "20%"; value: 20 }
        ListElement { title: "40%"; value: 40 }
        ListElement { title: "60%"; value: 60 }
        ListElement { title: "80%"; value: 80 }
        ListElement { title: "100%"; value: 100 }
    }

    function user_quidance_animate_channel_scan(){
        console.log("User guidance animate channel scan");
        anim_find_air_unit.start()
    }

    function read_param_int(model, param_id){
        if(model === undefined) return null;
        if(!model.system_is_alive()) return null;
        if(!model.has_params_fetched) return null;
        if(!model.param_int_exists(param_id)) return null;
        return model.get_cached_int(param_id);
    }

    function update_retransmission_switches(){
        m_block_retransmission_update = true;
        var value_video = read_param_int(_ohdSystemGroundSettings, "WB_RTX_VIDEO");
        if(value_video === null){
            value_video = read_param_int(_ohdSystemAirSettingsModel, "WB_RTX_VIDEO");
        }
        var value_telemetry = read_param_int(_ohdSystemGroundSettings, "WB_RTX_TELEM");
        if(value_telemetry === null){
            value_telemetry = read_param_int(_ohdSystemAirSettingsModel, "WB_RTX_TELEM");
        }
        var value_rc = read_param_int(_ohdSystemGroundSettings, "WB_RTX_RC");
        if(value_rc === null){
            value_rc = read_param_int(_ohdSystemAirSettingsModel, "WB_RTX_RC");
        }
        var value_history_video = read_param_int(_ohdSystemGroundSettings, "WB_RTX_V_MAXMS");
        if(value_history_video === null){
            value_history_video = read_param_int(_ohdSystemAirSettingsModel, "WB_RTX_V_MAXMS");
        }
        var value_history_telemetry = read_param_int(_ohdSystemGroundSettings, "WB_RTX_T_MAXMS");
        if(value_history_telemetry === null){
            value_history_telemetry = read_param_int(_ohdSystemAirSettingsModel, "WB_RTX_T_MAXMS");
        }
        var value_history_rc = read_param_int(_ohdSystemGroundSettings, "WB_RTX_R_MAXMS");
        if(value_history_rc === null){
            value_history_rc = read_param_int(_ohdSystemAirSettingsModel, "WB_RTX_R_MAXMS");
        }
        var value_retries = read_param_int(_ohdSystemGroundSettings, "WB_RTX_REQ_REP");
        if(value_retries === null){
            value_retries = read_param_int(_ohdSystemAirSettingsModel, "WB_RTX_REQ_REP");
        }
        m_retrans_video_enabled = value_video !== null ? value_video > 0 : false;
        m_retrans_telemetry_enabled = value_telemetry !== null ? value_telemetry > 0 : false;
        m_retrans_rc_enabled = value_rc !== null ? value_rc > 0 : false;
        m_retrans_history_video_ms = value_history_video !== null ? value_history_video : 10;
        m_retrans_history_telemetry_ms = value_history_telemetry !== null ? value_history_telemetry : 10;
        m_retrans_history_rc_ms = value_history_rc !== null ? value_history_rc : 10;
        m_retrans_request_retries = value_retries !== null ? value_retries : 1;
        m_block_retransmission_update = false;
    }

    function set_retransmission_param(param_id, value){
        if(_ohdSystemGroundSettings.system_is_alive() && _ohdSystemGroundSettings.has_params_fetched){
            _ohdSystemGroundSettings.try_set_param_int_async(param_id, value);
        }
        if(_ohdSystemAirSettingsModel.system_is_alive() && _ohdSystemAirSettingsModel.has_params_fetched){
            _ohdSystemAirSettingsModel.try_set_param_int_async(param_id, value);
        }
    }

    function power_model_ready(model) {
        return model !== undefined && model.system_is_alive() &&
                model.has_params_fetched && model.param_int_exists("TX_PWR_LVL");
    }

    function power_target_index(model) {
        if (!power_model_ready(model)) return -1;
        return find_index(power_target_model, model.get_cached_int("TX_PWR_LVL"));
    }

    function update_power_comboboxes() {
        comboBoxPowerAir.currentIndex = power_target_index(_ohdSystemAirSettingsModel);
        comboBoxPowerGround.currentIndex = power_target_index(_ohdSystemGroundSettings);
    }

    function set_power_target(model, index) {
        if (!power_model_ready(model) || index < 0 || index >= power_target_model.count) {
            _qopenhd.show_toast(qsTr("Power control is not ready"));
            update_power_comboboxes();
            return;
        }
        model.try_set_param_int_async("TX_PWR_LVL", power_target_model.get(index).value);
    }

    function ensure_power_params_fetched(model) {
        if (model === undefined || !model.system_is_alive() ||
                model.has_params_fetched || model.ui_is_busy) return;
        model.try_refetch_all_parameters_async(false);
    }

    function update_adaptive_channel_control() {
        m_block_adaptive_update = true;
        var value = read_param_int(_ohdSystemAirSettingsModel, "WB_ADAPT_CH");
        m_adaptive_available = value !== null;
        m_adaptive_enabled = value !== null && value > 0;
        m_block_adaptive_update = false;
    }

    function update_fhss_control() {
        m_block_fhss_update = true;
        var air = read_param_int(_ohdSystemAirSettingsModel, "WB_FHSS");
        var ground = read_param_int(_ohdSystemGroundSettings, "WB_FHSS");
        var slot = read_param_int(_ohdSystemAirSettingsModel, "WB_FHSS_SLOT");
        if (slot === null) slot = read_param_int(_ohdSystemGroundSettings, "WB_FHSS_SLOT");
        m_fhss_available = air !== null && ground !== null;
        m_fhss_enabled = m_fhss_available && air > 0 && ground > 0;
        m_fhss_slot_ms = slot !== null ? slot : 50;
        comboBoxFhssSlot.currentIndex = find_index(fhss_slot_model, m_fhss_slot_ms);
        m_block_fhss_update = false;
    }

    function set_fhss_enabled(enabled) {
        if (!m_fhss_available) return;
        // Arm the follower before the authority starts hopping. On shutdown,
        // stop the authority first so Ground can still hear the last channel.
        if (enabled) {
            _ohdSystemGroundSettings.try_set_param_int_async("WB_FHSS", 1);
            fhssSecondEndpointTimer.enabling = true;
            fhssSecondEndpointTimer.restart();
        } else {
            _ohdSystemAirSettingsModel.try_set_param_int_async("WB_FHSS", 0);
            fhssSecondEndpointTimer.enabling = false;
            fhssSecondEndpointTimer.restart();
        }
    }

    function set_fhss_slot(value) {
        _ohdSystemGroundSettings.try_set_param_int_async("WB_FHSS_SLOT", value);
        _ohdSystemAirSettingsModel.try_set_param_int_async("WB_FHSS_SLOT", value);
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
        id: frequencies_model
        ListElement {title: qsTr("Unknown"); value_frequency_mhz:-1}
    }

    function create_list_models_frequency(){
        frequencies_model.clear();
        const filter = filter_tab_bar.currentIndex;
        const frequencies_all=_frequencyHelper.get_frequencies(filter);
        for(var i=0;i<frequencies_all.length;i++){
            const frequency=frequencies_all[i];
            const text=_frequencyHelper.get_frequency_description(frequency)
            frequencies_model.append({title: text, value_frequency_mhz: frequency});
        }
    }

    function update_frequency_combobox(){
        create_list_models_frequency();
        comboBoxFreq.model=frequencies_model;
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

    onM_retrans_update_countChanged: {
        update_retransmission_switches();
        ensure_power_params_fetched(_ohdSystemAirSettingsModel);
        ensure_power_params_fetched(_ohdSystemGroundSettings);
        update_power_comboboxes();
        update_adaptive_channel_control();
        update_fhss_control();
    }

    //
    function close_all_dialoques(){
        popup_analyze_channels.close()
        popup_scan_channels.close();
        dialoqueFreqChangeGndOnly.close();
        dialoqueFreqChangeAirGnd.close();
        popup_enable_stbc_ldpc.close();
    }

    function get_text_stbc_ldpc(air){
        if(air){
            if(!_ohdSystemAir.is_alive)return qsTr("N/A");
            return qsTr("%1/%2")
                .arg(_ohdSystemAir.wb_stbc_enabled ? qsTr("YES") : qsTr("NO"))
                .arg(_ohdSystemAir.wb_lpdc_enabled ? qsTr("YES") : qsTr("NO"));
        }
        if(!_ohdSystemGround.is_alive)return qsTr("N/A");
        return qsTr("%1/%2")
            .arg(_ohdSystemGround.wb_stbc_enabled ? qsTr("YES") : qsTr("NO"))
            .arg(_ohdSystemGround.wb_lpdc_enabled ? qsTr("YES") : qsTr("NO"));
    }

    Component.onCompleted: {
        close_all_dialoques();
        create_list_models_frequency();
        update_frequency_combobox();
        update_retransmission_switches();
        ensure_power_params_fetched(_ohdSystemAirSettingsModel);
        ensure_power_params_fetched(_ohdSystemGroundSettings);
        update_power_comboboxes();
        update_adaptive_channel_control();
        update_fhss_control();
    }

    onVisibleChanged: {
        if (!visible) return;
        ensure_power_params_fetched(_ohdSystemAirSettingsModel);
        ensure_power_params_fetched(_ohdSystemGroundSettings);
        update_power_comboboxes();
        update_adaptive_channel_control();
        update_fhss_control();
    }

    ScrollView {
        id: main_scroll_view
        width: parent.width
        height: parent.height
        anchors.centerIn: parent
        contentHeight: main_column_layout.height
        //contentWidth: main_column_layout.width
        //ScrollBar.vertical.policy: ScrollBar.AlwaysOn
        ScrollBar.vertical.policy: ScrollBar.AlwaysOff
        visible: (!popup_analyze_channels.visible && !popup_enable_stbc_ldpc.visible && !popup_scan_channels.visible)
        clip: true

        Item {
            anchors.fill: parent

            Column{
                id: main_column_layout
                anchors.left: parent.left
                anchors.right: parent.right

                SettingsCategory{
            m_description: qsTr("FREQUENCY / TOOLKIT")
                    spacing: 1
                    m_hide_elements: false;

                    Row{
                        anchors.horizontalCenter: parent.horizontalCenter
                        spacing: 8
                        ComboBox {
                            width: elementComboBoxWidth
                            id: comboBoxFreq
                            model: frequencies_model
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
                                    m_openhd_licensed_band: _frequencyHelper.get_frequency_openhd_licensed_band(value_frequency_mhz)
                                    m_pollution_pps: _pollutionHelper.pollution_get_last_scan_pollution_for_frequency(value_frequency_mhz)
                                }
                                highlighted: comboBoxFreq.highlightedIndex === index
                            }
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
                                    _qopenhd.show_toast(qsTr("your HW does not support %1 MHz").arg(frequency_mhz));
                                    return;
                                }
                                if(_wbLinkSettingsHelper.curr_channel_mhz==frequency_mhz){
                                    console.log("Already at frequency "+frequency_mhz);
                                    return;
                                }
                                if(!_ohdSystemAir.is_alive){
                                    var error_message_not_alive=qsTr("AIR Unit not alive -")
                                    dialoqueFreqChangeGndOnly.initialize_and_show_frequency(frequency_mhz,error_message_not_alive);
                                    return;
                                }
                                // Change the freuquency
                                dialoqueFreqChangeAirGnd.initialize_and_show_frequency(frequency_mhz);
                            }
                            enabled: _ohdSystemGround.is_alive && _ohdSystemGround.wb_gnd_operating_mode==0;
                        }
                        TabBar {
                            id: filter_tab_bar
                            width: 350
                            currentIndex: settings.qopenhd_frequency_filter_selection
                            onCurrentIndexChanged: {
                                if (currentIndex != settings.qopenhd_frequency_filter_selection) {
                                    settings.qopenhd_frequency_filter_selection = currentIndex;
                                    console.log("Tab changed to index:", currentIndex);
                                    function_rebuild_ui();
                                }
                            }
                            TabButton {
                                text: qsTr("OpenHD")
                                font.capitalization: Font.MixedCase
                            }
                            TabButton {
                                text: qsTr("2.4G")
                                enabled: {
                                    if (_ohdSystemAir.is_alive && _ohdSystemAir.ohd_platform_type == 30) {
                                        // X20 does not support 2.4G
                                        return false;
                                    }
                                    return true;
                                }
                            }
                            TabButton {
                                text: qsTr("5.8G")
                            }
                            enabled: comboBoxFreq.enabled
                            TabButton {
                                text: qsTr("Custom")
                                font.capitalization: Font.MixedCase
                                visible: settings.dev_show_5180mhz_lowband
                            }
                        }

                        /*ButtonIconInfo2{
                    Layout.alignment: Qt.AlignRight
                    visible:false
                    onClicked: {
                        var text="Please select a channel / frequency free of noise and interference. The current loss / pollution stats below can help,"+
                                "as well as the analyze channels feature or a frequency analyzer on your phone. DEF: Show OpenHD standard channels [1-7] only - they "+
                                " often are free of wifi pollution and should be used."
                        _messageBoxInstance.set_text_and_show(text)
                    }
                }*/
                    }

                    Row{
                        anchors.horizontalCenter: parent.horizontalCenter
                        spacing: 8
                        Button{
                            width:  150
                            id: b_find_air_unit
                            text: qsTr("SCAN")
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
                            width:  150
                            text: qsTr("ANALYZE")
                            enabled: _ohdSystemGround.is_alive
                            onClicked: {
                                close_all_dialoques();
                                popup_analyze_channels.open()
                            }
                        }
                    }
                    Row{
                        anchors.horizontalCenter: parent.horizontalCenter
                        Text{
                            width:  m_small_width
                            height: m_small_height
                            text:{
                                qsTr("LOSS:\n%1%").arg(_ohdSystemGround.curr_rx_packet_loss_perc)
                            }
                            color: _ohdSystemGround.curr_rx_packet_loss_perc > 5 ? "red" : "black"
                            verticalAlignment: Qt.AlignVCenter
                            horizontalAlignment: Qt.AlignHCenter
                            font.bold: false
                            font.pixelSize: settings.qopenhd_general_font_pixel_size
                        }
                        Text{
                            width:  m_small_width
                            height: m_small_height
                            text: {
                                return "POLLUTION:\n"+_ohdSystemGround.wb_link_curr_foreign_pps+"pps"
                            }
                            color: _ohdSystemGround.wb_link_curr_foreign_pps > 20 ? "red" : "black"
                            verticalAlignment: Qt.AlignVCenter
                            horizontalAlignment: Qt.AlignHCenter
                            font.bold: false
                            font.pixelSize: settings.qopenhd_general_font_pixel_size
                        }
                        Text{
                            width:  m_small_width
                            height: m_small_height
                            text: {
                                return qsTr("TX ERRORS:\n%1").arg(_cameraStreamModelPrimary.total_n_tx_dropped_frames)
                            }
                            color: _ohdSystemGround.wb_link_curr_foreign_pps > 20 ? "red" : "black"
                            verticalAlignment: Qt.AlignVCenter
                            horizontalAlignment: Qt.AlignHCenter
                            font.bold: false
                            font.pixelSize: settings.qopenhd_general_font_pixel_size
                        }
                        /*Text{
                            width:  m_small_width
                            height: m_small_height
                            text: {
                                var ret="THROTTLE:\n";
                                if(_ohdSystemAir.curr_n_rate_adjustments<=-1){
                                    ret+="N/A";
                                }else if(_ohdSystemAir.curr_n_rate_adjustments==0){
                                    ret+="NONE";
                                }else{
                                    ret+=("ACTIVE:"+_ohdSystemAir.curr_n_rate_adjustments+"x");
                                }
                                return ret;
                            }
                            color: _ohdSystemAir.curr_n_rate_adjustments > 0 ? "red" : "black"
                            verticalAlignment: Qt.AlignVCenter
                            horizontalAlignment: Qt.AlignHCenter
                            font.bold: false
                            font.pixelSize: settings.qopenhd_general_font_pixel_size
                        }*/
                    }
                    Row {
                        anchors.horizontalCenter: parent.horizontalCenter
                        spacing: 12
                        Text {
                            height: m_small_height
                            text: qsTr("ADAPTIVE CHANNEL")
                            verticalAlignment: Qt.AlignVCenter
                            font.pixelSize: settings.qopenhd_general_font_pixel_size
                        }
                        Switch {
                            checked: m_adaptive_enabled
                            enabled: m_adaptive_available && !m_fhss_enabled &&
                                     !m_block_adaptive_update &&
                                     _ohdSystemAir.is_alive
                            onClicked: {
                                if (!m_adaptive_available) return;
                                _ohdSystemAirSettingsModel.try_set_param_int_async(
                                            "WB_ADAPT_CH", checked ? 1 : 0);
                            }
                        }
                        Text {
                            height: m_small_height
                            text: m_adaptive_available
                                  ? qsTr("Air radio 2 surveys for cleaner channels")
                                  : qsTr("Requires two Devourer radios on Air")
                            color: m_adaptive_available ? "black" : "#707070"
                            verticalAlignment: Qt.AlignVCenter
                            font.pixelSize: settings.qopenhd_general_font_pixel_size
                        }
                    }
                    Row {
                        anchors.horizontalCenter: parent.horizontalCenter
                        spacing: 12
                        Text {
                            height: m_small_height
                            text: qsTr("DEVOURER FHSS")
                            verticalAlignment: Qt.AlignVCenter
                            font.pixelSize: settings.qopenhd_general_font_pixel_size
                        }
                        Switch {
                            checked: m_fhss_enabled
                            enabled: m_fhss_available && !m_block_fhss_update &&
                                     _ohdSystemAir.is_alive && _ohdSystemGround.is_alive
                            onClicked: set_fhss_enabled(checked)
                        }
                        ComboBox {
                            id: comboBoxFhssSlot
                            width: 120
                            height: m_small_height
                            model: fhss_slot_model
                            textRole: "title"
                            enabled: m_fhss_available && !m_fhss_enabled
                            onActivated: set_fhss_slot(fhss_slot_model.get(currentIndex).value)
                        }
                        Text {
                            height: m_small_height
                            text: m_fhss_available
                                  ? qsTr("mLRS/secondary telemetry uplink required")
                                  : qsTr("Requires Devourer on Air and Ground")
                            color: m_fhss_available ? "black" : "#707070"
                            verticalAlignment: Qt.AlignVCenter
                            font.pixelSize: settings.qopenhd_general_font_pixel_size
                        }
                    }
                }

                SettingsCategory{
                    m_description: qsTr("TX POWER");
                    m_hide_elements: false;
                    Row{
                        anchors.horizontalCenter: parent.horizontalCenter
                        spacing: 24
                        Text{
                            width:  55
                            height: m_small_height
                            text: qsTr("AIR:")
                            verticalAlignment: Qt.AlignVCenter
                            horizontalAlignment: Qt.AlignRight
                            font.bold: false
                            font.pixelSize: settings.qopenhd_general_font_pixel_size
                        }
                        ComboBox {
                            id: comboBoxPowerAir
                            width: 180
                            height: m_small_height
                            model: power_target_model
                            textRole: "title"
                            currentIndex: -1
                            displayText: currentIndex >= 0 ? currentText : qsTr("N/A")
                            enabled: m_retrans_update_count >= 0 &&
                                     power_model_ready(_ohdSystemAirSettingsModel)
                            font.pixelSize: settings.qopenhd_general_font_pixel_size
                            onActivated: set_power_target(_ohdSystemAirSettingsModel, currentIndex)
                        }
                        Text{
                            width:  75
                            height: m_small_height
                            text: qsTr("GROUND:")
                            verticalAlignment: Qt.AlignVCenter
                            horizontalAlignment: Qt.AlignRight
                            font.bold: false
                            font.pixelSize: settings.qopenhd_general_font_pixel_size
                        }
                        ComboBox {
                            id: comboBoxPowerGround
                            width: 180
                            height: m_small_height
                            model: power_target_model
                            textRole: "title"
                            currentIndex: -1
                            displayText: currentIndex >= 0 ? currentText : qsTr("N/A")
                            enabled: m_retrans_update_count >= 0 &&
                                     power_model_ready(_ohdSystemGroundSettings)
                            font.pixelSize: settings.qopenhd_general_font_pixel_size
                            onActivated: set_power_target(_ohdSystemGroundSettings, currentIndex)
                        }

                    }
                }

                Loader{
                    id: retransmissionLoader
                    active: settings.dev_show_advanced_button
                    width: parent.width
                    height: item ? item.implicitHeight : 0
                    sourceComponent: SettingsCategory{
                        m_description: qsTr("RETRANSMISSION");
                        m_hide_elements: false;
                        Column{
                            anchors.horizontalCenter: parent.horizontalCenter
                            spacing: 6
                            Row{
                                spacing: 12
                                Text{
                                    width:  m_small_width
                                    height: m_small_height
                                    text: qsTr("VIDEO")
                                    verticalAlignment: Qt.AlignVCenter
                                    horizontalAlignment: Qt.AlignHCenter
                                    font.bold: false
                                    font.pixelSize: settings.qopenhd_general_font_pixel_size
                                }
                                Switch{
                                    checked: m_retrans_video_enabled
                                    enabled: !m_block_retransmission_update && _ohdSystemAir.is_alive && _ohdSystemGround.is_alive
                                    onClicked: {
                                        set_retransmission_param("WB_RTX_VIDEO", checked ? 1 : 0);
                                    }
                                }
                            }
                            Row{
                                spacing: 12
                                Text{
                                    width:  m_small_width
                                    height: m_small_height
                                    text: qsTr("TELEMETRY")
                                    verticalAlignment: Qt.AlignVCenter
                                    horizontalAlignment: Qt.AlignHCenter
                                    font.bold: false
                                    font.pixelSize: settings.qopenhd_general_font_pixel_size
                                }
                                Switch{
                                    checked: m_retrans_telemetry_enabled
                                    enabled: !m_block_retransmission_update && _ohdSystemAir.is_alive && _ohdSystemGround.is_alive
                                    onClicked: {
                                        set_retransmission_param("WB_RTX_TELEM", checked ? 1 : 0);
                                    }
                                }
                            }
                            Row{
                                spacing: 12
                                Text{
                                    width:  m_small_width
                                    height: m_small_height
                                    text: qsTr("RC")
                                    verticalAlignment: Qt.AlignVCenter
                                    horizontalAlignment: Qt.AlignHCenter
                                    font.bold: false
                                    font.pixelSize: settings.qopenhd_general_font_pixel_size
                                }
                                Switch{
                                    checked: m_retrans_rc_enabled
                                    enabled: !m_block_retransmission_update && _ohdSystemAir.is_alive && _ohdSystemGround.is_alive
                                    onClicked: {
                                        set_retransmission_param("WB_RTX_RC", checked ? 1 : 0);
                                    }
                                }
                            }
                            Row{
                                spacing: 12
                                Text{
                                    width:  m_small_width
                                    height: m_small_height
                                    text: qsTr("VIDEO\nMAX MS")
                                    verticalAlignment: Qt.AlignVCenter
                                    horizontalAlignment: Qt.AlignHCenter
                                    font.bold: false
                                    font.pixelSize: settings.qopenhd_general_font_pixel_size
                                }
                                SpinBox{
                                    from: 1
                                    to: 100
                                    value: m_retrans_history_video_ms
                                    enabled: !m_block_retransmission_update && _ohdSystemAir.is_alive && _ohdSystemGround.is_alive
                                    onValueModified: {
                                        if(m_block_retransmission_update)return;
                                        set_retransmission_param("WB_RTX_V_MAXMS", value);
                                    }
                                }
                            }
                            Row{
                                spacing: 12
                                Text{
                                    width:  m_small_width
                                    height: m_small_height
                                    text: qsTr("TELEM\nMAX MS")
                                    verticalAlignment: Qt.AlignVCenter
                                    horizontalAlignment: Qt.AlignHCenter
                                    font.bold: false
                                    font.pixelSize: settings.qopenhd_general_font_pixel_size
                                }
                                SpinBox{
                                    from: 1
                                    to: 100
                                    value: m_retrans_history_telemetry_ms
                                    enabled: !m_block_retransmission_update && _ohdSystemAir.is_alive && _ohdSystemGround.is_alive
                                    onValueModified: {
                                        if(m_block_retransmission_update)return;
                                        set_retransmission_param("WB_RTX_T_MAXMS", value);
                                    }
                                }
                            }
                            Row{
                                spacing: 12
                                Text{
                                    width:  m_small_width
                                    height: m_small_height
                                    text: qsTr("RC\nMAX MS")
                                    verticalAlignment: Qt.AlignVCenter
                                    horizontalAlignment: Qt.AlignHCenter
                                    font.bold: false
                                    font.pixelSize: settings.qopenhd_general_font_pixel_size
                                }
                                SpinBox{
                                    from: 1
                                    to: 100
                                    value: m_retrans_history_rc_ms
                                    enabled: !m_block_retransmission_update && _ohdSystemAir.is_alive && _ohdSystemGround.is_alive
                                    onValueModified: {
                                        if(m_block_retransmission_update)return;
                                        set_retransmission_param("WB_RTX_R_MAXMS", value);
                                    }
                                }
                            }
                            Row{
                                spacing: 12
                                Text{
                                    width:  m_small_width
                                    height: m_small_height
                                    text: qsTr("REQ\nRETRIES")
                                    verticalAlignment: Qt.AlignVCenter
                                    horizontalAlignment: Qt.AlignHCenter
                                    font.bold: false
                                    font.pixelSize: settings.qopenhd_general_font_pixel_size
                                }
                                SpinBox{
                                    from: 1
                                    to: 10
                                    value: m_retrans_request_retries
                                    enabled: !m_block_retransmission_update && _ohdSystemAir.is_alive && _ohdSystemGround.is_alive
                                    onValueModified: {
                                        if(m_block_retransmission_update)return;
                                        set_retransmission_param("WB_RTX_REQ_REP", value);
                                    }
                                }
                            }
                        }
                    }
                }

                SettingsCategory{
                    m_description: qsTr("ADVANCED (STBC,LDPC)")
                    m_hide_elements: false;
                    Row{
                        anchors.horizontalCenter: parent.horizontalCenter
                        Text{
                            width:  m_small_width
                            height: m_small_height
                            text: qsTr("AIR:\n%1").arg(get_text_stbc_ldpc(true))
                            verticalAlignment: Qt.AlignVCenter
                            horizontalAlignment: Qt.AlignHCenter
                            font.bold: false
                            font.pixelSize: settings.qopenhd_general_font_pixel_size
                        }
                        Text{
                            width:  m_small_width
                            height: m_small_height
                            text: qsTr("GND:\n%1").arg(get_text_stbc_ldpc(false))
                            verticalAlignment: Qt.AlignVCenter
                            horizontalAlignment: Qt.AlignHCenter
                            font.bold: false
                            font.pixelSize: settings.qopenhd_general_font_pixel_size
                        }
                        Button{
                            text: qsTr("EDIT");
                            //enabled: true
                            enabled: _ohdSystemAir.is_alive && _ohdSystemGround.is_alive && (_wbLinkSettingsHelper.ui_rebuild_models>=0) &&
                                     (_ohdSystemGround.wb_stbc_enabled!=true || _ohdSystemGround.wb_lpdc_enabled!=true || _ohdSystemAir.wb_stbc_enabled!=true || _ohdSystemAir.wb_lpdc_enabled!=true);
                            onClicked: {
                                close_all_dialoques();
                                popup_enable_stbc_ldpc.open()
                            }
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

