import QtQuick 2.12
import QtQuick.Controls 2.12
import QtQuick.Layouts 1.12

BaseWidget {
    id: artosynDebugWidget
    width: 280
    height: 148
    visible: settings.show_artosyn_debug_widget && settings.show_widgets && is_artosyn_detected()

    widgetIdentifier: "artosyn_debug_widget"
    bw_verbose_name: qsTr("ARTOSYN DEBUG")
    defaultAlignment: 1
    defaultXOffset: 8
    defaultYOffset: 258
    defaultHCenter: false
    defaultVCenter: false

    hasWidgetDetail: true
    hasWidgetAction: true
    widgetActionWidth: 560
    widgetActionHeight: 430

    property int maxSamples: 90
    property var txRateHistory: []
    property var rxRateHistory: []
    property var phyRateHistory: []
    property int groundSettingsUpdateCount: _ohdSystemGroundSettings.update_count
    property int airSettingsUpdateCount: _ohdSystemAirSettingsModel.update_count

    function settings_string_contains_artosyn(model, paramId, updateCount) {
        var unused = updateCount;
        if (!model.system_is_alive()) {
            return false;
        }
        if (!model.has_params_fetched) {
            return false;
        }
        if (!model.param_string_exists(paramId)) {
            return false;
        }
        return model.get_cached_string(paramId).indexOf("ARTOSYN") >= 0
                || model.get_cached_string(paramId).indexOf("artosyn") >= 0;
    }

    function settings_primary_link_is_artosyn(model, updateCount) {
        return settings_string_contains_artosyn(model, "PRIMARY_LINK", updateCount)
                || settings_string_contains_artosyn(model, "WIFI_IFACES", updateCount);
    }

    function ground_primary_link_is_artosyn() {
        return settings_primary_link_is_artosyn(_ohdSystemGroundSettings, groundSettingsUpdateCount);
    }

    function air_primary_link_is_artosyn() {
        return settings_primary_link_is_artosyn(_ohdSystemAirSettingsModel, airSettingsUpdateCount);
    }

    function ground_artosyn_detected() {
        return _ohdSystemGround.artosyn_link_detected
                || _ohdSystemGround.primary_link_type === 4
                || _ohdSystemGround.artosyn_debug_stats_available
                || ground_primary_link_is_artosyn()
                || _wifi_card_gnd0.card_type_as_string === "ARTOSYN";
    }

    function air_artosyn_detected() {
        return _ohdSystemAir.artosyn_link_detected
                || _ohdSystemAir.primary_link_type === 4
                || _ohdSystemAir.artosyn_debug_stats_available
                || air_primary_link_is_artosyn()
                || ground_artosyn_detected()
                || _wifi_card_air.card_type_as_string === "ARTOSYN";
    }

    function is_artosyn_detected() {
        return air_artosyn_detected()
                || ground_artosyn_detected();
    }

    function active_system() {
        if (_ohdSystemAir.is_alive) {
            return _ohdSystemAir;
        }
        return _ohdSystemGround;
    }

    function link_connected() {
        return _ohdSystemAir.curr_rx_last_packet_status_good
                || _ohdSystemGround.curr_rx_last_packet_status_good;
    }

    function kbits_to_mbits(valueKbits) {
        return valueKbits > 0 ? valueKbits / 1000.0 : 0;
    }

    function kbits_to_mbits_text(valueKbits) {
        if (valueKbits <= 0) {
            return "N/A";
        }
        var mbits = valueKbits / 1000.0;
        return Number(mbits).toLocaleString(Qt.locale(), "f", mbits < 10 ? 1 : 0) + " MBit/s";
    }

    function mbits_text(valueMbits) {
        if (valueMbits <= 0) {
            return "N/A";
        }
        return Number(valueMbits).toLocaleString(Qt.locale(), "f", valueMbits < 10 ? 1 : 0) + " MBit/s";
    }

    function pushSample(history, value) {
        var next = history.slice(0);
        next.push(Math.max(0, value));
        while (next.length > maxSamples) {
            next.shift();
        }
        return next;
    }

    function sampleRates() {
        var sys = active_system();
        txRateHistory = pushSample(txRateHistory, kbits_to_mbits(sys.curr_bitrate_kbits));
        rxRateHistory = pushSample(rxRateHistory, kbits_to_mbits(sys.artosyn_rx_rate_kbits));
        phyRateHistory = pushSample(phyRateHistory, sys.artosyn_tx_phy_rate_mbps > 0 ? sys.artosyn_tx_phy_rate_mbps : 0);
        compactGraph.requestPaint();
        actionGraph.requestPaint();
    }

    function maxHistoryValue() {
        var maxValue = 5;
        for (var i = 0; i < txRateHistory.length; i++) {
            maxValue = Math.max(maxValue,
                                txRateHistory[i] || 0,
                                rxRateHistory[i] || 0,
                                phyRateHistory[i] || 0);
        }
        return Math.ceil(maxValue);
    }

    function drawHistoryLine(ctx, history, color, maxValue, width, height, pad) {
        if (history.length < 2) {
            return;
        }
        var step = (width - 2 * pad) / Math.max(1, maxSamples - 1);
        var offset = maxSamples - history.length;
        ctx.beginPath();
        for (var i = 0; i < history.length; i++) {
            var x = pad + (offset + i) * step;
            var y = height - pad - (Math.min(history[i], maxValue) / maxValue) * (height - 2 * pad);
            if (i === 0) {
                ctx.moveTo(x, y);
            } else {
                ctx.lineTo(x, y);
            }
        }
        ctx.strokeStyle = color;
        ctx.lineWidth = 2;
        ctx.stroke();
    }

    function paintRateGraph(ctx, width, height, showLegend) {
        var pad = showLegend ? 24 : 8;
        var maxValue = maxHistoryValue();
        ctx.clearRect(0, 0, width, height);
        ctx.fillStyle = "rgba(0, 0, 0, 0.18)";
        ctx.fillRect(0, 0, width, height);
        ctx.strokeStyle = "rgba(120, 180, 255, 0.25)";
        ctx.lineWidth = 1;
        for (var i = 1; i < 4; i++) {
            var y = pad + i * (height - 2 * pad) / 4;
            ctx.beginPath();
            ctx.moveTo(pad, y);
            ctx.lineTo(width - pad, y);
            ctx.stroke();
        }
        drawHistoryLine(ctx, phyRateHistory, "#ffffff", maxValue, width, height, pad);
        drawHistoryLine(ctx, txRateHistory, "#05ff00", maxValue, width, height, pad);
        drawHistoryLine(ctx, rxRateHistory, "#ffcc00", maxValue, width, height, pad);
        if (showLegend) {
            ctx.fillStyle = "#ffffff";
            ctx.font = "12px sans-serif";
            ctx.fillText(maxValue + " MBit/s", pad, 14);
            ctx.fillStyle = "#05ff00";
            ctx.fillText("TX link", pad, height - 7);
            ctx.fillStyle = "#ffcc00";
            ctx.fillText("RX link", pad + 72, height - 7);
            ctx.fillStyle = "#ffffff";
            ctx.fillText("TX PHY", pad + 150, height - 7);
        }
    }

    Component.onCompleted: sampleRates()

    Timer {
        interval: 1000
        repeat: true
        running: artosynDebugWidget.visible
        onTriggered: sampleRates()
    }

    widgetDetailComponent: ScrollView {
        contentHeight: idBaseWidgetDefaultUiControlElements.height
        ScrollBar.horizontal.policy: ScrollBar.AlwaysOff
        clip: true

        BaseWidgetDefaultUiControlElements {
            id: idBaseWidgetDefaultUiControlElements
        }
    }

    widgetActionComponent: ScrollView {
        contentHeight: actionColumn.height
        ScrollBar.horizontal.policy: ScrollBar.AlwaysOff
        clip: true

        ColumnLayout {
            id: actionColumn
            width: 524
            spacing: 8

            Text {
                text: qsTr("ARTOSYN DEBUG")
                color: "#ff05ff00"
                font.bold: true
                font.pixelSize: 14
                Layout.fillWidth: true
                elide: Text.ElideRight
            }

            Canvas {
                id: actionGraph
                Layout.fillWidth: true
                Layout.preferredHeight: 170
                onPaint: artosynDebugWidget.paintRateGraph(getContext("2d"), width, height, true)
            }

            GridLayout {
                Layout.fillWidth: true
                columns: 2
                columnSpacing: 12
                rowSpacing: 3

                Text { text: qsTr("State"); color: "white"; font.pixelSize: 13; Layout.preferredWidth: 132 }
                Text {
                    text: link_connected() ? qsTr("CONNECTED") : qsTr("ARTOSYN / NO LINK")
                    color: link_connected() ? "#ff05ff00" : "#ffcc00"
                    font.pixelSize: 13
                    Layout.fillWidth: true
                    elide: Text.ElideRight
                }
                Text { text: qsTr("TX MCS"); color: "white"; font.pixelSize: 13; Layout.preferredWidth: 132 }
                Text { text: active_system().curr_mcs_index; color: settings.color_text; font.pixelSize: 13; Layout.fillWidth: true; elide: Text.ElideRight }
                Text { text: qsTr("RX MCS"); color: "white"; font.pixelSize: 13; Layout.preferredWidth: 132 }
                Text { text: active_system().artosyn_rx_mcs; color: settings.color_text; font.pixelSize: 13; Layout.fillWidth: true; elide: Text.ElideRight }
                Text { text: qsTr("TX link rate"); color: "#05ff00"; font.pixelSize: 13; Layout.preferredWidth: 132 }
                Text { text: kbits_to_mbits_text(active_system().curr_bitrate_kbits); color: settings.color_text; font.pixelSize: 13; Layout.fillWidth: true; elide: Text.ElideRight }
                Text { text: qsTr("RX link rate"); color: "#ffcc00"; font.pixelSize: 13; Layout.preferredWidth: 132 }
                Text { text: kbits_to_mbits_text(active_system().artosyn_rx_rate_kbits); color: settings.color_text; font.pixelSize: 13; Layout.fillWidth: true; elide: Text.ElideRight }
                Text { text: qsTr("TX PHY rate"); color: "white"; font.pixelSize: 13; Layout.preferredWidth: 132 }
                Text { text: mbits_text(active_system().artosyn_tx_phy_rate_mbps); color: settings.color_text; font.pixelSize: 13; Layout.fillWidth: true; elide: Text.ElideRight }
                Text { text: qsTr("Debug stats"); color: "white"; font.pixelSize: 13; Layout.preferredWidth: 132 }
                Text {
                    text: active_system().artosyn_debug_stats_available ? qsTr("ON") : qsTr("OFF")
                    color: active_system().artosyn_debug_stats_available ? "#ff05ff00" : "#ffcc00"
                    font.pixelSize: 13
                    Layout.fillWidth: true
                    elide: Text.ElideRight
                }
                Text { text: qsTr("TX traffic"); color: "white"; font.pixelSize: 13; Layout.preferredWidth: 132 }
                Text { text: active_system().tx_packets_per_second_and_bits_per_second; color: settings.color_text; font.pixelSize: 13; Layout.fillWidth: true; elide: Text.ElideRight }
                Text { text: qsTr("RX traffic"); color: "white"; font.pixelSize: 13; Layout.preferredWidth: 132 }
                Text { text: active_system().rx_packets_per_second_and_bits_per_second; color: settings.color_text; font.pixelSize: 13; Layout.fillWidth: true; elide: Text.ElideRight }
            }
        }
    }

    Item {
        id: widgetInner
        anchors.fill: parent
        opacity: bw_current_opacity
        scale: bw_current_scale

        Rectangle {
            anchors.fill: parent
            color: "#cc050505"
            border.color: link_connected() ? "#aa33cc66" : "#aaffcc00"
            border.width: 1
            radius: 4
        }

        Column {
            anchors.fill: parent
            anchors.margins: 6
            spacing: 3

            Row {
                width: parent.width
                height: 18
                spacing: 8
                Text {
                    width: 88
                    height: parent.height
                    text: qsTr("ARTOSYN")
                    color: "#ff05ff00"
                    font.bold: true
                    font.pixelSize: 12
                    verticalAlignment: Text.AlignVCenter
                    elide: Text.ElideRight
                }
                Text {
                    width: parent.width - 96
                    height: parent.height
                    text: link_connected() ? qsTr("connected") : qsTr("artosyn")
                    color: link_connected() ? "#ff05ff00" : "#ffcc00"
                    font.pixelSize: 12
                    verticalAlignment: Text.AlignVCenter
                    horizontalAlignment: Text.AlignRight
                    elide: Text.ElideRight
                }
            }

            Canvas {
                id: compactGraph
                width: parent.width
                height: 66
                onPaint: artosynDebugWidget.paintRateGraph(getContext("2d"), width, height, false)
            }

            Row {
                width: parent.width
                height: 17
                spacing: 6
                Text {
                    width: parent.width / 2 - 3
                    height: parent.height
                    text: qsTr("tx %1").arg(kbits_to_mbits_text(active_system().curr_bitrate_kbits))
                    color: "#ff05ff00"
                    font.pixelSize: 11
                    verticalAlignment: Text.AlignVCenter
                    elide: Text.ElideRight
                }
                Text {
                    width: parent.width / 2 - 3
                    height: parent.height
                    text: qsTr("rx %1").arg(kbits_to_mbits_text(active_system().artosyn_rx_rate_kbits))
                    color: "#ffcc00"
                    font.pixelSize: 11
                    verticalAlignment: Text.AlignVCenter
                    horizontalAlignment: Text.AlignRight
                    elide: Text.ElideRight
                }
            }

            Row {
                width: parent.width
                height: 17
                spacing: 6
                Text {
                    width: parent.width / 2 - 3
                    height: parent.height
                    text: qsTr("mcs %1/%2").arg(active_system().curr_mcs_index).arg(active_system().artosyn_rx_mcs)
                    color: settings.color_text
                    font.pixelSize: 11
                    verticalAlignment: Text.AlignVCenter
                    elide: Text.ElideRight
                }
                Text {
                    width: parent.width / 2 - 3
                    height: parent.height
                    text: qsTr("phy %1").arg(mbits_text(active_system().artosyn_tx_phy_rate_mbps))
                    color: "white"
                    font.pixelSize: 11
                    verticalAlignment: Text.AlignVCenter
                    horizontalAlignment: Text.AlignRight
                    elide: Text.ElideRight
                }
            }
        }
    }
}
