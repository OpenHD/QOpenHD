import QtQuick 2.12
import QtQuick.Controls 2.12
import QtQuick.Layouts 1.12

Rectangle {
    id: root
    property var host
    property int cardIndex: -1
    property bool keyboardSelected: false
    property bool simulated: settings.dev_simulate_wifibroadcast_link
    implicitHeight: cardContent.implicitHeight + 16
    radius: 10
    color: settings_form.panelBackgroundRaised
    border.color: keyboardSelected ? settings_form.accentColor : settings_form.lineColor
    border.width: keyboardSelected ? 2 : 1

    ListModel { id: bandwidths }
    ListModel { id: mcsValues }
    ListModel {
        id: frequencyFilters
        ListElement { title: qsTr("OHD frequencies"); value: 0 }
        ListElement { title: qsTr("5.8 GHz"); value: 2 }
        ListElement { title: qsTr("2.4 GHz"); value: 1 }
    }

    property int currentFrequency: simulated ? 5805 : (_ohdSystemGround.curr_channel_mhz > 0
                                   ? _ohdSystemGround.curr_channel_mhz
                                   : (_wbLinkSettingsHelper.curr_channel_mhz > 0
                                      ? _wbLinkSettingsHelper.curr_channel_mhz
                                      : _ohdSystemAir.curr_channel_mhz))
    property int currentBandwidth: simulated ? 20 : (_ohdSystemGround.curr_channel_width_mhz > 0
                                   ? _ohdSystemGround.curr_channel_width_mhz
                                   : (_wbLinkSettingsHelper.curr_channel_width_mhz > 0
                                      ? _wbLinkSettingsHelper.curr_channel_width_mhz
                                      : _ohdSystemAir.curr_channel_width_mhz))
    property int currentMcs: simulated ? 4 : _ohdSystemAir.curr_mcs_index
    property int settingsRevision: _ohdSystemGroundSettings.update_count + _ohdSystemAirSettingsModel.update_count
    property bool adaptiveAvailable: settingsRevision >= 0 && _ohdSystemAirSettingsModel.param_int_exists("WB_ADAPT_CH")
    property bool fhssAvailable: settingsRevision >= 0 &&
                                 (_ohdSystemGroundSettings.param_int_exists("WB_FHSS") ||
                                  _ohdSystemAirSettingsModel.param_int_exists("WB_FHSS"))
    property bool dwellAvailable: settingsRevision >= 0 &&
                                 (_ohdSystemGroundSettings.param_int_exists("WB_FHSS_SLOT") ||
                                  _ohdSystemAirSettingsModel.param_int_exists("WB_FHSS_SLOT"))
    property bool pitModeAvailable: settingsRevision >= 0 && _ohdSystemAirSettingsModel.param_int_exists("WB_PIT_MODE")
    property bool airPowerAvailable: settingsRevision >= 0 && _ohdSystemAirSettingsModel.param_int_exists("TX_PWR_LVL")
    property bool groundPowerAvailable: settingsRevision >= 0 && _ohdSystemGroundSettings.param_int_exists("TX_PWR_LVL")
    property bool showAirPower: airPowerAvailable
    property bool showGroundPower: groundPowerAvailable
    property bool airSystemAlive: _ohdSystemAir.is_alive
    property bool groundSystemAlive: _ohdSystemGround.is_alive
    readonly property int linkSwitchRevision: _ohdSystemGroundSettings.update_count
    readonly property bool linkSwitchAvailable: linkSwitchRevision >= 0 && _ohdSystemGroundSettings.param_int_exists("WFB_LINK_EN")
    readonly property bool linkRoutingEnabled: !linkSwitchAvailable || _ohdSystemGroundSettings.get_cached_int("WFB_LINK_EN") !== 0

    function ensureLinkParametersFetched() {
        if (_ohdSystemAirSettingsModel.system_is_alive()
                && !_ohdSystemAirSettingsModel.has_params_fetched
                && !_ohdSystemAirSettingsModel.ui_is_busy)
            _ohdSystemAirSettingsModel.ensure_parameters_available()
        if (_ohdSystemGroundSettings.system_is_alive()
                && !_ohdSystemGroundSettings.has_params_fetched
                && !_ohdSystemGroundSettings.ui_is_busy)
            _ohdSystemGroundSettings.ensure_parameters_available()
    }

    function modelIndex(model, value) {
        for (var i = 0; i < model.count; ++i) if (model.get(i).value === value) return i
        return -1
    }
    function syncRadio() {
        if (!host || !host.frequencyModel) return
        frequency.currentIndex = modelIndex(host.frequencyModel, currentFrequency)
        bandwidth.currentIndex = modelIndex(bandwidths, currentBandwidth)
        mcs.currentIndex = modelIndex(mcsValues, currentMcs)
    }
    function rebuildEnumModel(target, paramId, suffix) {
        target.clear()
        var metadata = _ohdSystemAirSettingsModel.get_ui_metadata(paramId)
        var keys = metadata.keys || []
        var values = metadata.values || []
        for (var i = 0; i < values.length; ++i) {
            var value = Number(values[i])
            var title = suffix.length ? String(value) + suffix
                                      : (i < keys.length ? String(keys[i]) : String(value))
            target.append({title: title, value: value})
        }
    }
    function rebuildRadioModels() {
        rebuildEnumModel(bandwidths, "WB_CHANNEL_W", " MHz")
        rebuildEnumModel(mcsValues, "WB_MCS_INDEX", "")
        syncRadio()
    }
    function controls() {
        var result = linkSwitchAvailable ? [linkSwitch, scan, analyze, frequencyFilter, frequency, bandwidth, mcs]
                                         : [scan, analyze, frequencyFilter, frequency, bandwidth, mcs]
        var settings = [pitMode, airPower, groundPower, espAnalyseAir, espAnalyseGround, adaptive, fhss, dwell]
        for (var i = 0; i < settings.length; ++i)
            if (settings[i].visible && settings[i].focusControl && settings[i].focusControl.enabled)
                result.push(settings[i].focusControl)
        return result.filter(function(item) { return item.visible && item.enabled })
    }
    function moveFocus(step) {
        var list = controls(), current = -1
        for (var i = 0; i < list.length; ++i) if (list[i].activeFocus) current = i
        if (!list.length) return
        focusAndReveal(list[(current + step + list.length) % list.length])
    }
    function focusAndReveal(item) {
        if (!item) return
        item.forceActiveFocus()
        if (host) Qt.callLater(function() { host.ensureItemVisible(item) })
    }
    function keyNav(event) {
        if (event.key === Qt.Key_Down || event.key === Qt.Key_Right) { moveFocus(1); event.accepted = true }
        else if (event.key === Qt.Key_Left) { moveFocus(-1); event.accepted = true }
        else if (event.key === Qt.Key_Up) { moveFocus(-1); event.accepted = true }
        else if (event.key === Qt.Key_Escape) { leaveCard(); event.accepted = true }
    }
    function leaveCard() { if (host) host.collapseCard(cardIndex) }
    function gainFocus() { var list = controls(); if (list.length) focusAndReveal(list[0]) }
    function animateScan() { scanAnimation.start() }
    function formatUptime(ms) {
        if (ms <= 0) return ""
        var seconds = Math.floor(ms / 1000), hours = Math.floor(seconds / 3600)
        var minutes = Math.floor((seconds % 3600) / 60); seconds %= 60
        return (hours < 10 ? "0" : "") + hours + ":" + (minutes < 10 ? "0" : "") + minutes + ":" + (seconds < 10 ? "0" : "") + seconds
    }

    property string radioRevision: currentFrequency + ":" + currentBandwidth + ":" + currentMcs
    onRadioRevisionChanged: syncRadio()
    onHostChanged: syncRadio()
    onAirSystemAliveChanged: if (airSystemAlive) ensureLinkParametersFetched()
    onGroundSystemAliveChanged: if (groundSystemAlive) ensureLinkParametersFetched()
    property int parameterRevision: _ohdSystemAirSettingsModel.update_count
    onParameterRevisionChanged: rebuildRadioModels()
    Component.onCompleted: {
        rebuildRadioModels()
        ensureLinkParametersFetched()
    }

    ColumnLayout {
        id: cardContent
        anchors.top: parent.top; anchors.left: parent.left; anchors.right: parent.right
        anchors.margins: 8; spacing: 7
        RowLayout {
            Layout.fillWidth: true; Layout.preferredHeight: 36; spacing: 8
            Text { text: "\uf1eb"; color: "#55aaff"; font.family: "Font Awesome 5 Free"; font.pixelSize: 18 }
            Text { text: qsTr("WiFiBroadcast Link"); color: settings_form.primaryText; font.pixelSize: 12; font.bold: true; Layout.fillWidth: true }
            Switch {
                id: linkSwitch
                visible: _qopenhd.debugMenuPreview || (root.linkSwitchAvailable && !root.simulated && root.host && root.host.bothMultiEnabled)
                enabled: _ohdSystemGround.is_alive && !_ohdSystemGroundSettings.ui_is_busy
                text: checked ? qsTr("ENABLED") : qsTr("DISABLED")
                onClicked: _ohdSystemGroundSettings.try_set_param_int_async("WFB_LINK_EN", checked ? 1 : 0, true)
                Keys.onPressed: root.keyNav(event)
            }
            Binding { target: linkSwitch; property: "checked"; value: root.linkRoutingEnabled }
            Rectangle { visible: !linkSwitch.visible; Layout.preferredWidth: activeText.implicitWidth + 14; Layout.preferredHeight: 21; radius: 7; color: root.simulated || (root.airSystemAlive && root.groundSystemAlive && root.linkRoutingEnabled) ? Qt.rgba(0.1, 0.8, 0.35, 0.12) : settings_form.panelBackground
                Text { id: activeText; anchors.centerIn: parent; text: root.simulated ? qsTr("SIMULATED") : !root.groundSystemAlive ? qsTr("GROUND OFFLINE") : !root.airSystemAlive ? qsTr("AIR OFFLINE") : !root.linkRoutingEnabled ? qsTr("DISABLED") : qsTr("UNITS ONLINE"); color: root.simulated || (root.airSystemAlive && root.groundSystemAlive && root.linkRoutingEnabled) ? settings_form.goodColor : settings_form.secondaryText; font.pixelSize: 8; font.bold: true }
            }
        }

        GridLayout {
            Layout.fillWidth: true; Layout.preferredHeight: root.width < 360 ? 88 : 44; Layout.maximumHeight: Layout.preferredHeight; columns: root.width < 360 ? 2 : 4; columnSpacing: 4; rowSpacing: 4
            Repeater {
                model: [
                    {label: qsTr("LOSS"), value: root.simulated ? "0%" : (!root.groundSystemAlive || _ohdSystemGround.curr_rx_packet_loss_perc < 0 ? qsTr("N/A") : _ohdSystemGround.curr_rx_packet_loss_perc + "%"), bad: !root.simulated && root.groundSystemAlive && _ohdSystemGround.curr_rx_packet_loss_perc > 5},
                    {label: qsTr("POLLUTION"), value: root.simulated ? "3 pps" : (!root.groundSystemAlive || _ohdSystemGround.wb_link_curr_foreign_pps < 0 ? qsTr("N/A") : _ohdSystemGround.wb_link_curr_foreign_pps + " pps"), bad: !root.simulated && root.groundSystemAlive && _ohdSystemGround.wb_link_curr_foreign_pps > 20},
                    {label: qsTr("TX DROPS"), value: root.simulated ? "0" : (root.airSystemAlive ? String(_ohdSystemAir.count_tx_dropped_packets) : qsTr("N/A")), bad: !root.simulated && root.airSystemAlive && _ohdSystemAir.count_tx_dropped_packets > 0,
                     details: qsTr("Packets that could not be transmitted. Slow injections (at least 1 ms): %1. Counts accumulate during the radio session.").arg(root.simulated ? 0 : _ohdSystemAir.count_tx_inj_error_hint)},
                    {label: qsTr("LINK LOAD"), value: root.simulated ? "42%" : (!root.groundSystemAlive || _ohdSystemGround.wb_link_pollution_perc < 0 ? qsTr("N/A") : _ohdSystemGround.wb_link_pollution_perc + "%"), bad: !root.simulated && root.groundSystemAlive && _ohdSystemGround.wb_link_pollution_perc > 75}
                ]
                delegate: Rectangle {
                    Layout.fillWidth: true; Layout.fillHeight: true; Layout.minimumHeight: 40; radius: 5; color: settings_form.panelBackground; border.color: settings_form.lineColor
                    Column { anchors.centerIn: parent; spacing: 1
                        Text { anchors.horizontalCenter: parent.horizontalCenter; text: modelData.label; color: settings_form.secondaryText; font.pixelSize: 8; font.bold: true }
                        Text { anchors.horizontalCenter: parent.horizontalCenter; text: modelData.value; color: modelData.bad ? settings_form.errorColor : settings_form.primaryText; font.pixelSize: 12; font.bold: true }
                    }
                }
            }
        }

        Rectangle {
            Layout.fillWidth: true
            Layout.preferredHeight: radioContent.implicitHeight + 24
            radius: 10; color: settings_form.panelBackground; border.color: settings_form.lineColor
            ColumnLayout {
                id: radioContent
                anchors.fill: parent; anchors.margins: 12; spacing: 10
                Text { text: qsTr("Channel & frequency"); color: settings_form.primaryText; font.pixelSize: 15; font.bold: true }
                GridLayout {
                    Layout.fillWidth: true
                    columns: root.width < 650 ? 1 : 2
                    columnSpacing: 12; rowSpacing: 12
                    Rectangle {
                        Layout.fillWidth: true; Layout.fillHeight: true; Layout.preferredWidth: 320
                        Layout.preferredHeight: 184
                        radius: 8; color: settings_form.panelBackgroundRaised
                        ColumnLayout {
                            id: discoveryContent
                            anchors.top: parent.top; anchors.left: parent.left; anchors.right: parent.right
                            anchors.margins: 12; spacing: 10
                            Text { text: qsTr("Find a channel"); color: settings_form.primaryText; font.pixelSize: 12; font.bold: true }
                            Text { Layout.fillWidth: true; text: qsTr("Scan to find your Air unit, or analyze interference before choosing a frequency."); color: settings_form.secondaryText; font.pixelSize: 11; wrapMode: Text.WordWrap }
                            RowLayout {
                                Layout.fillWidth: true; spacing: 8
                                Button {
                                    id: scan
                                    Layout.fillWidth: true; Layout.preferredWidth: 1; Layout.minimumWidth: 0; Layout.preferredHeight: 64
                                    enabled: !root.simulated; text: qsTr("Scan"); hoverEnabled: true
                                    contentItem: Item {
                                      Column {
                                        width: parent.width; anchors.verticalCenter: parent.verticalCenter; spacing: 5
                                        Text { width: parent.width; text: scan.text; color: "white"; font.pixelSize: 15; font.bold: true; horizontalAlignment: Text.AlignHCenter }
                                        Text { width: parent.width; text: qsTr("Find Air unit"); color: "white"; font.pixelSize: 10; horizontalAlignment: Text.AlignHCenter }
                                      }
                                    }
                                    background: Rectangle { radius: 8; color: scan.down ? Qt.darker(settings_form.accentColor, 1.2) : (scan.hovered ? Qt.lighter(settings_form.accentColor, 1.1) : settings_form.accentColor); opacity: scan.enabled ? 1 : 0.45; border.color: scan.activeFocus ? settings_form.primaryText : settings_form.accentColor; border.width: scan.activeFocus ? 2 : 1 }
                                    onClicked: if (host) host.openScan()
                                    Keys.onPressed: root.keyNav(event)
                                }
                                Button {
                                    id: analyze
                                    Layout.fillWidth: true; Layout.preferredWidth: 1; Layout.minimumWidth: 0; Layout.preferredHeight: 64
                                    enabled: !root.simulated; text: qsTr("Analyze"); hoverEnabled: true
                                    contentItem: Item {
                                      Column {
                                        width: parent.width; anchors.verticalCenter: parent.verticalCenter; spacing: 5
                                        Text { width: parent.width; text: analyze.text; color: settings_form.primaryText; font.pixelSize: 15; font.bold: true; horizontalAlignment: Text.AlignHCenter }
                                        Text { width: parent.width; text: qsTr("Check interference"); color: settings_form.secondaryText; font.pixelSize: 10; horizontalAlignment: Text.AlignHCenter }
                                      }
                                    }
                                    background: Rectangle { radius: 8; color: analyze.down || analyze.hovered ? settings_form.panelBackgroundRaised : settings_form.panelBackground; border.color: analyze.activeFocus || analyze.hovered ? settings_form.accentColor : settings_form.lineColor; border.width: analyze.activeFocus ? 2 : 1; opacity: analyze.enabled ? 1 : 0.6 }
                                    onClicked: if (host) host.openAnalyze()
                                    Keys.onPressed: root.keyNav(event)
                                }
                            }
                        }
                    }
                    Rectangle {
                        Layout.fillWidth: true; Layout.fillHeight: true; Layout.preferredWidth: 480
                        Layout.preferredHeight: channelContent.implicitHeight + 24
                        radius: 8; color: settings_form.panelBackgroundRaised
                        ColumnLayout {
                            id: channelContent
                            anchors.top: parent.top; anchors.left: parent.left; anchors.right: parent.right
                            anchors.margins: 12; spacing: 7
                            RowLayout {
                                Layout.fillWidth: true; spacing: 8
                                Text { Layout.fillWidth: true; text: qsTr("Radio settings"); color: settings_form.primaryText; font.pixelSize: 12; font.bold: true }
                                CompactLinkComboBox {
                                    id: frequencyFilter
                                    Layout.preferredWidth: 140; Layout.preferredHeight: 32; font.pixelSize: 11
                                    model: frequencyFilters; textRole: "title"
                                    currentIndex: root.modelIndex(frequencyFilters, settings.qopenhd_frequency_filter_selection)
                                    onActivated: { settings.qopenhd_frequency_filter_selection = frequencyFilters.get(currentIndex).value; root.syncRadio() }
                                    Keys.onPressed: root.keyNav(event)
                                }
                            }
                            Text { text: qsTr("Channel / frequency"); color: settings_form.secondaryText; font.pixelSize: 10 }
                            CompactLinkComboBox {
                                id: frequency
                                Layout.fillWidth: true; Layout.preferredHeight: 44; font.pixelSize: 14; font.bold: true
                                model: host ? host.frequencyModel : null; textRole: "title"; popupWidth: Math.max(width, 250)
                                displayText: root.currentFrequency > 0 && host ? host.formatFrequency(root.currentFrequency) : qsTr("N/A")
                                enabled: !root.simulated
                                onActivated: if (host) host.chooseFrequency(currentIndex)
                                Keys.onPressed: root.keyNav(event)
                            }
                            RowLayout {
                                Layout.fillWidth: true; spacing: 10
                                ColumnLayout {
                                    Layout.fillWidth: true; spacing: 4
                                    Text { text: qsTr("Channel width"); color: settings_form.secondaryText; font.pixelSize: 10 }
                                    CompactLinkComboBox { id: bandwidth; Layout.fillWidth: true; Layout.preferredHeight: 40; font.pixelSize: 12; model: bandwidths; textRole: "title"; displayText: root.currentBandwidth > 0 ? qsTr("%1 MHz").arg(root.currentBandwidth) : qsTr("N/A"); enabled: !root.simulated && _ohdSystemAir.is_alive; onActivated: if (currentIndex >= 0) _wbLinkSettingsHelper.change_param_air_channel_width_async(bandwidths.get(currentIndex).value, true); Keys.onPressed: root.keyNav(event) }
                                }
                                ColumnLayout {
                                    Layout.fillWidth: true; spacing: 4
                                    Text { text: qsTr("MCS"); color: settings_form.secondaryText; font.pixelSize: 10 }
                                    CompactLinkComboBox { id: mcs; Layout.fillWidth: true; Layout.preferredHeight: 40; font.pixelSize: 12; model: mcsValues; textRole: "title"; displayText: root.currentMcs >= 0 ? qsTr("MCS %1").arg(root.currentMcs) : qsTr("N/A"); enabled: !root.simulated && _ohdSystemAir.is_alive; onActivated: if (currentIndex >= 0) _wbLinkSettingsHelper.set_param_air_only_mcs_async(mcsValues.get(currentIndex).value); Keys.onPressed: root.keyNav(event) }
                                }
                            }
                        }
                    }
                }
            }
            SequentialAnimation { id: scanAnimation; loops: 3; PropertyAnimation { target: scan; property: "scale"; to: 1.04; duration: 130 } PropertyAnimation { target: scan; property: "scale"; to: 1; duration: 130 } }
        }

        Rectangle {
            visible: root.pitModeAvailable || root.showAirPower || root.showGroundPower
            Layout.fillWidth: true; Layout.preferredHeight: 91; radius: 7; color: settings_form.panelBackground; border.color: settings_form.lineColor
            RowLayout { anchors.fill: parent; anchors.margins: 7; spacing: 10
                DynamicLinkSetting {
                    id: pitMode
                    Layout.preferredWidth: Math.min(220, parent.width * 0.24)
                    Layout.fillHeight: true
                    visible: _qopenhd.debugMenuPreview || (root.pitModeAvailable)
                    editorEnabled: root.pitModeAvailable
                    settingsModel: _ohdSystemAirSettingsModel
                    paramId: "WB_PIT_MODE"
                    label: qsTr("Pit Mode")
                    onMoveRequested: root.moveFocus(step)
                    onBackRequested: root.leaveCard()
                }
                Rectangle {
                    visible: pitMode.visible
                    Layout.preferredWidth: 1; Layout.fillHeight: true
                    color: settings_form.lineColor
                }
                ColumnLayout {
                    Layout.fillWidth: true; Layout.fillHeight: true; spacing: 1
                    Text { text: qsTr("TX POWER"); color: settings_form.secondaryText; font.pixelSize: 8; font.bold: true }
                    RowLayout { Layout.fillWidth: true; spacing: 14
                        DynamicLinkSetting { id: airPower; Layout.fillWidth: true; visible: root.showAirPower; editorEnabled: root.airPowerAvailable; settingsModel: _ohdSystemAirSettingsModel; paramId: "TX_PWR_LVL"; label: qsTr("Air"); valueSuffix: "%"; preferSlider: true; preferredStepSize: 10; overrideSliderRange: true; preferredMinimum: 0; preferredMaximum: (settings.dev_show_advanced_button || _qopenhd.debugMenuPreview) ? 150 : 100; dangerAboveEnabled: settings.dev_show_advanced_button; dangerAbove: 100; detentEnabled: settings.dev_show_advanced_button; detentValue: 100; onMoveRequested: root.moveFocus(step); onBackRequested: root.leaveCard() }
                        DynamicLinkSetting { id: groundPower; Layout.fillWidth: true; visible: root.showGroundPower; editorEnabled: root.groundPowerAvailable; settingsModel: _ohdSystemGroundSettings; paramId: "TX_PWR_LVL"; label: qsTr("Ground"); valueSuffix: "%"; preferSlider: true; preferredStepSize: 10; overrideSliderRange: true; preferredMinimum: 0; preferredMaximum: (settings.dev_show_advanced_button || _qopenhd.debugMenuPreview) ? 150 : 100; dangerAboveEnabled: settings.dev_show_advanced_button; dangerAbove: 100; detentEnabled: settings.dev_show_advanced_button; detentValue: 100; onMoveRequested: root.moveFocus(step); onBackRequested: root.leaveCard() }
                    }
                }
            }
        }

        RowLayout {
            Layout.fillWidth: true
            visible: _qopenhd.debugMenuPreview || (settings.dev_show_advanced_button && root.settingsRevision >= 0 &&
                     (_ohdSystemAirSettingsModel.param_int_exists("ESP_ANALYSE") ||
                      _ohdSystemGroundSettings.param_int_exists("ESP_ANALYSE")))
            DynamicLinkSetting {
                id: espAnalyseAir
                Layout.fillWidth: true
                visible: _qopenhd.debugMenuPreview || (root.settingsRevision >= 0 && _ohdSystemAirSettingsModel.param_int_exists("ESP_ANALYSE"))
                settingsModel: _ohdSystemAirSettingsModel
                paramId: "ESP_ANALYSE"
                label: qsTr("ESP analysis (Air)")
                preferRadioToggle: true
                onMoveRequested: root.moveFocus(step)
                onBackRequested: root.leaveCard()
            }
            DynamicLinkSetting {
                id: espAnalyseGround
                Layout.fillWidth: true
                visible: _qopenhd.debugMenuPreview || (root.settingsRevision >= 0 && _ohdSystemGroundSettings.param_int_exists("ESP_ANALYSE"))
                settingsModel: _ohdSystemGroundSettings
                paramId: "ESP_ANALYSE"
                label: qsTr("ESP analysis (Ground)")
                preferRadioToggle: true
                onMoveRequested: root.moveFocus(step)
                onBackRequested: root.leaveCard()
            }
        }

        Rectangle {
            visible: _qopenhd.debugMenuPreview || (root.adaptiveAvailable || (settings.dev_show_advanced_button && (root.fhssAvailable || root.dwellAvailable)))
            Layout.fillWidth: true; Layout.preferredHeight: visible ? 66 : 0
            radius: 7; color: settings_form.panelBackground; border.color: settings_form.lineColor
            RowLayout { anchors.fill: parent; anchors.margins: 7; spacing: 10
                DynamicLinkSetting { id: adaptive; Layout.fillWidth: true; visible: _qopenhd.debugMenuPreview || (root.adaptiveAvailable); settingsModel: _ohdSystemAirSettingsModel; paramId: "WB_ADAPT_CH"; label: qsTr("Adaptive Link"); preferRadioToggle: true; onMoveRequested: root.moveFocus(step); onBackRequested: root.leaveCard() }
                ColumnLayout {
                    visible: _qopenhd.debugMenuPreview || (settings.dev_show_advanced_button && (root.fhssAvailable || root.dwellAvailable))
                    Layout.fillWidth: true
                    Layout.minimumWidth: root.dwellAvailable ? 210 : 120
                    spacing: 1
                    Text { text: qsTr("FHSS"); color: settings_form.secondaryText; font.pixelSize: 8; font.bold: true }
                    RowLayout {
                        Layout.fillWidth: true; spacing: 10
                        DynamicLinkSetting { id: fhss; Layout.preferredWidth: 190; visible: _qopenhd.debugMenuPreview || (root.fhssAvailable); settingsModel: _ohdSystemGroundSettings; paramId: "WB_FHSS"; label: qsTr("Enable"); preferRadioToggle: true; commitHandler: function(value) { host.setFhss(value !== 0) }; onMoveRequested: root.moveFocus(step); onBackRequested: root.leaveCard() }
                        DynamicLinkSetting { id: dwell; Layout.fillWidth: true; visible: _qopenhd.debugMenuPreview || (root.dwellAvailable); settingsModel: _ohdSystemGroundSettings.param_int_exists("WB_FHSS_SLOT") ? _ohdSystemGroundSettings : _ohdSystemAirSettingsModel; paramId: "WB_FHSS_SLOT"; label: qsTr("Dwell"); commitHandler: function(value) { host.setBoth("WB_FHSS_SLOT", value) }; onMoveRequested: root.moveFocus(step); onBackRequested: root.leaveCard() }
                    }
                }
            }
        }

        LinkUsageMeter {
            visible: _qopenhd.debugMenuPreview || (settings.dev_show_advanced_button)
            Layout.fillWidth: true
            Layout.preferredHeight: implicitHeight
            usage: root.host ? root.host.usageFor("wifi") : null
            title: qsTr("Link Usage")
        }

        RowLayout {
            Layout.fillWidth: true; Layout.preferredHeight: 25; spacing: 6
            Text { Layout.fillWidth: true; text: qsTr("Driver: %1").arg(root.simulated ? "RTL8812AU" : _wifi_card_air.card_type_as_string); color: settings_form.secondaryText; font.pixelSize: 7; elide: Text.ElideRight }
            Text { visible: _ohdSystemAir.onboard_uptime_ms > 0; text: qsTr("Uptime: %1").arg(root.formatUptime(_ohdSystemAir.onboard_uptime_ms)); color: settings_form.secondaryText; font.pixelSize: 7 }
        }
    }
}
