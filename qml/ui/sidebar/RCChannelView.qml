import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.12

import QtQuick.Shapes 1.0
import QtQuick.Controls.Material 2.0

import Qt.labs.settings 1.0

import OpenHD 1.0

import "../elements"

//
// Shows both the value from FC and the value from the joystick
//
Column{
    property int override_channel_index:0
    width: secondaryUiWidth
    spacing: 1

    function get_channel_value_fc(){
        if(override_channel_index==0){
            return _rcchannelsmodelfc.control_yaw
        }
        if(override_channel_index==1){
            return _rcchannelsmodelfc.control_roll
        }
        if(override_channel_index==2){
            return _rcchannelsmodelfc.control_pitch
        }
        if(override_channel_index==3){
            return _rcchannelsmodelfc.control_throttle
        }
    }
    function get_channel_value_joy(){
        if(override_channel_index==0){
            return _rcchannelsmodelground.control_yaw
        }
        if(override_channel_index==1){
            return _rcchannelsmodelground.control_roll
        }
        if(override_channel_index==2){
            return _rcchannelsmodelground.control_pitch
        }
        if(override_channel_index==3){
            return _rcchannelsmodelground.control_throttle
        }
    }

    Text{
        text: "Channel "+override_channel_index
        font.pixelSize: 14
        font.family: "AvantGarde-Medium"
        color: "#ffffff"
        smooth: true
    }
    // Shows joy input
    /*ProgressBar {
        from: 1000
        to: 2000
        Material.accent: Material.Grey
        width: secondaryUiWidth
        value: get_channel_value_fc()
    }*/
    // Shows value reported by FC
    ProgressBar {
        from: 1000
        to: 2000
        Material.accent: Material.Grey
        width: secondaryUiWidth-35
        value: get_channel_value_fc()
    }
}

