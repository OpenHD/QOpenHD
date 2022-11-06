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
ColumnLayout {
    Layout.fillHeight: true
    Layout.fillWidth: true

    //width: parent.width
    //height: 600

    property int rowHeight: 64
    property int elementHeight: 48
    property int elementComboBoxWidth: 250

    ListModel{
        id: frequenciesModel
        ListElement {title: "2312 (Atheros)"; value: 2312}
        ListElement {title: "2317 (Atheros)"; value: 2317}
        ListElement {title: "2322 (Atheros)"; value: 2322}
        ListElement {title: "2327 (Atheros)"; value: 2327}
        ListElement {title: "2332 (Atheros)"; value: 2332}
        ListElement {title: "2337 (Atheros)"; value: 2337}
        ListElement {title: "2342 (Atheros)"; value: 2342}
        ListElement {title: "2347 (Atheros)"; value: 2347}
        ListElement {title: "2352 (Atheros)"; value: 2352}
        ListElement {title: "2357 (Atheros)"; value: 2357}
        ListElement {title: "2362 (Atheros)"; value: 2362}
        ListElement {title: "2367 (Atheros)"; value: 2367}
        ListElement {title: "2372 (Atheros)"; value: 2372}
        ListElement {title: "2377 (Atheros)"; value: 2377}
        ListElement {title: "2382 (Atheros)"; value: 2382}
        ListElement {title: "2387 (Atheros)"; value: 2387}
        ListElement {title: "2392 (Atheros)"; value: 2392}
        ListElement {title: "2397 (Atheros)"; value: 2397}
        ListElement {title: "2402 (Atheros)"; value: 2402}
        ListElement {title: "2407 (Atheros)"; value: 2407}
        ListElement {title: "1  2412 (Ralink/Atheros)"; value: 2412}
        ListElement {title: "2  2417 (Ralink/Atheros)"; value: 2417}
        ListElement {title: "3  2422 (Ralink/Atheros)"; value: 2422}
        ListElement {title: "4  2427 (Ralink/Atheros)"; value: 2427}
        ListElement {title: "5  2432 (Ralink/Atheros)"; value: 2432}
        ListElement {title: "6  2437 (Ralink/Atheros)"; value: 2437}
        ListElement {title: "7  2442 (Ralink/Atheros)"; value: 2442}
        ListElement {title: "8  2447 (Ralink/Atheros)"; value: 2447}
        ListElement {title: "9  2452 (Ralink/Atheros)"; value: 2452}
        ListElement {title: "10 2457 (Ralink/Atheros)"; value: 2457}
        ListElement {title: "11 2462 (Ralink/Atheros)"; value: 2462}
        ListElement {title: "12 2467 (Ralink/Atheros)"; value: 2467}
        ListElement {title: "13 2472 (Ralink/Atheros)"; value: 2472}
        ListElement {title: "14 2484 (Ralink/Atheros)"; value: 2484}
        ListElement {title: "2477 (Atheros)"; value: 2477}
        ListElement {title: "2482 (Atheros)"; value: 2482}
        ListElement {title: "2487 (Atheros)"; value: 2487}
        ListElement {title: "2489 (Atheros)"; value: 2489}
        ListElement {title: "2492 (Atheros)"; value: 2492}
        ListElement {title: "2494 (Atheros)"; value: 2494}
        ListElement {title: "2497 (Atheros)"; value: 2497}
        ListElement {title: "2499 (Atheros)"; value: 2499}
        ListElement {title: "2512 (Atheros)"; value: 2512}
        ListElement {title: "2532 (Atheros)"; value: 2532}
        ListElement {title: "2572 (Atheros)"; value: 2572}
        ListElement {title: "2592 (Atheros)"; value: 2592}
        ListElement {title: "2612 (Atheros)"; value: 2612}
        ListElement {title: "2632 (Atheros)"; value: 2632}
        ListElement {title: "2652 (Atheros)"; value: 2652}
        ListElement {title: "2672 (Atheros)"; value: 2672}
        ListElement {title: "2692 (Atheros)"; value: 2692}
        ListElement {title: "2712 (Atheros)"; value: 2712}
        // 5G begin
        ListElement {title: "36  5180"; value: 5180}
        ListElement {title: "40  5200"; value: 5200}
        ListElement {title: "44  5220"; value: 5220}
        ListElement {title: "48  5240"; value: 5240}
        ListElement {title: "52  5260 (DFS RADAR)"; value: 5260}
        ListElement {title: "56  5280 (DFS RADAR)"; value: 5280}
        ListElement {title: "60  5300 (DFS RADAR)"; value: 5300}
        ListElement {title: "64  5320 (DFS RADAR)"; value: 5320}
        ListElement {title: "100 5500 (DFS RADAR)"; value: 5500}
        ListElement {title: "104 5520 (DFS RADAR)"; value: 5520}
        ListElement {title: "108 5540 (DFS RADAR)"; value: 5540}
        ListElement {title: "112 5560 (DFS RADAR)"; value: 5560}
        ListElement {title: "116 5580 (DFS RADAR)"; value: 5580}
        ListElement {title: "120 5600 (DFS RADAR)"; value: 5600}
        ListElement {title: "124 5620 (DFS RADAR)"; value: 5620}
        ListElement {title: "128 5640 (DFS RADAR)"; value: 5640}
        ListElement {title: "132 5660 (DFS RADAR)"; value: 5660}
        ListElement {title: "136 5680 (DFS RADAR)"; value: 5680}
        ListElement {title: "140 5700 (DFS RADAR)"; value: 5700}
        ListElement {title: "149 5745"; value: 5745}
        ListElement {title: "153 5765"; value: 5765}
        ListElement {title: "157 5785"; value: 5785}
        ListElement {title: "161 5805"; value: 5805}
        ListElement {title: "165 5825"; value: 5825}
    }

    ListModel{
        id: mcsIndexModel
        ListElement {title: "5.5Mbps/6.5Mbps(MCS1)"; value: 1}
        ListElement {title: "11Mbps/13Mbps  (MCS2)"; value: 2}
        ListElement {title: "12Mbps/13Mbps  (MCS3)"; value: 3}
        ListElement {title: "19.5Mbps       (MCS4)"; value: 4}
        ListElement {title: "24Mbps/26Mbps  (MCS5)"; value: 5}
        ListElement {title: "36Mbps/39Mbps  (MCS6)"; value: 6}
    }

    ListModel{
        id: channelWidthModel
         //ListElement {title: "5MHz"; value: 10}
         //ListElement {title: "10MHz"; value: 20}
         ListElement {title: "20MHz"; value: 20}
         ListElement {title: "40MHz (5G Atheros only,unsafe)"; value: 40}
    }

    // https://stackoverflow.com/questions/41991438/how-do-i-find-a-particular-listelement-inside-a-listmodel-in-qml
    //function find(model, criteria) {
    //  for(var i = 0; i < model.count; ++i) if (criteria(model.get(i))) return model.get(i)
    //  return null
    //}
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

    // Changing the wifi frequency, r.n only 5G
    RowLayout{
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
            Layout.minimumWidth : elementComboBoxWidth
            model: frequenciesModel
            textRole: "title"
        }
        Button{
            text: "Switch Frequency"
            id: buttonSwitchFreq
            enabled: false
            onClicked: {
                var selectedValue=frequenciesModel.get(comboBoxFreq.currentIndex).value
                _synchronizedSettings.change_param_air_and_ground_frequency(selectedValue);
            }
        }
    }

    RowLayout{
        Button{
            text: "Fetch"
            onClicked: {
                var _res=_synchronizedSettings.get_param_int_air_and_ground_value_mcs()
                if(_res>=0){
                    buttonSwitchMCS.enabled=true
                }
                //console.log("Got ",_res)
                update_combobox(comboBoxMcsIndex,_res);
            }
        }
        ComboBox {
            id: comboBoxMcsIndex
            Layout.minimumWidth : elementComboBoxWidth
            model: mcsIndexModel
            textRole: "title"
        }
        Button{
            text: "Change MCS"
            id: buttonSwitchMCS
            enabled: false
            onClicked: {
                 var selectedValue=mcsIndexModel.get(comboBoxMcsIndex.currentIndex).value
                _synchronizedSettings.change_param_air_and_ground_mcs(selectedValue)
            }
        }
    }

    RowLayout{
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
            Layout.minimumWidth : elementComboBoxWidth
            model: channelWidthModel
            textRole: "title"
        }
        Button{
            text: "Change Channel Width"
            id: buttonSwitchChannelWidth
            enabled: false
            onClicked: {
                 var selectedValue=channelWidthModel.get(comboBoxChannelWidth.currentIndex).value
                _synchronizedSettings.change_param_air_and_ground_channel_width(selectedValue)
            }
        }
    }
    Button{
        text: "SOFT RESTART"
        id: softRestartButton
        onClicked:{
            _synchronizedSettings.soft_restart()
        }
    }
    Text{
        text:
"To change these parameters, make sure your ground and air unit are alive and well.\nAlso, it is not recommended to change them during flight.
To apply a change, you need to click either soft restart or power cycle your air and ground unit manually"
    }

}
