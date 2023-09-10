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

    property int text_minHeight: 30

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

    // Padding
    Item{
        Layout.fillWidth: true
        Layout.fillHeight: true
    }
}
