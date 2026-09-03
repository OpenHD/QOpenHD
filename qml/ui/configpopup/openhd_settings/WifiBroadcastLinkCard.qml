import QtQuick 2.12
import QtQuick.Controls 2.12
import QtQuick.Layouts 1.12

Rectangle {
    id: root
    property var host
    property int cardIndex: -1
    property bool keyboardSelected: false
    radius: 10
    color: settings_form.panelBackgroundRaised
    border.color: keyboardSelected ? settings_form.accentColor : settings_form.lineColor
    border.width: keyboardSelected ? 2 : 1

    ListModel { id: bandwidths }
    ListModel { id: mcsValues }

    property int currentFrequency: _ohdSystemGround.curr_channel_mhz > 0
                                   ? _ohdSystemGround.curr_channel_mhz
                                   : (_wbLinkSettingsHelper.curr_channel_mhz > 0
                                      ? _wbLinkSettingsHelper.curr_channel_mhz
                                      : _ohdSystemAir.curr_channel_mhz)
    property int currentBandwidth: _ohdSystemGround.curr_channel_width_mhz > 0
                                   ? _ohdSystemGround.curr_channel_width_mhz
                                   : (_wbLinkSettingsHelper.curr_channel_width_mhz > 0
                                      ? _wbLinkSettingsHelper.curr_channel_width_mhz
                                      : _ohdSystemAir.curr_channel_width_mhz)
    property int currentMcs: _ohdSystemAir.curr_mcs_index
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

    function ensureLinkParametersFetched() {
        if (_ohdSystemAirSettingsModel.system_is_alive()
                && !_ohdSystemAirSettingsModel.has_params_fetched
                && !_ohdSystemAirSettingsModel.ui_is_busy)
            _ohdSystemAirSettingsModel.try_refetch_all_parameters_async(false)
        if (_ohdSystemGroundSettings.system_is_alive()
                && !_ohdSystemGroundSettings.has_params_fetched
                && !_ohdSystemGroundSettings.ui_is_busy)
            _ohdSystemGroundSettings.try_refetch_all_parameters_async(false)
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
        var result = [scan, analyze, frequency, bandwidth, mcs]
        var settings = [adaptive, fhss, dwell, pitMode, airPower, groundPower]
        for (var i = 0; i < settings.length; ++i)
            if (settings[i].visible && settings[i].focusControl && settings[i].focusControl.enabled)
                result.push(settings[i].focusControl)
        return result
    }
    function moveFocus(step) {
        var list = controls(), current = -1
        for (var i = 0; i < list.length; ++i) if (list[i].activeFocus) current = i
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
    function gainFocus() { focusAndReveal(scan) }
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
        anchors.fill: parent; anchors.margins: 8; spacing: 5
        RowLayout {
            Layout.fillWidth: true; Layout.preferredHeight: 36; spacing: 8
            Text { text: "\uf1eb"; color: "#55aaff"; font.family: "Font Awesome 5 Free"; font.pixelSize: 18 }
            Text { text: qsTr("WiFiBroadcast Link"); color: settings_form.primaryText; font.pixelSize: 12; font.bold: true; Layout.fillWidth: true }
            Rectangle { width: activeText.implicitWidth + 14; height: 21; radius: 7; color: Qt.rgba(0.1, 0.8, 0.35, 0.12)
                Text { id: activeText; anchors.centerIn: parent; text: qsTr("ACTIVE"); color: settings_form.goodColor; font.pixelSize: 8; font.bold: true }
            }
        }

        GridLayout {
            Layout.fillWidth: true; Layout.preferredHeight: 48; columns: 4; columnSpacing: 0; rowSpacing: 0
            Repeater {
                model: [
                    {label: qsTr("LOSS"), value: _ohdSystemGround.curr_rx_packet_loss_perc < 0 ? qsTr("N/A") : _ohdSystemGround.curr_rx_packet_loss_perc + "%", bad: _ohdSystemGround.curr_rx_packet_loss_perc > 5},
                    {label: qsTr("POLLUTION"), value: _ohdSystemGround.wb_link_curr_foreign_pps < 0 ? qsTr("N/A") : _ohdSystemGround.wb_link_curr_foreign_pps + " pps", bad: _ohdSystemGround.wb_link_curr_foreign_pps > 20},
                    {label: qsTr("TX ERRORS"), value: String(_ohdSystemAir.count_tx_inj_error_hint), bad: _ohdSystemAir.count_tx_inj_error_hint > 0},
                    {label: qsTr("LINK LOAD"), value: _ohdSystemGround.wb_link_pollution_perc < 0 ? qsTr("N/A") : _ohdSystemGround.wb_link_pollution_perc + "%", bad: _ohdSystemGround.wb_link_pollution_perc > 75}
                ]
                delegate: Rectangle {
                    Layout.fillWidth: true; Layout.fillHeight: true; color: settings_form.panelBackground; border.color: settings_form.lineColor
                    Column { anchors.centerIn: parent; spacing: 1
                        Text { anchors.horizontalCenter: parent.horizontalCenter; text: modelData.label; color: settings_form.secondaryText; font.pixelSize: 7; font.bold: true }
                        Text { anchors.horizontalCenter: parent.horizontalCenter; text: modelData.value; color: modelData.bad ? settings_form.errorColor : settings_form.primaryText; font.pixelSize: 10; font.bold: true }
                    }
                }
            }
        }

        RowLayout {
            Layout.fillWidth: true; Layout.preferredHeight: 31; spacing: 5
            Item { Layout.fillWidth: true }
            Button {
                id: scan; Layout.preferredWidth: 88; Layout.preferredHeight: 29
                text: qsTr("SCAN"); hoverEnabled: true
                contentItem: Text { text: scan.text; color: scan.activeFocus || scan.hovered ? settings_form.accentColor : settings_form.primaryText; font.pixelSize: 9; font.bold: true; horizontalAlignment: Text.AlignHCenter; verticalAlignment: Text.AlignVCenter }
                background: Rectangle { radius: 7; color: scan.down ? Qt.rgba(0.12, 0.55, 1, 0.18) : (scan.hovered ? settings_form.panelBackgroundRaised : settings_form.panelBackground); border.color: scan.activeFocus || scan.hovered ? settings_form.accentColor : settings_form.lineColor; border.width: scan.activeFocus ? 2 : 1 }
                onClicked: host.openScan(); Keys.onPressed: root.keyNav(event)
            }
            Button {
                id: analyze; Layout.preferredWidth: 88; Layout.preferredHeight: 29
                text: qsTr("ANALYZE"); hoverEnabled: true
                contentItem: Text { text: analyze.text; color: analyze.activeFocus || analyze.hovered ? settings_form.accentColor : settings_form.primaryText; font.pixelSize: 9; font.bold: true; horizontalAlignment: Text.AlignHCenter; verticalAlignment: Text.AlignVCenter }
                background: Rectangle { radius: 7; color: analyze.down ? Qt.rgba(0.12, 0.55, 1, 0.18) : (analyze.hovered ? settings_form.panelBackgroundRaised : settings_form.panelBackground); border.color: analyze.activeFocus || analyze.hovered ? settings_form.accentColor : settings_form.lineColor; border.width: analyze.activeFocus ? 2 : 1 }
                onClicked: host.openAnalyze(); Keys.onPressed: root.keyNav(event)
            }
            Item { Layout.fillWidth: true }
            SequentialAnimation { id: scanAnimation; loops: 3; PropertyAnimation { target: scan; property: "scale"; to: 1.08; duration: 130 } PropertyAnimation { target: scan; property: "scale"; to: 1; duration: 130 } }
        }

        Rectangle {
            Layout.fillWidth: true; Layout.preferredHeight: 92; radius: 7; color: settings_form.panelBackground; border.color: settings_form.lineColor
            ColumnLayout { anchors.fill: parent; anchors.margins: 7; spacing: 4
                Text { text: qsTr("FREQUENCY / RADIO"); color: settings_form.secondaryText; font.pixelSize: 8; font.bold: true }
                RowLayout { Layout.fillWidth: true; spacing: 6
                    ColumnLayout { Layout.fillWidth: true; spacing: 1
                        Text { text: qsTr("Channel"); color: settings_form.secondaryText; font.pixelSize: 7 }
                        CompactLinkComboBox { id: frequency; Layout.fillWidth: true; Layout.preferredHeight: 31; model: host ? host.frequencyModel : null; textRole: "title"; popupWidth: Math.max(width, 250); displayText: root.currentFrequency > 0 && host ? host.formatFrequency(root.currentFrequency) : qsTr("N/A"); onActivated: if (host) host.chooseFrequency(currentIndex); Keys.onPressed: root.keyNav(event) }
                    }
                    ColumnLayout { Layout.fillWidth: true; spacing: 1
                        Text { text: qsTr("Channel Width"); color: settings_form.secondaryText; font.pixelSize: 7 }
                        CompactLinkComboBox { id: bandwidth; Layout.fillWidth: true; Layout.preferredHeight: 31; model: bandwidths; textRole: "title"; displayText: root.currentBandwidth > 0 ? qsTr("%1 MHz").arg(root.currentBandwidth) : qsTr("N/A"); enabled: _ohdSystemAir.is_alive; onActivated: if (currentIndex >= 0) _wbLinkSettingsHelper.change_param_air_channel_width_async(bandwidths.get(currentIndex).value, true); Keys.onPressed: root.keyNav(event) }
                    }
                    ColumnLayout { Layout.fillWidth: true; spacing: 1
                        Text { text: qsTr("MCS"); color: settings_form.secondaryText; font.pixelSize: 7 }
                        CompactLinkComboBox { id: mcs; Layout.fillWidth: true; Layout.preferredHeight: 31; model: mcsValues; textRole: "title"; displayText: root.currentMcs >= 0 ? qsTr("MCS %1").arg(root.currentMcs) : qsTr("N/A"); enabled: _ohdSystemAir.is_alive; onActivated: if (currentIndex >= 0) _wbLinkSettingsHelper.set_param_air_only_mcs_async(mcsValues.get(currentIndex).value); Keys.onPressed: root.keyNav(event) }
                    }
                }
            }
        }

        Rectangle {
            visible: root.adaptiveAvailable || root.fhssAvailable || root.dwellAvailable
            Layout.fillWidth: true; Layout.preferredHeight: visible ? 66 : 0
            radius: 7; color: settings_form.panelBackground; border.color: settings_form.lineColor
            RowLayout { anchors.fill: parent; anchors.margins: 7; spacing: 10
                DynamicLinkSetting { id: adaptive; Layout.fillWidth: true; visible: root.adaptiveAvailable; settingsModel: _ohdSystemAirSettingsModel; paramId: "WB_ADAPT_CH"; label: qsTr("Adaptive Link"); preferRadioToggle: true; onMoveRequested: root.moveFocus(step); onBackRequested: root.leaveCard() }
                ColumnLayout {
                    visible: root.fhssAvailable || root.dwellAvailable
                    Layout.fillWidth: true
                    Layout.minimumWidth: root.dwellAvailable ? 210 : 120
                    spacing: 1
                    Text { text: qsTr("FHSS"); color: settings_form.secondaryText; font.pixelSize: 8; font.bold: true }
                    RowLayout {
                        Layout.fillWidth: true; spacing: 10
                        DynamicLinkSetting { id: fhss; Layout.preferredWidth: 190; visible: root.fhssAvailable; settingsModel: _ohdSystemGroundSettings; paramId: "WB_FHSS"; label: qsTr("Enable"); preferRadioToggle: true; commitHandler: function(value) { host.setFhss(value !== 0) }; onMoveRequested: root.moveFocus(step); onBackRequested: root.leaveCard() }
                        DynamicLinkSetting { id: dwell; Layout.fillWidth: true; visible: root.dwellAvailable; settingsModel: _ohdSystemGroundSettings.param_int_exists("WB_FHSS_SLOT") ? _ohdSystemGroundSettings : _ohdSystemAirSettingsModel; paramId: "WB_FHSS_SLOT"; label: qsTr("Dwell"); commitHandler: function(value) { host.setBoth("WB_FHSS_SLOT", value) }; onMoveRequested: root.moveFocus(step); onBackRequested: root.leaveCard() }
                    }
                }
            }
        }

        Rectangle {
            Layout.fillWidth: true; Layout.preferredHeight: 91; radius: 7; color: settings_form.panelBackground; border.color: settings_form.lineColor
            RowLayout { anchors.fill: parent; anchors.margins: 7; spacing: 10
                DynamicLinkSetting {
                    id: pitMode
                    Layout.preferredWidth: Math.min(220, parent.width * 0.24)
                    Layout.fillHeight: true
                    visible: root.pitModeAvailable
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
                        DynamicLinkSetting { id: airPower; Layout.fillWidth: true; visible: root.showAirPower; editorEnabled: root.airPowerAvailable; settingsModel: _ohdSystemAirSettingsModel; paramId: "TX_PWR_LVL"; label: qsTr("Air"); valueSuffix: "%"; preferSlider: true; preferredStepSize: 20; overrideSliderRange: true; preferredMinimum: 20; preferredMaximum: 100; onMoveRequested: root.moveFocus(step); onBackRequested: root.leaveCard() }
                        DynamicLinkSetting { id: groundPower; Layout.fillWidth: true; visible: root.showGroundPower; editorEnabled: root.groundPowerAvailable; settingsModel: _ohdSystemGroundSettings; paramId: "TX_PWR_LVL"; label: qsTr("Ground"); valueSuffix: "%"; preferSlider: true; preferredStepSize: 20; overrideSliderRange: true; preferredMinimum: 20; preferredMaximum: 100; onMoveRequested: root.moveFocus(step); onBackRequested: root.leaveCard() }
                    }
                }
            }
        }

        RowLayout {
            Layout.fillWidth: true; Layout.preferredHeight: 25; spacing: 6
            Text { Layout.fillWidth: true; text: qsTr("Driver: %1").arg(_wifi_card_air.card_type_as_string); color: settings_form.secondaryText; font.pixelSize: 7; elide: Text.ElideRight }
            Text { visible: _ohdSystemAir.onboard_uptime_ms > 0; text: qsTr("Uptime: %1").arg(root.formatUptime(_ohdSystemAir.onboard_uptime_ms)); color: settings_form.secondaryText; font.pixelSize: 7 }
            Rectangle { width: 7; height: 7; radius: 4; color: settings_form.goodColor }
        }
    }
}
