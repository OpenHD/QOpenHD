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

Rectangle{
    //width: parent.width-12
    //height: parent.height*2/3;
    width: parent.width - 20
    height: parent.height -20
    anchors.centerIn: parent
    color: "#333c4c"

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

    ColumnLayout{
        id:channelScanLayout
        anchors.fill: parent
        anchors.leftMargin: 10
        anchors.rightMargin: 5

        BaseHeaderItem{
            m_text: "Find Air Unit"
        }

        Item {
            id:closeButtonWrapper
            Layout.alignment: Qt.AlignTop | Qt.AlignRight
            Layout.rightMargin: closeButton.width-channelScanLayout.anchors.rightMargin
            Layout.topMargin: (closeButtonWrapper.height-closeButton.height)-1

            Button {
                id:closeButton
                text: "X"
                height:42
                width:42
                background: Rectangle {
                    Layout.fillHeight: parent
                    Layout.fillWidth: parent
                    color: closeButton.hovered ? "darkgrey" : "lightgrey"
                }
                onClicked: {
                    if (_ohdSystemGround.is_alive && _ohdSystemGround.wb_gnd_operating_mode == 1) {
                        _qopenhd.show_toast("STILL SCANNING, PLEASE WAIT ...");
                        return;
                    }
                    close()
                }
            }
        }

        RowLayout{
            id:channelSelectorRow
            Layout.alignment: Qt.AlignHCenter | Qt.AlignVCenter
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
            Button{
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
            ButtonIconInfo{
                visible:false
                onClicked: {
                    _messageBoxInstance.set_text_and_show("Initiate Channel Scan (Find a running air unit). Similar to analogue TX / RX, this listens on each channel for a short time"+
                                                          " to find a running openhd air unit."+
                                                          "Quick if you are only using the 5 OpenHD recommended channels, otherwise"+
                                                          " please specify the generic band and give it some time (There are a ton of possible channels, especially in 5.8G)")
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
            visible: _ohdSystemGround.is_alive && _ohdSystemGround.wb_gnd_operating_mode!=0
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
