import QtQuick 2.12
import QtQuick.Controls 2.12
import QtQuick.Layouts 1.12
import QtQuick.Dialogs 1.1
import QtQuick.Controls.Material 2.12

import Qt.labs.settings 1.0

import OpenHD 1.0

import "../../../ui" as Ui
import "../../elements"

ColumnLayout {
    // from https://doc.qt.io/qt-6/qml-qtquick-layouts-rowlayout.html
    anchors.fill: parent
    spacing: 2

    property bool m_is_ground: false

    property var m_model: m_is_ground ? _ohdSystemGround : _ohdSystemAir

    property string m_version: m_model.openhd_version
    property string m_last_ping: m_model.last_ping_result_openhd
    property bool m_is_alive: m_model.is_alive
    property string m_qopenhd_version: "TODO"

    function get_alive_text(){
        return m_is_alive ? "Yes" : "NOT ALIVE !"
    }
    function get_alive_text_color(){
        //return m_is_alive ? "green" : "red"
        return m_is_alive ? "green" : "black"
    }

    function get_cards_text(){
        if(!m_is_ground){
            return _wifi_card_air.card_type_as_string;
        }
        // Ground
        var ret="";
        if(_wifi_card_gnd0.alive){
            ret+="[1]"+_wifi_card_gnd0.card_type_as_string;
        }
        if(_wifi_card_gnd1.alive){
            ret+="\n"+"[2]"+_wifi_card_gnd1.card_type_as_string;
        }
        if(_wifi_card_gnd2.alive){
            ret+="\n"+"[3]"+_wifi_card_gnd2.card_type_as_string;
        }
        if(_wifi_card_gnd3.alive){
            ret+="\n"+"[4]"+_wifi_card_gnd3.card_type_as_string;
        }
        if(ret.length==0)return "N/A";
        return ret;
    }

    function gnd_uplink_state(){
        if(!_ohdSystemGround.is_alive)return 0;
        if(!_ohdSystemAir.is_alive)return 0;
        if(!_ohdSystemAir.curr_rx_last_packet_status_good)return -1;
        return 1;
    }
    function gnd_uplink_state_text(){
        var curr_gnd_uplink_state=gnd_uplink_state();
        if(curr_gnd_uplink_state==0)return "N/A";
        if(curr_gnd_uplink_state==1) return "OK";
        return "ERROR";
    }

    function get_text_qopenhd_openhd_ground_version_mismatch(){
        var ret="Your version of QOpenHD ["+m_qopenhd_version+"] is incompatible with your ground station OpenHD version: ["+m_version+"]"+
                "\nPlease update QOpenHD / your Ground station.";
        return ret;
    }
    function get_show_warning_qopenhd_openhd_ground_version_mismatch(){
        if(m_version==="N/A")return false;
        if(m_version!==m_qopenhd_version)return true;
        return false;
    }

    property int text_minHeight: 30
    property int column_preferred_height: 50

    property int left_part_preferred_with: 120

    RowLayout{
        Layout.fillWidth: true
        Layout.minimumHeight: text_minHeight
        spacing: 6
        Text {
            Layout.preferredWidth: left_part_preferred_with
            text: qsTr("OpenHD Version:")
        }
        Text {
            text: m_version
            visible: !(m_version==="N/A")
        }
        Button{
            text: "N/A"
            onClicked: _ohdAction.request_openhd_version_async()
            visible: (m_version==="N/A")
            Layout.preferredHeight: text_minHeight
            Layout.minimumHeight: text_minHeight
            height: text_minHeight
        }
        ButtonIconWarning{
            onClicked: {
                _messageBoxInstance.set_text_and_show(get_text_qopenhd_openhd_ground_version_mismatch())
            }
            visible: m_is_ground && get_show_warning_qopenhd_openhd_ground_version_mismatch()
            Layout.preferredHeight: text_minHeight
            Layout.minimumHeight: text_minHeight
            height: text_minHeight
        }
    }
    RowLayout{
        Layout.fillWidth: true
        Layout.minimumHeight: text_minHeight
        spacing: 6
        Text {
            Layout.preferredWidth: left_part_preferred_with
            text: qsTr("Last Ping:")
        }
        Text {
            text: m_last_ping
        }
    }
    RowLayout{
        Layout.fillWidth: true
        Layout.minimumHeight: text_minHeight
        spacing: 6
        Text {
            Layout.preferredWidth: left_part_preferred_with
            text: qsTr("Alive: ")
        }
        Text {
            text: get_alive_text()
            color: get_alive_text_color()
        }
    }
    RowLayout{
        Layout.fillWidth: true
        Layout.minimumHeight: text_minHeight
        spacing: 6
        Text {
            Layout.preferredWidth: left_part_preferred_with
            text: qsTr(m_is_ground ? "WB Card(s): " : "WB Card:")
        }
        Text {
            text: get_cards_text()
        }
    }
    RowLayout{
        Layout.fillWidth: true
        Layout.minimumHeight: text_minHeight
        spacing: 6
        visible: m_is_ground
        Text{
            Layout.preferredWidth: left_part_preferred_with
            text: "Uplink:"
        }
        Text{
            text: gnd_uplink_state_text()
            visible: {
                var gnd_up_state=gnd_uplink_state()
                if(gnd_up_state===0 || gnd_up_state===1)return true;
                return false;
            }
        }
        ButtonIconWarning{
            onClicked: {
                var message="Looks like your uplink (GND to AIR) is not functional - please use a supported card on your GND station"+
                " and make sure passive (listen only) mode is disabled on your ground station."
                _messageBoxInstance.set_text_and_show(message)
            }
            visible: gnd_uplink_state()===-1;
            Layout.preferredHeight: text_minHeight
            Layout.minimumHeight: text_minHeight
            height: text_minHeight
        }
    }

    // Padding
    Item{
        Layout.fillWidth: true
        Layout.fillHeight: true
    }
}
