import QtQuick 2.12
import QtQuick.Window 2.0
import QtQuick.Controls 2.12
import QtQuick.Layouts 1.12
import QtGraphicalEffects 1.12

import Qt.labs.settings 1.0

import OpenHD 1.0

import "../../../ui" as Ui
import "../../elements"

ScrollView {
    clip:true
    //contentHeight: 850
    width: parent.width
    height: parent.height
    background: Rectangle { color: "#eaeaea" }

    ColumnLayout{
        width: parent.width
        Layout.minimumHeight: 30
        spacing: 6
        Layout.topMargin: 15

        Card {
            id: infoBox
            height: 120
            Layout.topMargin: 15
            Layout.leftMargin: 15
            Layout.rightMargin: 15
            Layout.fillWidth: true
            width:parent.width
            cardName: qsTr("FC RC (for debugging)")
            cardBody:
                Text {
                text: qsTr("NOTE: Only works on ardupilot!\nNOTE: Slow update rate(1Hz)-only for debugging\nHere you can see the rc channel values your FC reports via mavlink")
                height: 24
                font.pixelSize: 14
                leftPadding: 12
            }
        }
        Card {
            id: valuesCard
            Layout.topMargin: 15
            Layout.leftMargin: 15
            Layout.rightMargin: 15
            height: 70
            width: 190
            cardBody:
                    Text {
                        text: qsTr("ranges: 1000-2000(pwm) \nunused: 65535, \nnot set: -1")
                        height: 24
                        font.pixelSize: 14
                        topPadding: -30
                        leftPadding: 12
                    }
        }

        Repeater {
               id: channels_ground
               model: _rcchannelsmodelfc
               RowLayout{
                   visible: true // settings.app_show_RC
                   Layout.leftMargin: 15
                   Layout.rightMargin: 15
                   Layout.fillWidth: true
                   Layout.minimumHeight: 20
                   //implicitWidth: parent.implicitWidth
                   Text {
                       id: text
                       text: get_description()+model.curr_value
                       Layout.minimumWidth: 100
                   }
                   ProgressBar {
                       id: progressBar
                       // mavlink rc is in pwm, 1000 is min, 2000 is max
                       from: 1000
                       to: 2000
                       value: model.curr_value
                       //Layout.maximumWidth: 600
                       Layout.minimumWidth: 300
                       //Layout.fillWidth: true
                   }
                   // To the user we display the more verbose "start counting at channel 1", even though we use normal array indices in c++
                   function get_description(){
                       var channel_index_plus_1=index+1;
                       // add an additional space for values <10
                       if(channel_index_plus_1>=10){
                           return channel_index_plus_1+" (channel):";
                       }
                       return channel_index_plus_1+"  (channel):";
                   }
               }
        }
    }
}
