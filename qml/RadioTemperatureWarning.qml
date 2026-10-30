import QtQuick 2.12
import QtQuick.Controls 2.12
import QtQuick.Layouts 1.12

Rectangle {
    id: root
    objectName: "radioTemperatureWarning"
    property var airWarnings: []
    property var groundWarnings: []
    property bool soundEnabled: true
    property int qtMajorVersion: typeof _qopenhd !== "undefined" ? _qopenhd.qtMajorVersion : 5
    // Adjustable intervals allow the production timing logic to be tested.
    property int hotRepeatMs: 30000
    property int overheatRepeatMs: 10000
    property int muteDurationMs: 60000
    readonly property var entries: {
        var result = []
        function add(warnings, role) {
            for (var i = 0; i < warnings.length; ++i) {
                var entry = warnings[i]
                if (entry.state >= 2)
                    result.push({role: role, index: entry.index, state: entry.state, value: entry.value})
            }
        }
        add(airWarnings, qsTr("Air"))
        add(groundWarnings, qsTr("Ground"))
        return result
    }
    readonly property int severity: {
        var worst = -1
        for (var i = 0; i < entries.length; ++i) worst = Math.max(worst, entries[i].state)
        return worst
    }
    readonly property bool active: entries.length > 0
    property double muteUntilMs: 0
    property int mutedSeverity: -1
    property double clockMs: Date.now()
    readonly property bool silenced: muteUntilMs > clockMs
    property double lastAlarmMs: -1
    property int lastAlarmSeverity: -1
    property bool pendingAlarm: false
    readonly property int repeatMs: severity >= 3 ? overheatRepeatMs : hotRepeatMs
    readonly property bool audioUnavailable: audio.status === Loader.Error
                                            || (audio.item !== null && audio.item.failed)
    signal alarmRequested()

    visible: active
    implicitHeight: content.implicitHeight + 24
    height: implicitHeight
    radius: 10
    color: severity >= 3 ? "#c62828" : "#8a4800"
    border.color: severity >= 3 ? "#ffb4ab" : "#ffcf80"
    border.width: 2

    function muteTemporarily() {
        clockMs = Date.now()
        muteUntilMs = clockMs + muteDurationMs
        mutedSeverity = severity
        pendingAlarm = false
    }
    function soundAlarm() {
        clockMs = Date.now()
        if (!active || !soundEnabled || silenced) return
        // Telemetry repeats and threshold jitter must not spam the speaker.
        if (lastAlarmMs >= 0 && clockMs - lastAlarmMs < repeatMs
                && severity <= lastAlarmSeverity) return
        lastAlarmMs = clockMs
        lastAlarmSeverity = severity
        pendingAlarm = true
        alarmRequested()
        playPendingAlarm()
    }
    function playPendingAlarm() {
        if (pendingAlarm && active && soundEnabled && !silenced && audio.item) {
            pendingAlarm = false
            audio.item.playAlarm()
        }
    }
    onSeverityChanged: {
        if (severity > mutedSeverity && silenced) muteUntilMs = 0
        soundAlarm()
    }
    onActiveChanged: {
        if (!active) {
            muteUntilMs = 0
            mutedSeverity = -1
            pendingAlarm = false
        } else soundAlarm()
    }
    onSoundEnabledChanged: {
        if (soundEnabled) soundAlarm()
        else pendingAlarm = false
    }
    Component.onCompleted: soundAlarm()
    Timer {
        interval: 250
        running: root.active
        repeat: true
        onTriggered: root.soundAlarm()
    }
    Loader {
        id: audio
        active: root.active && root.soundEnabled && !root.silenced
        source: root.qtMajorVersion >= 6 ? "RadioTemperatureAlarmSoundQt6.qml"
                                        : "RadioTemperatureAlarmSound.qml"
        onLoaded: root.playPendingAlarm()
    }

    GridLayout {
        id: content
        anchors.fill: parent
        anchors.margins: 12
        columns: root.width < 480 ? 2 : 3
        columnSpacing: 12
        rowSpacing: 8
        Text {
            Layout.row: 0
            Layout.column: 0
            text: "!"
            color: "white"
            font.bold: true
            font.pixelSize: 32
            Layout.alignment: Qt.AlignTop
        }
        ColumnLayout {
            Layout.row: 0
            Layout.column: 1
            Layout.fillWidth: true
            Layout.minimumWidth: 0
            spacing: 4
            Text {
                objectName: "radioTemperatureWarningTitle"
                Layout.fillWidth: true
                text: root.severity >= 3 ? qsTr("WI-FI RADIO OVERHEATING") : qsTr("WI-FI RADIO HOT")
                color: "white"
                font.bold: true
                font.pixelSize: root.width < 480 ? 16 : 20
                wrapMode: Text.WordWrap
            }
            Text {
                objectName: "radioTemperatureWarningDetails"
                Layout.fillWidth: true
                text: {
                    var lines = []
                    for (var i = 0; i < root.entries.length; ++i) {
                        var entry = root.entries[i]
                        lines.push(qsTr("%1 card %2: %3").arg(entry.role).arg(entry.index + 1).arg(entry.value))
                    }
                    return lines.join("\n")
                }
                color: "white"
                font.pixelSize: 14
                wrapMode: Text.WordWrap
            }
            Text {
                Layout.fillWidth: true
                text: qsTr("Check radio cooling. Link performance may be reduced.")
                color: "white"
                font.pixelSize: 13
                wrapMode: Text.WordWrap
            }
            Text {
                Layout.fillWidth: true
                visible: !root.soundEnabled || root.audioUnavailable
                text: root.soundEnabled ? qsTr("Warning sound unavailable") : qsTr("Warning sound disabled")
                color: "white"
                font.pixelSize: 12
                wrapMode: Text.WordWrap
            }
        }
        Button {
            objectName: "radioTemperatureWarningMute"
            Layout.row: root.width < 480 ? 1 : 0
            Layout.column: root.width < 480 ? 1 : 2
            Layout.alignment: Qt.AlignTop | Qt.AlignRight
            Layout.preferredWidth: 100
            font.pixelSize: 13
            visible: root.soundEnabled && !root.audioUnavailable
            text: root.silenced ? qsTr("Muted %1 s").arg(Math.ceil((root.muteUntilMs - root.clockMs) / 1000))
                               : qsTr("Mute 60 s")
            enabled: !root.silenced
            onClicked: root.muteTemporarily()
            contentItem: Text {
                text: parent.text
                color: "white"
                font.pixelSize: 13
                horizontalAlignment: Text.AlignHCenter
                verticalAlignment: Text.AlignVCenter
            }
            background: Rectangle {
                radius: 6
                color: "#40000000"
                border.color: "#99ffffff"
            }
        }
    }
}
