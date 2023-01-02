import QtQuick 2.12
import QtQuick.Window 2.0
import QtQuick.Controls 2.12
import QtQuick.Layouts 1.12
import QtGraphicalEffects 1.12

import Qt.labs.settings 1.0

import OpenHD 1.0

import "../../ui" as Ui
import "../elements"

ScrollView {
    anchors.fill: parent
    clip:true
    contentHeight: 800
    width: parent.width

// For joystick debugging. For ease of use, we have a simple model in c++ for it
    Rectangle{
    id: backgroundRect
    width: parent.width
    height: parent.height
    color : "#eaeaea"
    }

    ColumnLayout{
        width: parent.width
        Layout.minimumHeight: 30
        spacing: 6
        anchors.top: parent.top
        anchors.left: parent.left
        anchors.margins: 10


        Card {
            id: infoBox
            height: 90
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.rightMargin: 30
            Layout.fillWidth: true
            cardName: qsTr("OpenHD RC")
            cardBody:
                    Text {
                        text: qsTr("Here you can view the values which OpenHD reads \nfrom your Joystick when it is enabled")
                        height: 24
                        font.pixelSize: 14
                        leftPadding: 12
                    }
        }

        Button{
            visible: !_rcchannelsmodelground.is_alive
            height: 24
            text: "Enable RC and Reboot"
            onClicked: {
            //here we need to enable RC and do a reboot
            }
        }

        Repeater {
               model: _rcchannelsmodelground
               RowLayout{
                   visible: _rcchannelsmodelground.is_alive
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
        Card {
            id: valuesCard
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
    }
}

