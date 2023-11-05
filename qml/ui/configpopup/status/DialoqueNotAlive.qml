import QtQuick 2.12
import QtQuick.Controls 2.12
import QtQuick.Controls.Styles 1.4
import QtQuick.Controls.Material 2.12
import QtQuick.Layouts 1.0
import QtGraphicalEffects 1.12
import Qt.labs.settings 1.0

import OpenHD 1.0

import "../../../ui" as Ui
import "../../elements"

// Dialoque that prompts the user to go to the right location if ground / air is not alive
Card {
    id: groundNotAliveDialoque
    width: 360
    height: 340
    z: 20.0
    anchors.centerIn: parent
    cardName: qsTr("QOpenHD")
    cardNameColor: "black"
    visible: false
    property int m_type: 0;

    function open_ground(){
        m_type=0;
        visible=true;
    }

    function open_air(){
        m_type=1;
        visible=true;
    }

    cardBody: Column {
        height: 200
        width: 320
        Text {
            text: {
                if(m_type==0){
                    return "You are not connected to your openhd ground station (No incoming openhd telemetry messages)";
                }
                return "You are not connected to your openhd air unit (No incoming openhd telemetry messages). Please check air unit HW and use the scan channels / frequency scan"+
                        "to find and connect to your air unit.";
            }
            width: parent.width-24
            height:parent.height
            leftPadding: 12
            rightPadding: 12
            wrapMode: Text.WordWrap
        }
    }
    hasFooter: true
    cardFooter: Item {
        anchors.fill: parent

        Button {
            width: 140
            height: 48
            anchors.left: parent.left
            anchors.leftMargin: 12
            anchors.bottom: parent.bottom
            anchors.bottomMargin: 6
            font.pixelSize: 14
            font.capitalization: Font.MixedCase
            //Material.accent: Material.Green
            highlighted: true
            text:  qsTr("OKAY")
            onPressed: {
                groundNotAliveDialoque.visible=false;
            }
        }

        Button {
            width: 140
            height: 48
            anchors.right: parent.right
            anchors.rightMargin: 12
            anchors.bottom: parent.bottom
            anchors.bottomMargin: 6
            font.pixelSize: 14
            font.capitalization: Font.MixedCase
            Material.accent: Material.Green
            highlighted: true
            text:  qsTr("TAKE ME")
            onPressed: {
                groundNotAliveDialoque.visible=false;
                if(m_type==0){
                    settings_form.user_quidance_open_connect_screen();
                }else{
                    settings_form.user_guidance_open_openhd_settings_find_air_unit_location();
                }
            }
        }
    }
}
