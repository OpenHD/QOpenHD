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

    property bool normalized: false
    property int chartMinimumWidth: 1080
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

    function controls() { return [filterCombo, normalizeSwitch, startButton] }

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

                ComboBox {
                    id: filterCombo
                    Layout.fillWidth: true
                    Layout.preferredHeight: 38
                    model: filterModel
                    textRole: "title"
                    enabled: !root.analyzing
                    onCurrentIndexChanged: pollutionChart.updatePollutionGraph()
                    Keys.onPressed: root.handleKey(filterCombo, event)
                }

                RowLayout {
                    Layout.preferredWidth: 142
                    spacing: 5
                    Switch {
                        id: normalizeSwitch
                        checked: root.normalized
                        enabled: !root.analyzing
                        onClicked: {
                            root.normalized = checked
                            pollutionChart.updatePollutionGraph()
                            if (root.normalized)
                                _qopenhd.show_toast(qsTr("Relative scaling can exaggerate small differences"))
                        }
                        Keys.onPressed: root.handleKey(normalizeSwitch, event)
                    }
                    Text {
                        text: root.normalized ? qsTr("RELATIVE") : qsTr("ABSOLUTE")
                        color: settings_form.secondaryText
                        font.pixelSize: 10
                        font.bold: true
                    }
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
                ScrollBar.horizontal.policy: ScrollBar.AlwaysOff
                ScrollBar.vertical.policy: ScrollBar.AlwaysOff

                ChartView {
                    id: pollutionChart
                    width: filterCombo.currentIndex === 2
                           ? Math.max(chartScroller.width, root.chartMinimumWidth)
                           : chartScroller.width
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
                        if (filter === 2)
                            frequencies = _frequencyHelper.filter_frequencies_40mhz_ht40plus_only(frequencies)
                        categoryAxis.categories = _pollutionHelper.pollution_frequencies_int_to_qstringlist(frequencies)
                        pollutionBars.values = _pollutionHelper.pollution_frequencies_int_get_pollution(frequencies, root.normalized)
                        qualityAxis.labelsVisible = !root.normalized
                        qualityAxis.min = 0
                        qualityAxis.max = root.normalized ? 100 : 30
                    }

                    BarSeries {
                        axisX: BarCategoryAxis {
                            id: categoryAxis
                            labelsColor: settings_form.secondaryText
                            gridVisible: false
                            lineVisible: false
                        }
                        axisY: CategoryAxis {
                            id: qualityAxis
                            min: 0
                            max: 30
                            labelsColor: settings_form.secondaryText
                            gridLineColor: settings_form.lineColor
                            lineVisible: false
                            labelsPosition: CategoryAxis.AxisLabelsPositionOnValue
                            CategoryRange { label: qsTr("perfect"); endValue: 0 }
                            CategoryRange { label: qsTr("good"); endValue: 10 }
                            CategoryRange { label: qsTr("medium"); endValue: 20 }
                            CategoryRange { label: qsTr("bad"); endValue: 30 }
                        }
                        BarSet {
                            id: pollutionBars
                            label: qsTr("Wi-Fi pollution estimate")
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
            text: qsTr("Lower bars indicate cleaner channels. Swipe horizontally to inspect the full 5.8 GHz range.")
            color: settings_form.secondaryText
            font.pixelSize: 9
            horizontalAlignment: Text.AlignHCenter
            wrapMode: Text.WordWrap
        }
    }
}
