import QtQuick 2.12
import QtQuick.Controls 2.12
import QtQuick.Layouts 1.12

BaseWidget {
    id: debugWidget
    width: 260
    height: 138
    visible: settings.show_video_pipeline_debug_widget && settings.show_widgets

    widgetIdentifier: "video_pipeline_debug_widget"
    bw_verbose_name: qsTr("VIDEO PIPELINE DEBUG")
    defaultAlignment: 1
    defaultXOffset: 8
    defaultYOffset: 108
    defaultHCenter: false
    defaultVCenter: false

    hasWidgetDetail: true
    hasWidgetAction: true
    widgetActionWidth: 620
    widgetActionHeight: 900

    property int selectedCamera: 0
    property var selectedModel: selectedCamera === 0 ? _cameraStreamModelPrimary : _cameraStreamModelSecondary
    property var selectedSettingsModel: selectedCamera === 0 ? _airCameraSettingsModel : _airCameraSettingsModel2
    property int requestedMbits: 10
    property int requestedQpMin: 5
    property int requestedQpMax: 51
    property double userEditingUntilMs: 0
    property double qpEditingUntilMs: 0
    property int selectedSettingsUpdateCount: selectedSettingsModel.update_count
    property bool selectedSettingsHasParamsFetched: selectedSettingsModel.has_params_fetched
    property bool qpParamsAvailable: false
    property bool qpPidParamAvailable: false
    property bool rkBitratePidParamAvailable: false
    property bool impairmentParamsAvailable: false
    property bool intraRefreshParamsAvailable: false
    property bool forceKeyframeAvailable: false
    property int requestedPacketLossPercent: 0
    property int requestedKeyframeLossPercent: 0
    property bool requestedIntraRefreshEnabled: true
    property int requestedIntraRefreshMode: 2
    property int requestedIntraRefreshNum: 8
    property double impairmentEditingUntilMs: 0
    property int qpParamsAvailabilityUpdateCount: -1
    property int qpParamsAvailabilityCamera: -1
    property int maxSamples: 90
    property var measuredHistory: []
    property var injectedHistory: []
    property var targetHistory: []

    function currentSetMbits() {
        var kbits = selectedModel.curr_recomended_video_bitrate_kbits;
        if (kbits > 0) {
            return Math.max(1, Math.min(50, Math.round(kbits / 1000)));
        }
        return requestedMbits;
    }

    function syncRequestedMbits() {
        requestedMbits = currentSetMbits();
    }

    function qpControlsAvailable() {
        return qpParamsAvailable;
    }

    function refreshQpControlsAvailable(force) {
        var updateCount = selectedSettingsModel.update_count;
        if (!force && qpParamsAvailabilityCamera === selectedCamera && qpParamsAvailabilityUpdateCount === updateCount) {
            return;
        }
        qpParamsAvailabilityCamera = selectedCamera;
        qpParamsAvailabilityUpdateCount = updateCount;
        if (!selectedSettingsModel.has_params_fetched) {
            qpParamsAvailable = false;
            qpPidParamAvailable = false;
            rkBitratePidParamAvailable = false;
            impairmentParamsAvailable = false;
            intraRefreshParamsAvailable = false;
            forceKeyframeAvailable = false;
            return;
        }
        qpParamsAvailable = selectedSettingsModel.param_int_exists("QP_MIN") && selectedSettingsModel.param_int_exists("QP_MAX");
        qpPidParamAvailable = selectedSettingsModel.param_int_exists("QP_PID_ENABLE");
        rkBitratePidParamAvailable = selectedSettingsModel.param_int_exists("RK_BITRATE_PID");
        impairmentParamsAvailable = selectedSettingsModel.param_int_exists("DBG_PKT_LOSS")
                && selectedSettingsModel.param_int_exists("DBG_KEY_LOSS");
        intraRefreshParamsAvailable = selectedSettingsModel.param_int_exists("MPP_IR_ENABLE")
                && selectedSettingsModel.param_int_exists("MPP_IR_MODE")
                && selectedSettingsModel.param_int_exists("MPP_IR_NUM");
        forceKeyframeAvailable = selectedSettingsModel.param_int_exists("MPP_FORCE_IDR");
    }

    function currentQpMin() {
        if (!qpControlsAvailable()) {
            return requestedQpMin;
        }
        return Math.max(0, Math.min(51, selectedSettingsModel.get_cached_int("QP_MIN")));
    }

    function currentQpMax() {
        if (!qpControlsAvailable()) {
            return requestedQpMax;
        }
        return Math.max(0, Math.min(51, selectedSettingsModel.get_cached_int("QP_MAX")));
    }

    function syncRequestedQp() {
        if (!qpControlsAvailable()) {
            return;
        }
        requestedQpMin = currentQpMin();
        requestedQpMax = Math.max(requestedQpMin, currentQpMax());
    }

    function syncImpairmentControls() {
        if (impairmentParamsAvailable) {
            requestedPacketLossPercent = selectedSettingsModel.get_cached_int("DBG_PKT_LOSS");
            requestedKeyframeLossPercent = selectedSettingsModel.get_cached_int("DBG_KEY_LOSS");
        }
        if (intraRefreshParamsAvailable) {
            requestedIntraRefreshEnabled = selectedSettingsModel.get_cached_int("MPP_IR_ENABLE") !== 0;
            requestedIntraRefreshMode = selectedSettingsModel.get_cached_int("MPP_IR_MODE");
            requestedIntraRefreshNum = selectedSettingsModel.get_cached_int("MPP_IR_NUM");
        }
    }

    function markImpairmentEditing() {
        impairmentEditingUntilMs = Date.now() + 10000;
    }

    function setDebugParameter(name, value) {
        var result = selectedSettingsModel.try_update_parameter_int(name, value);
        if (result !== "") {
            _hudLogMessagesModel.signalAddLogMessage(4, result);
            return false;
        }
        return true;
    }

    function applyImpairmentControls() {
        var camName = selectedCamera === 0 ? qsTr("CAM1") : qsTr("CAM2");
        if (!_ohdSystemAir.is_alive) {
            _hudLogMessagesModel.signalAddLogMessage(4, qsTr("Air unit not alive, cannot update %1 MPP test mode").arg(camName));
            return;
        }
        var ok = setDebugParameter("DBG_PKT_LOSS", requestedPacketLossPercent)
                && setDebugParameter("DBG_KEY_LOSS", requestedKeyframeLossPercent);
        if (ok) {
            _hudLogMessagesModel.signalAddLogMessage(6, qsTr("%1 MPP video test mode updated").arg(camName));
            impairmentEditingUntilMs = 0;
        }
    }

    function disableImpairments() {
        requestedPacketLossPercent = 0;
        requestedKeyframeLossPercent = 0;
        markImpairmentEditing();
        applyImpairmentControls();
    }

    function applyIntraRefreshControls() {
        var ok = setDebugParameter("MPP_IR_ENABLE", requestedIntraRefreshEnabled ? 1 : 0)
                && setDebugParameter("MPP_IR_MODE", requestedIntraRefreshMode)
                && setDebugParameter("MPP_IR_NUM", requestedIntraRefreshNum);
        if (ok)
            _hudLogMessagesModel.signalAddLogMessage(6, qsTr("MPP intra-refresh updated"));
    }

    function markUserEditing() {
        userEditingUntilMs = Date.now() + 5000;
    }

    function markQpEditing() {
        qpEditingUntilMs = Date.now() + 5000;
    }

    function resetGraph() {
        measuredHistory = [];
        injectedHistory = [];
        targetHistory = [];
        compactGraph.requestPaint();
        actionGraph.requestPaint();
    }

    function pushSample(history, value) {
        var next = history.slice(0);
        next.push(Math.max(0, value));
        while (next.length > maxSamples) {
            next.shift();
        }
        return next;
    }

    function sampleBitrates() {
        var realBps = selectedModel.curr_video_measured_encoder_bitrate_bps;
        measuredHistory = pushSample(measuredHistory, realBps > 0 ? realBps / 1000000.0 : 0);
        injectedHistory = pushSample(injectedHistory, selectedModel.curr_video_injected_bitrate_bps / 1000000.0);
        targetHistory = pushSample(targetHistory, selectedModel.curr_recomended_video_bitrate_kbits / 1000.0);
        compactGraph.requestPaint();
        actionGraph.requestPaint();
    }

    function maxHistoryValue() {
        var maxValue = 5;
        for (var i = 0; i < measuredHistory.length; i++) {
            maxValue = Math.max(maxValue, measuredHistory[i] || 0, injectedHistory[i] || 0, targetHistory[i] || 0);
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

    function paintBitrateGraph(ctx, width, height, showLegend) {
        var pad = showLegend ? 24 : 8;
        var maxValue = maxHistoryValue();
        ctx.clearRect(0, 0, width, height);
        ctx.fillStyle = "rgba(0, 0, 0, 0.13)";
        ctx.fillRect(0, 0, width, height);
        ctx.strokeStyle = "rgba(51, 204, 102, 0.27)";
        ctx.lineWidth = 1;
        for (var i = 1; i < 4; i++) {
            var y = pad + i * (height - 2 * pad) / 4;
            ctx.beginPath();
            ctx.moveTo(pad, y);
            ctx.lineTo(width - pad, y);
            ctx.stroke();
        }
        drawHistoryLine(ctx, targetHistory, "#ffffff", maxValue, width, height, pad);
        drawHistoryLine(ctx, measuredHistory, "#05ff00", maxValue, width, height, pad);
        drawHistoryLine(ctx, injectedHistory, "#ffcc00", maxValue, width, height, pad);
        if (showLegend) {
            ctx.fillStyle = "#ffffff";
            ctx.font = "12px sans-serif";
            ctx.fillText(maxValue + " MBit/s", pad, 14);
            ctx.fillStyle = "#05ff00";
            ctx.fillText("real", pad, height - 7);
            ctx.fillStyle = "#ffcc00";
            ctx.fillText("injected", pad + 54, height - 7);
            ctx.fillStyle = "#ffffff";
            ctx.fillText("set", pad + 126, height - 7);
        }
    }

    function changeRequestedMbits(delta) {
        markUserEditing();
        requestedMbits = Math.max(1, Math.min(50, requestedMbits + delta));
    }

    function changeRequestedQpMin(delta) {
        markQpEditing();
        requestedQpMin = Math.max(0, Math.min(requestedQpMax, requestedQpMin + delta));
    }

    function changeRequestedQpMax(delta) {
        markQpEditing();
        requestedQpMax = Math.max(requestedQpMin, Math.min(51, requestedQpMax + delta));
    }

    function applyRequestedBitrate() {
        var camName = selectedCamera === 0 ? qsTr("CAM1") : qsTr("CAM2");
        if (!_ohdSystemAir.is_alive) {
            _hudLogMessagesModel.signalAddLogMessage(4, qsTr("Air unit not alive, cannot set %1 bitrate").arg(camName));
            return;
        }
        var result = selectedSettingsModel.try_update_parameter_int("BITRATE_MBITS", requestedMbits);
        if (result === "") {
            _hudLogMessagesModel.signalAddLogMessage(6, qsTr("%1 bitrate set to %2 MBit/s").arg(camName).arg(requestedMbits));
            userEditingUntilMs = 0;
        } else {
            _hudLogMessagesModel.signalAddLogMessage(4, result);
        }
    }

    function applyRequestedQp() {
        var camName = selectedCamera === 0 ? qsTr("CAM1") : qsTr("CAM2");
        if (!_ohdSystemAir.is_alive) {
            _hudLogMessagesModel.signalAddLogMessage(4, qsTr("Air unit not alive, cannot set %1 QP").arg(camName));
            return;
        }
        if (!qpControlsAvailable()) {
            _hudLogMessagesModel.signalAddLogMessage(4, qsTr("%1 QP parameters not available").arg(camName));
            return;
        }
        if (requestedQpMin > requestedQpMax) {
            _hudLogMessagesModel.signalAddLogMessage(4, qsTr("QP min must be <= QP max"));
            return;
        }
        var currentMin = currentQpMin();
        var firstParam = requestedQpMax < currentMin ? "QP_MIN" : "QP_MAX";
        var secondParam = firstParam === "QP_MIN" ? "QP_MAX" : "QP_MIN";
        var firstValue = firstParam === "QP_MIN" ? requestedQpMin : requestedQpMax;
        var secondValue = secondParam === "QP_MIN" ? requestedQpMin : requestedQpMax;
        var result = selectedSettingsModel.try_update_parameter_int(firstParam, firstValue);
        if (result === "") {
            result = selectedSettingsModel.try_update_parameter_int(secondParam, secondValue);
        }
        if (result === "") {
            _hudLogMessagesModel.signalAddLogMessage(6, qsTr("%1 QP set to %2-%3").arg(camName).arg(requestedQpMin).arg(requestedQpMax));
            qpEditingUntilMs = 0;
        } else {
            _hudLogMessagesModel.signalAddLogMessage(4, result);
        }
    }

    function intParamEnabled(paramName, available) {
        return available && selectedSettingsModel.get_cached_int(paramName) !== 0;
    }

    function toggleIntParam(paramName, available, label) {
        var camName = selectedCamera === 0 ? qsTr("CAM1") : qsTr("CAM2");
        if (!_ohdSystemAir.is_alive) {
            _hudLogMessagesModel.signalAddLogMessage(4, qsTr("Air unit not alive, cannot set %1 %2").arg(camName).arg(label));
            return;
        }
        if (!available) {
            _hudLogMessagesModel.signalAddLogMessage(4, qsTr("%1 %2 parameter not available").arg(camName).arg(label));
            return;
        }
        var newValue = intParamEnabled(paramName, available) ? 0 : 1;
        var result = selectedSettingsModel.try_update_parameter_int(paramName, newValue);
        if (result === "") {
            _hudLogMessagesModel.signalAddLogMessage(6, qsTr("%1 %2 %3").arg(camName).arg(label).arg(newValue === 0 ? qsTr("disabled") : qsTr("enabled")));
        } else {
            _hudLogMessagesModel.signalAddLogMessage(4, result);
        }
    }

    onSelectedCameraChanged: {
        userEditingUntilMs = 0;
        qpEditingUntilMs = 0;
        refreshQpControlsAvailable(true);
        syncRequestedMbits();
        syncRequestedQp();
        syncImpairmentControls();
        resetGraph();
    }

    onSelectedSettingsUpdateCountChanged: {
        refreshQpControlsAvailable(false);
        if (Date.now() > qpEditingUntilMs) {
            syncRequestedQp();
        }
        if (Date.now() > impairmentEditingUntilMs) syncImpairmentControls();
    }

    onSelectedSettingsHasParamsFetchedChanged: {
        refreshQpControlsAvailable(true);
        if (Date.now() > qpEditingUntilMs) {
            syncRequestedQp();
        }
        if (Date.now() > impairmentEditingUntilMs) syncImpairmentControls();
    }

    Component.onCompleted: {
        refreshQpControlsAvailable(true);
        syncRequestedMbits();
        syncRequestedQp();
        syncImpairmentControls();
        sampleBitrates();
    }

    Timer {
        interval: 1000
        repeat: true
        running: debugWidget.visible
        onTriggered: {
            sampleBitrates();
            if (!bitrateSlider.pressed && Date.now() > userEditingUntilMs) {
                syncRequestedMbits();
            }
            if (!qpMinSlider.pressed && !qpMaxSlider.pressed && Date.now() > qpEditingUntilMs) {
                syncRequestedQp();
            }
            if (Date.now() > impairmentEditingUntilMs) syncImpairmentControls();
        }
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
            width: 584
            spacing: 8

            RowLayout {
                Layout.fillWidth: true
                spacing: 6

                Text {
                    text: qsTr("VIDEO PIPELINE DEBUG")
                    color: "#ff05ff00"
                    font.bold: true
                    font.pixelSize: 14
                    Layout.fillWidth: true
                    elide: Text.ElideRight
                }

                Button {
                    text: qsTr("CAM1")
                    highlighted: selectedCamera === 0
                    onClicked: selectedCamera = 0
                    Layout.preferredWidth: 62
                }
                Button {
                    text: qsTr("CAM2")
                    highlighted: selectedCamera === 1
                    onClicked: selectedCamera = 1
                    Layout.preferredWidth: 62
                }
            }

            Canvas {
                id: actionGraph
                Layout.fillWidth: true
                Layout.preferredHeight: 170
                onPaint: debugWidget.paintBitrateGraph(getContext("2d"), width, height, true)
            }

            GridLayout {
                Layout.fillWidth: true
                columns: 2
                columnSpacing: 12
                rowSpacing: 3

                Text { text: qsTr("Dynamic bitrate"); color: "white"; font.pixelSize: 13; Layout.preferredWidth: 132 }
                Text {
                    text: selectedModel.supports_variable_bitrate ? qsTr("yes") : qsTr("no")
                    color: selectedModel.supports_variable_bitrate ? "#ff05ff00" : "yellow"
                    font.pixelSize: 13
                    Layout.fillWidth: true
                    elide: Text.ElideRight
                }
                Text { text: qsTr("QP limits"); color: "white"; font.pixelSize: 13; Layout.preferredWidth: 132 }
                Text {
                    text: qpControlsAvailable() ? qsTr("%1-%2").arg(currentQpMin()).arg(currentQpMax()) : qsTr("N/A")
                    color: settings.color_text
                    font.pixelSize: 13
                    Layout.fillWidth: true
                    elide: Text.ElideRight
                }
                Text { text: qsTr("Set bitrate"); color: "white"; font.pixelSize: 13; Layout.preferredWidth: 132 }
                Text { text: selectedModel.curr_recomended_video_bitrate_string; color: settings.color_text; font.pixelSize: 13; Layout.fillWidth: true; elide: Text.ElideRight }
                Text { text: qsTr("Real bitrate"); color: "#05ff00"; font.pixelSize: 13; Layout.preferredWidth: 132 }
                Text { text: selectedModel.curr_video_measured_encoder_bitrate; color: settings.color_text; font.pixelSize: 13; Layout.fillWidth: true; elide: Text.ElideRight }
                Text { text: qsTr("Set FPS"); color: "white"; font.pixelSize: 13; Layout.preferredWidth: 132 }
                Text { text: selectedModel.curr_set_video_fps; color: settings.color_text; font.pixelSize: 13; Layout.fillWidth: true; elide: Text.ElideRight }
                Text { text: qsTr("Real FPS"); color: "#05ff00"; font.pixelSize: 13; Layout.preferredWidth: 132 }
                Text { text: selectedModel.curr_video_measured_encoder_fps; color: settings.color_text; font.pixelSize: 13; Layout.fillWidth: true; elide: Text.ElideRight }
                Text { text: qsTr("Injected + FEC"); color: "white"; font.pixelSize: 13; Layout.preferredWidth: 132 }
                Text { text: selectedModel.curr_video_injected_bitrate; color: settings.color_text; font.pixelSize: 13; Layout.fillWidth: true; elide: Text.ElideRight }
                Text { text: qsTr("Link calculated"); color: "white"; font.pixelSize: 13; Layout.preferredWidth: 132 }
                Text { text: selectedModel.curr_video_link_calculated_bitrate; color: settings.color_text; font.pixelSize: 13; Layout.fillWidth: true; elide: Text.ElideRight }
                Text { text: qsTr("Ground RX"); color: "white"; font.pixelSize: 13; Layout.preferredWidth: 132 }
                Text { text: selectedModel.curr_received_bitrate_with_fec; color: settings.color_text; font.pixelSize: 13; Layout.fillWidth: true; elide: Text.ElideRight }
                Text { text: qsTr("PPS"); color: "white"; font.pixelSize: 13; Layout.preferredWidth: 132 }
                Text { text: selectedModel.curr_video_injected_pps; color: settings.color_text; font.pixelSize: 13; Layout.fillWidth: true; elide: Text.ElideRight }
                Text { text: qsTr("TX delay"); color: "white"; font.pixelSize: 13; Layout.preferredWidth: 132 }
                Text { text: selectedModel.curr_time_until_tx_min_max_avg; color: settings.color_text; font.pixelSize: 13; Layout.fillWidth: true; elide: Text.ElideRight }
            }

            Rectangle {
                Layout.fillWidth: true
                height: 1
                color: "#5533cc66"
            }

            ColumnLayout {
                Layout.fillWidth: true
                spacing: 4

                RowLayout {
                    Layout.fillWidth: true
                    spacing: 6

                    Button {
                        text: "-"
                        onClicked: changeRequestedMbits(-1)
                        Layout.preferredWidth: 42
                    }
                    Slider {
                        id: bitrateSlider
                        from: 1
                        to: 50
                        stepSize: 1
                        value: requestedMbits
                        snapMode: Slider.SnapAlways
                        onMoved: {
                            markUserEditing();
                            requestedMbits = Math.round(value);
                        }
                        Layout.fillWidth: true
                    }
                    Button {
                        text: "+"
                        onClicked: changeRequestedMbits(1)
                        Layout.preferredWidth: 42
                    }
                }

                RowLayout {
                    Layout.fillWidth: true
                    spacing: 6

                    Text {
                        text: qsTr("Selected bitrate: %1 MBit/s").arg(requestedMbits)
                        color: settings.color_text
                        font.pixelSize: 13
                        Layout.fillWidth: true
                        elide: Text.ElideRight
                    }
                    Button {
                        text: qsTr("SET")
                        enabled: !selectedSettingsModel.ui_is_busy
                        onClicked: applyRequestedBitrate()
                        Layout.preferredWidth: 96
                    }
                    SpinBox {
                        from: 1
                        to: 50
                        editable: true
                        value: requestedMbits
                        onValueModified: {
                            markUserEditing();
                            requestedMbits = value;
                        }
                        Layout.preferredWidth: 110
                    }
                }
            }

            Rectangle {
                Layout.fillWidth: true
                height: 1
                color: "#5533cc66"
            }

            ColumnLayout {
                Layout.fillWidth: true
                spacing: 4
                enabled: qpControlsAvailable()

                RowLayout {
                    Layout.fillWidth: true
                    spacing: 6

                    Text {
                        text: qsTr("QP min")
                        color: settings.color_text
                        font.pixelSize: 13
                        Layout.preferredWidth: 58
                        elide: Text.ElideRight
                    }
                    Button {
                        text: "-"
                        onClicked: changeRequestedQpMin(-1)
                        Layout.preferredWidth: 42
                    }
                    Slider {
                        id: qpMinSlider
                        from: 0
                        to: requestedQpMax
                        stepSize: 1
                        value: requestedQpMin
                        snapMode: Slider.SnapAlways
                        onMoved: {
                            markQpEditing();
                            requestedQpMin = Math.max(0, Math.min(requestedQpMax, Math.round(value)));
                        }
                        Layout.fillWidth: true
                    }
                    Button {
                        text: "+"
                        onClicked: changeRequestedQpMin(1)
                        Layout.preferredWidth: 42
                    }
                }

                RowLayout {
                    Layout.fillWidth: true
                    spacing: 6

                    Text {
                        text: qsTr("QP max")
                        color: settings.color_text
                        font.pixelSize: 13
                        Layout.preferredWidth: 58
                        elide: Text.ElideRight
                    }
                    Button {
                        text: "-"
                        onClicked: changeRequestedQpMax(-1)
                        Layout.preferredWidth: 42
                    }
                    Slider {
                        id: qpMaxSlider
                        from: requestedQpMin
                        to: 51
                        stepSize: 1
                        value: requestedQpMax
                        snapMode: Slider.SnapAlways
                        onMoved: {
                            markQpEditing();
                            requestedQpMax = Math.max(requestedQpMin, Math.min(51, Math.round(value)));
                        }
                        Layout.fillWidth: true
                    }
                    Button {
                        text: "+"
                        onClicked: changeRequestedQpMax(1)
                        Layout.preferredWidth: 42
                    }
                }

                RowLayout {
                    Layout.fillWidth: true
                    spacing: 6

                    Text {
                        text: qpControlsAvailable() ? qsTr("Selected QP: %1-%2").arg(requestedQpMin).arg(requestedQpMax) : qsTr("QP params unavailable")
                        color: settings.color_text
                        font.pixelSize: 13
                        Layout.fillWidth: true
                        elide: Text.ElideRight
                    }
                    Button {
                        text: qsTr("SET")
                        enabled: qpControlsAvailable() && !selectedSettingsModel.ui_is_busy
                        onClicked: applyRequestedQp()
                        Layout.preferredWidth: 96
                    }
                }
            }

            RowLayout {
                Layout.fillWidth: true
                spacing: 6
                visible: qpPidParamAvailable || rkBitratePidParamAvailable

                Text {
                    text: qsTr("PID")
                    color: settings.color_text
                    font.pixelSize: 13
                    Layout.preferredWidth: 58
                    elide: Text.ElideRight
                }
                Button {
                    visible: qpPidParamAvailable
                    text: intParamEnabled("QP_PID_ENABLE", qpPidParamAvailable) ? qsTr("QP PID ON") : qsTr("QP PID OFF")
                    enabled: !selectedSettingsModel.ui_is_busy
                    onClicked: toggleIntParam("QP_PID_ENABLE", qpPidParamAvailable, qsTr("QP PID"))
                    Layout.preferredWidth: visible ? 118 : 0
                }
                Button {
                    visible: rkBitratePidParamAvailable
                    text: intParamEnabled("RK_BITRATE_PID", rkBitratePidParamAvailable) ? qsTr("RK PID ON") : qsTr("RK PID OFF")
                    enabled: !selectedSettingsModel.ui_is_busy
                    onClicked: toggleIntParam("RK_BITRATE_PID", rkBitratePidParamAvailable, qsTr("RK PID"))
                    Layout.preferredWidth: visible ? 118 : 0
                }
                Item {
                    Layout.fillWidth: true
                }
            }

            Rectangle {
                Layout.fillWidth: true
                height: 1
                color: "#55ff8800"
                visible: true
            }

            ColumnLayout {
                Layout.fillWidth: true
                spacing: 5
                visible: true

                RowLayout {
                    Layout.fillWidth: true
                    Text {
                        text: qsTr("VIDEO LOSS TEST")
                        color: "#ffff9900"
                        font.bold: true
                        font.pixelSize: 13
                        Layout.fillWidth: true
                    }
                    Button {
                        text: qsTr("RESET")
                        onClicked: disableImpairments()
                        Layout.preferredWidth: 96
                    }
                }

                RowLayout {
                    Layout.fillWidth: true
                    Text { text: qsTr("All RTP packets %"); color: settings.color_text; Layout.preferredWidth: 145 }
                    Slider {
                        from: 0; to: 95; stepSize: 1
                        value: requestedPacketLossPercent
                        onMoved: { markImpairmentEditing(); requestedPacketLossPercent = Math.round(value); }
                        Layout.fillWidth: true
                    }
                    Text { text: requestedPacketLossPercent; color: "white"; Layout.preferredWidth: 30; horizontalAlignment: Text.AlignRight }
                }

                RowLayout {
                    Layout.fillWidth: true
                    Text { text: qsTr("Keyframe RTP packets %"); color: settings.color_text; Layout.preferredWidth: 145 }
                    Slider {
                        from: 0; to: 95; stepSize: 1
                        value: requestedKeyframeLossPercent
                        onMoved: { markImpairmentEditing(); requestedKeyframeLossPercent = Math.round(value); }
                        Layout.fillWidth: true
                    }
                    Text { text: requestedKeyframeLossPercent; color: "white"; Layout.preferredWidth: 30; horizontalAlignment: Text.AlignRight }
                }

                RowLayout {
                    Layout.fillWidth: true
                    Button {
                        text: qsTr("FORCE KEYFRAME")
                        enabled: forceKeyframeAvailable && !selectedSettingsModel.ui_is_busy
                        onClicked: setDebugParameter("MPP_FORCE_IDR", 1)
                        Layout.preferredWidth: 150
                    }
                    Item { Layout.fillWidth: true }
                    Button {
                        text: qsTr("APPLY")
                        enabled: impairmentParamsAvailable && !selectedSettingsModel.ui_is_busy
                        onClicked: applyImpairmentControls()
                        Layout.preferredWidth: 96
                    }
                }

                RowLayout {
                    Layout.fillWidth: true
                    Text { text: qsTr("Cyclic intra-refresh"); color: settings.color_text; Layout.preferredWidth: 145 }
                    CheckBox {
                        text: qsTr("enabled")
                        checked: requestedIntraRefreshEnabled
                        enabled: intraRefreshParamsAvailable
                        onToggled: { markImpairmentEditing(); requestedIntraRefreshEnabled = checked; }
                        Layout.fillWidth: true
                    }
                    Text { text: qsTr("units/frame"); color: settings.color_text }
                    SpinBox {
                        from: 1; to: 32; editable: true
                        value: requestedIntraRefreshNum
                        enabled: intraRefreshParamsAvailable
                        onValueModified: { markImpairmentEditing(); requestedIntraRefreshNum = value; }
                        Layout.preferredWidth: 68
                    }
                    Button {
                        text: qsTr("APPLY")
                        enabled: intraRefreshParamsAvailable && !selectedSettingsModel.ui_is_busy
                        onClicked: applyIntraRefreshControls()
                        Layout.preferredWidth: 80
                    }
                }

                RowLayout {
                    Layout.fillWidth: true
                    Text { text: qsTr("Refresh mode"); color: settings.color_text; Layout.preferredWidth: 122 }
                    ComboBox {
                        model: [qsTr("rows"), qsTr("columns"), qsTr("sparse blocks")]
                        currentIndex: requestedIntraRefreshMode
                        enabled: intraRefreshParamsAvailable
                        onActivated: { markImpairmentEditing(); requestedIntraRefreshMode = currentIndex; }
                        Layout.preferredWidth: 135
                    }
                    Text { text: qsTr("native MPP control"); color: "#ff99dd99"; font.pixelSize: 10 }
                }

                Text {
                    text: qsTr("Affects video only. RTP loss never drops telemetry or control traffic.")
                    color: "#ffffbb66"
                    font.pixelSize: 11
                    Layout.fillWidth: true
                    wrapMode: Text.WordWrap
                }
            }

            Text {
                text: qsTr("Pipeline")
                color: "white"
                font.bold: true
                font.pixelSize: 13
                Layout.fillWidth: true
            }

            Flickable {
                id: pipelineFlick
                Layout.fillWidth: true
                Layout.preferredHeight: 170
                contentWidth: width
                contentHeight: pipelineText.height
                clip: true

                Text {
                    id: pipelineText
                    width: pipelineFlick.width
                    text: selectedModel.curr_pipeline
                    color: "#ff05ff00"
                    font.pixelSize: 12
                    wrapMode: Text.WrapAnywhere
                }
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
            border.color: selectedModel.supports_variable_bitrate ? "#aa33cc66" : "#aaffcc00"
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
                    width: 72
                    height: parent.height
                    text: selectedCamera === 0 ? qsTr("CAM1 VDBG") : qsTr("CAM2 VDBG")
                    color: "#ff05ff00"
                    font.bold: true
                    font.pixelSize: 12
                    verticalAlignment: Text.AlignVCenter
                    elide: Text.ElideRight
                }
                Text {
                    width: parent.width - 80
                    height: parent.height
                    text: qsTr("real %1").arg(selectedModel.curr_video_measured_encoder_bitrate)
                    color: settings.color_text
                    font.pixelSize: 12
                    verticalAlignment: Text.AlignVCenter
                    horizontalAlignment: Text.AlignRight
                    elide: Text.ElideRight
                }
            }

            Canvas {
                id: compactGraph
                width: parent.width
                height: 62
                onPaint: debugWidget.paintBitrateGraph(getContext("2d"), width, height, false)
            }

            Row {
                width: parent.width
                height: 17
                spacing: 6
                Text {
                    width: parent.width / 2 - 3
                    height: parent.height
                    text: qsTr("set %1").arg(selectedModel.curr_recomended_video_bitrate_string)
                    color: "white"
                    font.pixelSize: 11
                    verticalAlignment: Text.AlignVCenter
                    elide: Text.ElideRight
                }
                Text {
                    width: parent.width / 2 - 3
                    height: parent.height
                    text: qsTr("real %1").arg(selectedModel.curr_video_measured_encoder_bitrate)
                    color: "#ff05ff00"
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
                    text: qsTr("set %1").arg(selectedModel.curr_set_video_fps)
                    color: "white"
                    font.pixelSize: 11
                    verticalAlignment: Text.AlignVCenter
                    elide: Text.ElideRight
                }
                Text {
                    width: parent.width / 2 - 3
                    height: parent.height
                    text: qsTr("real %1").arg(selectedModel.curr_video_measured_encoder_fps)
                    color: "#ff05ff00"
                    font.pixelSize: 11
                    verticalAlignment: Text.AlignVCenter
                    horizontalAlignment: Text.AlignRight
                    elide: Text.ElideRight
                }
            }
        }
    }
}
