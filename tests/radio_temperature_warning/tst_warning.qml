import QtQuick 2.12
import QtTest 1.2

Item {
    id: scene
    width: 800
    height: 480
    Rectangle { anchors.fill: parent; color: "#17222c" }
    RadioTemperatureWarning {
        id: warning
        qtMajorVersion: QT_MAJOR_VERSION
        anchors.horizontalCenter: parent.horizontalCenter
        y: 12
        width: scene.width - 24
        hotRepeatMs: 1500
        overheatRepeatMs: 700
        muteDurationMs: 900
    }
    SignalSpy { id: alarm; target: warning; signalName: "alarmRequested" }
    TestCase {
        name: "RadioTemperatureWarning"
        when: windowShown
        function entry(index, state, value) { return {index:index, state:state, value:value} }
        function init() {
            warning.airWarnings = []; warning.groundWarnings = []
            warning.soundEnabled = true
            warning.lastAlarmMs = -1; warning.lastAlarmSeverity = -1
            warning.muteUntilMs = 0; warning.clockMs = Date.now()
            scene.width = 800
            alarm.clear()
        }
        function test_missing_and_normal_are_quiet() {
            verify(!warning.visible); compare(alarm.count, 0)
            warning.airWarnings = [entry(0,-1,"N/A"),entry(1,1,"Warm")]
            verify(!warning.visible); compare(alarm.count, 0)
        }
        function test_hot_is_visible_and_audible_immediately() {
            warning.airWarnings = [entry(0,2,"Hot")]
            verify(warning.visible); compare(warning.severity, 2)
            compare(alarm.count, 1)
            verify(findChild(warning,"radioTemperatureWarningTitle").text.indexOf("HOT") >= 0)
            verify(findChild(warning,"radioTemperatureWarningDetails").text.indexOf("Air card 1: Hot") >= 0)
            for (var i=0;i<10;++i) warning.airWarnings = [entry(0,2,"Hot")]
            compare(alarm.count, 1)
            tryCompare(alarm, "count", 2, 2500)
        }
        function test_escalation_interrupts_cooldown_and_mute() {
            warning.airWarnings = [entry(0,2,"74°C")]
            warning.muteTemporarily()
            verify(warning.silenced)
            warning.airWarnings = [entry(0,3,"91°C")]
            verify(!warning.silenced); compare(alarm.count, 2)
            verify(findChild(warning,"radioTemperatureWarningTitle").text.indexOf("OVERHEATING") >= 0)
        }
        function test_ground_and_secondary_air_are_identified() {
            warning.airWarnings = [entry(1,2,"Hot")]
            warning.groundWarnings = [entry(0,1,"Normal"),entry(3,3,"Overheating")]
            compare(warning.entries.length, 2); compare(warning.severity, 3)
            var details = findChild(warning,"radioTemperatureWarningDetails").text
            verify(details.indexOf("Air card 2") >= 0)
            verify(details.indexOf("Ground card 4") >= 0)
            verify(details.indexOf("Normal") < 0)
        }
        function test_muting_keeps_warning_and_expires() {
            warning.groundWarnings = [entry(0,3,"Overheating")]
            compare(alarm.count, 1)
            var mute = findChild(warning,"radioTemperatureWarningMute")
            mouseClick(mute)
            verify(warning.silenced); verify(warning.visible)
            wait(600); compare(alarm.count, 1)
            tryCompare(alarm,"count",2,1500)
            verify(!warning.silenced)
        }
        function test_sound_disabled_keeps_visual() {
            warning.soundEnabled = false
            warning.airWarnings = [entry(0,3,"Overheating")]
            verify(warning.visible); compare(alarm.count,0)
            wait(800); compare(alarm.count,0)
            warning.soundEnabled = true
            compare(alarm.count,1)
        }
        function test_cooling_and_expired_telemetry_clear_warning() {
            warning.airWarnings = [entry(0,3,"Overheating")]
            warning.airWarnings = [entry(0,1,"Warm")]
            verify(!warning.visible)
            warning.groundWarnings = [entry(1,3,"Overheating")]
            warning.groundWarnings = [] // model expires missing per-card samples
            verify(!warning.visible); verify(!warning.pendingAlarm)
            var count = alarm.count
            wait(800); compare(alarm.count,count)
        }
        function test_threshold_jitter_does_not_spam() {
            warning.airWarnings = [entry(0,3,"Overheating")]
            warning.airWarnings = [entry(0,1,"Warm")]
            warning.airWarnings = [entry(0,3,"Overheating")]
            compare(alarm.count,1)
        }
        function test_layout_data() { return [{tag:"compact",width:320},{tag:"normal",width:800},{tag:"wide",width:1280}] }
        function test_layout(data) {
            scene.width = data.width
            warning.airWarnings = [entry(1,3,"Overheating")]
            warning.groundWarnings = [entry(0,2,"78°C"),entry(3,3,"93°C")]
            wait(100)
            verify(warning.height > 80); verify(warning.height < scene.height)
            var details = findChild(warning,"radioTemperatureWarningDetails")
            verify(details.width > 60, "Details width: " + details.width)
            verify(details.x + details.width <= warning.width)
            if (data.width === 800) grabImage(scene).save("SCREENSHOT_PATH")
        }
    }
}
