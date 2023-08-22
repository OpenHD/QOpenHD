import QtQuick 2.12
import QtQuick.Controls 2.12
import QtQuick.Layouts 1.12
import QtQuick.Dialogs 1.0
import QtQuick.Controls.Material 2.12

import "../../elements"

// I fucking hate writing UIs in QT
Card {
    id: dialoqueChangeFrequency
    width: 360
    height: 340
    z: 5.0
    anchors.centerIn: parent
    cardName: qsTr("Frequency "+m_wanted_frequency+"Mhz")
    cardNameColor: "black"
    visible: m_visible

    property int m_wanted_frequency: -1

    property int m_wanted_channel_width:-1

    // TYPE = 0 == change frequency, 1 == change channel width
    property int m_type: 0

    // Set to 1 to show the final warning message after which channel frequency or channel width are applied
    property int m_index: 0

    property bool m_visible: false


    function initialize_and_show_frequency(frequency){
        m_wanted_frequency=frequency
        m_wanted_channel_width=-1
        m_type=0;
        m_index=0
        m_visible=true
    }
    function initialize_and_show_channel_width(channel_width){
        m_wanted_channel_width=channel_width
        m_wanted_frequency=-1
        m_type=1;
        m_index=0
        m_visible=true
    }


    property string m_warning_str:"Looks like no air unit is connected.
Please use the channel scan to find your air unit, then change frequency.
Otherwise, you can manually change your ground station frequency,
leaving your air unit untouched -
NOTE: BOTH CHANNEL AND CHANNEL WIDTH NEED TO MACTCH,
AS WELL AS YOUR BIND PHRASE"

    property string m_info_string_frequency: "Looks like no air unit is connected.
Please use the channel scan to find your air unit, then change frequency.
Otherwise, you can manually change your ground station frequency,
leaving your air unit untouched -
NOTE: BOTH CHANNEL AND CHANNEL WIDTH NEED TO MACTCH,
AS WELL AS YOUR BIND PHRASE"

    property string m_info_string_chanel_width: "Looks like no air unit is connected.
Please use the channel scan to find your air unit, then change channel width.
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
                return m_info_string_frequency;
            }
            return m_info_string_chanel_width;
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

            Button{
                visible: m_index==0
                text:  qsTr("GND Only")
                Material.accent: Material.Red
                highlighted: true
                Layout.alignment: Qt.AlignLeft
                onPressed: {
                    m_index=1
                }
            }

            Button{
                visible: m_index==0
                text:  qsTr("Okay")
                Material.accent: Material.Green
                highlighted: true
                Layout.alignment: Qt.AlignRight
                onPressed: {
                    //
                    m_visible=false
                }
            }

            Button{
                visible: m_index==1
                text:  qsTr("YES,GND ONLY")
                Material.accent: Material.Green
                highlighted: true
                Layout.alignment: Qt.AlignRight
                onPressed: {
                    if(m_type==0){
                        console.log("Try changing ground only to frequency "+m_wanted_frequency)
                        var result = _synchronizedSettings.change_param_ground_only_frequency(m_wanted_frequency);
                        if(result){
                            _messageBoxInstance.set_text_and_show("GND set to channel frequency "+m_wanted_frequency+"Mhz",3);
                            m_visible=false;
                        }else{
                            _messageBoxInstance.set_text_and_show("Failed, GND busy,please try again later",3);
                        }
                    }else{
                        console.log("Try changing ground only to channel width "+m_wanted_channel_width)
                        var result = _synchronizedSettings.change_param_ground_only_channel_width(m_wanted_channel_width);
                        if(result){
                            _messageBoxInstance.set_text_and_show("GND set to channel width "+m_wanted_channel_width+"Mhz",3);
                            m_visible=false;
                        }else{
                            _messageBoxInstance.set_text_and_show("Failed, GND busy,please try again later",3);
                        }
                    }
                }
            }

            Button{
                visible: m_index==1
                text:  qsTr("Cancel")
                Material.accent: Material.Red
                highlighted: true
                Layout.alignment: Qt.AlignLeft
                onPressed: {
                    m_visible=false;
                }
            }
        }
    }
}
