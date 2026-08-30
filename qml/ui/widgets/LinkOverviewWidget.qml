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
    widgetActionWidth: 320

    hasWidgetDetail: true
    hasWidgetAction: true

    bw_scale_identifier: "link_overview_widget_scale"
    bw_background_color_identifier: "link_overview_widget_bg_color"
    bw_opacity_identifier: "link_overview_widget_opacity"

    property int m_curr_mcs_index: _ohdSystemAir.curr_mcs_index
    property int m_channel_width_mhz: _ohdSystemAir.curr_channel_width_mhz
    property int m_best_snr_db: get_best_snr_db()
    property int m_snr_value: get_quality_percent_value()
    property int snr_min_db: settings.link_snr_min_db
    property int snr_max_db: settings.link_snr_max_db
    property real m_air_txc_temp1: _ohdSystemAir.curr_txc_temp_degree_1
    property real m_air_txc_temp2: _ohdSystemAir.curr_txc_temp_degree_2
    property real m_gnd_txc_temp1: _ohdSystemGround.curr_txc_temp_degree_1
    property real m_gnd_txc_temp2: _ohdSystemGround.curr_txc_temp_degree_2
    property int m_packet_loss_perc: _ohdSystemGround.curr_rx_packet_loss_perc
    property bool use_calculated_quality: settings.downlink_calc_quality_enabled
    property bool use_artosyn_quality: _ohdSystemGround.artosyn_link_detected
    property real m_quality_raw: calculate_quality_raw()
    property real m_quality_smoothed: -1
    property string linkFont: "Quicksand"
    property string linkMonoFont: "ShareTechMono"
    property int snrBlockCount: 8
    property real snrBlockWidth: 12
    property real snrBlockHeight: 8
    property real snrBlockSkew: 4
    property bool useSimpleBlocks: Qt.platform.os === "android"
    property var snrBlockThresholds: {
        var arr = [];
        if (use_calculated_quality) {
            for (var i = 0; i < snrBlockCount; i++) {
                arr.push((i + 1) * 10);
            }
            return arr;
        }
        var span = Math.max(1, snr_max_db - snr_min_db);
        var step = span / snrBlockCount;
        for (var j = 0; j < snrBlockCount; j++) {
            arr.push(snr_min_db + step * (j + 1));
        }
        return arr;
    }

    function sync_shared_style_from_settings() {
        if (bw_current_scale !== settings.link_overview_widget_scale) {
            bw_current_scale = settings.link_overview_widget_scale;
        }
        if (bw_current_opacity !== settings.link_overview_widget_opacity) {
            bw_current_opacity = settings.link_overview_widget_opacity;
        }
        if (bw_current_background_color !== settings.link_overview_widget_bg_color) {
            bw_current_background_color = settings.link_overview_widget_bg_color;
        }
    }

    function bw_set_current_scale(scale) {
        if (scale <= 0 || scale >= 500) {
            console.warn("perhaps invalid widget scale");
        }
        if (bw_current_scale !== scale) {
            bw_current_scale = scale;
        }
        if (settings.link_overview_widget_scale !== scale) {
            settings.link_overview_widget_scale = scale;
        }
    }

    function bw_set_current_opacity(opacity) {
        if (opacity <= 0 || opacity > 1) {
            console.warn("perhaps invalid widget opacity");
        }
        if (bw_current_opacity !== opacity) {
            bw_current_opacity = opacity;
        }
        if (settings.link_overview_widget_opacity !== opacity) {
            settings.link_overview_widget_opacity = opacity;
        }
    }

    Connections {
        target: settings
        function onLink_overview_widget_scaleChanged() {
            if (bw_current_scale !== settings.link_overview_widget_scale) {
                bw_current_scale = settings.link_overview_widget_scale;
            }
        }
        function onLink_overview_widget_opacityChanged() {
            if (bw_current_opacity !== settings.link_overview_widget_opacity) {
                bw_current_opacity = settings.link_overview_widget_opacity;
            }
        }
        function onLink_overview_widget_bg_colorChanged() {
            if (bw_current_background_color !== settings.link_overview_widget_bg_color) {
                bw_current_background_color = settings.link_overview_widget_bg_color;
            }
        }
    }

    onM_quality_rawChanged: update_quality_smoothed()
    onUse_calculated_qualityChanged: {
        if (!use_calculated_quality) {
            m_quality_smoothed = -1;
        } else {
            update_quality_smoothed();
        }
    }
    onUse_artosyn_qualityChanged: update_quality_smoothed()
    Component.onCompleted: {
        update_quality_smoothed();
        sync_shared_style_from_settings();
    }

    function get_dbm_text() {
        var dbm = _ohdSystemGround.current_rx_rssi;
        if (dbm <= -127) {
            return "N/A";
        }
        return "" + dbm;
    }

    function is_valid_temp(value) {
        // OpenHD's legacy core-status packet uses zero when a driver cannot
        // provide a calibrated Celsius value.
        return value > 5;
    }

    function format_txc_temp(value) {
        if (!is_valid_temp(value)) {
            return "N/A";
        }
        return Math.round(value) + "C";
    }

    function get_max_air_txc_temp() {
        var max = -128;
        var temps = [m_air_txc_temp1, m_air_txc_temp2];
        for (var i = 0; i < temps.length; i++) {
            var t = temps[i];
            if (is_valid_temp(t) && t > max) {
                max = t;
            }
        }
        return max;
    }

    function get_txc_text() {
        return format_txc_temp(get_max_air_txc_temp());
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

    function clamp(value, minValue, maxValue) {
        return Math.max(minValue, Math.min(maxValue, value));
    }

    function loss_to_score(loss) {
        if (loss < 0) {
            return -1;
        }
        if (loss >= 5) {
            return 0;
        }
        var t = clamp(loss, 0, 5) / 5.0;
        return 100.0 * (1.0 - (t * t));
    }

    function snr_to_score(snr) {
        if (!snr_is_valid(snr)) {
            return -1;
        }
        var t = (snr - 5.0) / 20.0;
        t = clamp(t, 0.0, 1.0);
        return 100.0 * (t * t);
    }

    function rssi_to_score(rssi) {
        if (rssi <= -127) {
            return -1;
        }
        var t = (rssi + 92.0) / 47.0;
        t = clamp(t, 0.0, 1.0);
        return 100.0 * t;
    }

    function normalize_weight(value, fallback) {
        var v = Number(value);
        if (!isFinite(v)) {
            return fallback;
        }
        return v;
    }

    function calculate_quality_raw() {
        if (!use_calculated_quality) {
            return -1;
        }
        // OpenHD already combines Artosyn SNR and decoder errors into a
        // conservative link-margin percentage. The generic Wi-Fi weighting
        // would otherwise overstate the remaining margin when loss is zero.
        if (use_artosyn_quality) {
            var artosynQuality = _ohdSystemGround.current_rx_signal_quality;
            return artosynQuality >= 0 ? clamp(artosynQuality, 0, 100) : -1;
        }
        var lossScore = loss_to_score(m_packet_loss_perc);
        var snrScore = snr_to_score(m_best_snr_db);
        var rssiScore = rssi_to_score(_ohdSystemGround.current_rx_rssi);
        var anyValid = false;
        if (lossScore < 0) {
            lossScore = 0;
        } else {
            anyValid = true;
        }
        if (snrScore < 0) {
            snrScore = 0;
        } else {
            anyValid = true;
        }
        if (rssiScore < 0) {
            rssiScore = 0;
        } else {
            anyValid = true;
        }
        if (!anyValid) {
            return -1;
        }
        var lossWeight = normalize_weight(settings.downlink_quality_loss_weight, 0.60);
        var snrWeight = normalize_weight(settings.downlink_quality_snr_weight, 0.30);
        var rssiWeight = normalize_weight(settings.downlink_quality_rssi_weight, 0.10);
        var offset = normalize_weight(settings.downlink_quality_offset, 0.0);
        var quality = lossWeight * lossScore + snrWeight * snrScore + rssiWeight * rssiScore + offset;
        return clamp(quality, 0.0, 100.0);
    }

    function update_quality_smoothed() {
        if (!use_calculated_quality) {
            return;
        }
        var current = m_quality_raw;
        if (current < 0) {
            m_quality_smoothed = -1;
            return;
        }
        if (m_quality_smoothed < 0) {
            m_quality_smoothed = current;
            return;
        }
        if (use_artosyn_quality) {
            // The producer is already fast-down/slow-up; another EMA here
            // would delay a safety-relevant falling indication.
            m_quality_smoothed = current;
            return;
        }
        if (current < m_quality_smoothed) {
            m_quality_smoothed = (m_quality_smoothed * 0.70) + (current * 0.30);
        } else {
            m_quality_smoothed = (m_quality_smoothed * 0.90) + (current * 0.10);
        }
    }

    function get_quality_display_text() {
        if (use_calculated_quality) {
            if (m_quality_smoothed >= 0) {
                return "" + Math.round(m_quality_smoothed) + "%";
            }
            var fallback = _ohdSystemGround.current_rx_signal_quality;
            if (fallback >= 0) {
                return clamp(fallback, 0, 100) + "%";
            }
            return "N/A";
        }
        var raw = _ohdSystemGround.current_rx_signal_quality;
        if (raw >= 0) {
            return clamp(raw, 0, 100) + "%";
        }
        return "N/A";
    }

    function get_primary_link_text() {
        return get_dbm_text() + " dBm " + get_txc_text();
    }

    function get_quality_percent_value() {
        if (use_calculated_quality) {
            if (m_quality_smoothed >= 0) {
                return clamp(Math.round(m_quality_smoothed), 0, 100);
            }
            var fallback = _ohdSystemGround.current_rx_signal_quality;
            if (fallback >= 0) {
                return clamp(fallback, 0, 100);
            }
            if (snr_is_valid(m_best_snr_db)) {
                return snr_db_to_percent(m_best_snr_db);
            }
            return 0;
        }
        var raw = _ohdSystemGround.current_rx_signal_quality;
        if (raw >= 0) {
            return clamp(raw, 0, 100);
        }
        return snr_db_to_percent(m_best_snr_db);
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

    function metric_db_text(value) {
        return value > -127 ? value + " dB" : "N/A";
    }

    function metric_dbm_text(value) {
        return value > -127 ? value + " dBm" : "N/A";
    }

    function devourer_paths_text(card) {
        if (!card.rx_paths_valid) return "N/A";
        return card.rx_active_path_count + " active (0x" +
            Number(card.rx_active_path_mask).toString(16).toUpperCase() + ")";
    }

    function devourer_thermal_text(card) {
        if (!card.thermal_valid) return "N/A";
        return "raw " + card.thermal_raw + ", baseline " +
            card.thermal_baseline + ", delta " +
            (card.thermal_delta >= 0 ? "+" : "") + card.thermal_delta +
            " (" + card.card_temperature_status + ")";
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

    function get_tx_error_text() {
        return qsTr("TX hint/dropped: %1 %2")
            .arg(_ohdSystemAir.count_tx_inj_error_hint)
            .arg(_ohdSystemAir.count_tx_dropped_packets);
    }

    widgetActionComponent: ScrollView {
        contentHeight: actionColumn.implicitHeight
        ScrollBar.horizontal.policy: ScrollBar.AlwaysOff
        clip: true

        Column {
            id: actionColumn
            width: parent.width
            spacing: 2

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
                height: 28
                visible: get_best_card().devourer_quality_valid
                Text {
                    text: qsTr("Health: %1 | RX paths: %2")
                        .arg(get_best_card().devourer_link_health)
                        .arg(devourer_paths_text(get_best_card()))
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
                visible: get_best_card().devourer_quality_valid
                Text {
                    text: qsTr("EVM: %1 | Noise: %2")
                        .arg(metric_db_text(get_best_card().rx_evm_db))
                        .arg(metric_dbm_text(get_best_card().rx_noise_dbm))
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
                visible: get_best_card().rx_paths_valid
                Text {
                    text: qsTr("RSSI A1/A2: %1 / %2")
                        .arg(metric_dbm_text(get_best_card().curr_rx_rssi_dbm_antenna1))
                        .arg(metric_dbm_text(get_best_card().curr_rx_rssi_dbm_antenna2))
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
                visible: get_best_card().thermal_valid
                Text {
                    text: qsTr("GND radio thermal: %1")
                        .arg(devourer_thermal_text(get_best_card()))
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
                visible: _wifi_card_air.thermal_valid
                Text {
                    text: qsTr("AIR radio thermal: %1")
                        .arg(devourer_thermal_text(_wifi_card_air))
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
                visible: _wifi_card_air.devourer_quality_valid
                Text {
                    text: qsTr("AIR health: %1 | RX paths: %2")
                        .arg(_wifi_card_air.devourer_link_health)
                        .arg(devourer_paths_text(_wifi_card_air))
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
                visible: _wifi_card_air.devourer_quality_valid
                Text {
                    text: qsTr("AIR SNR A1/A2: %1 / %2 | EVM: %3")
                        .arg(snr_text(_wifi_card_air.rx_snr_antenna1))
                        .arg(snr_text(_wifi_card_air.rx_snr_antenna2))
                        .arg(metric_db_text(_wifi_card_air.rx_evm_db))
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
                    text: qsTr("Air TXC temp: %1 / %2")
                        .arg(format_txc_temp(m_air_txc_temp1))
                        .arg(format_txc_temp(m_air_txc_temp2))
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
                    text: qsTr("GND TXC temp: %1 / %2")
                        .arg(format_txc_temp(m_gnd_txc_temp1))
                        .arg(format_txc_temp(m_gnd_txc_temp2))
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
                    text: qsTr("Quality: %1").arg(get_quality_display_text())
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

            Rectangle {
                width: parent.width
                height: 1
                color: "#444444"
                opacity: 0.7
            }

            Text {
                text: qsTr("Debug")
                color: "white"
                font.bold: true
                font.family: linkFont
                font.pixelSize: detailPanelFontPixels
            }

            Column {
                width: parent.width
                spacing: 4

                Text {
                    text: get_tx_error_text()
                    color: "white"
                    font.bold: true
                    font.family: linkFont
                    font.pixelSize: detailPanelFontPixels
                    elide: Text.ElideRight
                    wrapMode: Text.NoWrap
                }

                RowLayout {
                    width: parent.width
                    spacing: 16

                    ColumnLayout {
                        Layout.fillWidth: true
                        spacing: 4
                        Text {
                            text: qsTr("Blocks lost: %1").arg(_cameraStreamModelPrimary.count_blocks_lost)
                            color: "white"
                            font.bold: true
                            font.family: linkFont
                            font.pixelSize: detailPanelFontPixels
                            elide: Text.ElideRight
                            wrapMode: Text.NoWrap
                        }
                        Text {
                            text: qsTr("Fragments recovered: %1").arg(_cameraStreamModelPrimary.count_fragments_recovered)
                            color: "white"
                            font.bold: true
                            font.family: linkFont
                            font.pixelSize: detailPanelFontPixels
                            elide: Text.ElideRight
                            wrapMode: Text.NoWrap
                        }
                        Text {
                            text: qsTr("AIR TX tele: %1").arg(_ohdSystemAir.tx_tele_packets_per_second_and_bits_per_second)
                            color: "white"
                            font.bold: true
                            font.family: linkFont
                            font.pixelSize: detailPanelFontPixels
                            elide: Text.ElideRight
                            wrapMode: Text.NoWrap
                        }
                        Text {
                            text: qsTr("AIR RX: %1").arg(_ohdSystemAir.rx_packets_per_second_and_bits_per_second)
                            color: "white"
                            font.bold: true
                            font.family: linkFont
                            font.pixelSize: detailPanelFontPixels
                            elide: Text.ElideRight
                            wrapMode: Text.NoWrap
                        }
                    }

                    ColumnLayout {
                        Layout.fillWidth: true
                        spacing: 4
                        Text {
                            text: qsTr("Blocks recovered: %1").arg(_cameraStreamModelPrimary.count_blocks_recovered)
                            color: "white"
                            font.bold: true
                            font.family: linkFont
                            font.pixelSize: detailPanelFontPixels
                            elide: Text.ElideRight
                            wrapMode: Text.NoWrap
                        }
                        Text {
                            text: qsTr("AIR TX: %1").arg(_ohdSystemAir.tx_packets_per_second_and_bits_per_second)
                            color: "white"
                            font.bold: true
                            font.family: linkFont
                            font.pixelSize: detailPanelFontPixels
                            elide: Text.ElideRight
                            wrapMode: Text.NoWrap
                        }
                        Text {
                            text: qsTr("AIR TX video0: %1").arg(_cameraStreamModelPrimary.air_tx_packets_per_second_and_bits_per_second)
                            color: "white"
                            font.bold: true
                            font.family: linkFont
                            font.pixelSize: detailPanelFontPixels
                            elide: Text.ElideRight
                            wrapMode: Text.NoWrap
                        }
                        Text {
                            text: qsTr("TX PWR Air: %1 %2").arg(_wifi_card_air.tx_power).arg(_wifi_card_air.tx_power_unit)
                            color: "white"
                            font.bold: true
                            font.family: linkFont
                            font.pixelSize: detailPanelFontPixels
                            elide: Text.ElideRight
                            wrapMode: Text.NoWrap
                        }
                    }
                }
            }
        }
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
                height: 32
                Text {
                    text: qsTr("Calculated Quality of Link")
                    color: "white"
                    height: parent.height
                    font.bold: true
                    font.family: linkFont
                    font.pixelSize: detailPanelFontPixels
                    anchors.left: parent.left
                    verticalAlignment: Text.AlignVCenter
                }
                Switch {
                    width: 32
                    height: parent.height
                    anchors.rightMargin: 6
                    anchors.right: parent.right
                    checked: settings.downlink_calc_quality_enabled
                    onCheckedChanged: settings.downlink_calc_quality_enabled = checked
                }
            }
            Item {
                width: parent.width
                height: 32
                visible: settings.downlink_calc_quality_enabled
                Text {
                    text: qsTr("Loss Weight: %1").arg(Number(settings.downlink_quality_loss_weight).toFixed(2))
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
                    value: settings.downlink_quality_loss_weight
                    to: 1
                    stepSize: 0.01
                    height: parent.height
                    anchors.rightMargin: 0
                    anchors.right: parent.right
                    width: parent.width - 140
                    onValueChanged: settings.downlink_quality_loss_weight = value
                }
            }
            Item {
                width: parent.width
                height: 32
                visible: settings.downlink_calc_quality_enabled
                Text {
                    text: qsTr("SNR Weight: %1").arg(Number(settings.downlink_quality_snr_weight).toFixed(2))
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
                    value: settings.downlink_quality_snr_weight
                    to: 1
                    stepSize: 0.01
                    height: parent.height
                    anchors.rightMargin: 0
                    anchors.right: parent.right
                    width: parent.width - 140
                    onValueChanged: settings.downlink_quality_snr_weight = value
                }
            }
            Item {
                width: parent.width
                height: 32
                visible: settings.downlink_calc_quality_enabled
                Text {
                    text: qsTr("RSSI Weight: %1").arg(Number(settings.downlink_quality_rssi_weight).toFixed(2))
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
                    value: settings.downlink_quality_rssi_weight
                    to: 1
                    stepSize: 0.01
                    height: parent.height
                    anchors.rightMargin: 0
                    anchors.right: parent.right
                    width: parent.width - 140
                    onValueChanged: settings.downlink_quality_rssi_weight = value
                }
            }
            Item {
                width: parent.width
                height: 32
                visible: settings.downlink_calc_quality_enabled
                Text {
                    text: qsTr("Quality Offset: %1").arg(Number(settings.downlink_quality_offset).toFixed(1))
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
                    from: -100
                    value: settings.downlink_quality_offset
                    to: 100
                    stepSize: 1
                    height: parent.height
                    anchors.rightMargin: 0
                    anchors.right: parent.right
                    width: parent.width - 140
                    onValueChanged: settings.downlink_quality_offset = value
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
                    text: qsTr("MCS: %1").arg(m_curr_mcs_index >= 0 ? m_curr_mcs_index : qsTr("N/A"))
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
                text: get_primary_link_text()
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
                    delegate: Item {
                        width: snrBlockWidth + snrBlockSkew
                        height: snrBlockHeight
                        property bool isActive: use_calculated_quality
                            ? (m_snr_value >= snrBlockThresholds[index])
                            : (snr_is_valid(m_best_snr_db) && m_best_snr_db >= snrBlockThresholds[index])
                        property color shapeColor: settings.color_shape

                        Rectangle {
                            visible: useSimpleBlocks
                            width: snrBlockWidth
                            height: snrBlockHeight
                            anchors.left: parent.left
                            anchors.bottom: parent.bottom
                            color: isActive ? shapeColor : "transparent"
                            border.width: 1
                            border.color: shapeColor
                        }

                        Shape {
                            visible: !useSimpleBlocks
                            anchors.fill: parent
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
}

