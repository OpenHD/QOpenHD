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
    widgetActionHeight: 690

    property int selectedCamera: 0
    property var selectedModel: selectedCamera === 0 ? _cameraStreamModelPrimary : _cameraStreamModelSecondary
    property var selectedSettingsModel: selectedCamera === 0 ? _airCameraSettingsModel : _airCameraSettingsModel2
    property int requestedMbits: 10
    property double userEditingUntilMs: 0
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

    function markUserEditing() {
        userEditingUntilMs = Date.now() + 5000;
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

    onSelectedCameraChanged: {
        userEditingUntilMs = 0;
        syncRequestedMbits();
        resetGraph();
    }

    Component.onCompleted: {
        syncRequestedMbits();
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
