import QtQuick 2.12
import QtQuick.Controls 2.12

Item {
    id: artosynDebugWidget
    width: 260
    height: 126
    anchors.top: parent.top
    anchors.right: parent.right
    anchors.topMargin: 68
    anchors.rightMargin: 10
    z: 2.1
    visible: is_artosyn_detected() && !sidebar.m_extra_is_visible

    function is_artosyn_detected() {
        return _ohdSystemAir.artosyn_link_detected
                || _ohdSystemGround.artosyn_link_detected
                || _wifi_card_air.card_type_as_string === "ARTOSYN"
                || _wifi_card_gnd0.card_type_as_string === "ARTOSYN";
    }

    function active_system() {
        if (_ohdSystemAir.is_alive) {
            return _ohdSystemAir;
        }
        return _ohdSystemGround;
    }

    function kbits_to_mbits_text(value_kbits) {
        if (value_kbits <= 0) {
            return "N/A";
        }
        var mbits = value_kbits / 1000.0;
        return Number(mbits).toLocaleString(Qt.locale(), "f", mbits < 10 ? 1 : 0) + " Mbit/s";
    }

    function mbits_text(value_mbits) {
        if (value_mbits <= 0) {
            return "N/A";
        }
        return value_mbits + " Mbit/s";
    }

    Rectangle {
        anchors.fill: parent
        color: "#A0000000"
        border.color: "#60FFFFFF"
        border.width: 1
        radius: 6
    }

    Column {
        anchors.fill: parent
        anchors.margins: 8
        spacing: 2

        Text {
            text: qsTr("Artosyn Link Debug")
            color: settings.color_text
            font.bold: true
            font.pixelSize: 13
            style: Text.Outline
            styleColor: settings.color_glow
        }

        Text {
            text: qsTr("TX MCS: %1   RX MCS: %2")
                    .arg(active_system().curr_mcs_index)
                    .arg(active_system().artosyn_rx_mcs)
            color: settings.color_text
            font.pixelSize: 12
            style: Text.Outline
            styleColor: settings.color_glow
        }

        Text {
            text: qsTr("TX Link: %1").arg(kbits_to_mbits_text(active_system().curr_bitrate_kbits))
            color: settings.color_text
            font.pixelSize: 12
            style: Text.Outline
            styleColor: settings.color_glow
        }

        Text {
            text: qsTr("RX Link: %1").arg(kbits_to_mbits_text(active_system().artosyn_rx_rate_kbits))
            color: settings.color_text
            font.pixelSize: 12
            style: Text.Outline
            styleColor: settings.color_glow
        }

        Text {
            text: qsTr("TX PHY: %1").arg(mbits_text(active_system().artosyn_tx_phy_rate_mbps))
            color: settings.color_text
            font.pixelSize: 12
            style: Text.Outline
            styleColor: settings.color_glow
        }

        Text {
            text: active_system().artosyn_debug_stats_available
                  ? qsTr("Debug: ON")
                  : qsTr("Debug: OFF (enable OpenHD debug.txt)")
            color: active_system().artosyn_debug_stats_available ? "#90EE90" : "#FFD580"
            font.pixelSize: 12
            style: Text.Outline
            styleColor: settings.color_glow
        }
    }
}
