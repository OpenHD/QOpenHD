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


    Rectangle{
        implicitWidth: middle_element.width
        implicitHeight: middle_element.height
        color: "blue"
        opacity: 0.2;
        anchors.top: middle_element.top
        anchors.left: middle_element.left
    }

    Column{
        anchors.centerIn: parent
        id: middle_element
        BaseJoyEditElement{
            m_title: "Channel"

            m_displayed_value:{
                if(!_ohdSystemGround.is_alive)return "NO GND";
                if(_ohdSystemGround.wb_gnd_operating_mode==1){
                    return "SCANNING";
                }
                if(_ohdSystemGround.wb_gnd_operating_mode==2){
                    return "ANALYZING";
                }
                if(!_ohdSystemAir.is_alive){
                    return _wbLinkSettingsHelper.curr_channel_mhz+"@\n"+"N/A"+" Mhz";
                }
                return _wbLinkSettingsHelper.curr_channel_mhz+"\n@"+_wbLinkSettingsHelper.curr_channel_width_mhz+" Mhz";
            }
            m_is_enabled: _ohdSystemAir.is_alive && _ohdSystemGround.is_alive

            m_displayed_extra_value: {
                var loss=_ohdSystemGround.curr_rx_packet_loss_perc
                var pollution=_ohdSystemGround.wb_link_curr_foreign_pps
                if(pollution>10 || (loss > 3 && ! _fcMavlinkSystem.armed)){
                    return "! POLLUTED CHANNEL !";
                }
                return "";
            }
        }
        BaseJoyEditElement{
            m_title: "Rate"

            m_displayed_value: {
                if(!_ohdSystemAir.is_alive)return "N/A";
                const mcs_index=_ohdSystemAir.curr_mcs_index
                const channel_width=_ohdSystemAir.curr_channel_width_mhz
                if(mcs_index==2 && channel_width==40){
                    return "RACE\n40Mhz";
                }else if(mcs_index==2 && channel_width==20){
                    return "RACE\n20Mhz";
                }else if(mcs_index==1 && channel_width==20){
                    return "LONG RANGE";
                }else if(mcs_index==0 && channel_width==20){
                    return "ULTRA LONG RANGE";
                }
                return "ERROR";
            }
            m_displayed_extra_value: "";
        }
        BaseJoyEditElement{
            m_title: "Resolution"

            m_displayed_value: {
                return "FHD";
            }

            m_displayed_extra_value: "";
        }
    }

}
