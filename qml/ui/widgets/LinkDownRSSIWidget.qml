import QtQuick 2.12
import QtQuick.Controls 2.12
import QtQuick.Layouts 1.12
import QtGraphicalEffects 1.12
import Qt.labs.settings 1.0
import QtQuick.Shapes 1.0

import OpenHD 1.0

import "../../ui" as Ui
import "../../ui/elements"
import "../elements"

BaseWidget {
    id: linkDownRSSIWidget
    width: 112
    height: 48

    visible: settings.show_downlink_rssi

    widgetIdentifier: "downlink_rssi_widget"
    bw_verbose_name: "DOWNLINK/GND RSSI"

    defaultAlignment: 0
    defaultXOffset: 80
    defaultYOffset: 0
    defaultHCenter: false
    defaultVCenter: false


    hasWidgetDetail: true
    hasWidgetAction: true

    widgetActionHeight: 164+50+30

    property int m_packet_loss_perc : _ohdSystemGround.curr_rx_packet_loss_perc
    function get_packet_loss_perc_warning_level(){
        if (m_packet_loss_perc>= settings.downlink_packet_loss_perc_warn) {
            return 2;
        }
        if (m_packet_loss_perc>= settings.downlink_packet_loss_perc_caution) {
            return 1;
        }
        return 0;
    }

    function int_to_string_N_chars_wide(value,n_chars){
        var ret=""+value;
        for(var i=ret.length;i<n_chars;i++){
            ret="0"+ret;
        }
        return ret;
    }

    function warning_level_to_color(level){
        if(level===2)return settings.color_warn;
        if(level===1)return settings.color_caution;
        return settings.color_shape;
    }

    function text_for_card(card_idx){
        var card=_wifi_card_gnd0;
        if(card_idx==1)card=_wifi_card_gnd1;
        if(card_idx==2)card=_wifi_card_gnd2;
        if(card_idx==3)card=_wifi_card_gnd3;
        // use rolling to not pollute the UI too much
        var ret="["+(card_idx+1)+"] " + int_to_string_N_chars_wide(card.n_received_packets_rolling,4) + " ";
        ret+=" "+ int_to_string_N_chars_wide(card.packet_loss_perc,2)+"% "
        // Number(card.packet_loss_perc).toLocaleString( Qt.locale(), 'f', 0)
        // dBm of card in general
        ret += card.curr_rx_rssi_dbm + " dBm";
        if(settings.downlink_dbm_per_card_show_multiple_antennas){
             ret+=(card.curr_rx_rssi_dbm_antenna1+"/"+card.curr_rx_rssi_dbm_antenna2+" dBm");
        }
        /*var dbm_antenna2=card.curr_rx_rssi_dbm_antenna2;
        var show_2_antenna_dbm_values=settings.downlink_dbm_per_card_show_multiple_antennas && dbm_antenna2>-127;
        if(show_2_antenna_dbm_values){
            ret+=(card.curr_rx_rssi_dbm_antenna1+"/"+dbm_antenna2+" dBm");
        }else{
            ret += card.curr_rx_rssi_dbm_antenna1 + " dBm";
        }*/
        if(card.is_active_tx){
            ret +=" TX"
        }
        return ret;
    }

    function get_text_dbm(){
        var dbm=_ohdSystemGround.current_rx_rssi;
        if(dbm<=-127){
            return "N/A";
        }
        return ""+dbm;
    }
    function get_dbm_text_color(){
        var warning_level=_ohdSystemGround.dbm_too_low_warning;
        if(settings.downlink_dbm_warning && warning_level==2){
            return "red";
        }
        if(settings.downlink_dbm_warning && warning_level==1){
            return "orange";
        }
        return settings.color_text;
    }

    function get_tx_error_text(){
        return "TX hint/dropped: "+_ohdSystemAir.count_tx_inj_error_hint+" "+_ohdSystemAir.count_tx_dropped_packets
    }

    //----------------------------- DETAIL BELOW ----------------------------------

    widgetDetailComponent: ScrollView {

        contentHeight: idBaseWidgetDefaultUiControlElements.height
        ScrollBar.horizontal.policy: ScrollBar.AlwaysOff
        clip: true

        BaseWidgetDefaultUiControlElements{
            id: idBaseWidgetDefaultUiControlElements

            Item {
                width: parent.width
                height: 32
                Text {
                    text: qsTr("Show stats per card")
                    color: "white"
                    height: parent.height
                    font.bold: true
                    font.pixelSize: detailPanelFontPixels;
                    anchors.left: parent.left
                    verticalAlignment: Text.AlignVCenter
                }
                Switch {
                    width: 32
                    height: parent.height
                    anchors.rightMargin: 6
                    anchors.right: parent.right
                    checked: settings.downlink_show_dbm_and_packets_per_card
                    onCheckedChanged: settings.downlink_show_dbm_and_packets_per_card = checked
                }
            }
            Item {
                width: parent.width
                height: 32
                Text {
                    text: qsTr("dBm of each ant/card")
                    color: "white"
                    height: parent.height
                    font.bold: true
                    font.pixelSize: detailPanelFontPixels;
                    anchors.left: parent.left
                    verticalAlignment: Text.AlignVCenter
                }
                Switch {
                    width: 32
                    height: parent.height
                    anchors.rightMargin: 6
                    anchors.right: parent.right
                    checked: settings.downlink_dbm_per_card_show_multiple_antennas
                    onCheckedChanged: settings.downlink_dbm_per_card_show_multiple_antennas = checked
                }
            }

            Item {
                width: parent.width
                height: 32
                Text {
                    text: qsTr("Loss caution")
                    color: "white"
                    height: parent.height
                    font.bold: true
                    font.pixelSize: detailPanelFontPixels
                    anchors.left: parent.left
                    verticalAlignment: Text.AlignVCenter
                }
                Slider {
                    orientation: Qt.Horizontal
                    from: 0
                    value: settings.downlink_packet_loss_perc_caution
                    to: 100
                    stepSize: .1
                    height: parent.height
                    anchors.rightMargin: 0
                    anchors.right: parent.right
                    width: parent.width - 96

                    onValueChanged: {
                        settings.downlink_packet_loss_perc_caution = value
                    }
                }
            }
            Item {
                width: parent.width
                height: 32
                Text {
                    text: qsTr("Loss warn")
                    color: "white"
                    height: parent.height
                    font.bold: true
                    font.pixelSize: detailPanelFontPixels
                    anchors.left: parent.left
                    verticalAlignment: Text.AlignVCenter
                }
                Slider {
                    orientation: Qt.Horizontal
                    from: 0
                    value: settings.downlink_packet_loss_perc_warn
                    to: 100
                    stepSize: .1
                    height: parent.height
                    anchors.rightMargin: 0
                    anchors.right: parent.right
                    width: parent.width - 96

                    onValueChanged: {
                        settings.downlink_packet_loss_perc_warn = value
                    }
                }
            }
            Item {
                width: parent.width
                height: 32
                Text {
                    text: qsTr("dBm low warning")
                    color: "white"
                    height: parent.height
                    font.bold: true
                    font.pixelSize: detailPanelFontPixels
                    anchors.left: parent.left
                    verticalAlignment: Text.AlignVCenter
                }
                Switch {
                    width: 32
                    height: parent.height
                    anchors.rightMargin: 6
                    anchors.right: parent.right
                    checked: settings.downlink_dbm_warning
                    onCheckedChanged: settings.downlink_dbm_warning = checked
                }
            }
            Item {
                width: parent.width
                height: 32
                Text {
                    text: qsTr("Show pollution estimate %")
                    color: "white"
                    height: parent.height
                    font.bold: true
                    font.pixelSize: detailPanelFontPixels
                    anchors.left: parent.left
                    verticalAlignment: Text.AlignVCenter
                }
                Switch {
                    width: 32
                    height: parent.height
                    anchors.rightMargin: 6
                    anchors.right: parent.right
                    checked: settings.downlink_pollution_show
                    onCheckedChanged: settings.downlink_pollution_show = checked
                }
            }
            Item {
                width: parent.width
                height: 32
                Text {
                    text: qsTr("Show signal quality %")
                    color: "white"
                    height: parent.height
                    font.bold: true
                    font.pixelSize: detailPanelFontPixels
                    anchors.left: parent.left
                    verticalAlignment: Text.AlignVCenter
                }
                Switch {
                    width: 32
                    height: parent.height
                    anchors.rightMargin: 6
                    anchors.right: parent.right
                    checked: settings.downlink_signal_quality_show
                    onCheckedChanged: settings.downlink_signal_quality_show = checked
                }
            }
        }
    }
    //---------------------------ACTION WIDGET COMPONENT BELOW-----------------------------

    widgetActionComponent: ScrollView{

        ScrollBar.horizontal.policy: ScrollBar.AlwaysOff
        clip: true

        ColumnLayout{
            width:200
            Text {
                //Layout.alignment: left
                text: get_tx_error_text();
                color: "white"
                font.bold: true
                height: parent.height
                font.pixelSize: detailPanelFontPixels
                verticalAlignment: Text.AlignVCenter
            }
            Text {
                //Layout.alignment: left
                text: "Blocks lost: "+_cameraStreamModelPrimary.count_blocks_lost
                color: "white"
                font.bold: true
                height: parent.height
                font.pixelSize: detailPanelFontPixels
                verticalAlignment: Text.AlignVCenter
            }
            Text {
                //Layout.alignment: left
                text: "Blocks recovered: "+_cameraStreamModelPrimary.count_blocks_recovered;
                color: "white"
                font.bold: true
                height: parent.height
                font.pixelSize: detailPanelFontPixels
                verticalAlignment: Text.AlignVCenter
            }
            Text {
                //Layout.alignment: left
                text: "Fragments recovered: "+_cameraStreamModelPrimary.count_fragments_recovered;
                color: "white"
                font.bold: true
                height: parent.height
                font.pixelSize: detailPanelFontPixels
                verticalAlignment: Text.AlignVCenter
            }
            Text {
                //Layout.alignment: left
                text: "AIR TX: "+_ohdSystemAir.tx_packets_per_second_and_bits_per_second
                color: "white"
                font.bold: true
                height: parent.height
                font.pixelSize: detailPanelFontPixels
                verticalAlignment: Text.AlignVCenter
            }
            Text {
                //Layout.alignment: left
                text: "AIR TX tele: "+_ohdSystemAir.tx_tele_packets_per_second_and_bits_per_second;
                color: "white"
                font.bold: true
                height: parent.height
                font.pixelSize: detailPanelFontPixels
                verticalAlignment: Text.AlignVCenter
            }
            Text {
                //Layout.alignment: left
                text: "AIR TX video0: "+_cameraStreamModelPrimary.air_tx_packets_per_second_and_bits_per_second;
                color: "white"
                font.bold: true
                height: parent.height
                font.pixelSize: detailPanelFontPixels
                verticalAlignment: Text.AlignVCenter
            }
            Text {
                //Layout.alignment: left
                text: "AIR RX: "+_ohdSystemAir.rx_packets_per_second_and_bits_per_second
                color: "white"
                font.bold: true
                height: parent.height
                font.pixelSize: detailPanelFontPixels
                verticalAlignment: Text.AlignVCenter
            }
            Text {
                //Layout.alignment: left
                text: "TX PWR Air: "+_wifi_card_air.tx_power +" "+ _wifi_card_air.tx_power_unit;
                color: "white"
                font.bold: true
                height: parent.height
                font.pixelSize: detailPanelFontPixels
                verticalAlignment: Text.AlignVCenter
            }
        }
    }

    Item {
        id: widgetInner

        anchors.fill: parent
        opacity: bw_current_opacity
        scale: bw_current_scale

        Text {
            id: downlink_icon
            width: 24
            height: 24
            color: settings.color_shape
            text: "\uf381"
            anchors.left: parent.left
            anchors.leftMargin: 0
            anchors.top: parent.top
            anchors.topMargin: 0
            font.family: "Font Awesome 5 Free"
            font.pixelSize: 18
            verticalAlignment: Text.AlignVCenter
            horizontalAlignment: Text.AlignRight
            style: Text.Outline
            styleColor: settings.color_glow
        }

        Text {
            id: downlink_rssi
            height: 24
            color: get_dbm_text_color()

            text: get_text_dbm()
            anchors.left: downlink_icon.right
            anchors.leftMargin: 3
            anchors.top: parent.top
            horizontalAlignment: Text.AlignRight
            font.pixelSize: 18
            font.family: settings.font_text
            verticalAlignment: Text.AlignVCenter
            wrapMode: Text.NoWrap
            elide: Text.ElideNone
            clip: false
            style: Text.Outline
            styleColor: settings.color_glow
        }

        Text {
            id: downlink_dbm
            width: 32
            height: 24
            color: get_dbm_text_color()
            text: qsTr("dBm")
            anchors.left: downlink_rssi.right
            anchors.leftMargin: 2
            anchors.top: parent.top
            anchors.topMargin: 2
            horizontalAlignment: Text.AlignLeft
            font.pixelSize: 12
            font.family: settings.font_text
            verticalAlignment: Text.AlignTop
            wrapMode: Text.NoWrap
            elide: Text.ElideNone
            clip: false
            style: Text.Outline
            styleColor: settings.color_glow
        }

// Consti10 temporary begin - r.n we only have the n of injected and received packets per card, no FEC statistics (and the fec statistics also have changed such
// that what was displayed previosly doesn't make sense anymore
        ColumnLayout{
            anchors.top: downlink_rssi.bottom
            spacing:0
            Text {
                visible: true
                text: "Loss: " + m_packet_loss_perc+"%"
                color: warning_level_to_color(get_packet_loss_perc_warning_level())
                verticalAlignment: Text.AlignVCenter
                font.pixelSize: 12
                font.family: settings.font_text
                horizontalAlignment: Text.AlignLeft
                wrapMode: Text.NoWrap
                elide: Text.ElideRight
                style: Text.Outline
                styleColor: settings.color_glow
            }
            Text {
                visible: settings.downlink_pollution_show
                text: settings.downlink_pollution_show? ("Pollution: "+_ohdSystemGround.wb_link_curr_foreign_pps+ " pps") : ""
                color:  settings.color_text
                verticalAlignment: Text.AlignVCenter
                font.pixelSize: 12
                font.family: settings.font_text
                horizontalAlignment: Text.AlignLeft
                wrapMode: Text.NoWrap
                elide: Text.ElideRight
                style: Text.Outline
                styleColor: settings.color_glow
            }
            Text {
                visible: settings.downlink_signal_quality_show
                text: settings.downlink_signal_quality_show ? ("Quality: "+_ohdSystemGround.current_rx_signal_quality+ "%") : ""
                color:  settings.color_text
                verticalAlignment: Text.AlignVCenter
                font.pixelSize: 12
                font.family: settings.font_text
                horizontalAlignment: Text.AlignLeft
                wrapMode: Text.NoWrap
                elide: Text.ElideRight
                style: Text.Outline
                styleColor: settings.color_glow
            }
            Text {
                visible: settings.downlink_show_received_injected_packets ? true : false
                text: "TX: " + Number(_ohdSystemGround.wifi_tx_packets_count).toLocaleString(Qt.locale(), 'f', 0)
                color: settings.color_text
                verticalAlignment: Text.AlignVCenter
                font.pixelSize: 12
                font.family: settings.font_text
                horizontalAlignment: Text.AlignLeft
                wrapMode: Text.NoWrap
                elide: Text.ElideRight
                style: Text.Outline
                styleColor: settings.color_glow
            }
            Text {
                visible: settings.downlink_show_received_injected_packets ? true : false
                text: "RX: " + Number(_ohdSystemGround.wifi_rx_packets_count).toLocaleString(Qt.locale(), 'f', 0)
                color: settings.color_text
                verticalAlignment: Text.AlignVCenter
                font.pixelSize: 12
                font.family: settings.font_text
                horizontalAlignment: Text.AlignLeft
                wrapMode: Text.NoWrap
                elide: Text.ElideRight
                style: Text.Outline
                styleColor: settings.color_glow
            }
            // dBm and packets for card index 0
            Text {
                visible: settings.downlink_show_dbm_and_packets_per_card  && _wifi_card_gnd0.alive
                text: text_for_card(0)
                color: settings.color_text
                verticalAlignment: Text.AlignVCenter
                font.pixelSize: 12
                font.family: settings.font_text
                horizontalAlignment: Text.AlignLeft
                wrapMode: Text.NoWrap
                elide: Text.ElideRight
                style: Text.Outline
                styleColor: settings.color_glow
            }
            // dBm and packets for card index 1
            Text {
                visible: settings.downlink_show_dbm_and_packets_per_card  && _wifi_card_gnd1.alive
                text: text_for_card(1)
                color: settings.color_text
                verticalAlignment: Text.AlignVCenter
                font.pixelSize: 12
                font.family: settings.font_text
                horizontalAlignment: Text.AlignLeft
                wrapMode: Text.NoWrap
                elide: Text.ElideRight
                style: Text.Outline
                styleColor: settings.color_glow
            }
            // dBm and packets for card index 2
            Text {
                visible: settings.downlink_show_dbm_and_packets_per_card && _wifi_card_gnd2.alive
                text: text_for_card(2)
                color: settings.color_text
                verticalAlignment: Text.AlignVCenter
                font.pixelSize: 12
                font.family: settings.font_text
                horizontalAlignment: Text.AlignLeft
                wrapMode: Text.NoWrap
                elide: Text.ElideRight
                style: Text.Outline
                styleColor: settings.color_glow
            }
            // dBm and packets for card index 3
            Text {
                visible: settings.downlink_show_dbm_and_packets_per_card && _wifi_card_gnd3.alive
                text: text_for_card(3)
                color: settings.color_text
                verticalAlignment: Text.AlignVCenter
                font.pixelSize: 12
                font.family: settings.font_text
                horizontalAlignment: Text.AlignLeft
                wrapMode: Text.NoWrap
                elide: Text.ElideRight
                style: Text.Outline
                styleColor: settings.color_glow
            }
        }
// Consti10 temporary end
    }
}
