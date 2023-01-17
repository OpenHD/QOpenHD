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
    clip:true
    contentHeight: 850
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
        Layout.topMargin: 15

        Card {
            id: infoBox
            height: 90
            Layout.topMargin: 15
            Layout.leftMargin: 15
            Layout.rightMargin: 15
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
            Layout.topMargin: 15
            Layout.leftMargin: 15
            Layout.rightMargin: 15
            visible: !settings.app_show_RC
            height: 24
            text: "Enable RC"
            onClicked: {
                var text="RC was enabled, now please restart OpenHD or reboot the Groundstation\n\n\nRemember that your Controller needs to be connected when booting for Rc to work correctly!"
                _messageBoxInstance.set_text_and_show(text)
                _groundPiSettingsModel.try_update_parameter_int("ENABLE_JOY_RC",1)
                settings.app_show_RC=true
            }
        }

        Card {
            id: connectRCCard
            visible: !_rcchannelsmodelground.is_alive
            Layout.topMargin: 15
            Layout.leftMargin: 15
            Layout.rightMargin: 15
            Layout.bottomMargin: 15
            height: 35
            width: 450
            cardBody:
                    Text {
                        text: qsTr("You need to connect your controller, if not OpenHD-RC can not work")
                        height: 24
                        font.pixelSize: 14
                        topPadding: -30
                        leftPadding: 12
                    }
        }

        Repeater {
               model: _rcchannelsmodelground
               RowLayout{
                   visible: settings.app_show_RC
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
        Button{
            Layout.topMargin: 15
            Layout.leftMargin: 15
            Layout.rightMargin: 15
            visible: settings.app_show_RC
            height: 24
            text: "Disable RC"
            onClicked: {
                var text="RC was disabled, now please restart OpenHD or reboot the Groundstation"
                _messageBoxInstance.set_text_and_show(text)
                _groundPiSettingsModel.try_update_parameter_int("ENABLE_JOY_RC",0)
                settings.app_show_RC=false
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
    }
}

