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
    id: downlinkRSSIWidget
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


            /*            Shape {
                id: line2
                height: 32
                width: parent.width

                ShapePath {
                    strokeColor: "white"
                    strokeWidth: 2
                    strokeStyle: ShapePath.SolidLine
                    fillColor: "transparent"
                    startX: 0
                    startY: line2.height / 2
                    PathLine { x: 0;           y: line2.height / 2 }
                    PathLine { x: line2.width; y: line2.height / 2 }
                }
            }
*/
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
                    text: qsTr("Show lost/damaged")
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
                    checked: settings.downlink_rssi_show_lost_damaged
                    onCheckedChanged: settings.downlink_rssi_show_lost_damaged = checked
                }
            }


            Item {
                width: parent.width
                height: 32
                Text {
                    text: qsTr("Show all cards to right")
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
                    checked: settings.downlink_cards_right
                    onCheckedChanged: settings.downlink_cards_right = checked
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
                target: OpenHD
                function onWifiAdapter0Changed(received_packet_cnt, current_signal_dbm, signal_good) {
                    card0textlower.text = Number(current_signal_dbm).toLocaleString(Qt.locale(), 'f', 0) + qsTr(" dBm");
                    card0textlower.visible = true;
                }

                function onWifiAdapter1Changed(received_packet_cnt, current_signal_dbm, signal_good) {
                    card1textlower.text = Number(current_signal_dbm).toLocaleString(Qt.locale(), 'f', 0) + qsTr(" dBm");
                    card1textlower.visible = true;
                }

                function onWifiAdapter2Changed(received_packet_cnt, current_signal_dbm, signal_good) {
                    card2textlower.text = Number(current_signal_dbm).toLocaleString(Qt.locale(), 'f', 0) + qsTr(" dBm");
                    card2textlower.visible = true;
                }

                function onWifiAdapter3Changed(received_packet_cnt, current_signal_dbm, signal_good) {
                    card3textlower.text = Number(current_signal_dbm).toLocaleString(Qt.locale(), 'f', 0) + qsTr(" dBm");
                    card3textlower.visible = true;
                }

                function onWifiAdapter4Changed(received_packet_cnt, current_signal_dbm, signal_good) {
                    card4textlower.text = Number(current_signal_dbm).toLocaleString(Qt.locale(), 'f', 0) + qsTr(" dBm");
                    card4textlower.visible = true;
                }

                function onWifiAdapter5Changed(received_packet_cnt, current_signal_dbm, signal_good) {
                    card5textlower.text = Number(current_signal_dbm).toLocaleString(Qt.locale(), 'f', 0) + qsTr(" dBm");
                    card5textlower.visible = true;
                }
            }

            Item {
                width: parent.width
                height: 32
                Text {
                    text: qsTr("CTS:")
                    color: "white"
                    font.bold: true
                    height: parent.height
                    font.pixelSize: detailPanelFontPixels
                    anchors.left: parent.left
                    verticalAlignment: Text.AlignVCenter
                }
                Text {
                    text: OpenHD.cts
                    color: "white"
                    font.bold: true
                    height: parent.height
                    font.pixelSize: detailPanelFontPixels
                    anchors.right: parent.right
                    verticalAlignment: Text.AlignVCenter
                }
            }           
        }
        Button {
            //this is for testing the new link microservice and freq change
            visible: true
            text: "Freq Test"
            anchors.centerIn: parent

            onPressed: {
                OpenHD.setAirFREQ(5180);
                OpenHD.setGndFREQ(5180);
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

            text: OpenHD.downlink_rssi == -127 ? qsTr("N/A") : OpenHD.downlink_rssi
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

        Text {
            id: extra_text
            visible: settings.downlink_rssi_show_lost_damaged ? true : false
            text: "D: " + Number(OpenHD.damaged_block_cnt).toLocaleString(Qt.locale(), 'f', 0) + qsTr(" (%L1%)").arg(OpenHD.damaged_block_percent);
            color: settings.color_text
            anchors.top: downlink_rssi.bottom
            //anchors.topMargin: -12
            anchors.left: parent.left
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
            visible: settings.downlink_rssi_show_lost_damaged ? true : false
            text: "L: " + Number(OpenHD.lost_packet_cnt).toLocaleString(Qt.locale(), 'f', 0) + qsTr(" (%L1%)").arg(OpenHD.lost_packet_percent);
            color: settings.color_text
            anchors.top: extra_text.bottom
            anchors.topMargin: 0
            anchors.left: extra_text.left
            verticalAlignment: Text.AlignVCenter
            font.pixelSize: 12
            font.family: settings.font_text
            horizontalAlignment: Text.AlignLeft
            wrapMode: Text.NoWrap
            elide: Text.ElideRight
            style: Text.Outline
            styleColor: settings.color_glow
        }

        Column {
            anchors.left: widgetInner.right
            anchors.leftMargin: 15
            anchors.top: widgetInner.top
            anchors.topMargin: 12
            spacing: 0

            visible: settings.downlink_cards_right

            Row {
                height: 18
                spacing: 6

                Text {
                    height: parent.height
                    color: settings.color_shape
                    text: "\uf381"
                    visible: card0textlower.visible
                    verticalAlignment: Text.AlignVCenter
                    font.family: "Font Awesome 5 Free"
                    font.pixelSize: 12
                    horizontalAlignment: Text.AlignRight
                    style: Text.Outline
                    styleColor: settings.color_glow
                }

                Text {
                    id: card0textlower
                    height: parent.height
                    color: settings.color_text
                    visible: false
                    verticalAlignment: Text.AlignVCenter
                    font.pixelSize: 14
                    font.family: settings.font_text
                    horizontalAlignment: Text.AlignLeft
                    wrapMode: Text.NoWrap
                    style: Text.Outline
                    styleColor: settings.color_glow
                }
            }

            Row {
                height: 18
                spacing: 6

                Text {
                    height: parent.height
                    color: settings.color_shape
                    text: "\uf381"
                    visible: card1textlower.visible
                    verticalAlignment: Text.AlignVCenter
                    font.family: "Font Awesome 5 Free"
                    font.pixelSize: 12
                    horizontalAlignment: Text.AlignRight
                    style: Text.Outline
                    styleColor: settings.color_glow
                }

                Text {
                    id: card1textlower
                    height: parent.height
                    color: settings.color_text
                    visible: false
                    verticalAlignment: Text.AlignVCenter
                    font.pixelSize: 14
                    font.family: settings.font_text
                    horizontalAlignment: Text.AlignLeft
                    wrapMode: Text.NoWrap
                    style: Text.Outline
                    styleColor: settings.color_glow
                }
            }

            Row {
                height: 18
                spacing: 6

                Text {
                    height: parent.height
                    color: settings.color_shape
                    text: "\uf381"
                    visible: card2textlower.visible
                    verticalAlignment: Text.AlignVCenter
                    font.family: "Font Awesome 5 Free"
                    font.pixelSize: 12
                    horizontalAlignment: Text.AlignRight
                    style: Text.Outline
                    styleColor: settings.color_glow
                }

                Text {
                    id: card2textlower
                    height: parent.height
                    color: settings.color_text
                    visible: false
                    verticalAlignment: Text.AlignVCenter
                    font.pixelSize: 14
                    font.family: settings.font_text
                    horizontalAlignment: Text.AlignLeft
                    wrapMode: Text.NoWrap
                    style: Text.Outline
                    styleColor: settings.color_glow
                }
            }

            Row {
                height: 18
                spacing: 6

                Text {
                    height: parent.height
                    color: settings.color_shape
                    text: "\uf381"
                    visible: card3textlower.visible
                    verticalAlignment: Text.AlignVCenter
                    font.family: "Font Awesome 5 Free"
                    font.pixelSize: 12
                    horizontalAlignment: Text.AlignRight
                    style: Text.Outline
                    styleColor: settings.color_glow
                }

                Text {
                    id: card3textlower
                    height: parent.height
                    color: settings.color_text
                    visible: false
                    verticalAlignment: Text.AlignVCenter
                    font.pixelSize: 14
                    font.family: settings.font_text
                    horizontalAlignment: Text.AlignLeft
                    wrapMode: Text.NoWrap
                    style: Text.Outline
                    styleColor: settings.color_glow
                }
            }

            Row {
                height: 18
                spacing: 6

                Text {
                    height: parent.height
                    color: settings.color_shape
                    text: "\uf381"
                    visible: card4textlower.visible
                    verticalAlignment: Text.AlignVCenter
                    font.family: "Font Awesome 5 Free"
                    font.pixelSize: 12
                    horizontalAlignment: Text.AlignRight
                    style: Text.Outline
                    styleColor: settings.color_glow
                }

                Text {
                    id: card4textlower
                    height: parent.height
                    color: settings.color_text
                    visible: false
                    verticalAlignment: Text.AlignVCenter
                    font.pixelSize: 14
                    font.family: settings.font_text
                    horizontalAlignment: Text.AlignLeft
                    wrapMode: Text.NoWrap
                    style: Text.Outline
                    styleColor: settings.color_glow
                }
            }

            Row {
                height: 18
                spacing: 6

                Text {
                    height: parent.height
                    color: settings.color_shape
                    text: "\uf381"
                    visible: card5textlower.visible
                    verticalAlignment: Text.AlignVCenter
                    font.family: "Font Awesome 5 Free"
                    font.pixelSize: 12
                    horizontalAlignment: Text.AlignRight
                    style: Text.Outline
                    styleColor: settings.color_glow
                }

                Text {
                    id: card5textlower
                    height: parent.height
                    color: settings.color_text
                    visible: false
                    verticalAlignment: Text.AlignVCenter
                    font.pixelSize: 14
                    font.family: settings.font_text
                    horizontalAlignment: Text.AlignLeft
                    wrapMode: Text.NoWrap
                    style: Text.Outline
                    styleColor: settings.color_glow
                }
            }
        }
    }
}
