import QtQuick 2.12
import QtQuick.Controls 2.12
import QtQuick.Layouts 1.12
import ".."
import "../MenuTypography.js" as Typography
import "SystemHealth.js" as Health

AdvancedDialog {
    id: dialog
    objectName: "healthWarningSettingsPopup"
    property int systemType: 0
    property string warningKind: ""
    readonly property bool ground: systemType === 0
    readonly property bool flightController: systemType === 2
    readonly property var unit: ground ? _ohdSystemGround : _ohdSystemAir
    readonly property string mutePrefix: ground ? "ground_status_" : "air_status_"
    readonly property string thresholdPrefix: Health.thresholdPrefix(unit, ground)
    readonly property var health: Health.evaluate(unit, ground, settings)
    readonly property var activeAlerts: {
        if (flightController) {
            var d = _fcMavlinkSystem.craft_diagnostics
            return _fcMavlinkSystem.is_alive && d.heartbeatAge >= 0 && d.heartbeatAge < 5 && d.statusAge >= 0 && d.statusAge < 5 &&
                    (d.enabled & d.present & ~d.healthy) !== 0 ?
                [{kind:"fc", severity:2, muted:settings.fc_status_health_muted, detail:qsTr("Flight controller health warning")}] : []
        }
        return health.alerts.filter(function(alert) { return !dialog.warningKind || alert.kind === dialog.warningKind })
    }
    readonly property string activeKinds: activeAlerts.map(function(alert) { return alert.kind }).join(",")
    parent: Overlay.overlay
    anchors.centerIn: parent
    width: Math.min(480, parent.width - 24)
    height: Math.min(parent.height - 24, 100 + activeAlerts.reduce(function(total, alert) { return total + (alert.kind === "temp" || alert.kind === "cpu" ? 160 : 120) }, 0))
    title: flightController ? qsTr("Flight controller warning") : ground ? qsTr("Ground warning") : qsTr("Air warning")
    onActiveAlertsChanged: if (visible && !activeAlerts.length) Qt.callLater(function() { if (!activeAlerts.length) close() })
    function openSettings(type, kind) {
        systemType = type; warningKind = kind || ""
        if (activeAlerts.length) open()
    }
    function value(kind, level) { return Health.threshold(unit, ground, settings, kind, level) }
    function setThreshold(kind, level, value) {
        var maximum = kind === "temp" ? 150 : 100
        value = Math.max(level === "warn" ? 2 : 1, Math.min(level === "warn" ? maximum : maximum - 1, Math.round(value)))
        var prefix = thresholdPrefix + kind + "_"
        settings[prefix + level] = value
        if (level === "caution" && value >= settings[prefix + "warn"]) settings[prefix + "warn"] = value + 1
        if (level === "warn" && value <= settings[prefix + "caution"]) settings[prefix + "caution"] = value - 1
    }
    onClosed: if (statusPanel.visible) statusPanel.gainFocus()
    contentItem: ScrollView {
        id: scroll
        clip: true
        contentWidth: availableWidth
        ScrollBar.horizontal.policy: ScrollBar.AlwaysOff
        ColumnLayout {
            id: warningColumn
            width: scroll.availableWidth
            spacing: 16
            Repeater {
                model: dialog.activeKinds ? dialog.activeKinds.split(",") : []
                delegate: ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 10
                    readonly property string kind: modelData
                    readonly property var alert: dialog.activeAlerts.filter(function(entry) { return entry.kind === kind })[0] || ({severity:0,muted:false,detail:""})
                    readonly property string level: alert.severity === 2 ? "warn" : "caution"
                    Label {
                        Layout.fillWidth: true
                        text: alert.detail
                        wrapMode: Text.WordWrap
                        color: alert.muted ? "#94a9b9" : alert.severity === 2 ? "#ff6675" : "#ffbd60"
                        font.family: Typography.family; font.pixelSize: Typography.body; font.bold: true
                    }
                    RowLayout {
                        Layout.fillWidth: true
                        visible: kind === "temp" || kind === "cpu"
                        Label {
                            Layout.fillWidth: true
                            text: (level === "warn" ? qsTr("Warning at") : qsTr("Caution at")) + (kind === "temp" ? " (\u00b0C)" : " (%)")
                            color: "#edf3fa"; font.family: Typography.family; font.pixelSize: Typography.body
                        }
                        SpinBox {
                            objectName: kind + (level === "warn" ? "WarningThreshold" : "CautionThreshold")
                            Layout.preferredWidth: 156
                            from: level === "warn" ? 2 : 1
                            to: kind === "temp" ? 150 : 100
                            editable: true
                            value: dialog.value(kind, level)
                            onValueModified: dialog.setThreshold(kind, level, value)
                            Accessible.name: kind + " " + level
                        }
                    }
                    CheckBox {
                        objectName: kind + "WarningMute"
                        text: qsTr("Mute")
                        checked: alert.muted
                        onToggled: {
                            if (kind === "fc") settings.fc_status_health_muted = checked
                            else settings[dialog.mutePrefix + kind + "_muted"] = checked
                        }
                    }
                }
            }
        }
    }
}
