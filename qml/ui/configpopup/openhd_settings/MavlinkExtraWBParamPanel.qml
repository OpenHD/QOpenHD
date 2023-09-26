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

//simport QtCharts 2.0

// This is an extra screen for changing the frequency / channel width -
// They both need to match !
Rectangle{
    width: parent.width
    height: parent.height

    //color: "transparent"
    //color: settings.screen_settings_openhd_parameters_transparent ? "transparent" : "white"
    //opacity: settings.screen_settings_openhd_parameters_transparent ? 0.2 : 1

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
        ListElement {title: "Unknown"; value:-1; radar: false; recommended: false; pollution: -1}
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
            const v_pollution= _wbLinkSettingsHelper.get_frequency_pollution(frequency)
            const simple=_wbLinkSettingsHelper.get_frequency_simplify(frequency)
            const radar=_wbLinkSettingsHelper.get_frequency_radar(frequency)
            const recommended=_wbLinkSettingsHelper.get_frequency_reccommended(frequency)
            var append_this_value=true;
            if(m_simplify_enable){
                // only add if it is a "simple" channel
                append_this_value = simple;
            }else{
                append_this_value=true;
            }
            if(append_this_value){
                supported_frequencies_model.append({title: text, value: frequency, radar:radar, recommended: recommended, pollution: v_pollution })
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
    }

    /*property BarCategoryAxis m_bar_category_axis;
    function update_pollution_graph(){
        const supported_frequencies=_wbLinkSettingsHelper.get_supported_frequencies();
        m_bar_category_axis.categories.clear();
        for(var i=0;i<supported_frequencies.length;i++){
            m_bar_category_axis.categories.append(""+supported_frequencies.at(i));
        }
        hm_bar_series.axisX = m_bar_category_axis
    }*/

    //
    Component.onCompleted: {

    }
    //

    // ------------------- PART HELPER FOR CURRENT LOSS / POLLUTION / THROTTLE BEGIN -------------------
    property bool m_is_ground_and_air_alive: _ohdSystemGround.is_alive && _ohdSystemAir.is_alive
    property int m_loss_warning_level: {
        if(!_ohdSystemAir.is_alive)return 0; // Info not available
        var curr_rx_packet_loss_perc=_ohdSystemGround.curr_rx_packet_loss_perc;
        if(curr_rx_packet_loss_perc>=8)return 2;
        if(curr_rx_packet_loss_perc>=4)return 1;
        return 0;
    }

    property int m_pollution_warning_level: {
        if(!_ohdSystemAir.is_alive)return 0; // Info not available
        var wb_link_pollution=_ohdSystemGround.wb_link_pollution;
        if(wb_link_pollution>=8)return 2;
        if(wb_link_pollution>=3)return 1;
        return 0;
    }

    property int m_throttle_warning_level: {
        if(!_ohdSystemAir.is_alive)return 0; // Info not available
        var throttle=_ohdSystemAir.curr_n_rate_adjustments;
        if(throttle>=3)return 2;
        if(throttle>=1)return 1;
        return 0;
    }
    function warning_level_to_color(level){
        if(level==2)return "red";
        if(level==1)return "green";
        return "black";
    }

    function get_text_current_loss(){
        if(!_ohdSystemGround.is_alive){
            return "No Ground unit"
        }
        if(!_ohdSystemAir.is_alive){
            return "No air unit";
        }
        return "Curr Loss:"+_ohdSystemGround.curr_rx_packet_loss_perc+"%";
    }

    function get_text_current_pollution(){
        if(!m_is_ground_and_air_alive){
            return "";
        }
        var wb_link_pollution=_ohdSystemGround.wb_link_pollution;
        return "Pollution:"+wb_link_pollution+" %";
    }
    function get_text_current_throttle(){
        if(!m_is_ground_and_air_alive){
            return "";
        }
        var throttle=_ohdSystemAir.curr_n_rate_adjustments;
        if(throttle<=-1)return "";
        if(throttle<=0){
            return " Throttle:None"
        }
        return " Throttle: -"+throttle;
    }
    // ------------------- PART HELPER FOR CURRENT LOSS / POLLUTION / THROTTLE END -------------------


    function get_combobox_text_color(element_index,curr_index,frequency){
        if(frequency===_wbLinkSettingsHelper.curr_channel_mhz){
            return "green";
        }
        if(element_index===curr_index){
            // currently selected in the combobox (but not neccessarily applied in openhd)
            return "blue";
        }
        return "black";
    }

    function get_color_pollution(pollution){
        if(pollution<=0)return "green";
        if(pollution<=10) return "orange"
        return "red";
    }

    function get_text_pollution(pollution){
        if(pollution<=-1)return "";
        if(pollution<=0)return "FREE";
        return "P:"+pollution;
    }
    function get_text_current_disarmed_armed(pwr_current,pwr_disarmed,pwr_armed){
        var ret= "Curr:"+pwr_current;
        if(pwr_armed==0){ // Same power regardless if armed or not
            ret += " Armed/Disarmed:"+pwr_disarmed;
        }else{
            ret +=" Disarm:"+pwr_disarmed;
            ret+=" Arm:"+pwr_armed;

        }
        return ret;
    }

    function get_text_tx_power(ground){
        var card= ground ? _wifi_card_gnd0 : _wifi_card_air;
        //var card= _wifi_card_gnd0;
        var ret = ground ? "TX PWR GND: " : "TX PWR AIR: ";
        var card_type=card.card_type;
        if(!card.alive){
            ret+="No info";
            return ret;
        }
        ret+=get_text_current_disarmed_armed(card.tx_power,card.tx_power_disarmed,card.tx_power_armed);
        ret+=" "+card.tx_power_unit
        return ret;
    }

    function set_channel_width_async(channel_width_mhz){
        if(!_ohdSystemAir.is_alive){
            _qopenhd.show_toast("Cannot change BW:"+channel_width_mhz+"Mhz, AIR not alive")
            return;
        }
        _wbLinkSettingsHelper.change_param_air_channel_width_async(channel_width_mhz,false);
    }

    property string m_text_warning_nosync_frequency: "WARNING: THIS CHANGES YOUR GROUND UNIT FREQUENCY WITHOUT CHANGING YOUR AIR UNIT FREQUENCY !
Only enable if you want to quickly change your ground unit's frequency to the already set frequency of a running air unit (And know both frequency and channel width on top of your head)";

    property string m_text_warning_nosync_chanel_width: "WARNING: THIS CHANGES YOUR GROUND UNIT CHANNEL WIDTH WITHOUT CHANGING YOUR AIR UNIT CHANNEL WIDTH !
Only enable if you want to quickly change your ground unit's channel width to the already set channel width of a running air unit (And know both frequency and channel width on top of your head)"


    /*property string more_info_text: "After flashing,openhd uses the same default frequency, and your air and ground unit automatically connect."+
    "If you change the frequency / channel width here, both air and ground unit are set to the new frequency."+
"If you changed the frequency of your air unit and are using a different Ground unit, use the FIND AIR UNIT feature (channel scan) to switch to the same frequency your air unit is running on."*/
    property string more_info_text: "Here you can easily change the openhd link frequency/bandwidth of you air and ground unit."+
"After flashing, both air and ground unit start on the same frequency and automatically connect."+
"If you changed the frequency of your air unit and are using a different Ground unit, use the FIND AIR UNIT feature (channel scan) to switch to the same frequency your air unit is running on."

    property string find_air_unit_text:"Scan all channels for a running Air unit. Might take up to 30seconds to complete (openhd supports a ton of channels, and we need to listen on each of them for a short timespan)"

    property string analyze_channels_text: "Listen for other WIFi packets packets on each frequency for a short amount of time - a lot of foreign packets hint at a polluted channel"

     property string m_info_text_change_frequency: "Frequency in Mhz and channel number. (DFS-RADAR) - also used by commercial plane(s) weather radar (not recommended unless you have ADSB). "+
" ! OPENHD DOESN'T HAVE ANY RESTRICTIONS ! - It is your responsibility to use channels (frequencies) allowed in your country."

    property string m_info_text_change_channel_width: "A channel width of 40Mhz (40Mhz bandwitdh) gives almost double the bandwidth (2x video bitrate/image quality), but uses 2x 20Mhz channels and therefore the likeliness of "+
"interference from other stations sending on either of those channels is increased. It also slightly decreases sensitivity. In general, we recommend 40Mhz unless you are flying ultra long range "+
"or in a highly polluted (urban) environment."

    property string m_info_text_change_tx_power: "Change GND / AIR TX power. Higher AIR TX power results in more range on the downlink (video,telemetry).
Higher GND TX power results in more range on the uplink (mavlink up). You can set different tx power for armed / disarmed state (requres FC),
but it is not possible to change the TX power during flight (due to the risk of misconfiguration / power outage)."+
    " ! OPENHD DOESN'T HAVE ANY RESTRICTIONS ON TX POWER - It is your responsibility to use a tx power allowed in your country. !"

    property string m_warning_text_no_gnd_unit: "GROUND not alive, settings uavailable. Please check status view."
    property string m_warning_text_no_air_unit: "Make sure your air unit hardware is functioning properly. If you freshly flashed your air and ground unit, they use the same frequency
and automatically connect. Otherwise, use the 'FIND AIR UNIT' feature to scan all channels for your air unit."

    property string m_warning_info_text_polluted_channel: "OpenHD is broadcast and works best on a channel free of noise and interference. Sometimes you cannot find such a channel
(e.g. in urban environments), in which case you might want to use the city preset from WBLink widget. To find a free channel, use a frequency analyzer on your phone,
the analyze channels feature or experience -  [169] 5845Mhz is a good bet in Europe, since it only allows 25mW."

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

    function get_text_current_frequency(){
        if(!_ohdSystemGround.is_alive)return "N/A";
        return _wbLinkSettingsHelper.curr_channel_mhz+"@"+_wbLinkSettingsHelper.curr_channel_width_mhz+"Mhz";
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
            height: rowHeight*7

            DIaloqueStartChannelScan{
                id: dialoqueStartChannelScan
            }
            DialoqueFreqChangeGndOnly{
                id: dialoqueFreqChangeGndOnly
            }
            DialoqueFreqChangeArmed{
                id: dialoqueFreqChangeArmed
            }
            DialoqueStartAnalyzeChannels{
                id: dialoqueAnalyzeChannels
            }

            DialoqueChangeTxPower{
                id: txPowerDialoque
            }

            Column {
                id:wbParamColumn
                spacing: 0
                anchors.left: parent.left
                anchors.right: parent.right

                Rectangle {
                    width: parent.width
                    height: rowHeight
                    color: "#00000000"
                    RowLayout{
                        anchors.verticalCenter: parent.verticalCenter
                        Button{
                            text: "MORE INFO"
                            Material.background:Material.LightBlue
                            onClicked: {
                                _messageBoxInstance.set_text_and_show(more_info_text)
                            }
                        }
                        Text{
                            text: get_text_current_loss()
                            color: warning_level_to_color(m_loss_warning_level)
                        }
                        Text{
                            text: get_text_current_pollution()
                            color: warning_level_to_color(m_pollution_warning_level)
                        }
                        Text{
                            text: get_text_current_throttle()
                            color: warning_level_to_color(m_throttle_warning_level)
                        }
                        ButtonIconWarning{
                            visible: !_ohdSystemGround.is_alive
                            onClicked: {
                                _messageBoxInstance.set_text_and_show(m_warning_text_no_gnd_unit)
                            }
                        }
                        ButtonIconWarning{
                            visible: _ohdSystemGround.is_alive && !_ohdSystemAir.is_alive
                            onClicked: {
                                _messageBoxInstance.set_text_and_show(m_warning_text_no_air_unit)
                            }
                        }
                        ButtonIconWarning{
                            visible: m_loss_warning_level>0 || m_pollution_warning_level>0 || m_throttle_warning_level>0;
                            onClicked: {
                                _messageBoxInstance.set_text_and_show(m_warning_info_text_polluted_channel)
                            }
                        }
                    }
                }


                // Changing the wifi frequency, r.n only 5G
                Rectangle {
                    width: parent.width
                    height: rowHeight
                    //color: (Positioner.index % 2 == 0) ? "#8cbfd7f3" : "#00000000"
                    color: "#8cbfd7f3"

                    RowLayout{
                        anchors.verticalCenter: parent.verticalCenter
                        ButtonIconInfo{
                            onClicked: {
                                _messageBoxInstance.set_text_and_show(m_info_text_change_frequency)
                            }
                        }
                        ComboBox {
                            id: comboBoxFreq
                            model: supported_frequencies_model
                            textRole: "title"
                            implicitWidth:  elementComboBoxWidth
                            currentIndex: 0
                            // Customization
                            // https://stackoverflow.com/questions/31411844/how-to-limit-the-size-of-drop-down-of-a-combobox-in-qml
                            /*style: ComboBoxStyle {
                                id: comboBoxStyle

                                // drop-down customization here
                                property Component __dropDownStyle: MenuStyle {
                                  __maxPopupHeight: Math.max(55, //min value to keep it to a functional size even if it would not look nice
                                                             Math.min(400,
                                                                      //limit the max size so the menu is inside the application bounds
                                                                        comboBoxStyle.control.Window.height
                                                                      - mapFromItem(comboBoxStyle.control, 0,0).y
                                                                      - comboBoxStyle.control.height))
                                  __menuItemType: "comboboxitem" //not 100% sure if this is needed
                                } //Component __dropDownStyle: MenuStyle
                            } //style: ComboBoxStyle */
                            delegate: ItemDelegate {
                                width: comboBoxFreq.width
                                contentItem: FreqComboBoxRow{
                                    m_main_text: title
                                    m_selection_tpye: (value===_wbLinkSettingsHelper.curr_channel_mhz) ? 1 : 0
                                    m_is_2G: value > 3000
                                    m_2G_5G_show: value > 100
                                    m_show_radar: radar
                                    m_show_good_channel: recommended
                                    m_pollution_text: get_text_pollution(pollution)
                                    m_pollution_color: get_color_pollution(pollution)
                                }
                                highlighted: comboBoxFreq.highlightedIndex === index
                            }
                        }
                        Button{
                            text: "APPLY FREQ"
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
                            enabled: _wbLinkSettingsHelper.ui_rebuild_models>=0 && _ohdSystemGround.is_alive;
                        }
                        Switch{
                            text: "Simplify"
                            checked: true
                            onCheckedChanged: {
                                if(m_simplify_enable!=checked){
                                    m_simplify_enable=checked;
                                    function_rebuild_ui();
                                }
                            }
                        }
                    }
                }
                Rectangle {
                    width: parent.width
                    height: rowHeight
                    //color: (Positioner.index % 2 == 0) ? "#8cbfd7f3" : "#00000000"
                    color: "#8cbfd7f3"

                    RowLayout{
                        anchors.verticalCenter: parent.verticalCenter
                        ButtonIconInfo{
                            onClicked: {
                                _messageBoxInstance.set_text_and_show(m_info_text_change_channel_width)
                            }
                        }
                        /*FreqComboBoxRow{
                            m_main_text: _fcM
                        }*/
                        Text{
                            text: "Curr:"+get_text_current_frequency();
                        }
                        Button{
                            text: "20Mhz"
                            onClicked: {
                                set_channel_width_async(20);
                            }
                            highlighted: _wbLinkSettingsHelper.curr_channel_width_mhz==20
                            enabled: _wbLinkSettingsHelper.ui_rebuild_models>0 && _ohdSystemAir.is_alive
                        }
                        Button{
                            text: "40Mhz"
                            onClicked: {
                               set_channel_width_async(40);
                            }
                            highlighted:  _wbLinkSettingsHelper.curr_channel_width_mhz==40
                            enabled: _wbLinkSettingsHelper.ui_rebuild_models>0 && _ohdSystemAir.is_alive
                        }
                    }
                }
                Rectangle {
                    width: parent.width
                    height: rowHeight
                    //color: (Positioner.index % 2 == 0) ? "#8cbfd7f3" : "#00000000"
                    color: "#00000000"

                    RowLayout{
                        anchors.verticalCenter: parent.verticalCenter
                        Layout.preferredWidth: 200
                        height: parent.height
                        ButtonIconInfo{
                            onClicked: {
                                _messageBoxInstance.set_text_and_show(m_info_text_change_tx_power)
                            }
                        }
                        Button{
                            text: "AIR TX PWR"
                            enabled: _ohdSystemAir.is_alive
                            onClicked: {
                                txPowerDialoque.open_tx_power_dialoque(false)
                            }
                        }
                        Button{
                            text: "GND TX PWR"
                            enabled: _ohdSystemGround.is_alive
                            onClicked: {
                                txPowerDialoque.open_tx_power_dialoque(true)
                            }
                        }
                        ColumnLayout{
                            Layout.fillWidth: true
                            Text{
                                text: get_text_tx_power(false)
                            }
                            Text{
                                text: get_text_tx_power(true)
                            }
                        }
                    }
                }

                Rectangle {
                    width: parent.width
                    height: rowHeight
                    //color: (Positioner.index % 2 == 0) ? "#8cbfd7f3" : "#00000000"
                    color: "#00000000"

                    RowLayout{
                        anchors.verticalCenter: parent.verticalCenter
                        width: parent.width
                        height: parent.height
                        ButtonIconInfo{
                            onClicked: {
                                _messageBoxInstance.set_text_and_show(find_air_unit_text)
                            }
                        }
                        Button{
                            id: buttonFindAirUnitId
                            text: "FIND AIR UNIT"
                            enabled: _ohdSystemGround.is_alive
                            onClicked: {
                                dialoqueStartChannelScan.open_channel_scan_dialoque()
                            }
                        }
                        ProgressBar{
                            Layout.fillWidth: true
                            Layout.rightMargin: 15
                            Layout.leftMargin: 15
                            height: parent.height
                            //indeterminate: true
                            from: 0
                            to: 100
                            value: _wbLinkSettingsHelper.progress_scan_channels_perc
                        }
                    }
                    // Highlight the button for the user
                    /*Rectangle{
                        width: 100
                        height: buttonFindAirUnitId.height
                        color: "red"
                        anchors.left: buttonFindAirUnitId.right
                        anchors.top: buttonFindAirUnitId.top
                    }*/
                }

                Rectangle {
                    width: parent.width
                    height: rowHeight
                    //color: (Positioner.index % 2 == 0) ? "#8cbfd7f3" : "#00000000"
                    color: "#00000000"
                    RowLayout{
                        anchors.verticalCenter: parent.verticalCenter
                        width: parent.width
                        height: parent.height
                        ButtonIconInfo{
                            onClicked: {
                                _messageBoxInstance.set_text_and_show(analyze_channels_text)
                            }
                        }
                        Button{
                            text: "ANALYZE"
                            enabled: _ohdSystemGround.is_alive
                            onClicked: {
                                dialoqueAnalyzeChannels.setup_and_show();
                            }
                        }
                        ProgressBar{
                            Layout.fillWidth: true
                            Layout.rightMargin: 15
                            Layout.leftMargin: 15
                            height: parent.height
                            //indeterminate: true
                            from: 0
                            to: 100
                            value: _wbLinkSettingsHelper.progress_analyze_channels_perc
                        }
                    }
                }
                Rectangle {
                    width: parent.width
                    height: rowHeight
                    Text{
                        text: _wbLinkSettingsHelper.text_for_qml
                    }
                }
                /*ChartView {
                      title: "Bar series"
                      width: parent.width
                      height: rowHeight * 3
                      legend.alignment: Qt.AlignBottom
                      antialiasing: true

                      PercentBarSeries {
                          id: hm_bar_series
                             axisX: BarCategoryAxis { categories: ["2007", "2008", "2009", "2010", "2011", "2012" ] }
                             BarSet { label: "Bob"; values: [2, 2, 3, 4, 5, 6] }
                             BarSet { label: "Susan"; values: [5, 1, 2, 4, 1, 7] }
                             BarSet { label: "James"; values: [3, 5, 8, 13, 5, 8] }
                        }
                }*/
            }
        }
    }
}
