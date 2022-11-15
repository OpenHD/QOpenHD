import QtQuick 2.12
import QtQuick.Controls 2.12
import QtQuick.Layouts 1.12
import QtGraphicalEffects 1.12

import Qt.labs.settings 1.0

import OpenHD 1.0

import "../../ui" as Ui
import "../elements"

// For joystick debugging. For ease of use, we have a simple model in c++ for it
Rectangle {
    id: rcInfoPanel
    Layout.fillHeight: true
    Layout.fillWidth: true

    property int rowHeight: 64
    property int text_minHeight: 20


    color: "#eaeaea"


    ColumnLayout{
        Layout.fillWidth: true
        Layout.minimumHeight: 30
        spacing: 6
        anchors.top: parent.top
        anchors.left: parent.left
        anchors.margins: 10

        Text {
            id: decr
            text: qsTr("Values read by OpenHD (not QOpenHD) from your Joystick RC if enabled.\nrange: 1000-2000(pwm), unused:65535, not set:-1")
            width:parent.width
        }

        Text {
            id: alive
            text: qsTr("alive:"+(_rcchannelsmodelground.is_alive ? "Y":"N"));
        }

        Repeater {
               model: _rcchannelsmodelground
               RowLayout{
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
