import QtQuick 2.12
import QtQuick.Controls 2.12
import QtQuick.Layouts 1.12
import ".."
import "../MenuTypography.js" as Typography

AdvancedPage {
    id: root
    objectName: "portsSettingsPanel"
    initialFocusItem: unitTabs.currentItem
    onBackRequested: settings_form.side_bar_regain_focus()

    readonly property bool editingAir: unitTabs.currentIndex === 0
    readonly property var activeDraft: editingAir ? airDraft : groundDraft

    PortsSettingsDraft {
        id: airDraft
        model: _ohdSystemAirSettingsModel
        connected: _ohdSystemAir.is_alive
    }
    PortsSettingsDraft {
        id: groundDraft
        model: _ohdSystemGroundSettings
        connected: _ohdSystemGround.is_alive
    }
    readonly property var sections: ({
        fc: {id: "fc", title: qsTr("Flight controller telemetry"), icon: "\uf1d8", groups: [
            {rows: [
                ["FC_UART_CONN", qsTr("Port"), "\uf1e6"],
                ["FC_UART_BAUD", qsTr("Baud rate"), "\uf3fd"],
                ["FC_UART_FLWCTL", qsTr("RTS/CTS flow control")]
            ]}
        ]},
        tracker: {id: "tracker", title: qsTr("Tracker output"), icon: "\uf05b", groups: [
            {rows: [
                ["TRACKER_UART_OUT", qsTr("Port"), "\uf1e6"],
                ["TRACK_UART_BAUD", qsTr("Baud rate"), "\uf3fd"],
                ["TRACK_UART_FLOW", qsTr("RTS/CTS flow control")]
            ]}
        ]},
        link: {id: "link", title: qsTr("UART Link (Air ↔ Ground)"), icon: "\uf0c1", groups: [
            {columns: true, rows: [
                ["OHD_UART_TLM", qsTr("Port"), "\uf1e6"],
                ["OHD_UART_BAUD", qsTr("Baud rate"), "\uf3fd"],
                ["OHD_UART_EN", qsTr("Enable link")]
            ]},
            {columns: true, rows: [
                ["UART_PRI_RC", qsTr("RC priority")],
                ["UART_PRI_OHD", qsTr("OpenHD priority")],
                ["UART_PRI_FC", qsTr("FC telemetry priority")]
            ]},
            {rows: [["OHD_UART_FLW", qsTr("RTS/CTS flow control")]]}
        ]},
        sbus: {id: "sbus", title: qsTr("SBUS output"), icon: "\uf11b", groups: [
            {rows: [
                ["SBUS_DEV", qsTr("Port"), "\uf1e6"],
                ["SBUS_HZ", qsTr("Update rate (Hz)"), "\uf3fd"],
                ["SBUS_EN", qsTr("Enable output")]
            ]}
        ]},
        gpio: {id: "gpio", title: qsTr("GPIO outputs"), icon: "\uf2db", groups: [
            {rows: [["GPIO_2", qsTr("GPIO 2")], ["GPIO_26", qsTr("GPIO 26")]]}
        ]}
    })

    readonly property var cardRows: {
        var rows = editingAir ? [[sections.fc, sections.gpio]] : [[sections.tracker]]
        if (settings_form.showAdvancedSettings) {
            rows.push([sections.link])
            if (editingAir) rows.push([sections.sbus])
        }
        return rows
    }

    function requestSettings(system, model) {
        if (visible && system.is_alive && !_qopenhd.debugMenuPreview)
            model.ensure_parameters_available()
    }

    onVisibleChanged: {
        requestSettings(_ohdSystemAir, _ohdSystemAirSettingsModel)
        requestSettings(_ohdSystemGround, _ohdSystemGroundSettings)
    }
    Connections {
        target: _ohdSystemAir
        function onIs_aliveChanged() { root.requestSettings(_ohdSystemAir, _ohdSystemAirSettingsModel) }
    }
    Connections {
        target: _ohdSystemGround
        function onIs_aliveChanged() { root.requestSettings(_ohdSystemGround, _ohdSystemGroundSettings) }
    }

    function portRoles(air) {
        var roles = air ? [
            {port: "FC_UART_CONN", name: qsTr("Flight controller telemetry")},
            {port: "SBUS_DEV", enable: "SBUS_EN", name: qsTr("SBUS output")}
        ] : [{port: "TRACKER_UART_OUT", name: qsTr("Tracker output")}]
        roles.push({port: "OHD_UART_TLM", enable: "OHD_UART_EN", name: qsTr("OpenHD UART link")})
        return roles
    }

    function resolvedPort(draft, role, value) {
        if (!value) return ""
        var meta = draft.model.get_ui_metadata(role.port)
        var path = meta.serialConfigured === value && meta.serialResolved ? meta.serialResolved : value
        return path === "DEFAULT" ? "" : path.trim().replace(/\/{2,}/g, "/")
    }

    function applyCurrent() {
        var draft = activeDraft
        if (!draft.connected || !draft.dirty || draft.applying || draft.model.ui_is_busy ||
                _qopenhd.debugMenuPreview) return
        var intended = Object.assign({}, draft.edits)
        var roles = portRoles(editingAir)
        var state = roles.map(function(role) {
            var enabled = !role.enable || Boolean(draft.valueFor(role.enable))
            return {
                role: role,
                enabled: enabled,
                wasEnabled: !role.enable || Boolean(draft.savedValue(role.enable)),
                edited: intended[role.port] !== undefined || (role.enable && intended[role.enable] !== undefined),
                path: enabled ? resolvedPort(draft, role, draft.valueFor(role.port)) : "",
                oldPath: resolvedPort(draft, role, draft.savedValue(role.port))
            }
        })
        var releases = []
        var portIds = []
        var enableIds = []
        for (var i = 0; i < state.length; ++i) {
            var entry = state[i]
            var role = entry.role
            portIds.push(role.port)
            if (role.enable) enableIds.push(role.enable)
            if (entry.edited && role.enable && entry.enabled && !draft.valueFor(role.port)) {
                draft.reject(qsTr("Choose a UART port for %1 before enabling it.").arg(role.name))
                return
            }
            var other = state.find(function(item) { return item !== entry && item.path && item.path === entry.path })
            if (entry.edited && other) {
                draft.reject(qsTr("%1 already uses %2.").arg(other.role.name).arg(entry.path))
                return
            }
            // Free a port another role will claim before writing any new owners.
            if (entry.wasEnabled && entry.oldPath && entry.oldPath !== entry.path &&
                    state.some(function(item) { return item !== entry && item.path === entry.oldPath })) {
                var stopId = role.enable || role.port
                if (intended[stopId] === undefined) intended[stopId] = draft.valueFor(stopId)
                releases.push({id: stopId, label: role.name, value: role.enable ? 0 : ""})
            }
        }

        function applyOrder(id) {
            if (enableIds.indexOf(id) >= 0) return intended[id] ? 3 : 0
            return portIds.indexOf(id) >= 0 ? 2 : 1
        }
        var writes = Object.keys(intended).sort(function(left, right) {
            return applyOrder(left) - applyOrder(right)
        }).map(function(id) {
            var metadata = draft.model.get_ui_metadata(id)
            return {id: id, value: intended[id], label: metadata.label || id}
        })
        draft.apply(releases.concat(writes), intended)
    }

    ColumnLayout {
        anchors.fill: parent
        spacing: 12

        TabBar {
            id: unitTabs
            objectName: "portsUnitTabs"
            Layout.fillWidth: true
            implicitHeight: Typography.controlHeight + 4
            spacing: 0
            padding: 1
            onCurrentIndexChanged: {
                if (portList) portList.contentY = 0
            }
            Keys.onLeftPressed: focusUnit(0)
            Keys.onRightPressed: focusUnit(1)

            function focusUnit(index) {
                setCurrentIndex(index)
                itemAt(index).forceActiveFocus()
            }

            contentItem: ListView {
                model: unitTabs.contentModel
                currentIndex: unitTabs.currentIndex
                orientation: ListView.Horizontal
                interactive: false
            }
            background: Rectangle {
                radius: Typography.controlRadius
                color: settings_form.panelBackground
                border.color: settings_form.lineColor
            }
            AdvancedTabButton {
                width: unitTabs.availableWidth / 2
                height: unitTabs.availableHeight
                underlined: true
                text: qsTr("Air Unit")
                iconText: "\uf1d8"
            }
            AdvancedTabButton {
                width: unitTabs.availableWidth / 2
                height: unitTabs.availableHeight
                underlined: true
                text: qsTr("Ground Unit")
                iconText: "\uf519"
            }
        }

        Item {
            Layout.fillWidth: true
            Layout.fillHeight: true

            Flickable {
                id: portList
                objectName: "portsScrollView"
                anchors.fill: parent
                contentWidth: width
                contentHeight: cards.implicitHeight
                boundsBehavior: Flickable.StopAtBounds
                clip: true
                ScrollBar.vertical: ScrollBar {
                    parent: portList.parent
                    anchors.left: portList.right
                    anchors.leftMargin: 2
                    anchors.top: portList.top
                    anchors.bottom: portList.bottom
                }

                function reveal(item) {
                    var top = item.mapToItem(cards, 0, 0).y
                    if (top < contentY)
                        contentY = top
                    else if (top + item.height > contentY + height)
                        contentY = top + item.height - height
                }

                Column {
                    id: cards
                    width: portList.width
                    spacing: 12

                    Loader {
                        id: boardLoader
                        width: cards.width
                        readonly property var unit: root.editingAir ? _ohdSystemAir : _ohdSystemGround
                        active: unit.ohd_platform_type >= 0
                        visible: active
                        sourceComponent: PortsBoardPinout {
                            platform: boardLoader.unit.ohd_platform_type
                            viewportHeight: portList.height
                            air: root.editingAir
                            advanced: settings_form.showAdvancedSettings
                            connected: boardLoader.unit.is_alive
                            onPinFocused: function(item) { portList.reveal(item) }
                            settingsModel: root.activeDraft.model
                            draft: root.activeDraft
                            onBackRequested: root.backRequested()
                        }
                    }

                    Repeater {
                        model: root.cardRows
                        delegate: Grid {
                            id: cardGrid
                            width: cards.width
                            columnSpacing: cards.spacing
                            rowSpacing: cards.spacing
                            columns: width >= 690 ? modelData.length : 1

                            Repeater {
                                model: modelData
                                delegate: PortsSettingsCard {
                                    id: card
                                    width: (cardGrid.width - cardGrid.columnSpacing * (cardGrid.columns - 1)) / cardGrid.columns
                                    section: modelData
                                    air: root.editingAir
                                    params: root.activeDraft.model
                                    connected: root.activeDraft.connected
                                    draft: root.activeDraft
                                    onSettingFocused: function(row) { portList.reveal(row) }
                                    onBackRequested: root.backRequested()
                                }
                            }
                        }
                    }
                }
            }
        }
        RowLayout {
            Layout.fillWidth: true
            visible: root.activeDraft.dirty || root.activeDraft.applying || root.activeDraft.status !== ""
            spacing: 10

            Text {
                Layout.fillWidth: true
                Layout.minimumWidth: 0
                text: root.activeDraft.applying ? qsTr("Applying…")
                      : root.activeDraft.status || qsTr("Unapplied changes")
                color: root.activeDraft.failed ? settings_form.errorColor : settings_form.secondaryText
                font.family: Typography.family
                font.pixelSize: Typography.helper
                wrapMode: Text.Wrap
            }

            AdvancedActionButton {
                objectName: "portsApply"
                primary: true
                text: qsTr("Apply")
                enabled: root.activeDraft.connected && root.activeDraft.dirty && !root.activeDraft.applying &&
                         !root.activeDraft.model.ui_is_busy && !_qopenhd.debugMenuPreview
                onClicked: root.applyCurrent()
                Keys.onEscapePressed: root.backRequested()
            }
        }
    }
}
