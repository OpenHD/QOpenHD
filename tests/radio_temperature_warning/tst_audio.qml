import QtQuick 2.12
import QtTest 1.2

Item {
    Loader { id: audio; source: "AUDIO_COMPONENT" }
    TestCase {
        name: "RadioTemperatureAlarmAudio"
        when: windowShown
        function test_real_sound_loads_and_queued_request_plays() {
            tryCompare(audio,"status",Loader.Ready)
            var tone = findChild(audio.item,"radioTemperatureAlarmTone")
            verify(tone !== null)
            tone.volume = 0 // Validate real playback without making test noise.
            audio.item.playAlarm()
            tryCompare(audio.item,"ready",true,5000)
            verify(!audio.item.failed)
            tryCompare(audio.item,"pending",false,1000)
            verify(tone.playing)
        }
    }
}
