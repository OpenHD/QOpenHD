import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.12

import QtQuick.Shapes 1.0
import QtQuick.Controls.Material 2.0

import Qt.labs.settings 1.0

import OpenHD 1.0

import "../elements"

SideBarBasePanel{
    override_title: "Channel Scan"

    function takeover_control(){
        start_button.forceActiveFocus();
    }

    ListModel{
        id: model_chann_to_scan
        ListElement {title: "OpenHD [1-7] only"; value: 0}
        ListElement {title: "All 2.4G channels"; value: 1}
        ListElement {title: "All 5.8G channels"; value: 2}
    }

    ColumnLayout{
        id: main_layout
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.top: parent.top
        anchors.bottom: parent.bottom
        anchors.leftMargin: 10
        anchors.rightMargin: 10
        anchors.topMargin: secondaryUiHeight / 8

        RowLayout{
            id: channelSelectorRow
            Layout.alignment: Qt.AlignHCenter | Qt.AlignVCenter
            Button{
                id: start_button
                text: "START"
                enabled: _ohdSystemGround.is_alive && _ohdSystemGround.wb_gnd_operating_mode==0
                onClicked: {
                    var how_many_freq_bands=comboBoxWhichFrequencyToScan.currentIndex
                    var how_many_bandwidths = 2
                    console.log("Initate channel scan "+how_many_freq_bands+","+how_many_bandwidths)
                    var result = _wbLinkSettingsHelper.start_scan_channels(how_many_freq_bands,how_many_bandwidths)
                    if(result){
                        _qopenhd.show_toast("Channel scan started, please wait",true)
                    }else{
                        console.log("Cannot initiate channel scan")
                        _qopenhd.show_toast("Busy,please try again later",true)
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
                enabled: _ohdSystemGround.is_alive && _ohdSystemGround.wb_gnd_operating_mode==0
            }
            ButtonIconInfo{
                onClicked: {
                    _messageBoxInstance.set_text_and_show("Initiate Channel Scan (Find a running air unit). Similar to analogue"+
                                                             " TX / RX, this listens on each channel for a short time"+
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
            Layout.alignment: Qt.AlignHCenter | Qt.AlignVCenter
            text: _wbLinkSettingsHelper.scanning_text_for_ui
            font.pixelSize: 21
            color: "#fff"
        }
        Item{ // Filler
            Layout.fillWidth: true
            Layout.fillHeight: true
        }
    }
}

