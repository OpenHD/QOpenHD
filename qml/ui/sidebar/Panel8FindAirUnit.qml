import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.12

SideBarBasePanel {
    id: page
    override_title: "Find Air Unit"
    headerIcon: "\uf002"

    readonly property bool groundOnline: _ohdSystemGround.is_alive
    readonly property bool radioIdle: groundOnline && _ohdSystemGround.wb_gnd_operating_mode === 0
    readonly property bool scanning: groundOnline && _ohdSystemGround.wb_gnd_operating_mode === 1
    readonly property bool passive: settings.scan_passive_nexmon
    readonly property bool allow10MHz: !passive && _wbLinkSettingsHelper.ground_supports_10mhz
    readonly property int selectedBandwidth: settings.scan_channel_width_mhz === 40 ? 40
        : settings.scan_channel_width_mhz === 10 && allow10MHz ? 10 : 20
    readonly property int scanProgress: Math.max(0, Math.min(100, _wbLinkSettingsHelper.scan_progress_perc))
    readonly property string scanResult: _wbLinkSettingsHelper.scanning_text_for_ui
    readonly property bool showProgress: groundOnline && (scanning
        || (scanError.length === 0 && scanProgress === 100 && scanResult.length > 0))

    property int selectedBand: 0
    property string scanError: ""

    onScanningChanged: if (scanning) scanError = ""

    function takeover_control() {
        bandSelection.takeover_control()
    }

    function startScan() {
        if (!radioIdle) return

        scanError = ""
        if (!_wbLinkSettingsHelper.start_scan_channels(selectedBand, selectedBandwidth, passive))
            scanError = passive
                ? qsTr("Passive scan could not start. Check Nexmon availability and radio status.")
                : qsTr("Scan could not start. Check the ground radio and try again.")
    }

    ListModel {
        id: bands
        ListElement { value: 0; verbose: qsTr("OpenHD [1–7]") }
        ListElement { value: 1; verbose: qsTr("2.4 GHz") }
        ListElement { value: 2; verbose: qsTr("5.8 GHz") }
    }

    ListModel { id: bandwidths }

    function rebuildBandwidths() {
        if (choiceSelector.visible && choiceSelector.m_parent === bandwidthSelection)
            choiceSelector.discard_and_close()
        bandwidths.clear()
        if (allow10MHz) bandwidths.append({ value: 10, verbose: qsTr("10 MHz") })
        bandwidths.append({ value: 20, verbose: qsTr("20 MHz") })
        bandwidths.append({ value: 40, verbose: qsTr("40 MHz") })
    }
    Component.onCompleted: rebuildBandwidths()
    onAllow10MHzChanged: rebuildBandwidths()

    ColumnLayout {
        width: parent.width
        spacing: 0

        BaseJoyEditElement2 {
            id: bandSelection
            objectName: "scanBand"
            Layout.fillWidth: true
            rowIcon: "\uf012"
            m_title: "Channels"
            m_displayed_value: bands.get(page.selectedBand).verbose

            function openChoices(clickable) {
                choiceSelector.open_choices(bands, page.selectedBand, bandSelection)
                choiceSelector.set_clickable(clickable)
            }
            function user_selected_value(value) {
                page.selectedBand = Number(value)
            }

            Keys.onLeftPressed: sidebar.regain_control_on_sidebar_stack()
            Keys.onUpPressed: sidebar.regain_control_on_sidebar_stack()
            Keys.onDownPressed: bandwidthSelection.takeover_control()
            Keys.onRightPressed: openChoices(false)
            Keys.onReturnPressed: openChoices(false)
            Keys.onEnterPressed: openChoices(false)
            onBase_joy_edit_element_clicked: openChoices(true)
        }

        BaseJoyEditElement2 {
            id: bandwidthSelection
            objectName: "scanBandwidth"
            Layout.fillWidth: true
            rowIcon: "\uf337"
            m_title: "Bandwidth"
            m_displayed_value: qsTr("%1 MHz").arg(page.selectedBandwidth)

            function openChoices(clickable) {
                choiceSelector.open_choices(bandwidths, page.selectedBandwidth, bandwidthSelection)
                choiceSelector.set_clickable(clickable)
            }
            function user_selected_value(value) {
                var widthMhz = Number(value)
                if (widthMhz === 20 || widthMhz === 40 || (widthMhz === 10 && page.allow10MHz))
                    settings.scan_channel_width_mhz = widthMhz
            }

            Keys.onLeftPressed: sidebar.regain_control_on_sidebar_stack()
            Keys.onUpPressed: bandSelection.takeover_control()
            Keys.onDownPressed: if (modeSwitch.enabled) modeSwitch.forceActiveFocus()
            Keys.onRightPressed: openChoices(false)
            Keys.onReturnPressed: openChoices(false)
            Keys.onEnterPressed: openChoices(false)
            onBase_joy_edit_element_clicked: openChoices(true)
        }

        Rectangle {
            Layout.fillWidth: true
            Layout.leftMargin: 24
            Layout.rightMargin: 24
            Layout.topMargin: 14
            Layout.preferredHeight: modeRow.implicitHeight + 20
            radius: 12
            color: modeSwitch.activeFocus ? "#25455f" : "#203448"
            border.color: modeSwitch.activeFocus ? "#71d4ff" : "#365169"

            RowLayout {
                id: modeRow
                anchors.fill: parent
                anchors.leftMargin: 14
                anchors.rightMargin: 14
                spacing: 12

                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 3
                    Label {
                        Layout.fillWidth: true
                        text: qsTr("Passive scan")
                        font.pixelSize: 20
                        font.weight: Font.DemiBold
                        color: "#edf6ff"
                        elide: Text.ElideRight
                    }
                    Label {
                        Layout.fillWidth: true
                        text: page.passive ? qsTr("Nexmon · Filters by Air bandwidth")
                                           : qsTr("Primary radio")
                        color: "#acbfd1"
                        font.pixelSize: 17
                        elide: Text.ElideRight
                    }
                }

                Switch {
                    id: modeSwitch
                    Accessible.name: qsTr("Passive scan")
                    Layout.preferredWidth: 54
                    Layout.preferredHeight: 40
                    checked: page.passive
                    enabled: page.radioIdle
                    onToggled: settings.scan_passive_nexmon = checked
                    Keys.onUpPressed: bandwidthSelection.takeover_control()
                    Keys.onDownPressed: startButton.forceActiveFocus()
                    Keys.onLeftPressed: sidebar.regain_control_on_sidebar_stack()
                    Keys.onRightPressed: settings.scan_passive_nexmon = !checked
                    Keys.onReturnPressed: settings.scan_passive_nexmon = !checked
                    Keys.onEnterPressed: settings.scan_passive_nexmon = !checked

                    indicator: Rectangle {
                        x: (modeSwitch.width - width) / 2
                        y: (modeSwitch.height - height) / 2
                        width: 52
                        height: 28
                        radius: 14
                        color: modeSwitch.checked ? "#278bc3" : "#52677a"
                        Rectangle {
                            x: modeSwitch.checked ? parent.width - width - 3 : 3
                            anchors.verticalCenter: parent.verticalCenter
                            width: 22
                            height: 22
                            radius: 11
                            color: "#edf6ff"
                        }
                    }
                }
            }
        }

        Button {
            id: startButton
            objectName: "scanStart"
            Layout.fillWidth: true
            Layout.leftMargin: 24
            Layout.rightMargin: 24
            Layout.topMargin: 12
            Layout.preferredHeight: 52
            text: page.scanning ? qsTr("Scanning…") : qsTr("Start scan")
            enabled: page.radioIdle
            hoverEnabled: true
            font.pixelSize: 21
            font.weight: Font.DemiBold
            onClicked: page.startScan()
            Keys.onLeftPressed: sidebar.regain_control_on_sidebar_stack()
            Keys.onUpPressed: modeSwitch.forceActiveFocus()
            Keys.onRightPressed: page.startScan()
            Keys.onReturnPressed: page.startScan()
            Keys.onEnterPressed: page.startScan()

            background: Rectangle {
                radius: 12
                color: !startButton.enabled ? "#26394b"
                    : startButton.down ? "#225677"
                    : startButton.hovered || startButton.activeFocus ? "#2f6d93" : "#285879"
                border.color: startButton.activeFocus ? "#89dbff" : "#395c77"
                border.width: startButton.activeFocus ? 2 : 1
            }
            contentItem: Label {
                text: startButton.text
                font: startButton.font
                color: startButton.enabled ? "#f2f9ff" : "#adc1d2"
                horizontalAlignment: Text.AlignHCenter
                verticalAlignment: Text.AlignVCenter
            }
        }

        ColumnLayout {
            Layout.fillWidth: true
            Layout.leftMargin: 24
            Layout.rightMargin: 24
            Layout.topMargin: 14
            spacing: 6

            RowLayout {
                Layout.fillWidth: true
                Label {
                    objectName: "sidebarScanFeedback"
                    Layout.fillWidth: true
                    text: !page.groundOnline ? qsTr("Ground unit offline")
                        : page.scanError.length ? page.scanError
                        : page.showProgress && page.scanResult.length ? page.scanResult
                        : page.scanning ? qsTr("Searching for Air")
                        : !page.radioIdle ? qsTr("Ground radio busy") : qsTr("Ready to scan")
                    font.pixelSize: 18
                    color: page.groundOnline && page.scanError.length ? "#ffcb76" : "#acbfd1"
                    wrapMode: Text.WordWrap
                }
                Label {
                    visible: page.showProgress
                    text: qsTr("%1%").arg(page.scanProgress)
                    font.pixelSize: 18
                    color: "#d6f3ff"
                }
            }

            Rectangle {
                visible: page.showProgress
                Layout.fillWidth: true
                Layout.preferredHeight: 6
                radius: 3
                color: "#29445b"
                Rectangle {
                    width: parent.width * page.scanProgress / 100
                    height: parent.height
                    radius: parent.radius
                    color: "#67cbfb"
                }
            }
        }
    }
}
