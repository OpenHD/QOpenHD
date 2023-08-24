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
            var frequency=_synchronizedSettings.get_next_supported_frequency(i);
            if(frequency<=0)break; // no more supported frequences
            var text=_synchronizedSettings.get_frequency_description(frequency)
            var v_pollution= _synchronizedSettings.get_frequency_pollution(frequency)
            supported_frequencies_model.append({title: text, value: frequency, pollution: v_pollution })
        }
        var index=find_index(supported_frequencies_model,_synchronizedSettings.curr_channel_mhz);
        comboBoxFreq.model=supported_frequencies_model
        if(index>=0){
            comboBoxFreq.currentIndex=index;
        }else{
            comboBoxFreq.currentIndex=0;
            console.log("Seems not to be a valid channel "+_synchronizedSettings.curr_channel_mhz)
        }
    }

    function update_channel_width(){
        var index=find_index(channel_width_model,_synchronizedSettings.curr_channel_width_mhz);
        if(index>=0){
            comboBoxChannelWidth.currentIndex=index;
        }else{
            comboBoxChannelWidth.currentIndex=0;
            console.log("Seems not to be a valid channel width"+_synchronizedSettings.curr_channel_width_mhz)
        }
    }

    // We get notified every time we should re-build the model(s) and their current selection
    property int m_ui_rebuild_models : _synchronizedSettings.ui_rebuild_models
    onM_ui_rebuild_modelsChanged: {
        console.log("Rebuilding models "+_synchronizedSettings.ui_rebuild_models);
        create_list_model_supported();
        update_channel_width()
    }

    // Re-set the "disable sync" on init
    Component.onCompleted: {

    }

    // ------------------- PART HELPER FOR CURRENT LOSS / POLLUTION / THROTTLE BEGIN -------------------
    property bool m_is_ground_and_air_alive: _ohdSystemGround.is_alive && _ohdSystemAir.is_alive
    function get_text_current_loss(){
        if(!_ohdSystemGround.is_alive){
            return "No Ground unit - Is OpenHD core running ?"
        }
        if(!_ohdSystemAir.is_alive){
            return "No air unit";
        }
        return "Curr Loss:"+_ohdSystemGround.curr_rx_packet_loss_perc+"%";
    }
    function get_color_current_loss(){
        var curr_rx_packet_loss_perc=_ohdSystemGround.curr_rx_packet_loss_perc;
        if(curr_rx_packet_loss_perc>=10)return "red";
        if(curr_rx_packet_loss_perc>=6)return "orange";
        return "black";
    }
    function get_text_current_pollution(){
        if(!m_is_ground_and_air_alive){
            return "";
        }
        var wb_link_pollution=_ohdSystemGround.wb_link_pollution;
        return "Pollution:"+wb_link_pollution+" %";
    }
    function get_color_current_pollution(){
        var wb_link_pollution=_ohdSystemGround.wb_link_pollution;
        if(wb_link_pollution>=8)return "red";
        if(wb_link_pollution>=3)return "orange";
        return "black";
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
    function get_color_current_throttle(){
        var throttle=_ohdSystemAir.curr_n_rate_adjustments;
        if(throttle>=3)return "red"
        if(throttle>=1)return "orange"
        return "black";
    }
    // ------------------- PART HELPER FOR CURRENT LOSS / POLLUTION / THROTTLE END -------------------


    function get_combobox_text_color(element_index,curr_index,frequency){
        if(frequency===_synchronizedSettings.curr_channel_mhz){
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


    property string more_info_text: "After flashing,openhd uses the same default frequency, and your air and ground unit automatically connect."+
    "If you change the frequency / channel width here, both air and ground unit are set to the new frequency."+
"If you changed the frequency of your air unit and are using a different Ground unit, use the FIND AIR UNIT feature (channel scan) to switch to the same frequency your air unit is running on."

    property string find_air_unit_text:"Scan all channels for a running Air unit. Might take up to 30seconds to complete (openhd supports a ton of channels, and we need to listen on each of them for a short timespan)"

    property string analyze_channels_text: "Analyze channels text"


    ScrollView {
        id:mavlinkExtraWBParamPanel
        width: parent.width
        height: parent.height
        contentHeight: wbParamColumn.height
        clip: true

        Item {
            anchors.fill: parent

            ChannelScanDialoque{
                id: dialoqueStartChannelScan
            }
            FrequencyChangeDialoque{
                id: dialoqueChangeFrequency
            }

            DialoqueAnalyzeChannels{
                id: dialoqueAnalyzeChannels
            }

            TxPowerDialoque{
                id: txPowerDialoque
            }

            Column {
                id:wbParamColumn
                spacing: 0
                anchors.left: parent.left
                anchors.right: parent.right

                Text{
                    width: parent.width
                    height: rowHeight / 2
                    elide: Text.ElideLeft
                    wrapMode: Text.WordWrap
                    horizontalAlignment: Text.AlignHCenter
                    verticalAlignment: Text.AlignVCenter
                    text:{
                        "NOTE: Frequency and channel width of air and ground unit BOTH need to match."
                    }
                }
                Rectangle {
                    width: parent.width
                    height: rowHeight
                    color: (Positioner.index % 2 == 0) ? "#8cbfd7f3" : "#00000000"
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
                            color: get_color_current_loss()
                        }
                        Text{
                            text: get_text_current_pollution()
                            color: get_color_current_pollution()
                        }
                        Text{
                            text: get_text_current_throttle()
                            color: get_color_current_throttle()
                        }
                        Item{ // padding
                            width: 20
                        }
                        ColumnLayout{
                            Text{
                                text: get_text_tx_power(true)
                            }
                            Text{
                                text: get_text_tx_power(false)
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
                        Button{
                            text: "Fetch"
                            onClicked: {
                                /*var _res=_synchronizedSettings.get_param_int_air_and_ground_value_freq()
                                if(_res>=0){
                                    buttonSwitchFreq.enabled=true
                                }
                                //console.log("Got ",_res)
                                update_combobox(comboBoxFreq,_res);*/
                                create_list_model_supported();
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
                            text: "Switch Frequency"
                            id: buttonSwitchFreq
                            //enabled: false
                            onClicked: {
                                // Ground needs to be alive and well
                                if(!_ohdSystemGround.is_alive){
                                    _messageBoxInstance.set_text_and_show("Ground unit not alive",5);
                                    return;
                                }
                                // FC needs to be disarmed (unless disabled)
                                if(_fcMavlinkSystem.is_alive && _fcMavlinkSystem.armed && (!settings.dev_allow_freq_change_when_armed)){
                                    var text="Cannot change frequency while FC is armed.";
                                    _messageBoxInstance.set_text_and_show(text,5);
                                    return;
                                }
                                var selectedValue=supported_frequencies_model.get(comboBoxFreq.currentIndex).value
                                if(selectedValue<=100){
                                    _messageBoxInstance.set_text_and_show("Please select a valid frequency",5);
                                    return;
                                }
                                var result=_synchronizedSettings.change_param_air_and_ground_frequency(selectedValue);
                                if(result){
                                    _messageBoxInstance.set_text_and_show("Succesfully set air and ground to "+selectedValue+"Mhz",5);
                                }else{
                                    dialoqueChangeFrequency.initialize_and_show_frequency(selectedValue);
                                }
                            }
                            //Material.background: fc_is_armed() ? Material.Red : Material.Normal;
                            enabled: _synchronizedSettings.ui_rebuild_models>=0
                        }
                        Button{
                            text: "INFO"
                            Material.background:Material.LightBlue
                            onClicked: {
                                var text="Frequency in Mhz and channel number. (DFS-RADAR) - also used by commercial plane(s) weather radar (most likely illegal). "+
                                        "[X] - Not a legal wifi frequency, AR9271 does them anyways."+
"It is your responsibility to only change the frequency to values allowed in your country. You can use a frequency analyzer on your phone or the packet loss to find the best channel for your environemnt."
                                _messageBoxInstance.set_text_and_show(text)
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
                        Button{
                            text: "Fetch"
                            onClicked: {
                                var _res=_synchronizedSettings.get_param_int_air_and_ground_value_channel_width()
                                if(_res>=0){
                                    buttonSwitchChannelWidth.enabled=true
                                }
                                //console.log("Got ",_res)
                                update_combobox(comboBoxChannelWidth,_res);
                            }
                        }
                        ComboBox {
                            id: comboBoxChannelWidth
                            model: channel_width_model
                            textRole: "title"
                            implicitWidth:  elementComboBoxWidth
                        }
                        Button{
                            text: "Change Channel Width"
                            id: buttonSwitchChannelWidth
                            enabled: _synchronizedSettings.ui_rebuild_models>=0
                            onClicked: {
                                // Ground needs to be alive and well
                                if(!_ohdSystemGround.is_alive){
                                    _messageBoxInstance.set_text_and_show("Ground unit not alive",5);
                                    return;
                                }
                                // FC needs to be disarmed (unless disabled)
                                if(_fcMavlinkSystem.is_alive && _fcMavlinkSystem.armed && (!settings.dev_allow_freq_change_when_armed)){
                                    var text="Cannot change channel width while FC is armed.";
                                    _messageBoxInstance.set_text_and_show(text,5);
                                    return;
                                }
                                var selectedValue=channel_width_model.get(comboBoxChannelWidth.currentIndex).value
                                if(!(selectedValue===10 || selectedValue===20 || selectedValue===40 || selectedValue===80)){
                                    _messageBoxInstance.set_text_and_show("Please select a valid channel width",5);
                                    return;
                                }
                                var result=_synchronizedSettings.change_param_air_and_ground_channel_width(selectedValue);
                                if(result){
                                    _messageBoxInstance.set_text_and_show("Succesfully set air and ground to "+selectedValue+"Mhz",5);
                                }else{
                                    dialoqueChangeFrequency.initialize_and_show_channel_width(selectedValue);
                                }
                            }
                            //Material.background: fc_is_armed() ? Material.Red : Material.Normal;
                            //Material.background: Material.Light;
                        }
                        Button{
                            text: "INFO"
                            Material.background:Material.LightBlue
                            onClicked: {
                                var text="A channel width of 40Mhz gives almost double the bandwidth, but uses 2x 20Mhz channels and therefore the likeliness of "+
"interference from other stations sending on either of those channels is increased. It also slightly decreases sensitivity. Only supported on rtl8812au/bu on air."
                                _messageBoxInstance.set_text_and_show(text)
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
                        Layout.preferredWidth: 200
                        height: parent.height
                        IconInfoButon{
                            onClicked: {
                                _messageBoxInstance.set_text_and_show("Change GND / AIR TX power. Higher Air TX power results in more range on the downlink (video,telemetry).
Higher GND TX power results in more range on the uplink (mavlink up). You can set different tx power for armed / disarmed state (requres FC),
but it is not possible to change the TX power during flight (due to the risk of misconfiguration / power outage).")
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
                        IconInfoButon{
                            onClicked: {
                                _messageBoxInstance.set_text_and_show(find_air_unit_text)
                            }
                        }
                        Button{
                            text: "Find Air unit"
                            enabled: _ohdSystemGround.is_alive
                            onClicked: {
                                dialoqueStartChannelScan.m_curr_index=0
                                dialoqueStartChannelScan.visible=true
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
                            value: _synchronizedSettings.progress_scan_channels_perc
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
                        IconInfoButon{
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
                            value: _synchronizedSettings.progress_analyze_channels_perc
                        }
                    }
                }
                Rectangle {
                    width: parent.width
                    height: rowHeight
                    Text{
                        text: _synchronizedSettings.text_for_qml
                    }
                }
            }
        }
    }
}
