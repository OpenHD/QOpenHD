import QtQuick 2.12
import QtQuick.Controls 2.12
import QtQuick.Layouts 1.12
import QtQuick.Controls.Material 2.12

import Qt.labs.settings 1.0

import OpenHD 1.0

import "../../../ui" as Ui
import "../../elements"

// TODO
Item {
    width: parent.width
    height: parent.height

    property int m_n_elements: 5;

    property int m_currently_selected_item:0;

    function takeover_visible_and_focus(){
        visible=true;
        m_currently_selected_item=0;
        set_focus_to_selected_item();
    }

    function gain_focus(){
        m_currently_selected_item=0;
       set_focus_to_selected_item();
    }

    function set_focus_to_selected_item(){
        if(m_currently_selected_item==0){
             go_back_element.focus=true;
        }else if(m_currently_selected_item==1){
            edit_frequency_element.focus=true;
        }else if(m_currently_selected_item==2){
            edit_channel_width_element.focus=true;
        }else if(m_currently_selected_item==3){
            edit_rate_element.focus=true;
        }else if(m_currently_selected_item==4){
            edit_resolution_element.focus=true;
        }
    }

    function set_focus_next_element(up){
        if(up){
            m_currently_selected_item--;
        }else{
            m_currently_selected_item++;
        }
        // loop around
        if(m_currently_selected_item>=m_n_elements)m_currently_selected_item=0;
        if(m_currently_selected_item<0)m_currently_selected_item=m_n_elements-1;
        set_focus_to_selected_item();
    }

    Keys.onPressed: (event)=> {
                        console.log("Panel Quick key was pressed:"+event);
                        if(event.key==Qt.Key_Up){
                            set_focus_next_element(true);
                        }else if (event.key == Qt.Key_Down) {
                            set_focus_next_element(false);
                        }else if(event.key == Qt.Key_Left){
                            // X
                            if(m_currently_selected_item==4){
                                // Go back

                            }
                        }else if(event.key == Qt.Key_Right){
                            //
                        }
                    }

    Column{
        width: parent.width
        //anchors.top: parent.top
        anchors.left: parent.left
        anchors.leftMargin: 50
        anchors.bottom: parent.bottom
        anchors.bottomMargin: 50

        InfoElement{
            m_left_text: "DOWNLINK:"
            m_right_text: {
                if(!_ohdSystemAir.is_alive){
                    m_use_red=true;
                    return "AIR NOT ALIVE";
                }
                if(!_ohdSystemGround.is_alive){
                    m_use_red=true;
                    return "N/A (NO GND)"
                }
                const loss_down = _ohdSystemGround.curr_rx_packet_loss_perc;
                if(loss_down>=8){
                    m_use_red=true;
                    return "BAD - LOSS: "+loss_down+"%"
                }
                m_use_red=false;
                return "GOOD, LOSS: "+loss_down+"%";
            }
        }
        InfoElement{
            m_left_text: "UPLINK:"
            m_right_text: {
                if(!_ohdSystemAir.is_alive){
                    m_use_red=true;
                    return "N/A (NO AIR)"
                }
                const loss_up=_ohdSystemAir.curr_rx_packet_loss_perc
                if(loss_up>50){
                    m_use_red=true;
                    return "BAD - LOSS: "+loss_up+"%";
                }
                m_use_red=false;
                return "GOOD - LOSS: "+loss_up+"%";
            }
        }
    }


    Column{
        anchors.centerIn: parent
        id: middle_element
        width: 200

        GoBackElement{
            id: go_back_element
        }

        EditFrequencyElement{
            id: edit_frequency_element
        }

        EditChannelWidthElement{
            id: edit_channel_width_element
        }

        EditRateElement{
            id: edit_rate_element
        }

        EditResolutionElement{
            id: edit_resolution_element
        }

    }

}
