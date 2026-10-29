import "../MenuTypography.js" as MenuTypography
import QtQuick 2.12
import QtQuick.Controls 2.12
import QtQuick.Layouts 1.12
import QtQuick.Controls.Material 2.12
import QtCharts 2.15

import OpenHD 1.0

PopupBigGeneric {
    id: root
    m_title: qsTr("ANALYZE CHANNELS")
    m_modern_style: true
    focus: visible

    property int chartMinimumWidth: 1080
    property int displayedChannelCount: 0
    property bool analyzing: _wbLinkSettingsHelper.analyze_request_pending ||
                             (_ohdSystemGround.is_alive && _ohdSystemGround.wb_gnd_operating_mode === 2)
    property int analyzeProgress: Math.max(0, Math.min(100, _wbLinkSettingsHelper.analyze_progress_perc))

    property int surveyRevision: _wbLinkSettingsHelper.analyze_results_revision
    onSurveyRevisionChanged: if (visible) update()

    Material.theme: settings_form.darkMode ? Material.Dark : Material.Light
    Material.accent: settings_form.accentColor
    Material.foreground: settings_form.primaryText
    Material.background: settings_form.panelBackgroundRaised

    function open() {
        visible = true
        enabled = true
        pollutionChart.updatePollutionGraph()
        Qt.callLater(function() { filterCombo.forceActiveFocus() })
    }

    function close() {
        visible = false
        enabled = false
    }

    function requestClose() {
        if (analyzing) {
            _qopenhd.show_toast(qsTr("Channel analysis is still running"))
            return
        }
        close()
    }

    function update() { pollutionChart.updatePollutionGraph() }

    function startAnalysis() {
        var accepted = _wbLinkSettingsHelper.start_analyze_channels(filterCombo.currentIndex, durationCombo.currentIndex)
        if (accepted) {
            pollutionChart.updatePollutionGraph()
            _qopenhd.show_toast(qsTr("Requesting channel analysis"))
        }
        else
            _qopenhd.show_toast(qsTr("Could not queue the analysis request. Please try again."))
    }

    function controls() { return [filterCombo, metricCombo, durationCombo, startButton] }

    function moveFocus(control, step) {
        var list = controls()
        var current = list.indexOf(control)
        list[(current + step + list.length) % list.length].forceActiveFocus()
    }

    function handleKey(control, event) {
        if (event.key === Qt.Key_Left) {
            moveFocus(control, -1)
            event.accepted = true
        } else if (event.key === Qt.Key_Right) {
            moveFocus(control, 1)
            event.accepted = true
        } else if (event.key === Qt.Key_Escape) {
            requestClose()
            event.accepted = true
        }
    }

    onCloseButtonClicked: requestClose()
    Keys.onEscapePressed: requestClose()

    ListModel {
        id: filterModel
        ListElement { title: qsTr("OpenHD channels 1-7"); value: 0 }
        ListElement { title: qsTr("All 2.4 GHz channels"); value: 1 }
        ListElement { title: qsTr("All supported 5 GHz channels"); value: 2 }
    }

    Flickable {
        id: analysisViewport
        contentWidth: width
        contentHeight: analysisContent.implicitHeight
        clip: true
        boundsBehavior: Flickable.StopAtBounds
        ScrollBar.vertical: ScrollBar { policy: ScrollBar.AsNeeded; active: true }
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.top: parent.top
        anchors.bottom: parent.bottom
        anchors.leftMargin: 12
        anchors.rightMargin: 24
        anchors.bottomMargin: 12
        anchors.topMargin: root.dirty_top_margin_for_implementation + 10
        Column {
            id: analysisContent
            width: analysisViewport.width
            spacing: 9

            Rectangle {
                id: optionsPanel
                width: parent.width
                height: analysisOptions.implicitHeight + 20
                radius: 11
                color: settings_form.panelBackgroundRaised
                border.color: settings_form.lineColor

                GridLayout {
                    id: analysisOptions
                    anchors.left: parent.left; anchors.right: parent.right; anchors.top: parent.top
                    anchors.margins: 10
                    columns: analysisViewport.width >= 1100 ? 4 : analysisViewport.width >= 600 ? 2 : 1
                    columnSpacing: 9
                    rowSpacing: 7

                    CompactLinkComboBox {
                        id: filterCombo
                        objectName: "surveyFilter"
                        Layout.minimumWidth: preferredTextWidth
                        Layout.preferredWidth: preferredTextWidth
                        Layout.fillWidth: true
                        Layout.preferredHeight: 38
                        model: filterModel
                        textRole: "title"
                        enabled: !root.analyzing
                        onCurrentIndexChanged: pollutionChart.updatePollutionGraph()
                        Keys.onPressed: root.handleKey(filterCombo, event)
                    }

                    CompactLinkComboBox {
                        id: metricCombo
                        objectName: "surveyMetric"
                        Layout.minimumWidth: preferredTextWidth
                        Layout.preferredWidth: preferredTextWidth
                        currentIndex: 0
                        Layout.fillWidth: true
                        Layout.preferredHeight: 38
                        model: [qsTr("Energy above noise floor (%)"), qsTr("Channel busy (%)"),
                                qsTr("Wi-Fi packets"), qsTr("Wi-Fi packets (relative)")]
                        enabled: !root.analyzing
                        onCurrentIndexChanged: pollutionChart.updatePollutionGraph()
                        Keys.onPressed: root.handleKey(metricCombo, event)
                    }

                    CompactLinkComboBox {
                        id: durationCombo
                        objectName: "surveyDuration"
                        Layout.minimumWidth: preferredTextWidth
                        Layout.preferredWidth: preferredTextWidth
                        currentIndex: 1
                        Layout.fillWidth: true
                        Layout.preferredHeight: 38
                        model: [qsTr("Quick"), qsTr("Medium"), qsTr("Detailed")]
                        enabled: !root.analyzing
                        Keys.onPressed: root.handleKey(durationCombo, event)
                    }

                    Button { font.family: MenuTypography.family; font.pixelSize: MenuTypography.body;
                        id: startButton
                        Layout.minimumWidth: implicitContentWidth + 24
                        Layout.fillWidth: true
                        Layout.preferredHeight: 38
                        text: root.analyzing ? qsTr("ANALYZING…") : qsTr("START ANALYSIS")
                        enabled: _ohdSystemGround.is_alive && !root.analyzing &&
                                 _ohdSystemGround.wb_gnd_operating_mode === 0
                        onClicked: root.startAnalysis()
                        Keys.onPressed: root.handleKey(startButton, event)
                        background: Rectangle {
                            radius: 9
                            color: startButton.enabled
                                   ? (startButton.hovered ? "#176fc7" : settings_form.accentColor)
                                   : settings_form.lineColor
                            border.color: startButton.activeFocus ? "#ffffff" : "transparent"
                            border.width: startButton.activeFocus ? 2 : 0
                        }
                        contentItem: Text {
                            text: startButton.text
                            color: startButton.enabled ? "#ffffff" : settings_form.secondaryText
                            font.pixelSize: MenuTypography.body; font.family: MenuTypography.family
                            font.bold: true
                            horizontalAlignment: Text.AlignHCenter
                            verticalAlignment: Text.AlignVCenter
                        }
                    }

                }
            }

            RowLayout {
                id: progressRow
                width: parent.width
                spacing: 10
                Text {
                    objectName: "surveyStatus"
                    text: root.analyzing ? (root.analyzeProgress >= 100 ? qsTr("Restoring radio") : qsTr("Analyzing (%1 channels)").arg(_wbLinkSettingsHelper.analyzed_channel_count)) : (root.analyzeProgress >= 100 ? qsTr("Analysis complete") : qsTr("Ready"))
                    color: settings_form.primaryText
                    font.pixelSize: MenuTypography.body; font.family: MenuTypography.family
                    font.bold: true
                }
                Rectangle {
                    Layout.fillWidth: true
                    Layout.preferredHeight: 5
                    radius: 3
                    color: settings_form.lineColor
                    Rectangle {
                        width: parent.width * root.analyzeProgress / 100
                        height: parent.height
                        radius: parent.radius
                        color: settings_form.accentColor
                        Behavior on width { NumberAnimation { duration: 180 } }
                    }
                }
                Text {
                    text: root.analyzeProgress + "%"
                    color: settings_form.accentColor
                    font.pixelSize: MenuTypography.body; font.family: MenuTypography.family
                    font.bold: true
                }
            }

            Text {
                width: parent.width
                wrapMode: Text.WordWrap
                id: sweepStatus
                objectName: "surveySweepStatus"
                text: root.analyzing && durationCombo.currentIndex === 2 &&
                      _wbLinkSettingsHelper.analyzed_channel_count >= root.displayedChannelCount && root.displayedChannelCount > 0
                      ? qsTr("Second sweep: comparing measurements")
                      : root.analyzing && _wbLinkSettingsHelper.current_analyze_frequency > 0
                        ? qsTr("Last measured: %1 MHz").arg(_wbLinkSettingsHelper.current_analyze_frequency)
                        : [qsTr("Quick: one short sweep"), qsTr("Medium: one longer sweep"),
                           qsTr("Detailed: two medium sweeps; readings averaged")][durationCombo.currentIndex]
                color: settings_form.secondaryText
                font.pixelSize: MenuTypography.helper; font.family: MenuTypography.family
                horizontalAlignment: Text.AlignHCenter
            }

            Rectangle {
                id: chartPanel
                width: parent.width
                height: Math.max(220, analysisViewport.height - optionsPanel.height - progressRow.height - sweepStatus.height - explanation.height - analysisContent.spacing * 4)
                radius: 11
                color: settings_form.panelBackgroundRaised
                border.color: settings_form.lineColor
                clip: true

                Flickable {
                    id: chartScroller
                    boundsBehavior: Flickable.StopAtBounds
                    flickableDirection: Flickable.HorizontalFlick
                    anchors.fill: parent
                    anchors.margins: 5
                    contentWidth: pollutionChart.width
                    contentHeight: height
                    clip: true
                    ScrollBar.horizontal: ScrollBar { policy: ScrollBar.AsNeeded; active: true }

                    ChartView {
                        id: pollutionChart
                        objectName: "surveyChart"
                        property int measuredChannels: 0
                        width: Math.max(chartScroller.width, root.displayedChannelCount * 116,
                                        filterCombo.currentIndex === 2 ? root.chartMinimumWidth : 0)
                        height: chartScroller.height
                        antialiasing: true
                        // Results arrive incrementally: rebuilding/animating all bars flashes
                        // the chart and momentarily hides measurements already received.
                        animationOptions: ChartView.NoAnimation
                        backgroundColor: "transparent"
                        plotAreaColor: "transparent"
                        legend.visible: false
                        margins.top: 8
                        margins.bottom: 8
                        margins.left: 8
                        margins.right: 8

                        function updatePollutionGraph() {
                            var filter = filterCombo.currentIndex
                            if (filter < 0) filter = 0
                            var frequencies = _frequencyHelper.get_analyze_frequencies(filter)
                            root.displayedChannelCount = frequencies.length
                            var labels = _pollutionHelper.survey_labels(frequencies, metricCombo.currentIndex)
                            if (JSON.stringify(categoryAxis.categories) !== JSON.stringify(labels))
                                categoryAxis.categories = labels
                            var values = _pollutionHelper.survey_values(frequencies, metricCombo.currentIndex)
                            var plotted = []
                            var measured = 0
                            for (var v = 0; v < values.length; ++v) {
                                if (values[v] >= 0) ++measured
                                plotted.push(Math.max(0, values[v]))
                            }
                            measuredChannels = measured
                            if (pollutionBars.count !== plotted.length) {
                                pollutionBars.values = plotted
                            } else {
                                for (var b = 0; b < plotted.length; ++b)
                                    if (pollutionBars.at(b) !== plotted[b])
                                        pollutionBars.replace(b, plotted[b])
                            }
                            var maximum = 0
                            for (var i = 0; i < values.length; ++i)
                                maximum = Math.max(maximum, values[i])
                            qualityAxis.min = 0
                            qualityAxis.max = metricCombo.currentIndex === 2 ? Math.max(10, maximum * 1.1) : 100
                            qualityAxis.labelFormat = metricCombo.currentIndex === 2 ? "%.0f" : "%.0f%%"
                        }

                        BarSeries {
                            axisX: BarCategoryAxis {
                                id: categoryAxis
                                labelsColor: settings_form.secondaryText
                                labelsFont.family: MenuTypography.family
                                labelsFont.pixelSize: MenuTypography.helper
                                gridVisible: false
                                lineVisible: false
                            }
                            axisY: ValueAxis {
                                id: qualityAxis
                                min: 0
                                max: 100
                                labelsColor: settings_form.secondaryText
                                labelsFont.family: MenuTypography.family
                                labelsFont.pixelSize: MenuTypography.helper
                                gridLineColor: settings_form.lineColor
                                lineVisible: false
                                labelFormat: "%.0f%%"
                                tickCount: 6
                            }
                            BarSet {
                                id: pollutionBars
                                objectName: "surveyBars"
                                label: metricCombo.currentText
                                values: [0, 0, 0, 0]
                                color: settings_form.errorColor
                                borderColor: settings_form.errorColor
                            }
                            labelsVisible: false
                        }
                    }
                }
            }

            Text {
                width: parent.width
                id: explanation
                objectName: "surveyExplanation"
                text: (pollutionChart.measuredChannels === 0
                       ? (root.analyzing ? qsTr("Waiting for measurements. ")
                          : root.analyzeProgress === 0 ? qsTr("Start an analysis to measure channels. ")
                          : qsTr("This analysis supplied no values for this view. The radio/backend may not support this measurement. Select another metric. "))
                       : qsTr("%1 of %2 channels measured. ").arg(pollutionChart.measuredChannels).arg(root.displayedChannelCount))
                      + [qsTr("Energy above the receiver's noise floor; includes OpenHD traffic."),
                         qsTr("Channel busy measures occupied airtime; it is not a packet count."),
                         qsTr("Foreign Wi-Fi packets received during each channel observation."),
                         qsTr("Relative Wi-Fi packets: the busiest measured channel is 100%. This is not airtime usage.")][metricCombo.currentIndex]
                      + qsTr(" Not scanned means no result; Unavailable means no valid reading. Stop Air transmission for an interference-only scan. Check both 20 MHz halves for 40 MHz. Swipe to inspect all channels.")
                color: settings_form.secondaryText
                font.pixelSize: MenuTypography.helper; font.family: MenuTypography.family
                horizontalAlignment: Text.AlignHCenter
                wrapMode: Text.WordWrap
            }
        }
    }
}
