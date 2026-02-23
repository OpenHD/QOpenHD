import QtQuick 2.12
import QtQuick.Controls 2.12
import QtQuick.Layouts 1.12
import QtQuick.Shapes 1.12

import OpenHD 1.0

BaseWidget {
    id: linkOverviewWidget
    width: 320
    height: 60

    visible: settings.show_link_overview_widget && settings.show_widgets

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
    property int snr_min_db: settings.link_snr_min_db
    property int snr_max_db: settings.link_snr_max_db
    property real m_txc_temp: _ohdSystemGround.curr_txc_temp_degree_1
    property int m_packet_loss_perc: _ohdSystemGround.curr_rx_packet_loss_perc
    property string linkFont: "Quicksand"
    property string linkMonoFont: "ShareTechMono"
    property int snrBlockCount: 8
    property real snrBlockWidth: 12
    property real snrBlockHeight: 8
    property real snrBlockSkew: 4
    property var snrBlockThresholds: {
        var arr = [];
        var span = Math.max(1, snr_max_db - snr_min_db);
        var step = span / snrBlockCount;
        for (var i = 0; i < snrBlockCount; i++) {
            arr.push(snr_min_db + step * (i + 1));
        }
        return arr;
    }

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
        var span = Math.max(1, snr_max_db - snr_min_db);
        var pct = ((db - snr_min_db) / span) * 100.0;
        return Math.max(0, Math.min(100, Math.round(pct)));
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

    function int_to_string_N_chars_wide(value, n_chars) {
        var ret = "" + value;
        for (var i = ret.length; i < n_chars; i++) {
            ret = "0" + ret;
        }
        return ret;
    }

    function text_for_card(card_idx) {
        var card = _wifi_card_gnd0;
        if (card_idx == 1) card = _wifi_card_gnd1;
        if (card_idx == 2) card = _wifi_card_gnd2;
        if (card_idx == 3) card = _wifi_card_gnd3;
        var ret = "[" + (card_idx + 1) + "] " + int_to_string_N_chars_wide(card.n_received_packets_rolling, 4) + " ";
        ret += " " + int_to_string_N_chars_wide(card.packet_loss_perc, 2) + "% ";
        ret += card.curr_rx_rssi_dbm + " dBm";
        if (settings.downlink_dbm_per_card_show_multiple_antennas) {
             ret += (card.curr_rx_rssi_dbm_antenna1 + "/" + card.curr_rx_rssi_dbm_antenna2 + " dBm");
        }
        if (card.is_active_tx) {
            ret += " TX";
        }
        return ret;
    }

    function get_text_dbm() {
        var dbm = _ohdSystemGround.current_rx_rssi;
        if (dbm <= -127) {
            return "N/A";
        }
        return "" + dbm;
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
            show_background_color: true
            background_color_target: linkOverviewWidget

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
            Item {
                width: parent.width
                height: 32
                Text {
                    text: qsTr("SNR min: %1 dB").arg(settings.link_snr_min_db)
                    color: "white"
                    height: parent.height
                    font.bold: true
                    font.family: linkFont
                    font.pixelSize: detailPanelFontPixels
                    anchors.left: parent.left
                    verticalAlignment: Text.AlignVCenter
                }
                Slider {
                    orientation: Qt.Horizontal
                    from: 0
                    value: settings.link_snr_min_db
                    to: 40
                    stepSize: 1
                    height: parent.height
                    anchors.rightMargin: 0
                    anchors.right: parent.right
                    width: parent.width - 120

                    onValueChanged: {
                        var v = Math.round(value);
                        if (settings.link_snr_min_db !== v) {
                            settings.link_snr_min_db = v;
                        }
                        if (settings.link_snr_min_db >= settings.link_snr_max_db) {
                            settings.link_snr_max_db = settings.link_snr_min_db + 1;
                        }
                    }
                }
            }
            Item {
                width: parent.width
                height: 32
                Text {
                    text: qsTr("SNR max: %1 dB").arg(settings.link_snr_max_db)
                    color: "white"
                    height: parent.height
                    font.bold: true
                    font.family: linkFont
                    font.pixelSize: detailPanelFontPixels
                    anchors.left: parent.left
                    verticalAlignment: Text.AlignVCenter
                }
                Slider {
                    orientation: Qt.Horizontal
                    from: 0
                    value: settings.link_snr_max_db
                    to: 40
                    stepSize: 1
                    height: parent.height
                    anchors.rightMargin: 0
                    anchors.right: parent.right
                    width: parent.width - 120

                    onValueChanged: {
                        var v = Math.round(value);
                        if (v <= settings.link_snr_min_db) {
                            v = settings.link_snr_min_db + 1;
                        }
                        if (settings.link_snr_max_db !== v) {
                            settings.link_snr_max_db = v;
                        }
                    }
                }
            }
            Item {
                width: parent.width
                height: 28
                Text {
                    text: qsTr("GND RSSI: %1 dBm").arg(get_text_dbm())
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
                    text: qsTr("Loss: %1%").arg(m_packet_loss_perc)
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
                    text: qsTr("Pollution: %1 pps").arg(_ohdSystemGround.wb_link_curr_foreign_pps)
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
                    text: qsTr("Quality: %1%").arg(_ohdSystemGround.current_rx_signal_quality)
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
                    text: qsTr("TX: %1").arg(Number(_ohdSystemGround.wifi_tx_packets_count).toLocaleString(Qt.locale(), 'f', 0))
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
                    text: qsTr("RX: %1").arg(Number(_ohdSystemGround.wifi_rx_packets_count).toLocaleString(Qt.locale(), 'f', 0))
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
                visible: _wifi_card_gnd0.alive
                Text {
                    text: text_for_card(0)
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
                visible: _wifi_card_gnd1.alive
                Text {
                    text: text_for_card(1)
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
                visible: _wifi_card_gnd2.alive
                Text {
                    text: text_for_card(2)
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
                visible: _wifi_card_gnd3.alive
                Text {
                    text: text_for_card(3)
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
            opacity: 0.5
            property real cutXRatio: 0.80
            property color fillColor: bw_current_background_color

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
                    text: "MCS: " + (m_curr_mcs_index >= 0 ? m_curr_mcs_index : "N/A")
                    color: settings.color_text
                    font.pixelSize: 12
                    font.family: linkFont
                    x: -4
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
                        property bool isActive: snr_is_valid(m_best_snr_db) && m_best_snr_db >= snrBlockThresholds[index]
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

