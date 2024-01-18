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

PopupBigGeneric{

    m_title: "STBC / LDPC (ADVANCED)"
    onCloseButtonClicked: {
        close();
    }

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

    ColumnLayout{
        id: main_layout
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.top: parent.top
        anchors.bottom: parent.bottom
        anchors.leftMargin: 10
        anchors.rightMargin: 10
        anchors.topMargin: dirty_top_margin_for_implementation

        ComboBox {
            id: comboBoxNAntennasAir
            Layout.minimumWidth: 100
            Layout.preferredWidth: 450
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
            id: comboBoxNAntennasGnd
            Layout.minimumWidth: 100
            Layout.preferredWidth: 450
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
            Layout.fillWidth: true
            Layout.preferredHeight: 40
            visible: !button_enable.enabled
            text: "CAN ONLY BE ENABLED IF BOTH AIR AND GND UNIT HAVE 2 RF PATHS / ANTENNAS";
            font.pixelSize: 14
            verticalAlignment: Qt.AlignVCenter
            horizontalAlignment: Qt.AlignLeft
            color: "white"
        }
        Text{
            id: stbc_warning_text
            text: "WARNING:\n YOU NEED TO REFLASH YOUR AIR / GROUND UNIT\nIF YOU ENABLE STBC / LDPC ON UNSUPPORTED HW";
            color: "red"
            Layout.fillWidth: true
            height: 200
            verticalAlignment: Qt.AlignVCenter
            horizontalAlignment: Qt.AlignHCenter
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
        Item{ // Filler
            Layout.row: 5
            Layout.column: 0
            Layout.columnSpan: 3
            Layout.fillWidth: true
            Layout.fillHeight: true
        }
        // ----------------
    }
}

