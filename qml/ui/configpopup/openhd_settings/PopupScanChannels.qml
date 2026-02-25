import QtQuick 2.0

import QtQuick 2.12
import QtQuick.Controls 2.12
import QtQuick.Layouts 1.12

import QtQuick.Controls.Material 2.12
 

import Qt.labs.settings 1.0

import OpenHD 1.0

import "../../../ui" as Ui
import "../../elements"

PopupBigGeneric{
    // Overwritten from parent
    m_title:  qsTr("Find Air Unit")
    onCloseButtonClicked: {
        if (_ohdSystemGround.is_alive && _ohdSystemGround.wb_gnd_operating_mode == 1) {
            _qopenhd.show_toast(qsTr("STILL SCANNING, PLEASE WAIT ..."));
            return;
        }
        close()
    }

    // Impl.
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
        ListElement {title: qsTr("OpenHD [1-7] only"); value: 0}
        ListElement {title: qsTr("All 2.4G channels"); value: 1}
        ListElement {title: qsTr("All 5.8G channels"); value: 2}
    }
    ListModel{
        id: model_bandwidth_to_scan
    }

    function rebuild_bandwidth_model(){
        model_bandwidth_to_scan.clear();
        model_bandwidth_to_scan.append({title: qsTr("10 MHz"), value: 10});
        model_bandwidth_to_scan.append({title: qsTr("20 MHz"), value: 20});
        if(settings.dev_allow_40mhz){
            model_bandwidth_to_scan.append({title: qsTr("40 MHz"), value: 40});
        }
    }

    function sync_bandwidth_selection(){
        for(var i=0;i<model_bandwidth_to_scan.count;i++){
            if(model_bandwidth_to_scan.get(i).value===settings.scan_channel_width_mhz){
                comboBoxBandwidthToScan.currentIndex=i;
                return;
            }
        }
        if(model_bandwidth_to_scan.count>0){
            comboBoxBandwidthToScan.currentIndex=0;
            settings.scan_channel_width_mhz=model_bandwidth_to_scan.get(0).value;
        }
    }

    Component.onCompleted: {
        rebuild_bandwidth_model();
        sync_bandwidth_selection();
    }

    ColumnLayout{
        id: main_layout
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.top: parent.top
        anchors.bottom: parent.bottom
        anchors.leftMargin: 10
        anchors.rightMargin: 10
        anchors.topMargin: dirty_top_margin_for_implementation

        RowLayout{
            id:channelSelectorRow
            Layout.alignment: Qt.AlignHCenter | Qt.AlignVCenter
            Button{
                text: qsTr("START")
                enabled: _ohdSystemGround.is_alive && _ohdSystemGround.wb_gnd_operating_mode==0
                onClicked: {
                    var how_many_freq_bands=comboBoxWhichFrequencyToScan.currentIndex
                    var channel_width_mhz = settings.scan_channel_width_mhz;
                    console.log("Initate channel scan "+how_many_freq_bands+","+channel_width_mhz)
                    var result = _wbLinkSettingsHelper.start_scan_channels(how_many_freq_bands,channel_width_mhz)
                    if(result){
                        _qopenhd.show_toast(qsTr("Channel scan started, please wait"),true)
                    }else{
                        console.log("Cannot initiate channel scan");
                        _qopenhd.show_toast(qsTr("Busy,please try again later"),true)
                    }
                }
            }

            ComboBox {
                Layout.preferredWidth: 400
                Layout.minimumWidth: 100
                id: comboBoxWhichFrequencyToScan
                model: model_chann_to_scan
                textRole: "title"
                Material.background: {
                    (comboBoxWhichFrequencyToScan.currentIndex===0) ? "#2b9848" : "#ffae42"
                }
                onCurrentIndexChanged: {
                }
                enabled: _ohdSystemGround.is_alive && _ohdSystemGround.wb_gnd_operating_mode==0
            }
            ComboBox {
                Layout.preferredWidth: 160
                Layout.minimumWidth: 80
                id: comboBoxBandwidthToScan
                model: model_bandwidth_to_scan
                textRole: "title"
                onCurrentIndexChanged: {
                    if(comboBoxBandwidthToScan.currentIndex<0)return;
                    settings.scan_channel_width_mhz = model_bandwidth_to_scan.get(comboBoxBandwidthToScan.currentIndex).value;
                }
                enabled: _ohdSystemGround.is_alive && _ohdSystemGround.wb_gnd_operating_mode==0
            }
            ButtonIconInfo{
                visible:false
                onClicked: {
                    _messageBoxInstance.set_text_and_show(qsTr("Initiate Channel Scan (Find a running air unit). Similar to analogue TX / RX, this listens on each channel for a short time to find a running openhd air unit. Quick if you are only using the 5 OpenHD recommended channels, otherwise please specify the generic band and give it some time (There are a ton of possible channels, especially in 5.8G)"))
                }
            }
        }

        SimpleProgressBar{
                        Layout.alignment: Qt.AlignHCenter | Qt.AlignVCenter
                        Layout.preferredWidth: channelSelectorRow.width
                        Layout.minimumWidth: 100
                        Layout.preferredHeight: 40
                        impl_curr_progress_perc: _wbLinkSettingsHelper.scan_progress_perc
                        impl_show_progress_text: true
                    }
        Text{
            Layout.alignment: Qt.AlignHCenter | Qt.AlignVCenter
            Layout.row: 3
            Layout.column: 0
            text: _wbLinkSettingsHelper.scanning_text_for_ui
            font.pixelSize: 21
            color: "#fff"
        }
        Item{ // Filler
            Layout.row: 4
            Layout.column: 0
            Layout.columnSpan: 3
            Layout.fillWidth: true
            Layout.fillHeight: true
        }
    }
}
