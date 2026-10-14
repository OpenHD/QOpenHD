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
    property bool analyzing: _ohdSystemGround.is_alive && _ohdSystemGround.wb_gnd_operating_mode === 2
    property int analyzeProgress: Math.max(0, Math.min(100, _wbLinkSettingsHelper.analyze_progress_perc))

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
        var accepted = _wbLinkSettingsHelper.start_analyze_channels(filterCombo.currentIndex)
        if (accepted)
            _qopenhd.show_toast(qsTr("Channel analysis started"))
        else
            _qopenhd.show_toast(qsTr("The radio is busy. Please try again."))
    }

    function controls() { return [filterCombo, metricCombo, startButton] }

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
        ListElement { title: qsTr("OpenHD channels 1–7"); value: 0 }
        ListElement { title: qsTr("All 2.4 GHz channels"); value: 1 }
        ListElement { title: qsTr("All 5.8 GHz channels"); value: 2 }
    }

    ColumnLayout {
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.top: parent.top
        anchors.bottom: parent.bottom
        anchors.leftMargin: 12
        anchors.rightMargin: 12
        anchors.bottomMargin: 12
        anchors.topMargin: root.dirty_top_margin_for_implementation + 10
        spacing: 9

        Rectangle {
            Layout.fillWidth: true
            Layout.preferredHeight: root.width >= 700 ? 68 : 116
            radius: 11
            color: settings_form.panelBackgroundRaised
            border.color: settings_form.lineColor

            GridLayout {
                anchors.fill: parent
                anchors.margins: 10
                columns: root.width >= 700 ? 4 : 2
                columnSpacing: 9
                rowSpacing: 7

                CompactLinkComboBox {
                    id: filterCombo
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
                    Layout.fillWidth: true
                    Layout.preferredHeight: 38
                    model: [qsTr("Energy above noise floor (%)"), qsTr("Channel busy (%)"),
                            qsTr("Wi-Fi packets"), qsTr("Wi-Fi packets (relative)")]
                    enabled: !root.analyzing
                    onCurrentIndexChanged: pollutionChart.updatePollutionGraph()
                    Keys.onPressed: root.handleKey(metricCombo, event)
                }

                Button {
                    id: startButton
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
                        font.pixelSize: 11
                        font.bold: true
                        horizontalAlignment: Text.AlignHCenter
                        verticalAlignment: Text.AlignVCenter
                    }
                }

            }
        }

        RowLayout {
            Layout.fillWidth: true
            spacing: 10
            Text {
                text: root.analyzing ? qsTr("Analyzing") : (root.analyzeProgress >= 100 ? qsTr("Analysis complete") : qsTr("Ready"))
                color: settings_form.primaryText
                font.pixelSize: 11
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
                font.pixelSize: 11
                font.bold: true
            }
        }

        Text {
            Layout.fillWidth: true
            Layout.preferredHeight: visible ? 18 : 0
            visible: _wbLinkSettingsHelper.current_analyze_frequency > 0
            text: qsTr("Analyzing %1 MHz").arg(_wbLinkSettingsHelper.current_analyze_frequency)
            color: settings_form.secondaryText
            font.pixelSize: 10
            horizontalAlignment: Text.AlignHCenter
        }

        Rectangle {
            Layout.fillWidth: true
            Layout.fillHeight: true
            radius: 11
            color: settings_form.panelBackgroundRaised
            border.color: settings_form.lineColor
            clip: true

            ScrollView {
                id: chartScroller
                anchors.fill: parent
                anchors.margins: 5
                contentWidth: pollutionChart.width
                contentHeight: height
                clip: true
                ScrollBar.horizontal.policy: ScrollBar.AsNeeded
                ScrollBar.vertical.policy: ScrollBar.AlwaysOff

                ChartView {
                    id: pollutionChart
                    width: Math.max(chartScroller.width, root.displayedChannelCount * 90,
                                    filterCombo.currentIndex === 2 ? root.chartMinimumWidth : 0)
                    height: chartScroller.height
                    antialiasing: true
                    animationOptions: ChartView.SeriesAnimations
                    animationDuration: 180
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
                        var frequencies = _frequencyHelper.get_frequencies(filter)
                        root.displayedChannelCount = frequencies.length
                        categoryAxis.categories = _pollutionHelper.survey_labels(frequencies, metricCombo.currentIndex)
                        var values = _pollutionHelper.survey_values(frequencies, metricCombo.currentIndex)
                        pollutionBars.values = values
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
                            labelsFont.family: Qt.application.font.family
                            labelsFont.pixelSize: 11
                            gridVisible: false
                            lineVisible: false
                        }
                        axisY: ValueAxis {
                            id: qualityAxis
                            min: 0
                            max: 100
                            labelsColor: settings_form.secondaryText
                            labelsFont.family: Qt.application.font.family
                            labelsFont.pixelSize: 11
                            gridLineColor: settings_form.lineColor
                            lineVisible: false
                            labelFormat: "%.0f%%"
                            tickCount: 6
                        }
                        BarSet {
                            id: pollutionBars
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
            Layout.fillWidth: true
            text: qsTr("Higher energy or busy bars indicate occupied channels. Energy includes OpenHD traffic; stop Air transmission for an interference-only scan. Check both 20 MHz halves for 40 MHz. N/A means no measurement. Repeat to check intermittent interference. Swipe to inspect all channels.")
            color: settings_form.secondaryText
            font.pixelSize: 9
            horizontalAlignment: Text.AlignHCenter
            wrapMode: Text.WordWrap
        }
    }
}
