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

    property string validationError: ""
    readonly property bool editingAir: unitTabs.currentIndex === 0
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

    function validatePort(air, model, id, value) {
        validationError = ""
        var roles = air ? [
            {port: "FC_UART_CONN", name: qsTr("Flight controller telemetry")},
            {port: "SBUS_DEV", enable: "SBUS_EN", name: qsTr("SBUS output")}
        ] : [{port: "TRACKER_UART_OUT", name: qsTr("Tracker output")}]
        roles.push({port: "OHD_UART_TLM", enable: "OHD_UART_EN", name: qsTr("OpenHD UART link")})

        function portFor(role) {
            var port = role.port === id ? String(value) : model.param_string_exists(role.port) ? model.get_cached_string(role.port) : ""
            // Linux treats repeated slashes in a local device path as a single slash.
            return port.trim().replace(/\/{2,}/g, "/")
        }
        function enabled(role) {
            return !role.enable || (role.enable === id ? Number(value) !== 0 :
                model.param_int_exists(role.enable) && model.get_cached_int(role.enable) !== 0)
        }

        var changed = roles.find(function(role) { return role.port === id || role.enable === id })
        if (!changed || !enabled(changed)) return ""
        var port = portFor(changed)
        if (!port && changed.enable) return qsTr("Choose a UART port for %1 before enabling it.").arg(changed.name)
        // DEFAULT is a role-specific alias resolved on the unit.
        if (!port || port === "DEFAULT") return ""
        var conflict = roles.find(function(role) { return role !== changed && enabled(role) && portFor(role) === port })
        if (conflict) return qsTr("%1 already uses %2 on %3.").arg(conflict.name).arg(port).arg(air ? qsTr("Air") : qsTr("Ground"))
        return ""
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
                root.validationError = ""
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

        Text {
            Layout.fillWidth: true
            visible: root.validationError !== ""
            text: root.validationError
            color: settings_form.errorColor
            font.family: Typography.family
            font.pixelSize: Typography.body
            wrapMode: Text.Wrap
        }

        Item {
            Layout.fillWidth: true
            Layout.fillHeight: true

            Flickable {
                id: portList
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
                            air: root.editingAir
                            advanced: settings_form.showAdvancedSettings
                            connected: boardLoader.unit.is_alive
                            onPinFocused: function(item) { portList.reveal(item) }
                            settingsModel: air ? _ohdSystemAirSettingsModel : _ohdSystemGroundSettings
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
                                    params: air ? _ohdSystemAirSettingsModel : _ohdSystemGroundSettings
                                    connected: air ? _ohdSystemAir.is_alive : _ohdSystemGround.is_alive
                                    validateChange: function(id, value) { return root.validatePort(card.air, card.params, id, value) }
                                    onValidationFailed: function(reason) { root.validationError = reason }
                                    onSettingFocused: function(row) { portList.reveal(row) }
                                    onBackRequested: root.backRequested()
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}
