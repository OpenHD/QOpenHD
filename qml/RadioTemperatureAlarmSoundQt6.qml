import QtQuick 2.12
import QtMultimedia 6.0

Item {
    property bool pending: false
    readonly property bool ready: tone.status === SoundEffect.Ready
    readonly property bool failed: tone.status === SoundEffect.Error
    function playAlarm() {
        pending = true
        if (ready) {
            pending = false
            tone.play()
        }
    }
    SoundEffect {
        id: tone
        objectName: "radioTemperatureAlarmTone"
        source: Qt.resolvedUrl("resources/radio-temperature-alarm.wav")
        volume: 0.8
        loops: 1
        onStatusChanged: if (tone.status === SoundEffect.Ready && pending) playAlarm()
    }
    Component.onDestruction: tone.stop()
}
