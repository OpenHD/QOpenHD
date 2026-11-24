import QtQuick 2.12
import QtQuick.Controls 2.12
import QtQuick.Layouts 1.12
import ".."
import "../qopenhd_settings"
import "../openhd_settings"
import "../MenuTypography.js" as Typography

AdvancedPage {
    id: root
    objectName: "portsSettingsPanel"
    initialFocusItem: portList
    onBackRequested: settings_form.side_bar_regain_focus()

    property string validationError: ""
    readonly property var linkRows: [
        ["OHD_UART_TLM", qsTr("Port")],
        ["OHD_UART_BAUD", qsTr("Baud rate")],
        ["OHD_UART_FLW", qsTr("RTS/CTS flow control")],
        ["OHD_UART_EN", qsTr("Enable link")],
        ["UART_PRI_RC", qsTr("RC priority")],
        ["UART_PRI_OHD", qsTr("OpenHD priority")],
        ["UART_PRI_FC", qsTr("FC telemetry priority")]
    ]
    readonly property var sections: [
        {id: "fc", title: qsTr("Flight controller telemetry"), air: true, icon: "\uf1d8", rows: [
            ["FC_UART_CONN", qsTr("Port")],
            ["FC_UART_BAUD", qsTr("Baud rate")],
            ["FC_UART_FLWCTL", qsTr("RTS/CTS flow control")]
        ]},
        {id: "tracker", title: qsTr("Tracker output"), air: false, icon: "\uf124", rows: [
            ["TRACKER_UART_OUT", qsTr("Port")],
            ["TRACK_UART_BAUD", qsTr("Baud rate")],
            ["TRACK_UART_FLOW", qsTr("RTS/CTS flow control")]
        ]},
        {id: "airLink", title: qsTr("OpenHD UART link"), air: true, icon: "\uf519", rows: linkRows},
        {id: "groundLink", title: qsTr("OpenHD UART link"), air: false, icon: "\uf519", rows: linkRows},
        {id: "sbus", title: qsTr("SBUS output"), air: true, icon: "\uf11b", rows: [
            ["SBUS_DEV", qsTr("Port")],
            ["SBUS_HZ", qsTr("Update rate (Hz)")],
            ["SBUS_EN", qsTr("Enable output")]
        ]},
        {id: "gpio", title: qsTr("GPIO outputs"), air: true, icon: "\uf2db", rows: [
            ["GPIO_2", qsTr("GPIO 2")],
            ["GPIO_26", qsTr("GPIO 26")]
        ]}
    ]

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
        spacing: 10

        Text {
            Layout.fillWidth: true
            visible: root.validationError !== ""
            text: root.validationError
            color: settings_form.errorColor
            font.family: Typography.family
            font.pixelSize: Typography.body
            wrapMode: Text.Wrap
        }

        Flickable {
            id: portList
            Layout.fillWidth: true
            Layout.fillHeight: true
            contentWidth: width
            contentHeight: cards.implicitHeight
            boundsBehavior: Flickable.StopAtBounds
            clip: true
            ScrollBar.vertical: ScrollBar {}

            GridLayout {
                id: cards
                width: portList.width
                columns: width >= 720 ? 2 : 1
                columnSpacing: 12
                rowSpacing: 12

                Repeater {
                    model: root.sections
                    delegate: MapSettingsCard {
                        id: card
                        objectName: "portsSection_" + section.id
                        readonly property var section: modelData
                        readonly property var params: section.air ? _ohdSystemAirSettingsModel : _ohdSystemGroundSettings
                        readonly property bool connected: section.air ? _ohdSystemAir.is_alive : _ohdSystemGround.is_alive
                        readonly property var rows: {
                            params.update_count
                            return section.rows.filter(function(entry) {
                                return params.param_int_exists(entry[0]) || params.param_string_exists(entry[0])
                            })
                        }

                        Layout.fillWidth: true
                        Layout.minimumWidth: 0
                        Layout.preferredWidth: 1
                        Layout.alignment: Qt.AlignTop
                        title: section.title
                        headerNote: section.air ? qsTr("Air") : qsTr("Ground")
                        icon: section.icon

                        Text {
                            Layout.fillWidth: true
                            visible: (!card.connected && !_qopenhd.debugMenuPreview) || !card.rows.length
                            text: !card.connected && !_qopenhd.debugMenuPreview ? qsTr("Unit offline") :
                                  card.params.ui_is_busy ? qsTr("Loading settings…") : qsTr("No settings reported")
                            color: settings_form.secondaryText
                            font.family: Typography.family
                            font.pixelSize: Typography.helper
                            wrapMode: Text.Wrap
                        }
                        Column {
                            Layout.fillWidth: true
                            Layout.minimumWidth: 0
                            Layout.preferredWidth: 0

                            Repeater {
                                model: card.rows
                                delegate: AirSettingRow {
                                    objectName: "portSetting_" + card.section.id + "_" + paramId
                                    width: parent.width
                                    stacked: width < 300
                                    settingsModel: card.params
                                    connectionAlive: card.connected
                                    paramId: modelData[0]
                                    labelOverride: modelData[1]
                                    validateChange: function(id, value) { return root.validatePort(card.section.air, card.params, id, value) }
                                    onValidationFailed: function(reason) { root.validationError = reason }
                                    onBackRequested: root.backRequested()
                                    onActiveFocusChanged: {
                                        if (!activeFocus) return
                                        var top = mapToItem(cards, 0, 0).y
                                        if (top < portList.contentY)
                                            portList.contentY = top
                                        else if (top + height > portList.contentY + portList.height)
                                            portList.contentY = top + height - portList.height
                                    }
                                }
                            }
                        }

                        Text {
                            Layout.fillWidth: true
                            visible: section.id === "groundLink" && card.rows.length > 0
                            text: qsTr("Use the same baud rate on Air and Ground.")
                            color: settings_form.secondaryText
                            font.family: Typography.family
                            font.pixelSize: Typography.helper
                            wrapMode: Text.Wrap
                        }
                    }
                }
            }
        }
    }
}
