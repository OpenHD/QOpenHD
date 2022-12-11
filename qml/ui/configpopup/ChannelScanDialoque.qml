import QtQuick 2.12
import QtQuick.Controls 2.12
import QtQuick.Layouts 1.12
import QtQuick.Dialogs 1.0
import QtQuick.Controls.Material 2.12

import "../elements"

// I fucking hate writing UIs in QT
Card {
    id: dialoqueStartChannelScan
    width: 360
    height: 340
    z: 5.0
    anchors.centerIn: parent
    cardName: qsTr("Channel Scan")
    cardNameColor: "black"
    visible: false

    property int m_curr_index: 0

    function open_channel_scan_dialoque(){
        m_curr_index=0;
        dialoqueStartChannelScan.visible=true
    }

    ListModel{
        id: model_chann_2G_or_5G
        ListElement {title: "All 2.4G and 5.8G channels (slow)"; value: 0}
        ListElement {title: "All 2.4G channels"; value: 1}
        ListElement {title: "All 5.8G channels"; value: 2}
    }

    cardBody: Item{
        height: 200
        width: 320
        Text {
            id: dialoqueStartChannelScan_text
            text: "Initiate Channel Scan. Might take more than 1 minute if you are not specifying 2.4G / 5.8G and your RX card supports both 2.4G / 5.8G. Otherwise,it'l take
max 30 seconds, usually less"
            width: parent.width
            height: parent.height-100
            leftPadding: 12
            rightPadding: 12
            wrapMode: Text.WordWrap

            visible: m_curr_index==0
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

            visible: m_curr_index==0

            onCurrentIndexChanged: {
            }
        }

        Text{
            id: dialoqueStartChannelScan_text2
            text: "Scanning channels, you can close this dialoque and go back to your OSD screen. This operation hapens in the background, progress is not implemented yet."
            width: parent.width
            height: parent.height-100
            leftPadding: 12
            rightPadding: 12
            wrapMode: Text.WordWrap

            visible: m_curr_index==1
        }

    }
    hasFooter: true
    cardFooter: Item {
        anchors.fill: parent
        Button {
            width: 140
            height: 48
            anchors.left: parent.left
            anchors.leftMargin: 12
            anchors.bottom: parent.bottom
            anchors.bottomMargin: 6
            font.pixelSize: 14
            font.capitalization: Font.MixedCase
            Material.accent: Material.Green
            highlighted: true
            text:  qsTr("Initiate")
            visible: m_curr_index==0
            onPressed: {
                if(m_curr_index==0){
                    var how_many_freq_bands=comboBoxWhichFrequencyToScan.currentIndex
                   console.log("Initate channel scan "+how_many_freq_bands)
                    _ohdSystemGround.request_channel_scan(how_many_freq_bands)
                    m_curr_index++;
                }else{
                     dialoqueStartChannelScan.visible=false;
                }
            }
        }
        Button {
            width: 140
            height: 48
            anchors.right: parent.right
            anchors.rightMargin: 12
            anchors.bottom: parent.bottom
            anchors.bottomMargin: 6
            font.pixelSize: 14
            font.capitalization: Font.MixedCase
            Material.accent: Material.Red
            highlighted: true
            text:  qsTr("Cancel")
            visible: m_curr_index==0
            onPressed: {
                m_curr_index=0;
                dialoqueStartChannelScan.visible=false;
            }
        }

        Button {
            width: 140
            height: 48
            anchors.left: parent.left
            anchors.leftMargin: 12
            anchors.bottom: parent.bottom
            anchors.bottomMargin: 6
            font.pixelSize: 14
            font.capitalization: Font.MixedCase
            Material.accent: Material.Green
            highlighted: true
            text:  qsTr("Close")
            visible: m_curr_index==1
            onPressed: {
                 dialoqueStartChannelScan.visible=false;
            }
        }
    }
}
