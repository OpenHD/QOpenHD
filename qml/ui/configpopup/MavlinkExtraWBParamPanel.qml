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

    ScrollView {
        id:mavlinkExtraWBParamPanel
        width: parent.width
        height: parent.height
        contentHeight: wbParamColumn.height
        clip: true

        Item {
            anchors.fill: parent

            Column {
                id:wbParamColumn
                spacing: 0
                anchors.left: parent.left
                anchors.right: parent.right

                // Dirty, for the 3 mavlink settings that need to be kept in sync on both air and ground

                // NOTE: WHile it would be possible to do the 2.4G frequencie(s) in 5Mhz increments (and OpenHD accepts those values)
                // We do not expose them here, since it incredibly pollutes the UI and gives the user the false perception of there being a lot of 2.4G Channels
                // (Even though they overlap, and therefore are not really usable
                ListModel{
                    id: frequenciesModel
                    ListElement {title: "2312Mhz [X] (Atheros)"; value: 2312}
                    //ListElement {title: "2317Mhz [X] (Atheros)"; value: 2317}
                    //ListElement {title: "2322Mhz [X] (Atheros)"; value: 2322}
                    //ListElement {title: "2327Mhz [X] (Atheros)"; value: 2327}
                    ListElement {title: "2332Mhz [X] (Atheros)"; value: 2332}
                    //ListElement {title: "2337Mhz [X] (Atheros)"; value: 2337}
                    //ListElement {title: "2342Mhz [X] (Atheros)"; value: 2342}
                    //ListElement {title: "2347Mhz [X] (Atheros)"; value: 2347}
                    ListElement {title: "2352Mhz [X] (Atheros)"; value: 2352}
                    //ListElement {title: "2357Mhz [X] (Atheros)"; value: 2357}
                    //ListElement {title: "2362Mhz [X] (Atheros)"; value: 2362}
                    //ListElement {title: "2367Mhz [X] (Atheros)"; value: 2367}
                    ListElement {title: "2372Mhz [X] (Atheros)"; value: 2372}
                    //ListElement {title: "2377Mhz [X] (Atheros)"; value: 2377}
                    //ListElement {title: "2382Mhz [X] (Atheros)"; value: 2382}
                    //ListElement {title: "2387Mhz [X] (Atheros)"; value: 2387}
                    ListElement {title: "2392Mhz [X] (Atheros)"; value: 2392}
                    //ListElement {title: "2397Mhz [X] (Atheros)"; value: 2397}
                    //ListElement {title: "2402Mhz [X] (Atheros)"; value: 2402}
                    //ListElement {title: "2407Mhz [X] (Atheros)"; value: 2407}
                    ListElement {title: "2412Mhz [1] (Ralink/Atheros)"; value: 2412}
                    ListElement {title: "2417Mhz [2]  (Ralink/Atheros)"; value: 2417}
                    ListElement {title: "2422Mhz [3]  (Ralink/Atheros)"; value: 2422}
                    ListElement {title: "2427Mhz [4]  (Ralink/Atheros)"; value: 2427}
                    ListElement {title: "2432Mhz [5]  (Ralink/Atheros)"; value: 2432}
                    ListElement {title: "2437Mhz [6]  (Ralink/Atheros)"; value: 2437}
                    ListElement {title: "2442Mhz [7]  (Ralink/Atheros)"; value: 2442}
                    ListElement {title: "2447Mhz [8]  (Ralink/Atheros)"; value: 2447}
                    ListElement {title: "2452Mhz [9]  (Ralink/Atheros)"; value: 2452}
                    ListElement {title: "2457Mhz [10](Ralink/Atheros)"; value: 2457}
                    ListElement {title: "2462Mhz [11](Ralink/Atheros)"; value: 2462}
                    ListElement {title: "2467Mhz [12](Ralink/Atheros)"; value: 2467}
                    ListElement {title: "2472Mhz [13](Ralink/Atheros)"; value: 2472}
                    ListElement {title: "2484Mhz [14](Ralink/Atheros)"; value: 2484}
                    //ListElement {title: "2477Mhz [X] (Atheros)"; value: 2477}
                    //ListElement {title: "2482Mhz [X] (Atheros)"; value: 2482}
                    //ListElement {title: "2487Mhz [X] (Atheros)"; value: 2487}
                    //ListElement {title: "2489Mhz [X] (Atheros)"; value: 2489}
                    ListElement {title: "2492Mhz [X] (Atheros)"; value: 2492}
                    //ListElement {title: "2494Mhz [X] (Atheros)"; value: 2494}
                    //ListElement {title: "2497Mhz [X] (Atheros)"; value: 2497}
                    //ListElement {title: "2499Mhz [X] (Atheros)"; value: 2499}
                    ListElement {title: "2512Mhz [X] (Atheros)"; value: 2512}
                    ListElement {title: "2532Mhz [X] (Atheros)"; value: 2532}
                    ListElement {title: "2572Mhz [X] (Atheros)"; value: 2572}
                    ListElement {title: "2592Mhz [X] (Atheros)"; value: 2592}
                    ListElement {title: "2612Mhz [X] (Atheros)"; value: 2612}
                    ListElement {title: "2632Mhz [X] (Atheros)"; value: 2632}
                    ListElement {title: "2652Mhz [X] (Atheros)"; value: 2652}
                    ListElement {title: "2672Mhz [X] (Atheros)"; value: 2672}
                    ListElement {title: "2692Mhz [X] (Atheros)"; value: 2692}
                    ListElement {title: "2712Mhz [X] (Atheros)"; value: 2712}
                    // 5G begin
                    ListElement {title: "5180Mhz [36] (DEFAULT)"; value: 5180}
                    ListElement {title: "5200Mhz [40]"; value: 5200}
                    ListElement {title: "5220Mhz [44]"; value: 5220}
                    ListElement {title: "5240Mhz [48]"; value: 5240}
                    ListElement {title: "5260Mhz [52]  (DFS RADAR)"; value: 5260}
                    ListElement {title: "5280Mhz [56]  (DFS RADAR)"; value: 5280}
                    ListElement {title: "5300Mhz [60]  (DFS RADAR)"; value: 5300}
                    ListElement {title: "5320Mhz [64]  (DFS RADAR)"; value: 5320}
                    ListElement {title: "5500Mhz [100] (DFS RADAR)"; value: 5500}
                    ListElement {title: "5520Mhz [104] (DFS RADAR)"; value: 5520}
                    ListElement {title: "5540Mhz [108] (DFS RADAR)"; value: 5540}
                    ListElement {title: "5560Mhz [112] (DFS RADAR)"; value: 5560}
                    ListElement {title: "5580Mhz [116] (DFS RADAR)"; value: 5580}
                    ListElement {title: "5600Mhz [120] (DFS RADAR)"; value: 5600}
                    ListElement {title: "5620Mhz [124] (DFS RADAR)"; value: 5620}
                    ListElement {title: "5640Mhz [128] (DFS RADAR)"; value: 5640}
                    ListElement {title: "5660Mhz [132] (DFS RADAR)"; value: 5660}
                    ListElement {title: "5680Mhz [136] (DFS RADAR)"; value: 5680}
                    ListElement {title: "5700Mhz [140] (DFS RADAR)"; value: 5700}
                    ListElement {title: "5745Mhz [149]"; value: 5745}
                    ListElement {title: "5765Mhz [153]"; value: 5765}
                    ListElement {title: "5785Mhz [157]"; value: 5785}
                    ListElement {title: "5805Mhz [161]"; value: 5805}
                    ListElement {title: "5825Mhz [165]"; value: 5825}
                    // These require patched kernel !
                    ListElement {title: "5845Mhz [169]"; value: 5845}
                    ListElement {title: "5865Mhz [173]"; value: 5865}
                    ListElement {title: "5885Mhz [177]"; value: 5885}
                    //ListElement {title: "5905Mhz [181]"; value: 5905}
                }

                ListModel{
                    id: mcsIndexModel
                    ListElement {title: "~4.5 Mbps  (MCS0)"; value: 0}
                    ListElement {title: "~6.5 Mbps  (MCS1)"; value: 1}
                    ListElement {title: "~8.5 Mbps (long range) (MCS2)"; value: 2}
                    ListElement {title: "~12  Mbps (default) (MCS3)"; value: 3}
                    ListElement {title: "~17  Mbps (EXP)(MCS4)"; value: 4}
                    ListElement {title: "~20+ Mbps (EXP) (MCS5)"; value: 5}
                    ListElement {title: "~20+ Mbps (EXP) (MCS6)"; value: 6}
                    ListElement {title: "~20+ Mbps (EXP) (MCS7)"; value: 7}
                }

                ListModel{
                    id: channelWidthModel
                    ListElement {title: "20MHz (default)"; value: 20}
                    ListElement {title: "40MHz (experimental)"; value: 40}
                }

                Rectangle {
                    width: parent.width
                    height: rowHeight
                    color: (Positioner.index % 2 == 0) ? "#8cbfd7f3" : "#00000000"

                    RowLayout{
                        anchors.verticalCenter: parent.verticalCenter
                        Button{
                            text: "Find Air unit"
                            enabled: _ohdSystemGround.is_alive
                            onClicked: {
                                dialoqueStartChannelScan.m_curr_index=0
                                dialoqueStartChannelScan.visible=true
                            }
                        }
                        Button{
                            text: "INFO"
                            Material.background:Material.LightBlue
                            onClicked: {
                                var text="Scan all channels for a running Air unit. Might take up to 30seconds to complete (openhd supports a ton of channels, and we need to listen on each of them for a short timespan)"
                                _messageBoxInstance.set_text_and_show(text)
                            }
                        }
                    }
                }

                // Changing the wifi frequency, r.n only 5G
                Rectangle {
                    width: parent.width
                    height: rowHeight
                    color: (Positioner.index % 2 == 0) ? "#8cbfd7f3" : "#00000000"

                    RowLayout{
                        anchors.verticalCenter: parent.verticalCenter
                        Button{
                            text: "Fetch"
                            onClicked: {
                                var _res=_synchronizedSettings.get_param_int_air_and_ground_value_freq()
                                if(_res>=0){
                                    buttonSwitchFreq.enabled=true
                                }
                                //console.log("Got ",_res)
                                update_combobox(comboBoxFreq,_res);
                            }
                        }
                        ComboBox {
                            id: comboBoxFreq
                            model: frequenciesModel
                            textRole: "title"
                            implicitWidth:  elementComboBoxWidth
                            // 5.8G is generally recommended and much more commonly used than 2.4G. Default to it when unknown, just like openhd does
                            currentIndex: 30
                        }
                        Button{
                            text: "Switch Frequency"
                            id: buttonSwitchFreq
                            enabled: false
                            onClicked: {
                                if(_fcMavlinkSystem.is_alive && _fcMavlinkSystem.armed && (!settings.dev_allow_freq_change_when_armed)){
                                    var text="Cannot change frequency while FC is armed. MCS index can be changed though.";
                                    _messageBoxInstance.set_text_and_show(text);
                                    return;
                                }
                                var selectedValue=frequenciesModel.get(comboBoxFreq.currentIndex).value
                                _synchronizedSettings.change_param_air_and_ground_frequency(selectedValue);
                            }
                            //Material.background: fc_is_armed() ? Material.Red : Material.Normal;
                        }
                        Button{
                            text: "INFO"
                            Material.background:Material.LightBlue
                            onClicked: {
                                var text="Frequency in Mhz and channel number. [X] - Not a legal wifi frequency, AR9271 does them anyways. (DFS-RADAR) - also used by commercial plane(s) weather radar. "+
"It is your responsibility to only change the frequency to values allowed in your country. You can use a frequency analyzer on your phone or the packet loss to find the best channel for your environemnt."
                                _messageBoxInstance.set_text_and_show(text)
                            }
                        }
                    }
                }
                Rectangle {
                    width: parent.width
                    height: rowHeight
                    color: (Positioner.index % 2 == 0) ? "#8cbfd7f3" : "#00000000"

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
                            model: channelWidthModel
                            textRole: "title"
                            implicitWidth:  elementComboBoxWidth
                        }
                        Button{
                            text: "Change Channel Width"
                            id: buttonSwitchChannelWidth
                            enabled: false
                            onClicked: {
                                if(_fcMavlinkSystem.is_alive && _fcMavlinkSystem.armed && (!settings.dev_allow_freq_change_when_armed)){
                                    var text="Cannot change channel width while FC is armed. MCS index can be changed though."
                                    _messageBoxInstance.set_text_and_show(text);
                                    return;
                                }
                                var selectedValue=channelWidthModel.get(comboBoxChannelWidth.currentIndex).value
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
                    }
                }
                Rectangle {
                    width: parent.width
                    height: rowHeight
                    color: (Positioner.index % 2 == 0) ? "#8cbfd7f3" : "#00000000"

                    RowLayout{
                        anchors.verticalCenter: parent.verticalCenter
                        Button{
                            text: "Fetch"
                            onClicked: {
                                //var _res=_synchronizedSettings.get_param_int_air_and_ground_value_mcs()
                                var _res=_synchronizedSettings.get_param_int_air_only_mcs()
                                if(_res>=0){
                                    buttonSwitchMCS.enabled=true
                                }
                                //console.log("Got ",_res)
                                update_combobox(comboBoxMcsIndex,_res);
                            }
                        }
                        ComboBox {
                            id: comboBoxMcsIndex
                            model: mcsIndexModel
                            textRole: "title"
                            implicitWidth:  elementComboBoxWidth
                            // openhd defaults to MCS 3
                            currentIndex: 3
                        }
                        Button{
                            text: "Change MCS"
                            id: buttonSwitchMCS
                            enabled: false
                            onClicked: {
                                var selectedValue=mcsIndexModel.get(comboBoxMcsIndex.currentIndex).value
                                //_synchronizedSettings.change_param_air_and_ground_mcs(selectedValue)
                                _synchronizedSettings.change_param_air_only_mcs(selectedValue,false)
                            }
                            //Material.foreground: fc_is_armed() ? Material.Green : Material.Dark;
                        }
                        Button{
                            text: "INFO"
                            Material.background:Material.LightBlue
                            onClicked: {
                                var text="Only supported on rtl8812au!\nThe MCS index controlls the available bandwidth. Higher MCS index - higher bandwidth, but less sensitivity/range."+
                                        "In contrast to the frequency / channel width, this param only needs to be set on the air unit. As long as your camera supports variable bitrate,"+
                                        "you can even safely change this param without adjusting the camera bitrate / during flight."
                                _messageBoxInstance.set_text_and_show(text)
                            }
                        }
                    }
                }
                Text{
                    width: parent.width
                    elide: Text.ElideLeft
                    wrapMode: Text.WordWrap
                    text:{
                        "Changing the frequency / channel width requires synchronisation between your air and ground unit. It can fail and is therefore only safe to change in disarmed state. "+
                        "You can use the channel scan feature to recover a failed synchronisation.\n"+
                        "Changing the MCS index only requires changing the value on the air unit, and is therefore safe to do during flight - as long as your camera supports variable bitrate."
                    }
                }
            }
        }
    }
}
