import QtQuick 2.12
import QtQuick.Controls 2.12
import QtQuick.Layouts 1.12
import QtQuick.Dialogs 1.0
import QtQuick.Controls.Material 2.12

import "../../elements"

// I fucking hate writing UIs in QT
Card {
    id: dialoqueAnalyzeChannels
    width: 360
    height: 340
    z: 5.0
    anchors.centerIn: parent
    cardName: qsTr("Analyze Channels")
    cardNameColor: "black"
    visible: m_visible

    property bool m_visible: false

    function setup_and_show(){
        m_visible=true
    }

    property string m_info_string: "Analyze channels for pollution by wifi access points.
NOTE: This only gives a hint at free channels, using a proper channel analyzer (e.g. on the phone) is recommended.
PLEASE DO NOT CHANGE SETTINGS WHILE ANALYZING."


    cardBody: Item{
        height: 200
        width: 320
        Text {
            id: dialoqueStartChannelScan_text
            text: m_info_string
            width: parent.width
            height: parent.height-100
            leftPadding: 12
            rightPadding: 12
            wrapMode: Text.WordWrap

        }
    }
    hasFooter: true
    cardFooter: Item {
        anchors.fill: parent
        RowLayout{
            anchors.fill: parent

            Button{
                text:  qsTr("CANCEL")
                Material.accent: Material.RED
                highlighted: true
                Layout.alignment: Qt.AlignLeft
                onPressed: {
                    m_visible= false
                }
            }

            Button{
                text:  qsTr("INITIATE")
                Material.accent: Material.Green
                highlighted: true
                Layout.alignment: Qt.AlignRight
                onPressed: {
                    var result=_wbLinkSettingsHelper.start_analyze_channels()
                    if(result!==true){
                        _messageBoxInstance.set_text_and_show("Busy,please try again later",3)
                    }else{
                        m_visible=false;
                    }
                }
            }
        }
    }
}
