import QtQuick 2.12
import QtQuick.Controls 2.12
import QtQuick.Layouts 1.12
import QtQuick.Dialogs 1.0
import QtQuick.Controls.Material 2.12

import "../../elements"

// I fucking hate writing UIs in QT
// Dialoque that initiates a channel/frequency analyze once the user selected everything correctly / passed all the checks
Card {
    id: dialoqueAnalyzeChannels
    width: 360
    height: 340
    z: 5.0
    anchors.centerIn: parent
    cardName: qsTr("Analyze Channels")
    cardNameColor: "black"
    visible: false

    property int m_index: 0

    function setup_and_show(){
        if(!_fcMavlinkSystem.armed){
            m_index=0;
        }else{
            m_index=1;
        }
        dialoqueAnalyzeChannels.visible=true;
    }

    property string m_armed_warning: "WARNING ! Analyze channels while armed is not recommended, you'l loose connection for a significant amount of time !"

    property string m_info_string: "Analyze channels for pollution by wifi access points.
NOTE: This only gives a hint at free channels, using a proper channel analyzer (e.g. on the phone) is recommended.
PLEASE DO NOT CHANGE SETTINGS WHILE ANALYZING."


    cardBody: Item{
        height: 200
        width: 320
        // Dialoque one
        Text {
            visible: m_index==0
            text: m_armed_warning
            width: parent.width
            height: parent.height-100
            leftPadding: 12
            rightPadding: 12
            wrapMode: Text.WordWrap
        }
        // Dialoque two
        Text {
            visible: m_index==1
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
        // Dialoque one
        RowLayout{
            anchors.fill: parent
            visible: m_index==0
            ButtonRed{
                Layout.preferredWidth: 140
                Layout.alignment: Qt.AlignLeft
                Layout.leftMargin: 12
                text:  qsTr("PROCEED ANYWAY")
                onPressed: {
                    m_index=1
                }
            }
            ButtonGreen{
                Layout.preferredWidth: 140
                Layout.alignment: Qt.AlignRight
                Layout.rightMargin: 12
                text:  qsTr("CANCEL")
                onPressed: {
                   dialoqueAnalyzeChannels.visible=false;
                }
            }
        }
        // Dialoque 2
        RowLayout{
            anchors.fill: parent
            visible: m_index==1
            ButtonRed{
                Layout.preferredWidth: 140
                Layout.alignment: Qt.AlignLeft
                Layout.leftMargin: 12
                text:  qsTr("CANCEL")
                onPressed: {
                    dialoqueAnalyzeChannels.visible=false;
                }
            }
            ButtonGreen{
                Layout.preferredWidth: 140
                Layout.alignment: Qt.AlignLeft
                Layout.leftMargin: 12
                text:  qsTr("INITIATE")
                onPressed: {
                    var result=_wbLinkSettingsHelper.start_analyze_channels()
                    if(result!==true){
                        _messageBoxInstance.set_text_and_show("Busy,please try again later",3)
                    }else{
                        dialoqueAnalyzeChannels.visible=false;
                    }
                }
            }
        }
    }
}
