import QtQuick 2.12
import QtQuick.Controls 2.12
import QtQuick.Layouts 1.12
import QtQuick.Dialogs 1.0
import QtQuick.Controls.Material 2.12

import "../../elements"

// I fucking hate writing UIs in QT
// Dialoque that initiates a channel scan once the user selected everything correctly / passed all the checks
Card {
    id: dialoqueStartChannelScan
    width: 360
    height: 340
    z: 5.0
    anchors.centerIn: parent
    cardName: qsTr("Find Air Unit")
    cardNameColor: "black"
    visible: false

    property int m_curr_index: 0

    function open_channel_scan_dialoque(){
        var is_armed= _fcMavlinkSystem.is_alive && _fcMavlinkSystem.armed
        if(is_armed){
            m_curr_index=0;
        }else{
            m_curr_index=1;
        }
        dialoqueStartChannelScan.visible=true
    }

    ListModel{
        id: model_chann_2G_or_5G
        ListElement {title: "All 2.4G and 5.8G channels (slow)"; value: 0}
        ListElement {title: "All 2.4G channels"; value: 1}
        ListElement {title: "All 5.8G channels"; value: 2}
    }

    // like dji, we use 20 or 40Mhz bandwidth(s) but never 5 or 10
    ListModel{
        id: model_bandwidth_all_or_20_or_40
        ListElement {title: "20Mhz and 40Mhz (slow)"; value: 0}
        ListElement {title: "20Mhz only"; value: 1}
        ListElement {title: "40Mhz only"; value: 2}
    }

    cardBody: Item{
        height: 200
        width: 320
        // warn if armed dialoque
        Item{
            id: dialoque1
            visible: m_curr_index==0
            width: parent.width
            height: parent.height
            Text{
                text: "WARNING ! Performing a channel scan while armed is not recommended, you'l loose connecion !"
                width: parent.width
                height: parent.height-100
                leftPadding: 12
                rightPadding: 12
                wrapMode: Text.WordWrap
            }
        }
        // select and then initiate dialoque
        Item{
            id: dialoque2
            visible: m_curr_index==1
            width: parent.width
            height: parent.height
            Text {
                id: dialoqueStartChannelScan_text
                text: "Initiate Channel Scan (Find a running air unit). Might take more than 1 minute if you are not specifying the generic band below. Otherwise,it'l take
    max 30 seconds, usually less"
                width: parent.width
                height: parent.height-100
                leftPadding: 12
                rightPadding: 12
                wrapMode: Text.WordWrap

            }
            ComboBox {
                width: parent.width
                //height: 100
                anchors.top: dialoqueStartChannelScan_text.bottom
                id: comboBoxWhichFrequencyToScan
                model: model_chann_2G_or_5G
                textRole: "title"
                Material.background: {
                    (comboBoxWhichFrequencyToScan.currentIndex===0) ? Material.Orange : Material.Green
                }
                onCurrentIndexChanged: {
                }
            }
            /*ComboBox {
                width: parent.width
                //height: 100
                anchors.top: comboBoxWhichFrequencyToScan.bottom
                id: comboBoxWhichChannelWidthsToScan
                model: model_bandwidth_all_or_20_or_40
                textRole: "title"
                Material.background: {
                    (comboBoxWhichChannelWidthsToScan.currentIndex===0) ? Material.Orange : Material.Green
                }
                onCurrentIndexChanged: {
                }
            }*/
        }
        // after initiate dialoque
        Item{
            id: dialoque3
            visible: m_curr_index==2
            width: parent.width
            height: parent.height
            Text{
                id: dialoqueStartChannelScan_text2
                text: "Scanning channels, you can close this dialoque and go back to your OSD screen. PLEASE DO NOT CHANGE SETTINGS WHILE CHANNEL SCAN IS ACTIVE !"
                width: parent.width
                height: parent.height-100
                leftPadding: 12
                rightPadding: 12
                wrapMode: Text.WordWrap
            }
        }

    }
    hasFooter: true
    cardFooter: Item {
        anchors.fill: parent

        // First dialoque
        RowLayout{
            anchors.fill: parent
            visible: m_curr_index==0
            ButtonRed{
                text: "PROCCEED ANYWAY"
                /*Layout.fillWidth: true
                Layout.preferredWidth: 140
                Layout.alignment: Qt.AlignLeft*/
                Layout.preferredWidth: 140
                Layout.alignment: Qt.AlignLeft
                Layout.leftMargin: 12
                onClicked: {
                    m_curr_index++;
                }
            }
            ButtonGreen{
                text: "CANCEL"
                /*Layout.fillWidth: true
                Layout.preferredWidth: 140
                Layout.alignment: Qt.AlignRight*/
                Layout.preferredWidth: 140
                Layout.alignment: Qt.AlignRight
                Layout.rightMargin: 12
                onClicked: {
                    dialoqueStartChannelScan.visible=false;
                }
            }
        }
        // Second dialoque
        RowLayout{
            anchors.fill: parent
            visible: m_curr_index==1
            Button{
                Layout.preferredWidth: 140
                Layout.alignment: Qt.AlignLeft
                Layout.leftMargin: 12
                text:  qsTr("Cancel")
                visible: m_curr_index==1
                onPressed: {
                    dialoqueStartChannelScan.visible=false;
                }
            }
            Button{
                Layout.preferredWidth: 140
                Layout.alignment: Qt.AlignRight
                Layout.rightMargin: 12
                text:  qsTr("Initiate")
                onPressed: {
                    var how_many_freq_bands=comboBoxWhichFrequencyToScan.currentIndex
                    // Changed: We now (only) support scanning in 40Mhz mode, since this way, we are quicker and catch both 20Mhz and 40Mhz air unit(s)
                    //var how_many_bandwidths=comboBoxWhichChannelWidthsToScan.currentIndex
                    var how_many_bandwidths = 2;
                    console.log("Initate channel scan "+how_many_freq_bands+","+how_many_bandwidths)
                    var result = _wbLinkSettingsHelper.start_scan_channels(how_many_freq_bands,how_many_bandwidths)
                    if(result){
                        m_curr_index=2;
                    }else{
                        console.log("Cannot initiate channel scan");
                        _qopenhd.show_toast("Busy,please try again later",true)
                    }
                }
            }
        }
        RowLayout{
            anchors.fill: parent
            visible: m_curr_index==2
            Button{
                Layout.preferredWidth: 140
                Layout.alignment: Qt.AlignRight
                Layout.rightMargin: 12
                text:  qsTr("Close")
                onPressed: {
                    dialoqueStartChannelScan.visible=false;
                }
            }
        }
    }
}
