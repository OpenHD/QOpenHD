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

Rectangle{
    width: parent.width
    height: parent.height /2
    anchors.bottom: parent.bottom
    anchors.left: parent.left
    color: "#8cbfd7f3"

    function open(){
        visible=true
        enabled=true
    }

    function close(){
        visible=false;
        enabled=false;
    }

    ListModel{
        id: model_chann_to_scan
        ListElement {title: "OpenHD [1-5] only (fast)"; value: 0}
        ListElement {title: "All 2.4G channels (slow)"; value: 1}
        ListElement {title: "All 5.8G channels (slow)"; value: 2}
    }

    GridLayout{
        Layout.fillWidth: true
        Layout.fillHeight: true

        ComboBox {
            Layout.row: 0
            Layout.column: 0
            Layout.preferredWidth: 400
            Layout.minimumWidth: 100
            id: comboBoxWhichFrequencyToScan
            model: model_chann_to_scan
            textRole: "title"
            Material.background: {
                (comboBoxWhichFrequencyToScan.currentIndex===0) ? Material.Green : Material.Orange
            }
            onCurrentIndexChanged: {
            }
            enabled: _ohdSystemGround.is_alive && _ohdSystemGround.wb_gnd_operating_mode==0
        }

        Button{
            Layout.row: 0
            Layout.column: 1
            text: "START"
            enabled: _ohdSystemGround.is_alive && _ohdSystemGround.wb_gnd_operating_mode==0
            onClicked: {
                var how_many_freq_bands=comboBoxWhichFrequencyToScan.currentIndex
                var how_many_bandwidths = 2;
                console.log("Initate channel scan "+how_many_freq_bands+","+how_many_bandwidths)
                var result = _wbLinkSettingsHelper.start_scan_channels(how_many_freq_bands,how_many_bandwidths)
                if(result){
                    _qopenhd.show_toast("Channel scan started, please wait",true)
                }else{
                    console.log("Cannot initiate channel scan");
                    _qopenhd.show_toast("Busy,please try again later",true)
                }
            }
        }
        SimpleProgressBar{
            Layout.row: 1
            Layout.column: 0
            Layout.fillWidth: true
            Layout.preferredHeight: 40
            Layout.preferredWidth: 400
            Layout.minimumWidth: 100
            impl_curr_progress_perc: _wbLinkSettingsHelper.scan_progress_perc
        }
        ButtonIconInfo{
            Layout.row: 1
            Layout.column: 1
            onClicked: {
                _messageBoxInstance.set_text_and_show("Initiate Channel Scan (Find a running air unit). Similar to analogue TX / RX, this listens on each channel for a short time"+
                                                      " to find a running openhd air unit."+
                                                      "Quick if you are only using the 5 OpenHD recommended channels, otherwise"+
                                                      " please specify the generic band and give it some time (There are a ton of possible channels, especially in 5.8G)")
            }
        }
        Text{
            Layout.row: 2
            Layout.column: 0
            text: _wbLinkSettingsHelper.scanning_text_for_ui
        }
    }
    Button{
        anchors.top: parent.top
        anchors.right: parent.right
        text: "CLOSE"
        onClicked: {
            close()
        }
    }
}
