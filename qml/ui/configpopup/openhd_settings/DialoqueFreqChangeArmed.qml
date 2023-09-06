import QtQuick 2.12
import QtQuick.Controls 2.12
import QtQuick.Layouts 1.12
import QtQuick.Dialogs 1.0
import QtQuick.Controls.Material 2.12

import "../../elements"

// Dialoque that is shown to the user when the FC is armed and he wants to change frequency / channel width
// Once the user clicks the warning away, proceed as if FC is not armed
Card {
    id: dialoqueFreqChangeArmed
    width: 360
    height: 340
    z: 5.0
    anchors.centerIn: parent
    cardName: get_card_title_string()
    cardNameColor: "black"
    visible: false

    property int m_wanted_frequency: -1

    property int m_wanted_channel_width:-1

    // TYPE = 0 == change frequency, 1 == change channel width
    property int m_type: 0



    function initialize_and_show_frequency(frequency){
        m_wanted_frequency=frequency
        m_wanted_channel_width=-1
        m_type=0;
        dialoqueFreqChangeArmed.visible=true
    }
    function initialize_and_show_channel_width(channel_width){
        m_wanted_channel_width=channel_width
        m_wanted_frequency=-1
        m_type=1;
        dialoqueFreqChangeArmed.visible=true
    }


    function get_card_title_string(){
        if(m_type==0)return "Frequency "+m_wanted_frequency+"Mhz"
        return "Bandwidth "+m_wanted_channel_width+"Mhz"
    }

    function get_card_body_string(){
        return "WARNING ! Changing frequency / bandwidth while armed is not recommended - while unlikely, changing them needs synchronization and therefore can fail,
after which you have to perform a channel scan to reconnect to your air unit.";
    }

    cardBody: Item{
        height: 200
        width: 320

        Text{
            width: parent.width
            height: parent.height
            leftPadding: 12
            rightPadding: 12
            wrapMode: Text.WordWrap
            text: get_card_body_string();
        }
    }
    hasFooter: true
    cardFooter: Item {
        anchors.fill: parent
        RowLayout{
            anchors.fill: parent
            ButtonRed{
                Layout.preferredWidth: 180
                Layout.alignment: Qt.AlignLeft
                Layout.leftMargin: 12
                text:  qsTr("CONTINUE ANYWAY")
                onPressed: {
                    dialoqueFreqChangeArmed.visible=false
                    // Call function from MavlinkExtraWBParamPanel
                    if(m_type==0){
                        change_frequency_or_channel_width_sync_otherwise_handle_error(m_wanted_frequency,-1,true/*ignore armed state*/)
                    }else{
                        change_frequency_or_channel_width_sync_otherwise_handle_error(-1,m_wanted_channel_width,true/*ignore armed state*/)
                    }
                }
            }
            ButtonGreen{
                Layout.preferredWidth: 140
                Layout.alignment: Qt.AlignRight
                Layout.rightMargin: 12
                text:  qsTr("Okay")
                onPressed: {
                    dialoqueFreqChangeArmed.visible=false
                }
            }
        }
    }
}

