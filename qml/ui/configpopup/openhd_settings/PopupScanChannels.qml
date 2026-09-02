import QtQuick 2.12
import QtQuick.Controls 2.12
import QtQuick.Layouts 1.12
import QtQuick.Controls.Material 2.12

import OpenHD 1.0

PopupBigGeneric {
    id: root
    m_title: qsTr("FIND AIR UNIT")
    m_modern_style: true
    focus: visible

    property bool scanning: _ohdSystemGround.is_alive && _ohdSystemGround.wb_gnd_operating_mode === 1
    property int scanProgress: Math.max(0, Math.min(100, _wbLinkSettingsHelper.scan_progress_perc))
    property bool scanFinished: !scanning && scanProgress >= 100

    Material.theme: settings_form.darkMode ? Material.Dark : Material.Light
    Material.accent: settings_form.accentColor
    Material.foreground: settings_form.primaryText
    Material.background: settings_form.panelBackgroundRaised

    function controls() { return [rangeCombo, bandwidthCombo, startButton] }

    function moveFocus(control, step) {
        var list = controls()
        var current = list.indexOf(control)
        var next = (current + step + list.length) % list.length
        list[next].forceActiveFocus()
    }

    function handleHorizontalKey(control, event) {
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

    function requestClose() {
        if (scanning) {
            _qopenhd.show_toast(qsTr("A channel scan is still running"))
            return
        }
        close()
    }

    function open() {
        visible = true
        enabled = true
        Qt.callLater(function() { rangeCombo.forceActiveFocus() })
    }

    function close() {
        visible = false
        enabled = false
    }

    function startScan() {
        var band = rangeCombo.currentIndex
        var widthMhz = settings.scan_channel_width_mhz
        var accepted = _wbLinkSettingsHelper.start_scan_channels(band, widthMhz)
        if (accepted)
            _qopenhd.show_toast(qsTr("Channel scan started"))
        else
            _qopenhd.show_toast(qsTr("The radio is busy. Please try again."))
    }

    onCloseButtonClicked: requestClose()
    Keys.onEscapePressed: requestClose()

    ListModel {
        id: channelModel
        ListElement { title: qsTr("OpenHD channels 1–7"); value: 0 }
        ListElement { title: qsTr("All 2.4 GHz channels"); value: 1 }
        ListElement { title: qsTr("All 5.8 GHz channels"); value: 2 }
    }

    ListModel { id: bandwidthModel }

    function rebuildBandwidthModel() {
        bandwidthModel.clear()
        bandwidthModel.append({title: qsTr("5 MHz"), value: 5})
        bandwidthModel.append({title: qsTr("10 MHz"), value: 10})
        bandwidthModel.append({title: qsTr("20 MHz"), value: 20})
        bandwidthModel.append({title: qsTr("40 MHz"), value: 40})
    }

    function syncBandwidthSelection() {
        for (var i = 0; i < bandwidthModel.count; ++i) {
            if (bandwidthModel.get(i).value === settings.scan_channel_width_mhz) {
                bandwidthCombo.currentIndex = i
                return
            }
        }
        if (bandwidthModel.count > 0) {
            bandwidthCombo.currentIndex = 0
            settings.scan_channel_width_mhz = bandwidthModel.get(0).value
        }
    }

    Component.onCompleted: {
        rebuildBandwidthModel()
        syncBandwidthSelection()
    }

    Flickable {
        id: scroller
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.top: parent.top
        anchors.bottom: parent.bottom
        anchors.topMargin: root.dirty_top_margin_for_implementation
        clip: true
        contentWidth: width
        contentHeight: Math.max(height, root.width >= 560 ? 410 : 550)
        boundsBehavior: Flickable.StopAtBounds
        flickableDirection: Flickable.VerticalFlick
        ScrollBar.vertical: ScrollBar { policy: ScrollBar.AlwaysOff }

        ColumnLayout {
            id: contentColumn
            width: Math.min(scroller.width - 28, 620)
            anchors.horizontalCenter: parent.horizontalCenter
            spacing: 10

            Item { Layout.preferredHeight: 4 }

            RowLayout {
                Layout.fillWidth: true
                spacing: 12
                Rectangle {
                    width: 34; height: 34; radius: 9
                    color: settings_form.darkMode ? "#173b61" : "#dcecff"
                    Text {
                        anchors.centerIn: parent
                        text: "\uf1eb"
                        color: settings_form.accentColor
                        font.family: "Font Awesome 5 Free"
                        font.pixelSize: 16
                    }
                }
                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 2
                    Text {
                        Layout.fillWidth: true
                        text: qsTr("Locate a running OpenHD air unit")
                        color: settings_form.primaryText
                        font.pixelSize: 15
                        font.bold: true
                    }
                    Text {
                        Layout.fillWidth: true
                        text: qsTr("The ground station checks each selected channel until it finds a compatible signal.")
                        color: settings_form.secondaryText
                        font.pixelSize: 10
                        wrapMode: Text.WordWrap
                    }
                }
            }

            Rectangle {
                Layout.fillWidth: true
                Layout.preferredHeight: root.width >= 560 ? 118 : 196
                radius: 12
                color: settings_form.panelBackgroundRaised
                border.color: settings_form.lineColor

                GridLayout {
                    anchors.fill: parent
                    anchors.margins: 11
                    columns: root.width >= 560 ? 2 : 1
                    columnSpacing: 10
                    rowSpacing: 7

                    ColumnLayout {
                        Layout.fillWidth: true
                        spacing: 5
                        Text {
                            text: qsTr("SCAN RANGE")
                            color: settings_form.secondaryText
                            font.pixelSize: 10
                            font.bold: true
                            font.letterSpacing: 1
                        }
                        ComboBox {
                            id: rangeCombo
                            Layout.fillWidth: true
                            Layout.preferredHeight: 34
                            model: channelModel
                            textRole: "title"
                            enabled: _ohdSystemGround.is_alive && !root.scanning
                            Keys.onPressed: root.handleHorizontalKey(rangeCombo, event)
                        }
                    }

                    ColumnLayout {
                        Layout.fillWidth: true
                        spacing: 5
                        Text {
                            text: qsTr("CHANNEL WIDTH")
                            color: settings_form.secondaryText
                            font.pixelSize: 10
                            font.bold: true
                            font.letterSpacing: 1
                        }
                        ComboBox {
                            id: bandwidthCombo
                            Layout.fillWidth: true
                            Layout.preferredHeight: 34
                            model: bandwidthModel
                            textRole: "title"
                            enabled: _ohdSystemGround.is_alive && !root.scanning
                            onCurrentIndexChanged: {
                                if (currentIndex >= 0)
                                    settings.scan_channel_width_mhz = bandwidthModel.get(currentIndex).value
                            }
                            Keys.onPressed: root.handleHorizontalKey(bandwidthCombo, event)
                        }
                    }

                    Button {
                        id: startButton
                        Layout.fillWidth: true
                        Layout.columnSpan: root.width >= 560 ? 2 : 1
                        Layout.preferredHeight: 36
                        text: root.scanning ? qsTr("SCANNING…") : qsTr("START SCAN")
                        enabled: _ohdSystemGround.is_alive && !root.scanning &&
                                 _ohdSystemGround.wb_gnd_operating_mode === 0
                        onClicked: root.startScan()
                        Keys.onPressed: root.handleHorizontalKey(startButton, event)
                        background: Rectangle {
                            radius: 10
                            color: startButton.enabled
                                   ? (startButton.hovered ? "#176fc7" : settings_form.accentColor)
                                   : settings_form.lineColor
                            border.color: startButton.activeFocus ? "#ffffff" : "transparent"
                            border.width: startButton.activeFocus ? 2 : 0
                        }
                        contentItem: Text {
                            text: startButton.text
                            color: startButton.enabled ? "#ffffff" : settings_form.secondaryText
                            font.pixelSize: 12
                            font.bold: true
                            horizontalAlignment: Text.AlignHCenter
                            verticalAlignment: Text.AlignVCenter
                        }
                    }
                }
            }

            Rectangle {
                Layout.fillWidth: true
                Layout.preferredHeight: 58
                radius: 12
                color: settings_form.panelBackgroundRaised
                border.color: settings_form.lineColor

                ColumnLayout {
                    anchors.fill: parent
                    anchors.margins: 11
                    spacing: 6
                    RowLayout {
                        Layout.fillWidth: true
                        Text {
                            text: root.scanning ? qsTr("Scanning channels")
                                                : (root.scanFinished ? qsTr("Scan complete") : qsTr("Ready"))
                            color: settings_form.primaryText
                            font.pixelSize: 12
                            font.bold: true
                            Layout.fillWidth: true
                        }
                        Text {
                            text: root.scanProgress + "%"
                            color: settings_form.accentColor
                            font.pixelSize: 12
                            font.bold: true
                        }
                    }
                    Rectangle {
                        Layout.fillWidth: true
                        Layout.preferredHeight: 6
                        radius: 3
                        color: settings_form.lineColor
                        Rectangle {
                            width: parent.width * root.scanProgress / 100
                            height: parent.height
                            radius: parent.radius
                            color: settings_form.accentColor
                            Behavior on width { NumberAnimation { duration: 180 } }
                        }
                    }
                }
            }

            Rectangle {
                Layout.fillWidth: true
                Layout.preferredHeight: 78
                radius: 12
                color: root.scanFinished
                       ? (settings_form.darkMode ? "#103326" : "#ecfaf2")
                       : settings_form.panelBackground
                border.color: root.scanFinished ? settings_form.goodColor : settings_form.lineColor

                RowLayout {
                    anchors.fill: parent
                    anchors.margins: 12
                    spacing: 11
                    Text {
                        text: root.scanFinished ? "\uf00c" : (root.scanning ? "\uf110" : "\uf05a")
                        color: root.scanFinished ? settings_form.goodColor : settings_form.accentColor
                        font.family: "Font Awesome 5 Free"
                        font.pixelSize: 17
                    }
                    ColumnLayout {
                        Layout.fillWidth: true
                        spacing: 3
                        Text {
                            Layout.fillWidth: true
                            text: root.scanFinished
                                  ? (_wbLinkSettingsHelper.scanning_text_for_ui.length > 0
                                     ? _wbLinkSettingsHelper.scanning_text_for_ui : qsTr("Channel scan finished"))
                                  : (root.scanning ? qsTr("Keep this window open while the radio scans.")
                                                   : (_ohdSystemGround.is_alive
                                                      ? qsTr("Choose a range and channel width, then start the scan.")
                                                      : qsTr("Ground station is offline.")))
                            color: settings_form.primaryText
                            font.pixelSize: 11
                            font.bold: root.scanFinished
                            wrapMode: Text.WordWrap
                        }
                        Text {
                            Layout.fillWidth: true
                            visible: root.scanFinished
                            text: qsTr("The link switches automatically when an air unit is found.")
                            color: settings_form.secondaryText
                            font.pixelSize: 10
                            wrapMode: Text.WordWrap
                        }
                    }
                }
            }

            Text {
                Layout.fillWidth: true
                text: qsTr("OpenHD channels 1–7 are the quickest option. Wider scans can take considerably longer.")
                color: settings_form.secondaryText
                font.pixelSize: 10
                horizontalAlignment: Text.AlignHCenter
                wrapMode: Text.WordWrap
            }

            Item { Layout.preferredHeight: 8 }
        }
    }
}
