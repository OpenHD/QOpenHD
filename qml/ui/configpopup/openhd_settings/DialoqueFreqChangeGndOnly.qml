import QtQuick 2.12
import QtQuick.Controls 2.12
import QtQuick.Layouts 1.12

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
    cardName: get_card_title_string()
    cardNameColor: "black"
    visible: false

    property int m_wanted_frequency: -1
    property bool m_target_air: false

    // Set to 1 to show the final warning message after which channel frequency or channel width are applied
    property int m_index: 0

    property string m_original_error_message: ""

    function close(){
        visible=false;
        enabled=false;
    }

    function initialize_and_show_frequency(frequency,error_message,target_air){
        m_wanted_frequency=frequency
        m_target_air=target_air
        m_index=0
        m_original_error_message=error_message;
        visible=true;
        enabled=true;
    }

    property string m_info_string_frequency: m_target_air
        ? qsTr("Change the connected air unit to this frequency so it can be matched with a ground unit later.")
        : qsTr("Use channel scan to find your air unit, or change the connected ground unit manually if you already know the air frequency.")

    property string m_last_warning_frequency: m_target_air
        ? qsTr("WARNING: This changes only the air unit frequency!")
        : qsTr("WARNING: This changes only the ground unit frequency!")

    function get_card_title_string(){
        return "Frequency "+m_wanted_frequency+"Mhz"
    }

    function get_card_body_string(){
        if(m_index==0){
            // In Info mode
            return m_original_error_message +"\n"+ m_info_string_frequency;
        }
        return m_last_warning_frequency
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
            color: settings_form.primaryText
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
                text: m_target_air ? qsTr("AIR Only") : qsTr("GND Only")
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
                text: m_target_air ? qsTr("YES, AIR ONLY") : qsTr("YES, GND ONLY")
                onPressed: {
                    console.log("Try changing single unit to frequency "+m_wanted_frequency)
                    var result = m_target_air
                               ? _wbLinkSettingsHelper.change_param_air_only_frequency(m_wanted_frequency)
                               : _wbLinkSettingsHelper.change_param_ground_only_frequency(m_wanted_frequency);
                    if(result){
                        var unit = m_target_air ? qsTr("AIR") : qsTr("GND")
                        _qopenhd.show_toast(qsTr("%1 set to frequency %2 MHz").arg(unit).arg(m_wanted_frequency),false);
                        dialoqueChangeFrequency.visible=false;
                    }else{
                        _qopenhd.show_toast(qsTr("Failed, unit busy or unavailable; please try again"),true);
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
