import QtQuick 2.0

import QtQuick 2.12
import QtQuick.Controls 2.12
import QtQuick.Layouts 1.12
import QtQuick.Dialogs 1.0
import QtQuick.Controls.Material 2.12
import QtQuick.Controls.Styles 1.4

import Qt.labs.settings 1.0

import OpenHD 1.0

import "../../../ui" as Ui
import "../../elements"

Rectangle{
    id: main_background
    width: parent.width-12
    height: parent.height*2/3;
    anchors.centerIn: parent
    color: "#ADD8E6"
    border.color: "black"
    border.width: 3

    function open(){
        if(_fcMavlinkSystem.is_alive && _fcMavlinkSystem.armed){
            _qopenhd.show_toast("PLEASE DISARM FIRST");
            return;
        }
        visible=true;
        enabled=true;
    }

    function close(){
        visible=false;
        enabled=false;
    }

    ListModel{
        id: model_n_antennas_air
        ListElement {title: "AIR: PLEASE SELECT N RF PATH / ANTENNAS"; value: 0}
        ListElement {title: "AIR: 1 RF PATH / ANTENNAS"; value: 1}
        ListElement {title: "AIR: 2 RF PATHS / ANTENNAS"; value: 2}
    }
    ListModel{
        id: model_n_antennas_gnd
        ListElement {title: "GND: PLEASE SELECT N RF PATH / ANTENNAS"; value: 0}
        ListElement {title: "GND: 1 RF PATH / ANTENNAS"; value: 1}
        ListElement {title: "GND: 2 RF PATHS / ANTENNAS"; value: 2}
    }

    GridLayout{
        id: main_row_layout
        Layout.fillWidth: true
        Layout.fillHeight: true
        Layout.leftMargin: 5
        Layout.rightMargin: 5

        Text{
            id: stbc_warning_text
            Layout.row: 0
            Layout.column: 0
            text: "WARNING:\n YOU NEED TO REFLASH YOUR AIR / GROUND UNIT\nIF YOU ENABLE STBC / LDPC ON UNSUPPORTED HW";
            color: "red"
            width: main_background.width
            height: 200
            horizontalAlignment: Qt.AlignHCenter
            verticalAlignment: Qt.AlignVCenter
            font.pixelSize: 15
            wrapMode: Text.WordWrap
            SequentialAnimation {
                running: false
                loops: 3
                id: anim_warn_user_stbc
                // Expand the button
                PropertyAnimation {
                    target: stbc_warning_text
                    property: "scale"
                    to: 2.0
                    duration: 300
                    easing.type: Easing.InOutQuad
                }
                // Shrink back to normal
                PropertyAnimation {
                    target: stbc_warning_text
                    property: "scale"
                    to: 1.0
                    duration: 300
                    easing.type: Easing.InOutQuad
                }
            }
        }
        ComboBox {
            Layout.row: 1
            Layout.column: 0
            id: comboBoxNAntennasAir
            Layout.minimumWidth: 100
            Layout.preferredWidth: 350
            model: model_n_antennas_air
            textRole: "title"
            font.pixelSize: 14
            onCurrentIndexChanged: {
                if(currentIndex==2){
                    anim_warn_user_stbc.start();
                }
            }
        }
        ComboBox {
            Layout.row: 2
            Layout.column: 0
            id: comboBoxNAntennasGnd
            Layout.minimumWidth: 100
            Layout.preferredWidth: 350
            model: model_n_antennas_gnd
            textRole: "title"
            font.pixelSize: 14
            onCurrentIndexChanged: {
                if(currentIndex==2){
                    anim_warn_user_stbc.start();
                }
            }
        }
        Button{
            id: button_enable
            Layout.row: 3
            Layout.column: 0
            text: "ENABLE"
            enabled: comboBoxNAntennasAir.currentIndex==2 && comboBoxNAntennasGnd.currentIndex==2;
            font.pixelSize: 14
            onClicked: {
                if(_wbLinkSettingsHelper.set_param_stbc_ldpc_enable_air_ground()){
                    _qopenhd.show_toast("Success (STBC & LDPC set to ON on both AIR and GND)");
                    close();
                }else{
                    _qopenhd.show_toast("Something went wrong, please try again");
                }
            }
        }
        Text{
            Layout.row: 4
            Layout.column: 0
            visible: !button_enable.enabled
            text: "CAN ONLY BE ENABLED IF BOTH AIR AND GND UNIT HAVE 2 RF PATHS / ANTENNAS";
            font.pixelSize: 14
        }
        // ----------------
    }

    Button{
        text: "CLOSE"
        anchors.top: parent.top
        anchors.right: parent.right
        onClicked: {
            close()
        }
    }


}

