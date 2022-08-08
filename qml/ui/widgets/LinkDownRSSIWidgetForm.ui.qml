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
    height: 24

    visible: settings.show_downlink_rssi

    widgetIdentifier: "downlink_rssi_widget"

    defaultAlignment: 0
    defaultXOffset: 80
    defaultYOffset: 0
    defaultHCenter: false
    defaultVCenter: false


    hasWidgetDetail: true
    hasWidgetAction: true

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
                    text: qsTr("Show received/injected")
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
                    checked: settings.downlink_show_received_injected_packets
                    onCheckedChanged: settings.downlink_show_received_injected_packets = checked
                }
            }

            Item {
                width: parent.width
                height: 32
                Text {
                    text: qsTr("Show current bitrate")
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
                    checked: settings.downlink_show_current_bitrate
                    onCheckedChanged: settings.downlink_show_current_bitrate = checked
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
            Connections {
                target: _ohdSystemGround
                function wifi_adapter0_changed(received_packet_cnt, current_signal_dbm, signal_good) {
                    card0textlower.text = Number(current_signal_dbm).toLocaleString(Qt.locale(), 'f', 0) + qsTr(" dBm");
                    card0textlower.visible = true;
                }

                function  wifi_adapter1_changed(received_packet_cnt, current_signal_dbm, signal_good) {
                    card1textlower.text = Number(current_signal_dbm).toLocaleString(Qt.locale(), 'f', 0) + qsTr(" dBm");
                    card1textlower.visible = true;
                }

                function  wifi_adapter2_changed(received_packet_cnt, current_signal_dbm, signal_good) {
                    card2textlower.text = Number(current_signal_dbm).toLocaleString(Qt.locale(), 'f', 0) + qsTr(" dBm");
                    card2textlower.visible = true;
                }

                function  wifi_adapter3_changed(received_packet_cnt, current_signal_dbm, signal_good) {
                    card3textlower.text = Number(current_signal_dbm).toLocaleString(Qt.locale(), 'f', 0) + qsTr(" dBm");
                    card3textlower.visible = true;
                }
            }
            Text {
                //Layout.alignment: left
                text: "TX error:"+_ohdSystemGround.total_tx_error_count
                color: "white"
                font.bold: true
                height: parent.height
                font.pixelSize: detailPanelFontPixels
                verticalAlignment: Text.AlignVCenter
            }
            Text {
                //Layout.alignment: left
                text: "Blocks lost:"+_ohdSystemGround.video_rx_blocks_lost
                color: "white"
                font.bold: true
                height: parent.height
                font.pixelSize: detailPanelFontPixels
                verticalAlignment: Text.AlignVCenter
            }
            Text {
                //Layout.alignment: left
                text: "Blocks recovered:"+_ohdSystemGround.video_rx_blocks_recovered;
                color: "white"
                font.bold: true
                height: parent.height
                font.pixelSize: detailPanelFontPixels
                verticalAlignment: Text.AlignVCenter
            }
            Text {
                //Layout.alignment: left
                text: "Rx tele:"+_ohdSystemGround.curr_incoming_tele_bitrate;
                color: "white"
                font.bold: true
                height: parent.height
                font.pixelSize: detailPanelFontPixels
                verticalAlignment: Text.AlignVCenter
            }
            Text {
                //Layout.alignment: left
                text: "Rx video:"+_ohdSystemGround.curr_incoming_video_bitrate;
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

            text: _ohdSystemGround.best_rx_rssi == -127 ? qsTr("N/A") : _ohdSystemGround.best_rx_rssi
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
            // RX (Ground in) bitrate
            Text {
                visible: settings.downlink_show_current_bitrate ? true : false
                text: _ohdSystemGround.curr_incoming_bitrate
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
