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

    defaultAlignment: 0
    defaultXOffset: 80
    defaultYOffset: 0
    defaultHCenter: false
    defaultVCenter: false


    hasWidgetDetail: true
    hasWidgetAction: true

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

    function warning_level_to_color(level){
        if(level===2)return settings.color_warn;
        if(level===1)return settings.color_caution;
        return settings.color_shape;
    }


    //----------------------------- DETAIL BELOW ----------------------------------

    widgetDetailComponent: ScrollView{

        contentHeight: downrssiSettingsColumn.height
        ScrollBar.horizontal.policy: ScrollBar.AlwaysOff
        clip: true
        Column {
            id: downrssiSettingsColumn

            Item {
                width: parent.width
                height: 32
                Text {
                    id: opacityTitle
                    text: qsTr("Transparency")
                    color: "white"
                    height: parent.height
                    font.bold: true
                    font.pixelSize: detailPanelFontPixels
                    anchors.left: parent.left
                    verticalAlignment: Text.AlignVCenter
                }
                Slider {
                    id: downlink_rssi_opacity_Slider
                    orientation: Qt.Horizontal
                    from: .1
                    value: settings.downlink_rssi_opacity
                    to: 1
                    stepSize: .1
                    height: parent.height
                    anchors.rightMargin: 0
                    anchors.right: parent.right
                    width: parent.width - 96

                    onValueChanged: {
                        settings.downlink_rssi_opacity = downlink_rssi_opacity_Slider.value
                    }
                }
            }
            Item {
                width: parent.width
                height: 32
                Text {
                    text: qsTr("Size")
                    color: "white"
                    height: parent.height
                    font.bold: true
                    font.pixelSize: detailPanelFontPixels
                    anchors.left: parent.left
                    verticalAlignment: Text.AlignVCenter
                }
                Slider {
                    id: downlink_rssi_size_Slider
                    orientation: Qt.Horizontal
                    from: .5
                    value: settings.downlink_rssi_size
                    to: 3
                    stepSize: .1
                    height: parent.height
                    anchors.rightMargin: 0
                    anchors.right: parent.right
                    width: parent.width - 96

                    onValueChanged: {
                        settings.downlink_rssi_size = downlink_rssi_size_Slider.value
                    }
                }
            }
            Item {
                width: 230
                height: 32
                Text {
                    text: qsTr("Lock to Horizontal Center")
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
                    checked: {
                        // @disable-check M222
                        var _hCenter = settings.value(hCenterIdentifier, defaultHCenter)
                        // @disable-check M223
                        if (_hCenter === "true" || _hCenter === 1 || _hCenter === true) {
                            checked = true;
                            // @disable-check M223
                        } else {
                            checked = false;
                        }
                    }

                    onCheckedChanged: settings.setValue(hCenterIdentifier, checked)
                }
            }
            Item {
                width: 230
                height: 32
                Text {
                    text: qsTr("Lock to Vertical Center")
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
                    checked: {
                        // @disable-check M222
                        var _vCenter = settings.value(vCenterIdentifier, defaultVCenter)
                        // @disable-check M223
                        if (_vCenter === "true" || _vCenter === 1 || _vCenter === true) {
                            checked = true;
                            // @disable-check M223
                        } else {
                            checked = false;
                        }
                    }

                    onCheckedChanged: settings.setValue(vCenterIdentifier, checked)
                }
            }

            Item {
                width: parent.width
                height: 32
                Text {
                    text: qsTr("Show dBm per card")
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
                text: "TX error/dropped: "+_ohdSystemAir.count_tx_inj_error_hint+" "+_ohdSystemAir.count_tx_dropped_packets
                color: "white"
                font.bold: true
                height: parent.height
                font.pixelSize: detailPanelFontPixels
                verticalAlignment: Text.AlignVCenter
            }
            Text {
                //Layout.alignment: left
                text: "Blocks lost: "+_cameraStreamModelPrimary.video0_count_blocks_lost
                color: "white"
                font.bold: true
                height: parent.height
                font.pixelSize: detailPanelFontPixels
                verticalAlignment: Text.AlignVCenter
            }
            Text {
                //Layout.alignment: left
                text: "Blocks recovered: "+_cameraStreamModelPrimary.video0_count_blocks_recovered;
                color: "white"
                font.bold: true
                height: parent.height
                font.pixelSize: detailPanelFontPixels
                verticalAlignment: Text.AlignVCenter
            }
            Text {
                //Layout.alignment: left
                text: "Fragments recovered: "+_cameraStreamModelPrimary.video0_count_fragments_recovered;
                color: "white"
                font.bold: true
                height: parent.height
                font.pixelSize: detailPanelFontPixels
                verticalAlignment: Text.AlignVCenter
            }

            Text {
                //Layout.alignment: left
                text: "Rx video0: "+_cameraStreamModelPrimary.curr_video0_received_bitrate_with_fec;
                color: "white"
                font.bold: true
                height: parent.height
                font.pixelSize: detailPanelFontPixels
                verticalAlignment: Text.AlignVCenter
            }
            Text {
                //Layout.alignment: left
                text: "Rx tele: "+_ohdSystemGround.curr_telemetry_rx_bps;
                color: "white"
                font.bold: true
                height: parent.height
                font.pixelSize: detailPanelFontPixels
                verticalAlignment: Text.AlignVCenter
            }
            Text {
                //Layout.alignment: left
                text: "Tx tele: "+_ohdSystemGround.curr_telemetry_tx_pps;
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
        opacity: settings.downlink_rssi_opacity
        scale: settings.downlink_rssi_size

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
            color: settings.color_text

            text: _ohdSystemGround.current_rx_rssi <= -127 ? qsTr("N/A") : _ohdSystemGround.current_rx_rssi
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
            color: settings.color_text
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
                text: "[1] " + _wifi_card_gnd0.n_received_packets + " " + _wifi_card_gnd0.curr_rx_rssi_dbm + " dBm"
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
                text: "[2] "  + _wifi_card_gnd1.n_received_packets + " " + _wifi_card_gnd1.curr_rx_rssi_dbm + " dBm"
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
                text: "[3] " + _wifi_card_gnd2.n_received_packets + " " + _wifi_card_gnd2.curr_rx_rssi_dbm + " dBm"
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
                text: "[4] " + _wifi_card_gnd3.n_received_packets + " " + _wifi_card_gnd3.curr_rx_rssi_dbm + " dBm"
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
