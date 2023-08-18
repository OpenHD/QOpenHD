import QtQuick 2.0

import QtQuick 2.12
import QtQuick.Controls 2.12
import QtQuick.Layouts 1.12
import QtQuick.Dialogs 1.0
import QtQuick.Controls.Material 2.12

import Qt.labs.settings 1.0

import OpenHD 1.0

import "../../ui" as Ui
import "../elements"

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

    property bool m_has_fetched_channels : _synchronizedSettings.has_fetched_channels


    ListModel{
        id: supported_frequencies_model
        ListElement {title: "Unknown"; value:-1}
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
            supported_frequencies_model.append({title: text, value: frequency})
        }
        var index=find_index(supported_frequencies_model,_synchronizedSettings.curr_channel_mhz);
        comboBoxFreq.model=supported_frequencies_model
        if(index>=0){
            comboBoxFreq.currentIndex=index;
        }else{
            comboBoxFreq.currentIndex=0;
        }
    }

    function update_channel_width(){
        var index=find_index(channel_width_model,_synchronizedSettings.curr_channel_width_mhz);
        if(index>=0){
            comboBoxChannelWidth.currentIndex=index;
        }else{
            comboBoxChannelWidth.currentIndex=0;
        }
    }

    onM_has_fetched_channelsChanged: {
        // Create the channels model
        if(m_has_fetched_channels){
            console.log("Populating model");
            create_list_model_supported();
            update_channel_width()
        }
    }

    // Re-set the "disable sync" on init
    Component.onCompleted: {
        settings.qopenhd_allow_changing_ground_unit_channel_width_no_sync=false
        settings.qopenhd_allow_changing_ground_unit_frequency_no_sync=false
    }

    function get_text_current_loss_pollution(){
        if(!_ohdSystemAir.is_alive){
            return "No air unit";
        }
        var ret=("Curr Loss:"+_ohdSystemGround.curr_rx_packet_loss_perc+"%d"+" Pollution:"+_ohdSystemGround.wb_link_pollution+"%");
        var throttle=_ohdSystemAir.curr_n_rate_adjustments;
        if(throttle<=0){
            ret+=" Throttle:None"
        }else{
            ret+=" Throttle: -"+throttle;
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
                            text: get_text_current_loss_pollution()
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
                            /*delegate: ItemDelegate {
                                width: comboBoxFreq.width
                                contentItem: Rectangle{
                                    color: "transparent"
                                    anchors.fill: parent
                                    Rectangle{
                                        anchors.fill: parent
                                        color: "transparent"
                                        //border.color: "red"
                                    }
                                    Text {
                                        anchors.fill: parent
                                        text: title
                                        //color: "#21be2b"
                                        font: comboBoxFreq.font
                                        elide: Text.ElideLeft
                                        verticalAlignment: Text.AlignVCenter
                                    }

                                }
                                highlighted: comboBoxFreq.highlightedIndex === index
                            }*/
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
                                _synchronizedSettings.change_param_air_and_ground_frequency(selectedValue);
                            }
                            //Material.background: fc_is_armed() ? Material.Red : Material.Normal;
                            enabled: _synchronizedSettings.has_fetched_channels
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
                        Switch{
                            text: "allow gnd only"
                            checked: settings.qopenhd_allow_changing_ground_unit_frequency_no_sync
                            onCheckedChanged: {
                                if(settings.qopenhd_allow_changing_ground_unit_frequency_no_sync != checked && checked){
                                    _messageBoxInstance.set_text_and_show(m_text_warning_nosync_frequency,10)
                                }
                                settings.qopenhd_allow_changing_ground_unit_frequency_no_sync = checked
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
                            enabled: false
                            onClicked: {
                                if(_fcMavlinkSystem.is_alive && _fcMavlinkSystem.armed && (!settings.dev_allow_freq_change_when_armed)){
                                    var text="Cannot change channel width while FC is armed."
                                    _messageBoxInstance.set_text_and_show(text,5);
                                    return;
                                }
                                var selectedValue=channel_width_model.get(comboBoxChannelWidth.currentIndex).value
                                if(!(selectedValue===10 || selectedValue===20 || selectedValue===40 || selectedValue===80)){
                                    _messageBoxInstance.set_text_and_show("Please select a valid channel width",5);
                                    return;
                                }
                                _synchronizedSettings.change_param_air_and_ground_channel_width(selectedValue)
                            }
                            //Material.background: fc_is_armed() ? Material.Red : Material.Normal;
                            //Material.background: Material.Light;
                        }
                        Button{
                            text: "INFO"
                            Material.background:Material.LightBlue
                            onClicked: {
                                var text="Only supported on rtl8812au!\nA channel width of 40Mhz gives almost double the bandwidth, but uses 2x 20Mhz channels and therefore the likeliness of "+
"interference from other stations sending on either of those channels is increased. It also slightly decreases sensitivity. Only changeable on rtl8812au."
                                _messageBoxInstance.set_text_and_show(text)
                            }
                        }
                        Switch{
                            text: "allow gnd only"
                            checked: settings.qopenhd_allow_changing_ground_unit_channel_width_no_sync
                            onCheckedChanged: {
                                if(settings.qopenhd_allow_changing_ground_unit_channel_width_no_sync != checked && checked){
                                    _messageBoxInstance.set_text_and_show(m_text_warning_nosync_chanel_width,10)
                                }
                                settings.qopenhd_allow_changing_ground_unit_channel_width_no_sync = checked
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
                                _synchronizedSettings.start_analyze_channels()
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
