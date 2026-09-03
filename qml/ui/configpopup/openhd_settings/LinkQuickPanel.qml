import QtQuick 2.12
import QtQuick.Controls 2.12
import QtQuick.Layouts 1.12
import QtQuick.Controls.Material 2.12
import OpenHD 1.0

Rectangle {
    id: root
    color: "transparent"
    signal backRequested()
    property alias frequencyModel: frequencyChoices
    property int availableCardColumns: width >= 1050 ? 3 : (width >= 700 ? 2 : 1)
    // A single active link owns the complete content width. Additional active
    // link types share the row only when there is actually something to show.
    property int cardColumns: Math.max(1, Math.min(activeLinks.count, availableCardColumns))
    property int collapsedCardWidth: Math.floor((cardsFlow.width - (cardColumns - 1) * cardsFlow.spacing) / cardColumns)
    property int expandedCardIndex: -1
    property bool fleetConfigured: _fleetControlLte.configured ||
                                   _ohdSystemAir.fleetcontrol_lte_active ||
                                   _ohdSystemAir.fleetcontrol_lte_max_kbit > 0
    property int linkRevision: _ohdSystemGround.primary_link_type + _ohdSystemAir.primary_link_type +
                               _ohdSystemGround.microhard_enabled + _ohdSystemAir.microhard_enabled +
                               (_ohdSystemGround.artosyn_link_detected ? 10 : 0) +
                               (_ohdSystemAir.artosyn_link_detected ? 20 : 0) +
                               (_wifi_card_gnd0.alive ? 40 : 0) + (_wifi_card_air.alive ? 80 : 0) +
                               (_mlrsController.alive ? 160 : 0)

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
        var card = (_wifi_card_gnd0.alive && _wifi_card_gnd0.card_type_as_string !== "ARTOSYN") ||
                   (_wifi_card_air.alive && _wifi_card_air.card_type_as_string !== "ARTOSYN")
        return card || ((_ohdSystemGround.is_alive || _ohdSystemAir.is_alive) &&
                        !_ohdSystemGround.artosyn_link_detected && !_ohdSystemAir.artosyn_link_detected &&
                        _ohdSystemGround.microhard_enabled <= 0 && _ohdSystemAir.microhard_enabled <= 0)
    }
    function artosynActive() {
        return _ohdSystemGround.artosyn_link_detected || _ohdSystemAir.artosyn_link_detected ||
               _ohdSystemGround.primary_link_type === 4 || _ohdSystemAir.primary_link_type === 4
    }
    function microhardActive() { return _ohdSystemGround.microhard_enabled > 0 || _ohdSystemAir.microhard_enabled > 0 }

    function rebuildLinks() {
        expandedCardIndex = -1
        activeLinks.clear()
        if (wifiActive()) activeLinks.append({kind: "wifi"})
        if (microhardActive()) activeLinks.append({kind: "microhard"})
        if (artosynActive()) activeLinks.append({kind: "artosyn"})
        if (_mlrsController.alive) activeLinks.append({kind: "mlrs"})
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
        if (value === _wbLinkSettingsHelper.curr_channel_mhz) return
        if (!_frequencyHelper.hw_supports_frequency_threadsafe(value)) {
            _qopenhd.show_toast(qsTr("Your hardware does not support %1 MHz").arg(value)); return
        }
        if (_ohdSystemAir.is_alive) frequencyDialog.initialize_and_show_frequency(value)
        else groundFrequencyDialog.initialize_and_show_frequency(value, qsTr("Air unit is offline"))
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
        groundFrequencyDialog.close(); frequencyDialog.close()
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
                    height: 462
                    z: root.expandedCardIndex === index ? 2 : 1
                    Behavior on width { NumberAnimation { duration: 180; easing.type: Easing.OutCubic } }
                    Loader {
                        id: loader; anchors.fill: parent
                        sourceComponent: kind === "wifi" ? wifiCard
                                         : (kind === "microhard" ? microhardCard
                                         : (kind === "artosyn" ? artosynCard
                                         : (kind === "fleetcontrol" ? fleetControlCard : mlrsCard)))
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
    Component { id: microhardCard; MicrohardLinkCard {} }
    Component { id: artosynCard; ArtosynLinkCard {} }
    Component { id: mlrsCard; MLRSLinkCard {} }
    Component { id: fleetControlCard; FleetControlLinkCard {} }

    PopupScanChannels { id: scanPopup }
    PopupAnalyzeChannels { id: analyzePopup }
    DialoqueFreqChangeGndOnly { id: groundFrequencyDialog }
    DialoqueFreqChangeAirGnd { id: frequencyDialog }
}
