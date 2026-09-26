import QtQuick 2.12
import QtQuick.Controls 2.12
import QtQuick.Layouts 1.12
import QtQuick.Controls.Material 2.12
import OpenHD 1.0

Rectangle {
    id: root
    color: "transparent"
    signal backRequested()
    readonly property var fleetBackend: (typeof _fleetControlLte !== "undefined") ? _fleetControlLte : null
    property alias frequencyModel: frequencyChoices
    property int availableCardColumns: width >= 1050 ? 3 : (width >= 700 ? 2 : 1)
    // A single active link owns the complete content width. Additional active
    // link types share the row only when there is actually something to show.
    property int cardColumns: Math.max(1, Math.min(activeLinks.count, availableCardColumns))
    property int collapsedCardWidth: Math.floor((cardsFlow.width - (cardColumns - 1) * cardsFlow.spacing) / cardColumns)
    property int expandedCardIndex: -1
    readonly property var reportedUsage: _ohdSystemAir.link_usage
    readonly property string reportedLinkKinds: {
        var ids = []
        for (var i = 0; i < reportedUsage.length; ++i) ids.push(reportedUsage[i].id)
        return ids.sort().join(",")
    }
    readonly property var totalUsage: primaryUsage()
    property bool fleetConfigured: (fleetBackend && fleetBackend.configured) ||
                                   _ohdSystemAir.fleetcontrol_lte_active ||
                                   _ohdSystemAir.fleetcontrol_lte_max_kbit > 0 ||
                                   hasReportedUsage(6)
    property int linkRevision: _ohdSystemGround.primary_link_type + _ohdSystemAir.primary_link_type +
                               _ohdSystemGround.microhard_enabled + _ohdSystemAir.microhard_enabled +
                               (_ohdSystemGround.artosyn_link_detected ? 10 : 0) +
                               (_ohdSystemAir.artosyn_link_detected ? 20 : 0) +
                               (_wifi_card_gnd0.alive ? 40 : 0) + (_wifi_card_air.alive ? 80 : 0) +
                               (_mlrsController.alive ? 160 : 0) +
                               (settings.dev_simulate_ethernet_link ? 320 : 0) +
                               (settings.dev_simulate_wifibroadcast_link ? 640 : 0) +
                               (settings.dev_simulate_uart_link ? 1280 : 0)

    Material.theme: settings_form.darkMode ? Material.Dark : Material.Light
    Material.accent: settings_form.accentColor
    Material.foreground: settings_form.primaryText
    Material.background: settings_form.panelBackgroundRaised

    ListModel { id: activeLinks }
    ListModel { id: frequencyChoices }

    Timer {
        id: fhssTimer
        interval: 700; repeat: false
        property bool enabling: false
        onTriggered: {
            if (enabling) _ohdSystemAirSettingsModel.try_set_param_int_async("WB_FHSS", 1, true)
            else _ohdSystemGroundSettings.try_set_param_int_async("WB_FHSS", 0, true)
        }
    }

    function wifiActive() {
        if (settings.dev_simulate_wifibroadcast_link) return true
        if (hasReportedUsage(1)) return true
        var card = (_wifi_card_gnd0.alive && _wifi_card_gnd0.card_type_as_string !== "ARTOSYN") ||
                   (_wifi_card_air.alive && _wifi_card_air.card_type_as_string !== "ARTOSYN")
        return card || ((_ohdSystemGround.is_alive || _ohdSystemAir.is_alive) &&
                        !_ohdSystemGround.artosyn_link_detected && !_ohdSystemAir.artosyn_link_detected &&
                        _ohdSystemGround.microhard_enabled <= 0 && _ohdSystemAir.microhard_enabled <= 0)
    }
    function hasReportedUsage(id) {
        for (var i = 0; i < reportedUsage.length; ++i)
            if (reportedUsage[i].id === id) return true
        return false
    }
    function fixture(id, capacity, rates) {
        var categories = []
        var total = 0
        for (var i = 0; i < rates.length; ++i) {
            categories.push({id: i + 1, bps: rates[i]})
            total += rates[i]
        }
        return {id: id, total_bps: total, capacity_bps: capacity, categories: categories}
    }
    function usageFor(kind) {
        var id = kind === "wifi" ? 1 : kind === "ethernet" ? 2 :
                 kind === "uart" ? 3 : kind === "microhard" ? 4 :
                 kind === "artosyn" ? 5 : kind === "fleetcontrol" ? 6 : 7
        if (id === 1 && settings.dev_simulate_wifibroadcast_link)
            return fixture(1, 40000000, [12000000, 2000000, 1000000, 400000, 0, 0])
        if (id === 2 && settings.dev_simulate_ethernet_link)
            return fixture(2, 1000000000, [0, 0, 0, 0, 0, 0])
        if (id === 3 && settings.dev_simulate_uart_link)
            return fixture(3, 2000000, [0, 0, 0, 400000, 200000, 200000])
        for (var i = 0; i < reportedUsage.length; ++i)
            if (reportedUsage[i].id === id) return reportedUsage[i]
        return null
    }
    function primaryUsage() {
        // Do not combine unlike capacities: a quiet gigabit Ethernet link
        // must not dilute the utilization of the constrained radio link.
        var kinds = ["wifi", "microhard", "artosyn", "fleetcontrol", "ethernet", "uart", "mlrs"]
        for (var i = 0; i < kinds.length; ++i) {
            var link = usageFor(kinds[i])
            if (link) return link
        }
        return null
    }
    function ethernetActive() { return settings.dev_simulate_ethernet_link || hasReportedUsage(2) }
    function uartActive() { return settings.dev_simulate_uart_link || hasReportedUsage(3) }
    function artosynActive() {
        return hasReportedUsage(5) || _ohdSystemGround.artosyn_link_detected || _ohdSystemAir.artosyn_link_detected ||
               _ohdSystemGround.primary_link_type === 4 || _ohdSystemAir.primary_link_type === 4
    }
    function microhardActive() { return hasReportedUsage(4) || _ohdSystemGround.microhard_enabled > 0 || _ohdSystemAir.microhard_enabled > 0 }

    function rebuildLinks() {
        expandedCardIndex = -1
        activeLinks.clear()
        if (wifiActive()) activeLinks.append({kind: "wifi"})
        if (ethernetActive()) activeLinks.append({kind: "ethernet"})
        if (uartActive()) activeLinks.append({kind: "uart"})
        if (microhardActive()) activeLinks.append({kind: "microhard"})
        if (artosynActive()) activeLinks.append({kind: "artosyn"})
        if (_mlrsController.alive || hasReportedUsage(7)) activeLinks.append({kind: "mlrs"})
        if (fleetConfigured) activeLinks.append({kind: "fleetcontrol"})
    }
    function rebuildFrequencies() {
        frequencyChoices.clear()
        var list = _frequencyHelper.get_frequencies(settings.qopenhd_frequency_filter_selection)
        for (var i = 0; i < list.length; ++i)
            frequencyChoices.append({title: formatFrequency(list[i]), value: list[i]})

        // Always retain the currently reported channel, even when it sits
        // outside the user's active frequency filter.
        var current = _ohdSystemGround.curr_channel_mhz > 0
                    ? _ohdSystemGround.curr_channel_mhz
                    : (_wbLinkSettingsHelper.curr_channel_mhz > 0
                       ? _wbLinkSettingsHelper.curr_channel_mhz
                       : _ohdSystemAir.curr_channel_mhz)
        if (current > 0) {
            var found = false
            for (var j = 0; j < frequencyChoices.count; ++j) {
                if (frequencyChoices.get(j).value === current) {
                    found = true
                    break
                }
            }
            if (!found)
                frequencyChoices.append({title: formatFrequency(current), value: current})
        }
    }
    function formatFrequency(value) {
        return _frequencyHelper.get_frequency_description(value)
                .replace(/\[\s+/g, "[")
                .replace(/Mhz/g, " MHz")
                .trim()
    }
    function chooseFrequency(index) {
        if (index < 0 || index >= frequencyChoices.count) return
        var value = frequencyChoices.get(index).value
        var airAlive = _ohdSystemAir.is_alive
        var groundAlive = _ohdSystemGround.is_alive
        var airCurrent = _ohdSystemAir.curr_channel_mhz
        var groundCurrent = _ohdSystemGround.curr_channel_mhz > 0
                          ? _ohdSystemGround.curr_channel_mhz
                          : _wbLinkSettingsHelper.curr_channel_mhz
        if ((airAlive && groundAlive && airCurrent === value && groundCurrent === value) ||
                (airAlive && !groundAlive && airCurrent === value) ||
                (groundAlive && !airAlive && groundCurrent === value)) return
        // No capability announcement means "unknown", not "unsupported".
        // This is expected while either the air or ground unit is offline;
        // let the connected unit's backend validate the actual request.
        if (groundAlive &&
                _frequencyHelper.has_valid_supported_frequencies_data() &&
                !_frequencyHelper.hw_supports_frequency_threadsafe(value)) {
            _qopenhd.show_toast(qsTr("Your hardware does not support %1 MHz").arg(value)); return
        }
        if (airAlive && groundAlive) {
            frequencyDialog.initialize_and_show_frequency(value)
        } else if (airAlive) {
            singleUnitFrequencyDialog.initialize_and_show_frequency(
                        value, qsTr("Ground unit is offline"), true)
        } else if (groundAlive) {
            singleUnitFrequencyDialog.initialize_and_show_frequency(
                        value, qsTr("Air unit is offline"), false)
        } else {
            _qopenhd.show_toast(qsTr("No OpenHD unit is connected"))
        }
    }
    function setFhss(enabled) {
        if (enabled) {
            _ohdSystemGroundSettings.try_set_param_int_async("WB_FHSS", 1, true); fhssTimer.enabling = true
        } else {
            _ohdSystemAirSettingsModel.try_set_param_int_async("WB_FHSS", 0, true); fhssTimer.enabling = false
        }
        fhssTimer.restart()
    }
    function setBoth(id, value) {
        if (_ohdSystemGroundSettings.param_int_exists(id)) _ohdSystemGroundSettings.try_set_param_int_async(id, value, true)
        if (_ohdSystemAirSettingsModel.param_int_exists(id)) _ohdSystemAirSettingsModel.try_set_param_int_async(id, value, true)
    }
    function openScan() { close_all_dialoques(); scanPopup.open() }
    function openAnalyze() { close_all_dialoques(); analyzePopup.open() }
    function close_all_dialoques() {
        scanPopup.close(); analyzePopup.close()
        singleUnitFrequencyDialog.close(); frequencyDialog.close()
    }
    function focusCard(index) {
        if (activeLinks.count < 1) return
        var next = Math.max(0, Math.min(activeLinks.count - 1, index))
        var card = cards.itemAt(next)
        if (card) {
            card.forceActiveFocus()
            Qt.callLater(function() { ensureItemVisible(card) })
        }
    }
    function enterCard(index) {
        if (index < 0 || index >= activeLinks.count) return
        expandedCardIndex = index
        var card = cards.itemAt(index)
        if (card && card.loadedCard)
            Qt.callLater(card.loadedCard.gainFocus)
    }
    function collapseCard(index) {
        if (expandedCardIndex < 0) return
        var target = index >= 0 ? index : expandedCardIndex
        expandedCardIndex = -1
        Qt.callLater(function() { focusCard(target) })
    }
    function ensureItemVisible(item) {
        if (!item || !linksFlickable) return
        var point = item.mapToItem(cardsFlow, 0, 0)
        var margin = 14
        var top = point.y - margin
        var bottom = point.y + item.height + margin
        var viewportTop = linksFlickable.contentY
        var viewportBottom = viewportTop + linksFlickable.height
        var targetY = viewportTop
        if (top < viewportTop)
            targetY = top
        else if (bottom > viewportBottom)
            targetY = bottom - linksFlickable.height
        linksFlickable.contentY = Math.max(0, Math.min(targetY,
                                     Math.max(0, linksFlickable.contentHeight - linksFlickable.height)))
    }
    function gainFocus() { if (activeLinks.count) focusCard(0); else settings_form.side_bar_regain_focus() }
    function user_quidance_animate_channel_scan() {
        for (var i = 0; i < activeLinks.count; ++i)
            if (activeLinks.get(i).kind === "wifi" && cards.itemAt(i).item) cards.itemAt(i).item.animateScan()
    }

    onLinkRevisionChanged: rebuildLinks()
    onReportedLinkKindsChanged: rebuildLinks()
    onFleetConfiguredChanged: rebuildLinks()
    property int frequencyRevision: _wbLinkSettingsHelper.ui_rebuild_models
    onFrequencyRevisionChanged: rebuildFrequencies()
    property int frequencyFilterRevision: settings.qopenhd_frequency_filter_selection
    onFrequencyFilterRevisionChanged: rebuildFrequencies()
    property int reportedFrequencyRevision: _ohdSystemGround.curr_channel_mhz > 0
                                            ? _ohdSystemGround.curr_channel_mhz
                                            : _ohdSystemAir.curr_channel_mhz
    onReportedFrequencyRevisionChanged: rebuildFrequencies()
    Component.onCompleted: { rebuildFrequencies(); rebuildLinks(); close_all_dialoques() }

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 8
        spacing: 9

        Rectangle {
            visible: settings.dev_show_advanced_button
            Layout.fillWidth: true
            Layout.preferredHeight: visible ? 86 : 0
            radius: 10
            color: settings_form.panelBackgroundRaised
            border.color: settings_form.lineColor
            LinkUsageMeter {
                anchors.fill: parent
                anchors.margins: 9
                usage: root.totalUsage
                title: qsTr("Total Link Usage")
            }
        }

        Flickable {
            id: linksFlickable
            Layout.fillWidth: true; Layout.fillHeight: true
            contentWidth: width; contentHeight: Math.max(height, cardsFlow.height)
            clip: true; boundsBehavior: Flickable.StopAtBounds
            Behavior on contentY { NumberAnimation { duration: 130; easing.type: Easing.OutCubic } }
            ScrollBar.vertical: ScrollBar { policy: ScrollBar.AlwaysOff }
            Flow {
                id: cardsFlow
                width: parent.width; spacing: 10
                Repeater {
                id: cards
                model: activeLinks
                delegate: FocusScope {
                    id: cell
                    property var loadedCard: loader.item
                    width: root.expandedCardIndex === index ? cardsFlow.width : root.collapsedCardWidth
                    height: 570
                    z: root.expandedCardIndex === index ? 2 : 1
                    Behavior on width { NumberAnimation { duration: 180; easing.type: Easing.OutCubic } }
                    Loader {
                        id: loader; anchors.fill: parent
                        sourceComponent: kind === "wifi" ? wifiCard
                                         : (kind === "ethernet" ? ethernetCard
                                         : (kind === "uart" ? uartCard
                                         : (kind === "microhard" ? microhardCard
                                         : (kind === "artosyn" ? artosynCard
                                         : (kind === "fleetcontrol" ? fleetControlCard : mlrsCard)))))
                        onLoaded: {
                            item.host = root
                            item.cardIndex = index
                            item.keyboardSelected = Qt.binding(function() { return cell.activeFocus })
                        }
                    }
                    Keys.onPressed: function(event) {
                        if (event.key === Qt.Key_Escape && root.expandedCardIndex === index) {
                            root.collapseCard(index); event.accepted = true
                        } else if (root.expandedCardIndex >= 0) {
                            event.accepted = true
                        } else if (event.key === Qt.Key_Right) { root.focusCard(index + 1); event.accepted = true }
                        else if (event.key === Qt.Key_Left) { root.focusCard(index - 1); event.accepted = true }
                        else if (event.key === Qt.Key_Down) { root.focusCard(index + root.cardColumns); event.accepted = true }
                        else if (event.key === Qt.Key_Up) {
                            if (index < root.cardColumns) settings_form.side_bar_regain_focus(); else root.focusCard(index - root.cardColumns)
                            event.accepted = true
                        } else if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter) {
                            root.enterCard(index); event.accepted = true
                        } else if (event.key === Qt.Key_Escape) { root.backRequested(); event.accepted = true }
                    }
                }
            }
                Rectangle {
                    visible: activeLinks.count === 0; width: cardsFlow.width; height: 150; radius: 10
                    color: settings_form.panelBackgroundRaised; border.color: settings_form.lineColor
                    Column {
                        anchors.centerIn: parent; spacing: 8
                        Text { anchors.horizontalCenter: parent.horizontalCenter; text: "\uf1eb"; font.family: "Font Awesome 5 Free"; font.pixelSize: 22; color: settings_form.secondaryText }
                        Text { anchors.horizontalCenter: parent.horizontalCenter; text: qsTr("No active links yet"); color: settings_form.primaryText; font.pixelSize: 11; font.bold: true }
                        Text { anchors.horizontalCenter: parent.horizontalCenter; text: qsTr("Connect an OpenHD unit or add an optional Air link above."); color: settings_form.secondaryText; font.pixelSize: 9 }
                    }
                }
            }
        }
    }

    Component { id: wifiCard; WifiBroadcastLinkCard {} }
    Component { id: ethernetCard; SimulatedLinkCard { linkKind: "ethernet" } }
    Component { id: uartCard; SimulatedLinkCard { linkKind: "uart" } }
    Component { id: microhardCard; MicrohardLinkCard {} }
    Component { id: artosynCard; ArtosynLinkCard {} }
    Component { id: mlrsCard; MLRSLinkCard {} }
    Component { id: fleetControlCard; FleetControlLinkCard {} }

    PopupScanChannels { id: scanPopup }
    PopupAnalyzeChannels { id: analyzePopup }
    DialoqueFreqChangeGndOnly { id: singleUnitFrequencyDialog }
    DialoqueFreqChangeAirGnd { id: frequencyDialog }
}
