import QtQuick 2.12
import "ui/configpopup/status/SystemHealth.js" as Health

Item {
    id: root
    visible: false
    property var preferences: settings
    property var airModel: _ohdSystemAir
    property var groundModel: _ohdSystemGround
    property var flightModel: _fcMavlinkSystem
    property var announcements: _audioAnnouncements
    property bool radioSilenced: false
    readonly property var airHealth: Health.evaluate(airModel, false, preferences)
    readonly property var groundHealth: Health.evaluate(groundModel, true, preferences)
    readonly property var diagnostics: flightModel.craft_diagnostics
    readonly property bool fcWarning: flightModel.is_alive && diagnostics.heartbeatAge >= 0 && diagnostics.heartbeatAge < 5 &&
        diagnostics.statusAge >= 0 && diagnostics.statusAge < 5 && (diagnostics.enabled & diagnostics.present & ~diagnostics.healthy) !== 0
    function refresh() {
        if (!announcements || !airModel || !groundModel || !flightModel || !preferences || !airHealth || !groundHealth) return
        function send(health, endpoint, name) {
            var kinds = ["temp", "cpu", "undervolt", "radio"]
            for (var i = 0; i < kinds.length; ++i) {
                var kind = kinds[i], alert = null
                for (var j = 0; j < health.alerts.length; ++j) if (health.alerts[j].kind === kind) alert = health.alerts[j]
                announcements.updateWarning(endpoint + "." + kind, kind, alert ? name + " " + alert.detail : "",
                    alert ? alert.severity : 0, !!alert && (alert.muted || (kind === "radio" && radioSilenced)))
            }
        }
        send(airHealth, "air", qsTr("Air"))
        send(groundHealth, "ground", qsTr("Ground"))
        announcements.updateWarning("fc.health", "fc", qsTr("Flight controller health warning"), fcWarning ? 2 : 0, preferences.fc_status_health_muted === true)
    }
    onAirHealthChanged: refresh()
    onGroundHealthChanged: refresh()
    onFcWarningChanged: refresh()
    onRadioSilencedChanged: refresh()
    readonly property bool fcMuted: preferences.fc_status_health_muted === true
    onFcMutedChanged: refresh()
    onPreferencesChanged: refresh()
    Timer { interval: 1000; repeat: true; running: true; triggeredOnStart: true; onTriggered: root.refresh() }
}
