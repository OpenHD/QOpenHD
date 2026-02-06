import QtQuick 2.12
import QtQuick.Controls 2.12
import QtQuick.Layouts 1.12
import QtQuick.Shapes 1.12

import OpenHD 1.0

BaseWidget {
    id: linkOverviewWidget
    width: 320
    height: 60

    visible:true
    //visible: settings.show_link_overview_widget && settings.show_widgets

    widgetIdentifier: "link_overview_widget"
    bw_verbose_name: qsTr("LINK OVERVIEW")

    defaultAlignment: 0
    defaultXOffset: 0
    defaultYOffset: 0
    defaultHCenter: false
    defaultVCenter: false

    hasWidgetDetail: true

    property int m_curr_mcs_index: _ohdSystemAir.curr_mcs_index
    property int m_channel_width_mhz: _ohdSystemAir.curr_channel_width_mhz
    property int m_best_snr_db: get_best_snr_db()
    property int m_snr_value: snr_db_to_percent(m_best_snr_db)
    property real m_txc_temp: _ohdSystemGround.curr_txc_temp_degree_1
    property string linkFont: "Quicksand"
    property string linkMonoFont: "ShareTechMono"
    property int snrBlockCount: 8
    property real snrBlockWidth: 12
    property real snrBlockHeight: 8
    property real snrBlockSkew: 4

    function get_dbm_text() {
        var dbm = _ohdSystemGround.current_rx_rssi;
        if (dbm <= -127) {
            return "N/A";
        }
        return "" + dbm;
    }

    function get_txc_text() {
        if (m_txc_temp <= -127) {
            return "N/A";
        }
        return Math.round(m_txc_temp) + "C";
    }

    function get_channel_width_index() {
        if (m_channel_width_mhz === 10) {
            return "1";
        }
        if (m_channel_width_mhz === 20) {
            return "2";
        }
        if (m_channel_width_mhz === 40) {
            return "3";
        }
        return "N/A";
    }

    function snr_is_valid(db) {
        return db > -127;
    }

    function snr_db_to_percent(db) {
        if (!snr_is_valid(db)) {
            return 0;
        }
        return Math.max(0, Math.min(100, Math.round(db * 2)));
    }

    function best_snr_for_card(card) {
        var best = -128;
        if (snr_is_valid(card.rx_snr_antenna1)) {
            best = card.rx_snr_antenna1;
        }
        if (snr_is_valid(card.rx_snr_antenna2) && card.rx_snr_antenna2 > best) {
            best = card.rx_snr_antenna2;
        }
        return best;
    }

    function get_best_card_index() {
        var best = -128;
        var bestIdx = -1;
        var cards = [_wifi_card_gnd0, _wifi_card_gnd1, _wifi_card_gnd2, _wifi_card_gnd3];
        for (var i = 0; i < cards.length; i++) {
            var card = cards[i];
            if (!card.alive) {
                continue;
            }
            var cardBest = best_snr_for_card(card);
            if (cardBest > best) {
                best = cardBest;
                bestIdx = i;
            }
        }
        return bestIdx >= 0 ? bestIdx : 0;
    }

    function get_best_card() {
        var idx = get_best_card_index();
        if (idx === 1) return _wifi_card_gnd1;
        if (idx === 2) return _wifi_card_gnd2;
        if (idx === 3) return _wifi_card_gnd3;
        return _wifi_card_gnd0;
    }

    function get_best_snr_db() {
        var card = get_best_card();
        return best_snr_for_card(card);
    }

    function snr_text(db) {
        if (!snr_is_valid(db)) {
            return "N/A";
        }
        return db + " dB";
    }

    function get_mcs_color() {
        if (m_curr_mcs_index === 2) {
            return "green";
        }
        if (m_curr_mcs_index === 1) {
            return "yellow";
        }
        if (m_curr_mcs_index === 0) {
            return "red";
        }
        return settings.color_text;
    }

    function get_snr_blocks_text() {
        var blocks = "";
        for (var i = 0; i < 10; i++) {
            blocks += m_snr_value >= (i + 1) * 10 ? "▰" : "▱";
        }
        return blocks;
    }

    widgetDetailComponent: ScrollView {
        contentHeight: idBaseWidgetDefaultUiControlElements.height
        ScrollBar.horizontal.policy: ScrollBar.AlwaysOff
        clip: true

        BaseWidgetDefaultUiControlElements {
            id: idBaseWidgetDefaultUiControlElements
            show_transparency: false

            Item {
                width: parent.width
                height: 28
                Text {
                    text: qsTr("SNR A1/A2 (Card %1): %2 / %3")
                        .arg(get_best_card_index() + 1)
                        .arg(snr_text(get_best_card().rx_snr_antenna1))
                        .arg(snr_text(get_best_card().rx_snr_antenna2))
                    color: "white"
                    height: parent.height
                    font.bold: true
                    font.family: linkFont
                    font.pixelSize: detailPanelFontPixels
                    anchors.left: parent.left
                    verticalAlignment: Text.AlignVCenter
                }
            }
            Item {
                width: parent.width
                height: 28
                Text {
                    text: qsTr("SNR best: %1").arg(snr_text(m_best_snr_db))
                    color: "white"
                    height: parent.height
                    font.bold: true
                    font.family: linkFont
                    font.pixelSize: detailPanelFontPixels
                    anchors.left: parent.left
                    verticalAlignment: Text.AlignVCenter
                }
            }
        }
    }

    Item {
        id: widgetInner

        anchors.fill: parent
        opacity: bw_current_opacity
        scale: bw_current_scale
        clip: true

        Shape {
            id: cutRect
            anchors.fill: parent
            property real cutXRatio: 0.80
            property color fillColor: Qt.rgba(0, 0, 0, 0.5)

            ShapePath {
                strokeWidth: 0
                strokeColor: "transparent"
                fillColor: cutRect.fillColor
                startX: 0
                startY: 0
                PathLine { x: width; y: 0 }
                PathLine { x: width * cutRect.cutXRatio; y: height }
                PathLine { x: 0; y: height }
                PathLine { x: 0; y: 0 }
            }
        }


        Item {
            id: topLeftIcons
            width: ohdLogo.width
            height: ohdLogo.height
            anchors.left: parent.left
            anchors.leftMargin: 2
            anchors.top: parent.top
            anchors.topMargin: 2

            Image {
                id: ohdLogo
                source: "../../resources/ic128.png"
                width: 42
                height: 42
                fillMode: Image.PreserveAspectFit
                anchors.left: parent.left
                anchors.top: parent.top
            }

            MouseArea {
                anchors.fill: ohdLogo
                onClicked: hudOverlayGrid.open_config_popup()
            }
        }

        Item {
            id: wifiArea
            width: 48
            height: 44
            anchors.right: parent.right
            anchors.rightMargin: 55
            anchors.top: parent.top
            anchors.topMargin: 6

            Column {
                anchors.centerIn: parent
                spacing: 2
                Text {
                    text: "\uf1eb"
                    color: get_mcs_color()
                    font.pixelSize: 20
                    font.family: "Font Awesome 5 Free"
                    horizontalAlignment: Text.AlignHCenter
                    style: Text.Outline
                    styleColor: settings.color_glow
                }
                Text {
                    text: get_channel_width_index()
                    color: settings.color_text
                    font.pixelSize: 12
                    font.family: linkFont
                    horizontalAlignment: Text.AlignHCenter
                    style: Text.Outline
                    styleColor: settings.color_glow
                }
            }
        }

        RowLayout {
            id: topRow
            anchors.left: topLeftIcons.right
            anchors.leftMargin: 20
            anchors.right: wifiArea.left
            anchors.rightMargin: 6
            anchors.top: parent.top
            anchors.topMargin: 10
            height: 24
            spacing: 6

            Text {
                text: get_dbm_text() + " dBm " + get_txc_text()
                color: settings.color_text
                font.pixelSize: 16
                font.family: linkFont
                verticalAlignment: Text.AlignVCenter
                style: Text.Outline
                styleColor: settings.color_glow
            }
        }

        RowLayout {
            id: snrRow
            anchors.left: topLeftIcons.right
            anchors.leftMargin: 2
            anchors.right: parent.right
            anchors.rightMargin: 12
            anchors.bottom: parent.bottom
            anchors.bottomMargin: 12
            spacing: 2
            height: 14

            Row {
                id: snrBlocks
                spacing: snrRow.spacing
                Layout.alignment: Qt.AlignVCenter

                Repeater {
                    model: snrBlockCount
                    delegate: Shape {
                        width: snrBlockWidth + snrBlockSkew
                        height: snrBlockHeight
                        property bool isActive: m_snr_value >= (index + 1) * 10
                        property color shapeColor: settings.color_shape

                        ShapePath {
                            strokeWidth: 1
                            strokeColor: shapeColor
                            fillColor: isActive ? shapeColor : "transparent"
                            startX: 0
                            startY: height
                            PathLine { x: snrBlockSkew; y: 0 }
                            PathLine { x: snrBlockWidth + snrBlockSkew; y: 0 }
                            PathLine { x: snrBlockWidth; y: height }
                            PathLine { x: 0; y: height }
                        }
                    }
                }
            }
        }
    }
}

