import QtQuick 2.12
import QtQuick.Controls 2.12
import QtQuick.Layouts 1.12
import QtQuick.Dialogs 1.0
import QtQuick.Controls.Material 2.12

import "../../elements"

// I fucking hate writing UIs in QT
// Dialoque that is shown to the user with the option to manually change the grond station frequency.
Card {
    id: dialoqueChangeFrequency
    width: 360
    height: 340
    z: 5.0
    anchors.centerIn: parent
    cardName: qsTr("Frequency "+m_wanted_frequency+"Mhz")
    cardNameColor: "black"
    visible: false

    property int m_wanted_frequency: -1

    property int m_wanted_channel_width:-1

    // TYPE = 0 == change frequency, 1 == change channel width
    property int m_type: 0

    // Set to 1 to show the final warning message after which channel frequency or channel width are applied
    property int m_index: 0

    property string m_original_error_message: ""


    function initialize_and_show_frequency(frequency,error_message){
        m_wanted_frequency=frequency
        m_wanted_channel_width=-1
        m_type=0;
        m_index=0
        m_original_error_message=error_message;
        dialoqueChangeFrequency.visible=true
    }
    function initialize_and_show_channel_width(channel_width,error_message){
        m_wanted_channel_width=channel_width
        m_wanted_frequency=-1
        m_type=1;
        m_index=0
        m_original_error_message=error_message;
        dialoqueChangeFrequency.visible=true
    }


    property string m_info_string_frequency: "Please use the channel scan to find your air unit, then change frequency.
Otherwise, you can manually change your ground station frequency,
leaving your air unit untouched -
NOTE: BOTH CHANNEL AND CHANNEL WIDTH NEED TO MACTCH,
AS WELL AS YOUR BIND PHRASE"

    property string m_info_string_chanel_width: "Please use the channel scan to find your air unit, then change channel width (bandwidth).
Otherwise, you can manually change your ground station channel width,
leaving your air unit untouched -
NOTE: BOTH CHANNEL AND CHANNEL WIDTH NEED TO MACTCH,
AS WELL AS YOUR BIND PHRASE"

    property string m_info_ground_only: "WARNING: This changes your ground unit frequency without changing your air unit frequency !"

    property string m_last_warning_frequency: "WARNING: This changes your ground unit frequency without changing your air unit frequency !"
    property string m_last_warning_channel_width: "WARNING: This changes your ground unit channel width without changing your air unit channel width !"

    function get_card_body_string(){
        if(m_index==0){
            // In Info mode
            if(m_type==0){
                return m_original_error_message +"\n"+ m_info_string_frequency;
            }
            return m_original_error_message +"\n"+ m_info_string_chanel_width;
        }
        // In last warning mode
        if(m_type==0){
            return m_last_warning_frequency
        }
        return m_last_warning_channel_width;
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
            visible: m_index==0
            ButtonRed{
                Layout.preferredWidth: 140
                Layout.alignment: Qt.AlignLeft
                Layout.leftMargin: 12
                text:  qsTr("GND Only")
                onPressed: {
                    m_index=1
                }
            }
            ButtonGreen{
                Layout.preferredWidth: 140
                Layout.alignment: Qt.AlignRight
                Layout.rightMargin: 12
                text:  qsTr("Okay")
                onPressed: {
                    dialoqueChangeFrequency.visible=false
                }
            }
        }
         RowLayout{
            anchors.fill: parent
            visible: m_index==1
            ButtonGreen{
                Layout.preferredWidth: 140
                Layout.alignment: Qt.AlignLeft
                Layout.leftMargin: 12
                text:  qsTr("YES,GND ONLY")
                onPressed: {
                    if(m_type==0){
                        console.log("Try changing ground only to frequency "+m_wanted_frequency)
                        var result = _wbLinkSettingsHelper.change_param_ground_only_frequency(m_wanted_frequency);
                        if(result){
                            _messageBoxInstance.set_text_and_show("GND set to frequency "+m_wanted_frequency+"Mhz",3);
                            dialoqueChangeFrequency.visible=false;
                        }else{
                            _messageBoxInstance.set_text_and_show("Failed, GND busy,please try again later",3);
                        }
                    }else{
                        console.log("Try changing ground only to channel width "+m_wanted_channel_width)
                        var result = _wbLinkSettingsHelper.change_param_ground_only_channel_width(m_wanted_channel_width);
                        if(result){
                            _messageBoxInstance.set_text_and_show("GND set to channel width "+m_wanted_channel_width+"Mhz",3);
                            dialoqueChangeFrequency.visible=false;
                        }else{
                            _messageBoxInstance.set_text_and_show("Failed, GND busy,please try again later",3);
                        }
                    }
                }
            }
            ButtonRed{
                Layout.preferredWidth: 140
                Layout.alignment: Qt.AlignRight
                Layout.rightMargin: 12
                text:  qsTr("Cancel")
                onPressed: {
                    dialoqueChangeFrequency.visible=false;
                }
            }
        }
    }
}
