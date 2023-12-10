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


    property bool m_supports_reboot_actions: true
 //m_supports_shutdown_actions added due to testers reporting FC does not shutdown
    property bool m_supports_shutdown_actions: true

    function get_show_power_actions(){
        if(m_type==0){
            return _ohdSystemGround.is_alive
        }else if(m_type==1){
            return _ohdSystemAir.is_alive
        }
        //hide FC shutdown button
        m_supports_shutdown_actions=false
        return _fcMavlinkSystem.is_alive
    }

    function open_warning(){
        if(m_type==0){
            dialoqueNotAlive.open_ground();
        }else if(m_type==1){
            if(_ohdSystemGround.is_alive){
                dialoqueNotAlive.open_air();
            }else{
                var text="Please make sure your ground unit is alive first."
                _messageBoxInstance.set_text_and_show(text)
            }
        }else{
            var text=""
            if(!(_ohdSystemGround.is_alive && _ohdSystemAir.is_alive)){
                text="Please make sure your air and ground unit are alive first."
            }else{
                text="No FC detected - your FC needs to be connected to your AIR UNIT via UART and you have to set the matching baud rate / FC_UART_CONN type in the OpenHD AIR UNIT parameters set."
            }
            _messageBoxInstance.set_text_and_show(text)
        }
    }

    RowLayout{
        anchors.fill: parent
        //visible: get_show_power_actions()
        Button{
            visible: get_show_power_actions() && m_supports_reboot_actions
            Layout.alignment: {if (m_supports_shutdown_actions == false)
                    return Qt.AlignCenter
                else
                    return Qt.Align.Right
            }
            Layout.leftMargin: 10
            text: qsTr("REBOOT")
            onPressed: {
                open_power_action_dialoque(m_type,true)
            }
        }
        Button{
            visible: get_show_power_actions() && m_supports_shutdown_actions
            Layout.alignment: Qt.AlignRight
            Layout.rightMargin: 10
            text: qsTr("SHUTDOWN")
            onPressed: {
                open_power_action_dialoque(m_type,false)
            }
        }
        ButtonIconConnect{
            m_type_wired: m_type==0 ? true : false;
            visible: !get_show_power_actions()
            Layout.alignment: Qt.AlignCenter
            height:12
            onPressed: {
                open_warning();
            }
        }
        /*ButtonIconWarning{
            visible: !get_show_power_actions()
            Layout.alignment: Qt.AlignCenter
            height:12
            onPressed: {
                open_warning();
            }
        }*/
    }
}
