import QtQuick 2.12
import QtQuick.Controls 2.12
import QtQuick.Layouts 1.12
import QtQuick.Controls.Material 2.12

import Qt.labs.settings 1.0

import OpenHD 1.0

import "../../../ui" as Ui
import "../../elements"

Item {
    anchors.fill: parent
    property int m_type: 0 // 0 = ground, 1= air, 2=FC

    function get_show_power_actions(){
        if(m_type==0){
            return _ohdSystemGround.is_alive
        }else if(m_type==1){
            return _ohdSystemAir.is_alive
        }
        return _fcMavlinkSystem.is_alive
    }

    function open_warning(){
        if(m_type==0){
            var text="Looks like you are not receiving any messages from your OpenHD ground unit - when running on an external device,"+
                    "please use the connect tab to connect to your ground unit. Otherwise, please make sure OpenHD core is running on your ground station."
            _messageBoxInstance.set_text_and_show(text)
        }else if(m_type==1){
            var text=""
            if(_ohdSystemGround.is_alive){
                text="Please go to OpenHD settings and connect to your air unit via Wifibroadcast."
            }else{
                text="Please make sure your ground unit is alive first."
            }
            _messageBoxInstance.set_text_and_show(text)
        }else{
            var text=""
            if(!(_ohdSystemGround.is_alive && _ohdSystemAir.is_alive)){
                text="Please make sure your air and ground unit are alive first."
            }else{
                text="Please check baud and telemetry connection under OpenHD settings / AIR. Your air unit needs to be connected to the FC via UART."
            }
            _messageBoxInstance.set_text_and_show(text)
        }
    }

    RowLayout{
        anchors.fill: parent
        //visible: get_show_power_actions()
        ButtonOrange{
            visible: get_show_power_actions()
            Layout.alignment: Qt.AlignLeft
            Layout.leftMargin: 10
            text: qsTr("REBOOT")
            onPressed: {
                open_power_action_dialoque(m_type,true)
            }
        }
        ButtonRed{
            visible: get_show_power_actions()
            Layout.alignment: Qt.AlignRight
            Layout.rightMargin: 10
            text: qsTr("SHUTDOWN")
            onPressed: {
                open_power_action_dialoque(m_type,false)
            }
        }
        ButtonIconWarning{
            visible: !get_show_power_actions()
            Layout.alignment: Qt.AlignCenter
            onPressed: {
                open_warning();
            }
        }
    }
}
