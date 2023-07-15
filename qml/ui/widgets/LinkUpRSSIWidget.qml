import QtQuick 2.12
import QtQuick.Controls 2.12
import QtQuick.Layouts 1.12
import QtGraphicalEffects 1.12
import Qt.labs.settings 1.0

import OpenHD 1.0

BaseWidget {
    id: linkUpRSSIWidget
    width: 112
    height: 48

    visible: settings.show_uplink_rssi

    widgetIdentifier: "uplink_rssi_widget"
    bw_verbose_name: "UPLINK/AIR RSSI"

    defaultAlignment: 1
    defaultXOffset: 0
    defaultYOffset: 0
    defaultHCenter: false
    defaultVCenter: false

    hasWidgetDetail: true
    hasWidgetAction: true

    widgetActionHeight: 164+50

    // If openhd feature passive mode is enabled, show watermark instead
    property bool m_passive_mode: _ohdSystemGround.tx_passive_mode

    widgetDetailComponent: ScrollView {

        contentHeight: idBaseWidgetDefaultUiControlElements.height
        ScrollBar.horizontal.policy: ScrollBar.AlwaysOff
        clip: true

        BaseWidgetDefaultUiControlElements{
            id: idBaseWidgetDefaultUiControlElements
        }
    }
    widgetActionComponent: ScrollView{

        ScrollBar.horizontal.policy: ScrollBar.AlwaysOff
        clip: true

        ColumnLayout{
            width:200

            Text {
                //Layout.alignment: left
                text: "TX error/dropped: "+_ohdSystemGround.count_tx_inj_error_hint+" "+_ohdSystemGround.count_tx_dropped_packets
                color: "white"
                font.bold: true
                height: parent.height
                font.pixelSize: detailPanelFontPixels
                verticalAlignment: Text.AlignVCenter
            }
            Text {
                //Layout.alignment: left
                text: "GND TX: "+_ohdSystemGround.tx_packets_per_second_and_bits_per_second
                color: "white"
                font.bold: true
                height: parent.height
                font.pixelSize: detailPanelFontPixels
                verticalAlignment: Text.AlignVCenter
            }
            Text {
                //Layout.alignment: left
                text: "GND RX: "+_ohdSystemGround.rx_packets_per_second_and_bits_per_second
                color: "white"
                font.bold: true
                height: parent.height
                font.pixelSize: detailPanelFontPixels
                verticalAlignment: Text.AlignVCenter
            }
            /*Text {
                //Layout.alignment: left
                text: "GND RX vid0: "+_cameraStreamModelPrimary.
                color: "white"
                font.bold: true
                height: parent.height
                font.pixelSize: detailPanelFontPixels
                verticalAlignment: Text.AlignVCenter
            }*/
            Text {
                //Layout.alignment: left
                text: "GND RX tele: "+_ohdSystemAir.rx_tele_packets_per_second_and_bits_per_second
                color: "white"
                font.bold: true
                height: parent.height
                font.pixelSize: detailPanelFontPixels
                verticalAlignment: Text.AlignVCenter
            }
            Text {
                //Layout.alignment: left
                text: "TX PWR Gnd: "+_wifi_card_gnd0.tx_power;
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
            id: uplink_icon
            width: 24
            height: 24
            color: settings.color_shape
            text: "\uf382"
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
            id: uplink_rssi
            height: 24
            color: settings.color_text

            text: _ohdSystemAir.current_rx_rssi
                  <= -127 ? qsTr("N/A") : _ohdSystemAir.current_rx_rssi
            anchors.left: uplink_icon.right
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
            id: uplink_dbm
            width: 32
            height: 24
            color: settings.color_text
            text: qsTr("dBm")
            anchors.left: uplink_rssi.right
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
        ColumnLayout{
            anchors.top: uplink_rssi.bottom
            spacing:0
            Text {
                visible: true
                text: m_passive_mode ? "LISTEN ONLY" : ("Loss: " + _ohdSystemAir.curr_rx_packet_loss_perc+"%")
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
    }
}
