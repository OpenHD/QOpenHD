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
    property string m_qopenhd_version: "2.5.1-evo-alpha"

    function get_alive_text(){
        return m_is_alive ? "Yes" : "NOT ALIVE !"
    }
    function get_alive_text_color(){
        //return m_is_alive ? "green" : "red"
        return m_is_alive ? "green" : "black"
    }

    function get_cards_text() {
      if (!m_is_ground) {
        var airCardType = _wifi_card_air.card_type_as_string;
        airCardType = airCardType.substring(3);
        return airCardType;
      }


      // Ground
      var ret = "";

      if (_wifi_card_gnd0.alive) {
        ret += _wifi_card_gnd0.card_type_as_string;
      }
      if (_wifi_card_gnd1.alive) {
        ret += "\n" + _wifi_card_gnd1.card_type_as_string;
      }
      if (_wifi_card_gnd2.alive) {
        ret += "\n" + _wifi_card_gnd2.card_type_as_string;
      }
      if (_wifi_card_gnd3.alive) {
        ret += "\n" + _wifi_card_gnd3.card_type_as_string;
      }

      if (ret.length == 0) return "N/A";

      // Remove the first 3 characters if ret is not "N/A"
      if (ret !== "N/A") {
        ret = ret.substring(3);
      }

      return ret;
    }
    function get_gnd_active_cards(){
        var ret=0;
        if(_wifi_card_gnd0.alive) ret++;
        if(_wifi_card_gnd1.alive) ret++;
        if(_wifi_card_gnd2.alive) ret++;
        if(_wifi_card_gnd3.alive) ret++;
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
    function get_text_openhd_air_ground_version_mismatch(){
        var ret="Your version of OpenHD AIR ["+_ohdSystemAir.openhd_version+"] is incompatible with OpenHD GROUND: ["+_ohdSystemGround.openhd_version+"]"+
                "\nPlease update your AIR / GROUND unit.";
        return ret;
    }

    property int text_minHeight: 30
    property int column_preferred_height: 50

    property int left_part_preferred_with: 100

    RowLayout{
        Layout.fillWidth: true
        Layout.minimumHeight: text_minHeight
        Layout.leftMargin: 12
        spacing: 3
        Text {
            Layout.preferredWidth: left_part_preferred_with
            text: qsTr("OHD Version:")
            font.bold: true
        }
        Text {
            text: m_version
            color: "green"
            visible: !b_version_warning.visible
        }
        ButtonSimple{
            text: m_version
            id: b_version_warning
            onClicked: {
                var text_warning= m_is_ground ? get_text_qopenhd_openhd_ground_version_mismatch() : get_text_openhd_air_ground_version_mismatch()
                _messageBoxInstance.set_text_and_show(text_warning)
            }
            visible: {
                if(m_is_ground){
                    // Show if ground reported version is valid and there is a mismatch OpenHD ground / QOpenHD
                    if(_ohdSystemGround.openhd_version=="N/A"){
                        return false;
                    }
                    return _ohdSystemGround.openhd_version != m_qopenhd_version;
                }else{
                    // Show if ground and air reported version is valid and there is a mismatch
                    if(_ohdSystemGround.openhd_version=="N/A" || _ohdSystemAir.openhd_version=="N/A"){
                        return false;
                    }
                    return _ohdSystemGround.openhd_version != _ohdSystemAir.openhd_version
                }
            }
            Layout.preferredHeight: text_minHeight
            Layout.minimumHeight: text_minHeight
            height: text_minHeight
        }
    }
    RowLayout{
        Layout.fillWidth: true
        Layout.minimumHeight: text_minHeight
        Layout.leftMargin: 12
        spacing: 3
        Text {
            Layout.preferredWidth: left_part_preferred_with
            text: qsTr("Last Ping:")
            font.bold: true
        }
        Text {
            text: m_last_ping
            color: m_last_ping === "N/A" ? "#DC143C" : "green"
        }
    }
    RowLayout{
        Layout.fillWidth: true
        Layout.minimumHeight: text_minHeight
        Layout.leftMargin: 12
        spacing: 3
        Text {
            Layout.preferredWidth: left_part_preferred_with
            text: qsTr("Alive: ")
            font.bold: true
        }
        Text {
            text: get_alive_text()
            color: get_alive_text_color()
        }
    }
    RowLayout{
        Layout.fillWidth: true
        Layout.minimumHeight: text_minHeight
        Layout.leftMargin: 12
        spacing: 3
        Text {
            Layout.preferredWidth: left_part_preferred_with
            text: qsTr(m_is_ground ? "OHD Card(s): " : "OHD Card:")
            font.bold: true
        }
        ButtonSimple{
            id: b_unsupported_cards_warning
            text: {
                if(m_is_ground){
                    if(!_ohdSystemGround.is_alive){
                        return "N/A";
                    }
                    var alive_count=get_gnd_active_cards();
                    if(alive_count==0) return "WAITING";
                    if(alive_count==1) return _wifi_card_gnd0.card_type_as_string;
                    return ""+alive_count+"x ARRAY";
                }else{
                    // On air, we always have only one card
                    if(! _wifi_card_air.alive){
                        return "N/A";
                    }
                    return _wifi_card_air.card_type_as_string
                }
            }
            onClicked: {
                var show_message_card_unsupported=false;
                if(m_is_ground){
                    if(_wifi_card_gnd0.alive && !_wifi_card_gnd0.card_type_supported){
                        show_message_card_unsupported=true;
                    }
                }else{
                    if(_wifi_card_air.alive && ! _wifi_card_air.card_type_supported){
                        show_message_card_unsupported=true;
                    }
                }
                if(show_message_card_unsupported){
                    var message="Using unsupported card(s) has side effects like non-working frequency changes, no uplink gnd-air or bad range. Be warned !";
                    _messageBoxInstance.set_text_and_show(message);
                }
            }
            visible: {
                return true;
            }
            Layout.preferredHeight: text_minHeight
            Layout.minimumHeight: text_minHeight
        }
    }
    RowLayout{
        Layout.fillWidth: true
        Layout.minimumHeight: text_minHeight
        Layout.leftMargin: 12

        visible: m_is_ground
        Text{
            Layout.preferredWidth: left_part_preferred_with
            text: "Uplink:"
            font.bold: true
        }
        Text{
            text: gnd_uplink_state_text()
            color: "green"
            visible: {
                var gnd_up_state=gnd_uplink_state()
                if(gnd_up_state===0 || gnd_up_state===1)return true;
                return false;
            }
        }
        ButtonSimple{
            text: gnd_uplink_state_text()
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
    RowLayout{
        Layout.fillWidth: true
        Layout.minimumHeight: text_minHeight
        Layout.leftMargin: 12

        visible: true
        Text{
            Layout.preferredWidth: left_part_preferred_with
            text: "WiFi Hotspot:"
            font.bold: true
        }
        ButtonSimple{
            id: b_wifi_hs
            text: {
                if(!m_model.is_alive || m_model.wifi_hotspot_state<0){
                    return "N/A";
                }
                if(m_model.wifi_hotspot_state==0){
                    return "UNAVAILABLE";
                }
                if(m_model.wifi_hotspot_state==1){
                    return "DISABLED";
                }
                return "ENABLED";
            }
            onClicked: {
                if(!m_model.is_alive || m_model.wifi_hotspot_state<0){
                    return;
                }
                if(m_model.wifi_hotspot_state==0){
                    var message="To use the WiFi hotspot feature on your air / ground unit you need to use a RPI / ROCK with integrated wifi module. "
                    _messageBoxInstance.set_text_and_show(message)
                }
                if(m_model.wifi_hotspot_state==1 || m_model.wifi_hotspot_state==2){
                    var message="WiFi hotspot is automatically disabled when armed, and enabled when disarmed. To change this behaviour (discouraged) set it to either always off / always on";
                     _messageBoxInstance.set_text_and_show(message)
                }
            }
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
