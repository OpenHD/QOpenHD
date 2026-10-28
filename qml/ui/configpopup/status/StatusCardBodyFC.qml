import QtQuick 2.12

Column {
    id: body
    width: parent.width
    spacing: 0
    property bool m_is_alive: _fcMavlinkSystem.is_alive
    readonly property var diagnostics: _fcMavlinkSystem.craft_diagnostics
    readonly property bool heartbeatFresh: m_is_alive && diagnostics.heartbeatAge >= 0 && diagnostics.heartbeatAge < 5
    readonly property bool healthKnown: heartbeatFresh && diagnostics.statusAge >= 0 && diagnostics.statusAge < 5 && diagnostics.present > 0
    readonly property bool healthWarning: healthKnown && ((diagnostics.enabled & diagnostics.present & ~diagnostics.healthy) !== 0)
    function firmwareText() {
        var identity = _fcMavlinkSystem.firmware_identity
        var version = Number(identity.ver || 0)
        var name = identity.name || qsTr("Unknown")
        if ((version >>> 24) > 0 && version !== 4294967295)
            name += " " + (version >>> 24) + "." + ((version >>> 16) & 255) + "." + ((version >>> 8) & 255)
        return name
    }
    StatusCardRow { m_left_text: qsTr("Firmware"); m_icon: "\uf2db"; m_right_text: body.firmwareText() }
    StatusCardRow { m_left_text: qsTr("Type"); m_icon: "\uf0b1"; m_right_text: _fcMavlinkSystem.mav_type_str }
    StatusCardRow { m_left_text: qsTr("Flight mode"); m_icon: "\uf1d8"; m_right_text: body.heartbeatFresh && _fcMavlinkSystem.flight_mode !== "------" ? _fcMavlinkSystem.flight_mode : qsTr("Unknown") }
    StatusCardRow {
        m_left_text: qsTr("System health"); m_icon: "\uf2db"
        m_right_text: !body.healthKnown ? qsTr("Not reported") : (body.healthWarning ? qsTr("Warning") : qsTr("Healthy"))
        m_status_dot: body.healthKnown
        m_right_text_color: !body.healthKnown ? "#94a9b9" : (body.healthWarning ? settings_form.errorColor : "#3bda69")
    }
    StatusCardRow {
        m_left_text: qsTr("Battery"); m_icon: "\uf2c2"
        m_right_text: body.heartbeatFresh && _fcMavlinkSystem.battery_voltage_volt > 0
                      ? qsTr("%1 V (%2 %)").arg(_fcMavlinkSystem.battery_voltage_volt.toFixed(1)).arg(_fcMavlinkSystem.battery_percent) : qsTr("Not reported")
    }
    StatusCardRow { m_left_text: qsTr("GPS"); m_icon: "\uf3c5"; m_right_text: body.heartbeatFresh ? qsTr("%1 sats (%2)").arg(_fcMavlinkSystem.satellites_visible).arg(_fcMavlinkSystem.gps_status_fix_type_str) : qsTr("Not reported") }
}
