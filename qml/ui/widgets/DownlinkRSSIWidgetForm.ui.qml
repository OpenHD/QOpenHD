import QtQuick 2.12
import QtQuick.Controls 2.12
import QtQuick.Layouts 1.12
import QtGraphicalEffects 1.12
import Qt.labs.settings 1.0
import QtQuick.Shapes 1.0

import OpenHD 1.0

BaseWidget {
    id: downlinkRSSIWidget
    width: 96
    height: 48

    visible: settings.show_downlink_rssi

    widgetIdentifier: "downlink_rssi_widget"

    defaultAlignment: 0
    defaultXOffset: 80
    defaultYOffset: 0
    defaultHCenter: false
    defaultVCenter: false


    hasWidgetDetail: true
    widgetDetailWidth: 256
    widgetDetailHeight: 320

    widgetDetailComponent: Column {
        Connections {
            target: OpenHD
            onWifiAdapter0Changed: {
                card0text.text = Number(current_signal_dbm).toLocaleString(Qt.locale(), 'f', 0) + qsTr(" dBm");
                card0.visible = true;
                card0textlower.text = Number(current_signal_dbm).toLocaleString(Qt.locale(), 'f', 0) + qsTr(" dBm");
                card0textlower.visible = true;
            }
            onWifiAdapter1Changed: {
                card1text.text = Number(current_signal_dbm).toLocaleString(Qt.locale(), 'f', 0) + qsTr(" dBm");
                card1.visible = true;
                card1textlower.text = Number(current_signal_dbm).toLocaleString(Qt.locale(), 'f', 0) + qsTr(" dBm");
                card1textlower.visible = true;
            }
            onWifiAdapter2Changed: {
                card2text.text = Number(current_signal_dbm).toLocaleString(Qt.locale(), 'f', 0) + qsTr(" dBm");
                card2.visible = true;
                card2textlower.text = Number(current_signal_dbm).toLocaleString(Qt.locale(), 'f', 0) + qsTr(" dBm");
                card2textlower.visible = true;
            }
            onWifiAdapter3Changed: {
                card3text.text = Number(current_signal_dbm).toLocaleString(Qt.locale(), 'f', 0) + qsTr(" dBm");
                card3.visible = true;
                card3textlower.text = Number(current_signal_dbm).toLocaleString(Qt.locale(), 'f', 0) + qsTr(" dBm");
                card3textlower.visible = true;
            }
            onWifiAdapter4Changed: {
                card4text.text = Number(current_signal_dbm).toLocaleString(Qt.locale(), 'f', 0) + qsTr(" dBm");
                card4.visible = true;
                card4textlower.text = Number(current_signal_dbm).toLocaleString(Qt.locale(), 'f', 0) + qsTr(" dBm");
                card4textlower.visible = true;
            }
            onWifiAdapter5Changed: {
                card5text.text = Number(current_signal_dbm).toLocaleString(Qt.locale(), 'f', 0) + qsTr(" dBm");
                card5.visible = true;
                card5textlower.text = Number(current_signal_dbm).toLocaleString(Qt.locale(), 'f', 0) + qsTr(" dBm");
                card5textlower.visible = true;
            }
        }
        Item {
            id: card0
            visible: false
            width: parent.width
            height: 32
            Text {
                text: "Card 1:"
                color: "white"
                font.bold: true
                height: parent.height
                font.pixelSize: detailPanelFontPixels
                anchors.left: parent.left
                verticalAlignment: Text.AlignVCenter
            }
            Text {
                id: card0text
                color: "white";
                font.bold: true;
                height: parent.height
                font.pixelSize: detailPanelFontPixels;
                anchors.right: parent.right
                verticalAlignment: Text.AlignVCenter
            }
        }
        Item {
            id: card1
            visible: false
            width: parent.width
            height: 32
            Text {
                text: "Card 2:"
                color: "white"
                font.bold: true
                height: parent.height;
                font.pixelSize: detailPanelFontPixels
                anchors.left: parent.left
                verticalAlignment: Text.AlignVCenter
            }
            Text {
                id: card1text
                color: "white";
                font.bold: true;
                height: parent.height
                font.pixelSize: detailPanelFontPixels;
                anchors.right: parent.right
                verticalAlignment: Text.AlignVCenter
            }
        }

        Item {
            id: card2
            visible: false
            width: parent.width
            height: 24
            Text {
                text: "Card 3:"
                color: "white"
                font.bold: true
                height: parent.height;
                font.pixelSize: detailPanelFontPixels
                anchors.left: parent.left
                verticalAlignment: Text.AlignVCenter
            }
            Text {
                id: card2text
                color: "white";
                font.bold: true;
                height: parent.height;
                font.pixelSize: detailPanelFontPixels;
                anchors.right: parent.right
                verticalAlignment: Text.AlignVCenter
            }
        }

        Item {
            id: card3
            visible: false
            width: parent.width
            height: 24
            Text {
                text: "Card 4:"
                color: "white"
                font.bold: true
                height: parent.height
                font.pixelSize: detailPanelFontPixels
                anchors.left: parent.left
                verticalAlignment: Text.AlignVCenter
            }
            Text {
                id: card3text
                color: "white";
                font.bold: true;
                height: parent.height;
                font.pixelSize: detailPanelFontPixels;
                anchors.right: parent.right
                verticalAlignment: Text.AlignVCenter
            }
        }

        Item {
            id: card4
            visible: false
            width: parent.width
            height: 24
            Text {
                text: "Card 5:"
                color: "white"
                font.bold: true
                height: parent.height
                font.pixelSize: detailPanelFontPixels
                anchors.left: parent.left
                verticalAlignment: Text.AlignVCenter
            }
            Text {
                id: card4text
                color: "white";
                font.bold: true;
                height: parent.height;
                font.pixelSize: detailPanelFontPixels;
                anchors.right: parent.right
                verticalAlignment: Text.AlignVCenter
            }
        }

        Item {
            id: card5
            visible: false
            width: parent.width
            height: 24
            Text {
                text: "Card 6:"
                color: "white"
                font.bold: true
                height: parent.height
                font.pixelSize: detailPanelFontPixels
                anchors.left: parent.left
                verticalAlignment: Text.AlignVCenter
            }
            Text {
                id: card5text
                color: "white";
                font.bold: true;
                height: parent.height
                font.pixelSize: detailPanelFontPixels;
                anchors.right: parent.right
                verticalAlignment: Text.AlignVCenter
            }
        }


        Shape {
            id: line
            height: 32
            width: parent.width

            ShapePath {
                strokeColor: "white"
                strokeWidth: 2
                strokeStyle: ShapePath.SolidLine
                fillColor: "transparent"
                startX: 0
                startY: line.height / 2
                PathLine { x: 0;          y: line.height / 2 }
                PathLine { x: line.width; y: line.height / 2 }
            }
        }

        Item {
            width: parent.width
            height: 32
            Text {
                text: "Lost:"
                color: "white"
                font.bold: true
                height: parent.height
                font.pixelSize: detailPanelFontPixels
                anchors.left: parent.left
                verticalAlignment: Text.AlignVCenter
            }
            Text {
                text: Number(OpenHD.lost_packet_cnt).toLocaleString(Qt.locale(), 'f', 0) + qsTr(" (%L1%)").arg(OpenHD.lost_packet_percent);
                color: "white";
                font.bold: true;
                height: parent.height
                font.pixelSize: detailPanelFontPixels;
                anchors.right: parent.right
                verticalAlignment: Text.AlignVCenter
            }
        }
        Item {
            width: parent.width
            height: 32
            Text {
                text: "Damaged:"
                color: "white"
                font.bold: true
                height: parent.height
                font.pixelSize: detailPanelFontPixels
                anchors.left: parent.left
                verticalAlignment: Text.AlignVCenter
            }
            Text {
                text: Number(OpenHD.damaged_block_cnt).toLocaleString(Qt.locale(), 'f', 0) + qsTr(" (%L1%)").arg(OpenHD.damaged_block_percent);
                color: "white";
                font.bold: true;
                height: parent.height
                font.pixelSize: detailPanelFontPixels;
                anchors.right: parent.right
                verticalAlignment: Text.AlignVCenter
            }
        }
        Item {
            width: parent.width
            height: 32
            Text {
                text: "CTS:"
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

        Shape {
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
        Item {
            width: parent.width
            height: 32
            Text {
                id: opacityTitle
                text: "Transparency"
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
                text: "Show lost/damaged on OSD"
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
                anchors.rightMargin: 12
                anchors.right: parent.right
                checked: settings.downlink_rssi_showall
                onCheckedChanged: settings.downlink_rssi_showall = checked
            }
        }


        Item {
            width: parent.width
            height: 32
            Text {
                text: "Show all cards to right"
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
                anchors.rightMargin: 12
                anchors.right: parent.right
                checked: settings.downlink_cards_right
                onCheckedChanged: settings.downlink_cards_right = checked
            }
        }


    }

    Item {
        id: widgetInner

        anchors.fill: parent

        opacity: settings.downlink_rssi_opacity

        Text {
            id: downlink_icon
            y: 0
            width: 24
            height: 48
            color: settings.color_shape
            text: "\uf381"
            anchors.left: parent.left
            anchors.leftMargin: -2
            verticalAlignment: Text.AlignVCenter
            font.family: "Font Awesome 5 Free"
            styleColor: "#f7f7f7"
            font.pixelSize: 18
            horizontalAlignment: Text.AlignRight
        }

        Text {
            id: primary_radio_dbm
            width: 32
            height: 24
            color: settings.color_text
            text: "dBm"
            anchors.left: downlink_rssi.right
            anchors.leftMargin: 2
            anchors.verticalCenter: downlink_rssi.verticalCenter
            verticalAlignment: Text.AlignTop
            font.pixelSize: 12
            horizontalAlignment: Text.AlignLeft
            wrapMode: Text.NoWrap
            elide: Text.ElideRight
            clip: false
        }

        Text {
            id: downlink_rssi
            width: 42
            height: 48
            color: settings.color_text

            text: OpenHD.downlink_rssi == -127 ? qsTr("N/A") : OpenHD.downlink_rssi
            anchors.left: downlink_icon.right
            anchors.leftMargin: 0
            anchors.top: parent.top
            anchors.topMargin: 0
            verticalAlignment: Text.AlignVCenter
            font.pixelSize: 18
            horizontalAlignment: Text.AlignRight
            wrapMode: Text.NoWrap
            elide: Text.ElideRight
            clip: true
        }

        Text {
            id: extra_text
            visible: settings.downlink_rssi_showall ? true : false
            text: "D: " + Number(OpenHD.damaged_block_cnt).toLocaleString(Qt.locale(), 'f', 0) + qsTr(" (%L1%)").arg(OpenHD.damaged_block_percent);
            color: settings.color_text
            anchors.top: downlink_rssi.bottom
            anchors.topMargin: -12
            anchors.left: parent.left
            verticalAlignment: Text.AlignVCenter
            font.pixelSize: 12
            horizontalAlignment: Text.AlignLeft
            wrapMode: Text.NoWrap
            elide: Text.ElideRight
        }

        Text {
            visible: settings.downlink_rssi_showall ? true : false
            text: "L: " + Number(OpenHD.lost_packet_cnt).toLocaleString(Qt.locale(), 'f', 0) + qsTr(" (%L1%)").arg(OpenHD.lost_packet_percent);
            color: settings.color_text
            anchors.top: extra_text.bottom
            anchors.topMargin: 0
            anchors.left: extra_text.left
            verticalAlignment: Text.AlignVCenter
            font.pixelSize: 12
            horizontalAlignment: Text.AlignLeft
            wrapMode: Text.NoWrap
            elide: Text.ElideRight
        }

        Column {
            anchors.left: widgetInner.right
            anchors.leftMargin: 30
            anchors.top: widgetInner.top
            anchors.topMargin: 12
            width: 224
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
                    styleColor: "#f7f7f7"
                    font.pixelSize: 12
                    horizontalAlignment: Text.AlignRight
                }

                Text {
                    id: card0textlower
                    height: parent.height
                    color: settings.color_text
                    visible: false
                    verticalAlignment: Text.AlignVCenter
                    font.pixelSize: 14
                    horizontalAlignment: Text.AlignLeft
                    wrapMode: Text.NoWrap
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
                    styleColor: "#f7f7f7"
                    font.pixelSize: 12
                    horizontalAlignment: Text.AlignRight
                }

                Text {
                    id: card1textlower
                    height: parent.height
                    color: settings.color_text
                    visible: false
                    verticalAlignment: Text.AlignVCenter
                    font.pixelSize: 14
                    horizontalAlignment: Text.AlignLeft
                    wrapMode: Text.NoWrap
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
                    styleColor: "#f7f7f7"
                    font.pixelSize: 12
                    horizontalAlignment: Text.AlignRight
                }

                Text {
                    id: card2textlower
                    height: parent.height
                    color: settings.color_text
                    visible: false
                    verticalAlignment: Text.AlignVCenter
                    font.pixelSize: 14
                    horizontalAlignment: Text.AlignLeft
                    wrapMode: Text.NoWrap
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
                    styleColor: "#f7f7f7"
                    font.pixelSize: 12
                    horizontalAlignment: Text.AlignRight
                }

                Text {
                    id: card3textlower
                    height: parent.height
                    color: settings.color_text
                    visible: false
                    verticalAlignment: Text.AlignVCenter
                    font.pixelSize: 14
                    horizontalAlignment: Text.AlignLeft
                    wrapMode: Text.NoWrap
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
                    styleColor: "#f7f7f7"
                    font.pixelSize: 12
                    horizontalAlignment: Text.AlignRight
                }

                Text {
                    id: card4textlower
                    height: parent.height
                    color: settings.color_text
                    visible: false
                    verticalAlignment: Text.AlignVCenter
                    font.pixelSize: 14
                    horizontalAlignment: Text.AlignLeft
                    wrapMode: Text.NoWrap
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
                    styleColor: "#f7f7f7"
                    font.pixelSize: 12
                    horizontalAlignment: Text.AlignRight
                }

                Text {
                    id: card5textlower
                    height: parent.height
                    color: settings.color_text
                    visible: false
                    verticalAlignment: Text.AlignVCenter
                    font.pixelSize: 14
                    horizontalAlignment: Text.AlignLeft
                    wrapMode: Text.NoWrap
                }
            }
        }
    }
}
