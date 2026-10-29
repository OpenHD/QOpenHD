import "../MenuTypography.js" as MenuTypography
import QtQuick 2.12
import QtQuick.Controls 2.12
 
import QtQuick.Controls.Material 2.12
import QtQuick.Layouts 1.0

import Qt.labs.settings 1.0

import OpenHD 1.0

import "../../../ui" as Ui
import "../../elements"
import ".."

// Dialoque that prompts the user to go to the right location if ground / air is not alive
Card {
    dialogStyle: true
    id: groundNotAliveDialoque
    width: 360
    height: 340
    z: 20.0
    anchors.centerIn: parent
    cardName: qsTr("QOpenHD")
    cardNameColor: "#edf4fa"
    cardBackgroundColor: "#041d2c"
    cardFooterColor: "#041d2c"
    borderColor: "#0089c4"
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
        Text { font.family: MenuTypography.family; font.pixelSize: MenuTypography.body;
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
            color: settings_form.primaryText
        }
    }
    hasFooter: true
    cardFooter: Item {
        anchors.fill: parent

        AdvancedDialogButton {
            width: 140
            height: 48
            anchors.left: parent.left
            anchors.leftMargin: 12
            anchors.bottom: parent.bottom
            anchors.bottomMargin: 6
            font.pixelSize: MenuTypography.body; font.family: MenuTypography.family
            font.capitalization: Font.MixedCase
            //Material.accent: Material.Green
            highlighted: true
            text:  qsTr("OKAY")
            onPressed: {
                groundNotAliveDialoque.visible=false;
            }
        }

        AdvancedDialogButton {
            width: 140
            height: 48
            anchors.right: parent.right
            anchors.rightMargin: 12
            anchors.bottom: parent.bottom
            anchors.bottomMargin: 6
            font.pixelSize: MenuTypography.body; font.family: MenuTypography.family
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
