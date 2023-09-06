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
        ListElement {title: "Unknown"; value:-1; pollution: -1}
    }
    ListModel{
        id: channel_width_model
        ListElement {title: "Unknown"; value: -1}
        ListElement {title: "20MHz (default)"; value: 20}
        ListElement {title: "40MHz (rtl8812au only)"; value: 40}
    }

    function create_list_model_supported(){
        supported_frequencies_model.clear()
        //supported_frequencies_model.append({title: "Unknown", value: -1})
        for(var i=0;i<100;i++){
            var frequency=_wbLinkSettingsHelper.get_next_supported_frequency(i);
            if(frequency<=0)break; // no more supported frequences
            var text=_wbLinkSettingsHelper.get_frequency_description(frequency)
            var v_pollution= _wbLinkSettingsHelper.get_frequency_pollution(frequency)
            supported_frequencies_model.append({title: text, value: frequency, pollution: v_pollution })
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

    function update_channel_width(){
        var index=find_index(channel_width_model,_wbLinkSettingsHelper.curr_channel_width_mhz);
        if(index>=0){
            comboBoxChannelWidth.currentIndex=index;
        }else{
            comboBoxChannelWidth.currentIndex=0;
            console.log("Seems not to be a valid channel width"+_wbLinkSettingsHelper.curr_channel_width_mhz)
        }
    }

    // We get notified every time we should re-build the model(s) and their current selection
    property int m_ui_rebuild_models : _wbLinkSettingsHelper.ui_rebuild_models
    onM_ui_rebuild_modelsChanged: {
        console.log("Rebuilding models "+_wbLinkSettingsHelper.ui_rebuild_models);
        create_list_model_supported();
        update_channel_width()
    }

    // Re-set the "disable sync" on init
    Component.onCompleted: {

    }

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
        return "Curr:"+pwr_current+" Arm:"+pwr_armed+" Disarm:"+pwr_disarmed;
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
        if(card_type==1){
            ret+=get_text_current_disarmed_armed(card.tx_power,card.tx_power_disarmed,card.tx_power_armed);
            ret+=" (unitless)"
            return ret;
        }
        ret+=get_text_current_disarmed_armed(card.tx_power,card.tx_power_disarmed,card.tx_power_armed);
        ret+=" MW";
        if(card_type<=0){
            ret+=" (maybe,unreliable)";
        }
        return ret;
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

    property string m_info_text_change_channel_width: "A channel width of 40Mhz (40Mhz bandwitdh) gives almost double the bandwidth, but uses 2x 20Mhz channels and therefore the likeliness of "+
"interference from other stations sending on either of those channels is increased. It also slightly decreases sensitivity. Only supported on rtl8812au/bu on air."

    property string m_info_text_change_tx_power: "Change GND / AIR TX power. Higher Air TX power results in more range on the downlink (video,telemetry).
Higher GND TX power results in more range on the uplink (mavlink up). You can set different tx power for armed / disarmed state (requres FC),
but it is not possible to change the TX power during flight (due to the risk of misconfiguration / power outage)."+
    " ! OPENHD DOESN'T HAVE ANY RESTRICTIONS ON TX POWER - It is your responsibility to use a tx power allowed in your country. !"

    property string m_warning_text_no_gnd_unit: "If you are running QOpenHD (the UI application) on your ground station itself, make sure OpenHD core is running. Otherwise, if you
are running QOpenHD on an external device, connect it to your ground station."
    property string m_warning_text_no_air_unit: "Make sure your air unit hardware is functioning properly. If you freshly flashed your air and ground unit, they use the same frequency
and automatically connect. Otherwise, use the 'FIND AIR UNIT' feature to scan all channels for your air unit."

    property string m_warning_info_text_polluted_channel: "OpenHD is broadcast and works best on a channel free of noise and interference. Sometimes you cannot find such a channel
(e.g. in urban environments), in which case you might want to use the city preset from WBLink widget. To find a free channel, use a frequency analyzer on your phone,
the analyze channels feature or experience -  [169] 5845Mhz is a good bet in Europe, since it only allows 25mW."

    // Changes either the frequency or channel width
    // These 2 need to be synced, so we have ( a bit complicated, but quite natural for the user) dialoque for the cases where we need to handle errors / show a warning
    function change_frequency_or_channel_width_sync_otherwise_handle_error(frequency_mhz,channel_width_mhz,ignore_armed_state){
        if(frequency_mhz>0 && channel_width_mhz>0){
            console.log("Use this method to change either of both !");
            return;
        }
        const change_frequency=frequency_mhz > 0 ? true : false;
        console.log("change_frequency_or_channel_width_sync_otherwise_handle_error: "+(change_frequency ? ("FREQ:"+frequency_mhz) : ("BWIDTH:"+channel_width_mhz))+"Mhz");
        // Ground needs to be alive and well
        if(!_ohdSystemGround.is_alive){
            _messageBoxInstance.set_text_and_show("Ground unit not alive",5);
            return;
        }
        // Air needs to be alive and well - otherwise we show the "do you want to change gnd only" dialoque
        if(!_ohdSystemAir.is_alive){
            var error_message_not_alive="AIR Unit not alive -"
            if(change_frequency){
                dialoqueFreqChangeGndOnly.initialize_and_show_frequency(frequency_mhz,error_message_not_alive);
            }else{
                dialoqueFreqChangeGndOnly.initialize_and_show_channel_width(channel_width_mhz,error_message_not_alive);
            }
            return;
        }
        // FC needs to be disarmed - otherwise show warning
        const fc_currently_armed = (_fcMavlinkSystem.is_alive && _fcMavlinkSystem.armed)// || true;
        if(fc_currently_armed && ignore_armed_state===false){
            if(frequency_mhz>0){
                dialoqueFreqChangeArmed.initialize_and_show_frequency(frequency_mhz)
            }else{
                dialoqueFreqChangeArmed.initialize_and_show_channel_width(channel_width_mhz)
            }
            return;
        }
        var result=-100;
        if(change_frequency){
            result= _wbLinkSettingsHelper.change_param_air_and_ground_frequency(frequency_mhz);
        }else{
            result = _wbLinkSettingsHelper.change_param_air_and_ground_channel_width(channel_width_mhz);
        }
        if(result==0){
            var message="";
            if(change_frequency){
                message = "Succesfully set air and ground to FREQUENCY: "+frequency_mhz+"Mhz"
            }else{
                message = "Succesfully set air and ground to BANDWIDTH: "+channel_width_mhz+"Mhz"
            }
            _messageBoxInstance.set_text_and_show(message,5);
            return;
        }else if(result==-1){
            // Air unit rejected
            _messageBoxInstance.set_text_and_show("Air unit does not support this value",5);
            return;
        }else if(result==-2){
            // Couldn't reach air unit
            var error_message_not_alive="Couldn't reach air unit -"
            if(change_frequency){
                dialoqueFreqChangeGndOnly.initialize_and_show_frequency(frequency_mhz,error_message_not_alive);
            }else{
                dialoqueFreqChangeGndOnly.initialize_and_show_channel_width(channel_width_mhz,error_message_not_alive);
            }
            return;
        }
        // Really really bad
        _messageBoxInstance.set_text_and_show("Something went wrong - please use 'FIND AIR UNIT' to fix");
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
                            // 5.8G is generally recommended and much more commonly used than 2.4G. Default to it when unknown, just like openhd does
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
                                contentItem: Rectangle{
                                    color: "transparent"
                                    anchors.fill: parent
                                    anchors.margins: 6
                                    Rectangle{
                                        anchors.fill: parent
                                        color: "transparent"
                                        //border.color: "red"
                                    }
                                    RowLayout{
                                        width:parent.width
                                        height:parent.height
                                        Text {
                                            //anchors.fill: parent
                                            //anchors.centerIn: parent
                                            //Layout.fillHeight: true
                                            Layout.fillWidth: true
                                            text: title
                                            //color: "#21be2b"
                                            //color: comboBoxFreq.currentIndex === index ? "blue" : "black"
                                            color: get_combobox_text_color(comboBoxFreq.currentIndex,index,value)
                                            font: comboBoxFreq.font
                                            //elide: comboBoxFreq
                                            //verticalAlignment: Text.AlignVCenter
                                        }
                                        Text{
                                            text: get_text_pollution(pollution)
                                            color: get_color_pollution(pollution)
                                        }
                                        /*Text{
                                            text: "Y";
                                        }*/
                                    }
                                }
                                highlighted: comboBoxFreq.highlightedIndex === index
                            }
                            /*background: Rectangle {
                                visible: control.enabled && control.editable && !control.flat
                                border.width: parent && parent.activeFocus ? 2 : 1
                                border.color: parent && parent.activeFocus ? control.palette.highlight : control.palette.button
                                color: "green"
                            }*/
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
                                change_frequency_or_channel_width_sync_otherwise_handle_error(selectedValue,-1,false);
                            }
                            //Material.background: fc_is_armed() ? Material.Red : Material.Normal;
                            enabled: _wbLinkSettingsHelper.ui_rebuild_models>=0
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
                        ComboBox {
                            id: comboBoxChannelWidth
                            model: channel_width_model
                            textRole: "title"
                            implicitWidth:  elementComboBoxWidth
                        }
                        Button{
                            text: "APPLY BW"
                            id: buttonSwitchChannelWidth
                            enabled: _wbLinkSettingsHelper.ui_rebuild_models>=0
                            onClicked: {
                                // Ground needs to be alive and well
                                var selectedValue=channel_width_model.get(comboBoxChannelWidth.currentIndex).value
                                if(!(selectedValue===10 || selectedValue===20 || selectedValue===40 || selectedValue===80)){
                                    _messageBoxInstance.set_text_and_show("Please select a valid channel width",5);
                                    return;
                                }
                                change_frequency_or_channel_width_sync_otherwise_handle_error(-1,selectedValue,false);
                            }
                            //Material.background: fc_is_armed() ? Material.Red : Material.Normal;
                            //Material.background: Material.Light;
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
                            text: "GND TX PWR"
                            enabled: _ohdSystemGround.is_alive
                            onClicked: {
                                txPowerDialoque.open_tx_power_dialoque(true)
                            }
                        }
                        Button{
                            text: "AIR TX PWR"
                            enabled: _ohdSystemAir.is_alive
                            onClicked: {
                                txPowerDialoque.open_tx_power_dialoque(false)
                            }
                        }
                        ColumnLayout{
                            Layout.fillWidth: true
                            Text{
                                text: get_text_tx_power(true)
                            }
                            Text{
                                text: get_text_tx_power(false)
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
                            text: "Find Air unit"
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
            }
        }
    }
}
