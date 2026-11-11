import QtQuick 2.12
import QtTest 1.2
import QtQuick.Window 2.12
import "../../qml/ui/configpopup/qopenhd_settings" as Audio

Item {
    id: fixture
    width: 860; height: 720
    QtObject {
        id: settings_form
        property bool darkMode: true
        property bool compactSidebar: true
        property color pageBackground: "#091827"
        property color panelBackground: "#102235"
        property color panelBackgroundRaised: "#15283b"
        property color lineColor: "#26394c"
        property color primaryText: "#f2f6fb"
        property color secondaryText: "#aebdcb"
        property color accentColor: "#278cff"
        property color errorColor: "#ff4e5d"
        function side_bar_regain_focus() {}
    }
    FontLoader { source: "../../qml/resources/Font Awesome 5 Free-Solid-900.otf" }
    FontLoader { source: Qt.platform.os === "windows" ? "file:///C:/Windows/Fonts/arial.ttf" : "" }
    FontLoader { source: Qt.platform.os === "windows" ? "file:///C:/Windows/Fonts/arialbd.ttf" : "" }
    QtObject {
        id: settings
        property bool dev_show_advanced_button: true
        property bool audio_warning_tts_message_enabled: true
        property bool audio_warning_tts_openhd_message_enabled: true
        property double air_status_temp_warn: 70
        property double air_status_temp_caution: 60
        property double air_status_cpu_warn: 70
        property double air_status_cpu_caution: 50
        property double ground_status_temp_warn: 70
        property double ground_status_temp_caution: 60
        property double ground_status_cpu_warn: 70
        property double ground_status_cpu_caution: 50
        property int audio_warning_tts_openhd_message_mode: 0
        property string audio_warning_tts_openhd_message_phrase: "{message}"
        property double x20_status_cpu_warn: 95
        property double x20_status_cpu_caution: 85
        property double x20_status_temp_warn: 78
        property double x20_status_temp_caution: 74
        property string audio_warning_tts_message_phrase: "{message}"
        property string audio_warning_tts_fc_phrase: "{message}"
        property string audio_warning_tts_radio_phrase: "{message}"
        property string audio_warning_tts_undervolt_phrase: "{message}"
        property string audio_warning_tts_cpu_phrase: "{message}"
        property string audio_warning_tts_temp_phrase: "{message}"
        property bool audio_warning_tts_fc_enabled: true
        property bool audio_warning_tts_radio_enabled: true
        property bool audio_warning_tts_undervolt_enabled: true
        property bool audio_warning_tts_cpu_enabled: true
        property bool audio_warning_tts_temp_enabled: true
        property int audio_warning_tts_interval: 30
        property int audio_warning_tts_message_mode: 0
        property int audio_warning_tts_fc_mode: 0
        property int audio_warning_tts_radio_mode: 0
        property int audio_warning_tts_undervolt_mode: 0
        property int audio_warning_tts_cpu_mode: 0
        property int audio_warning_tts_temp_mode: 0
        property bool air_status_radio_muted: false
        property bool ground_status_radio_muted: false
        property bool fc_status_health_muted: false
        property bool air_status_undervolt_muted: false
        property bool air_status_cpu_muted: false
        property bool air_status_temp_muted: false
        property bool ground_status_undervolt_muted: false
        property bool ground_status_cpu_muted: false
        property bool ground_status_temp_muted: false
        property int rpi_audio_output: 0
        property bool audio_welcome_sound: true
        property bool audio_warning_sound: true
        property int audio_notification_volume: 70
        property bool enable_speech: true
        property string audio_speech_language: "en"
        property double speech_rate: 1.0
    }
    QtObject {
        id: _qopenhd
        function is_platform_rpi() { return true }
    }
    QtObject {
        id: _restartqopenhdmessagebox
        property int shown: 0
        function show() { shown++ }
    }
    QtObject {
        id: _audioAnnouncements
        property bool supported: true
        property bool speechAvailable: true
        property string status: "Ready"
        property int saves: 0
        property var rules: [{ source: 3, enabled: false, condition: 0, threshold: 50, cooldown: 30, filter: "", phrase: "Battery at {value} percent" },
            { source: 4, enabled: false, condition: 1, threshold: 50, cooldown: 30, filter: "", phrase: "Wind speed {value} knots" }]
        function saveRule(index, rule) { var copy = rules.slice(); copy[index] = rule; rules = copy; saves++ }
        function removeRule(index) { var copy = rules.slice(); copy.splice(index, 1); rules = copy }
        function addRule(source) { }
        function testSound() { }
        function testVoice() { }
    }
    Audio.AppAudioRulesView { id: page; anchors.fill: parent }
    TestCase {
        name: "AudioSettings"
        when: windowShown
        function test_advancedTabs() {
            for (var tab of ["warningsTab", "rulesTab"]) {
                settings.dev_show_advanced_button = true
                wait(20)
                mouseClick(findChild(page, tab))
                verify(findChild(page, tab).checked)
                settings.dev_show_advanced_button = false
                tryCompare(findChild(page, "soundsTab"), "checked", true)
                verify(!findChild(page, "warningsTab").visible)
                verify(!findChild(page, "rulesTab").visible)
                compare(findChild(page, "warningsTab").width, 0)
                compare(findChild(page, "rulesTab").width, 0)
            }
            settings.dev_show_advanced_button = true
            wait(20)
            verify(findChild(page, "warningsTab").visible)
            verify(findChild(page, "rulesTab").visible)
        }
        function test_allOffSwitches() {
            mouseClick(findChild(page, "warningsTab"))
            wait(50)
            var openhd = findChild(page, "openhdAllOff")
            var mavlink = findChild(page, "mavlinkAllOff")
            verify(!openhd.checked)
            mouseClick(openhd)
            verify(openhd.checked)
            for (var key of ["temp", "cpu", "undervolt", "radio", "openhd_message"])
                compare(settings["audio_warning_tts_" + key + "_enabled"], false)
            compare(settings.audio_warning_tts_fc_enabled, true)
            compare(settings.audio_warning_tts_message_enabled, true)
            mouseClick(openhd)
            verify(!openhd.checked)
            mouseClick(findChild(page, "warningSpeechEnabled_temp"))
            verify(!openhd.checked) // Other OpenHD warnings are still enabled.
            settings.audio_warning_tts_temp_enabled = true
            mouseClick(findChild(page, "rulesTab"))
            wait(50)
            var rule = Object.assign({}, _audioAnnouncements.rules[0])
            rule.enabled = true
            _audioAnnouncements.saveRule(0, rule)
            mouseClick(mavlink)
            verify(mavlink.checked)
            compare(settings.audio_warning_tts_fc_enabled, false)
            compare(settings.audio_warning_tts_message_enabled, false)
            for (var i = 0; i < _audioAnnouncements.rules.length; ++i)
                compare(_audioAnnouncements.rules[i].enabled, false)
            compare(settings.audio_warning_tts_temp_enabled, true)
            mouseClick(mavlink)
            verify(!mavlink.checked)
            compare(settings.audio_warning_tts_fc_enabled, true)
            compare(settings.audio_warning_tts_message_enabled, true)
            compare(_audioAnnouncements.rules[0].enabled, true)
            // Restore rules for the editor tests.
            for (var j = 0; j < _audioAnnouncements.rules.length; ++j) {
                rule = Object.assign({}, _audioAnnouncements.rules[j])
                rule.enabled = false
                _audioAnnouncements.saveRule(j, rule)
            }
            _audioAnnouncements.saves = 0
        }
        function test_warningTab() {
            mouseClick(findChild(page,"warningsTab"));wait(100)
            for (var width of [480,860]) {
                fixture.width=width;wait(60)
                var field=findChild(page,"ground_status_temp_warn")
                var position=field.mapToItem(page,0,0)
                verify(position.x>=0)
                verify(position.x+field.width<=page.width+1,"Warning threshold overflows at " + width)
            }
            var preview=grabImage(page)
            if(preview.width>0) preview.save("build/audio-openhd-warnings.png")
            var phrase=findChild(page,"warningSpeechPhrase_temp")
            verify(phrase.visible)
            phrase.text="Custom temperature warning"
            phrase.editingFinished()
            compare(settings.audio_warning_tts_temp_phrase,"Custom temperature warning")
            var mode=findChild(page,"warningAlertMode_temp")
            mode.currentIndex=2;mode.activated(2)
            compare(settings.audio_warning_tts_temp_mode,2)
            verify(!phrase.visible)
            mode.currentIndex=0;mode.activated(0)
            compare(settings.audio_warning_tts_temp_mode,0)
            verify(phrase.visible)
            compare(findChild(page,"warningsTab").text,"OPENHD")
            compare(findChild(page,"rulesTab").text,"MAVLINK")
            verify(findChild(page,"warningAlertMode_fc").visible === false)
            var caution=findChild(page,"ground_status_temp_caution")
            caution.value=80;caution.valueModified()
            compare(settings.ground_status_temp_caution,80)
            compare(settings.ground_status_temp_warn,81)
            mouseClick(findChild(page,"rulesTab"));wait(100)
            verify(findChild(page,"warningAlertMode_fc").visible)
            verify(!findChild(page,"warningAlertMode_temp").visible)
            mouseClick(findChild(page,"soundsTab"));wait(50)
            verify(!findChild(page,"warningSpeechInterval").visible)
        }
        function test_rulesOnly() {
            compare(findChild(page, "audioOutput1"), null)
            compare(findChild(page, "liveAudioSwitch"), null)
        }
        function test_ruleSave() {
            mouseClick(findChild(page, "rulesTab"))
            wait(50)
            findChild(page, "editRule").clicked()
            wait(50)
            var threshold = findChild(page.Window.window.contentItem, "ruleThreshold")
            var save = findChild(page.Window.window.contentItem, "saveRule")
            verify(threshold !== null && save !== null)
            threshold.value = 40
            save.clicked()
            compare(_audioAnnouncements.rules[0].threshold, 40)
            compare(_audioAnnouncements.saves, 1)
        }
        function test_smallScreenLayout() {
            fixture.width = 480
            mouseClick(findChild(page, "rulesTab"))
            wait(50)
            var edit = findChild(page, "editRule")
            verify(edit.width > 0 && edit.visible)
            var first = findChild(page, "audioRuleCard0")
            var second = findChild(page, "audioRuleCard1")
            verify(first.height >= 84)
            verify(second.y >= first.y + first.height)
            fixture.width = 860
        }
        function test_languageSelection() {
            var language = findChild(page, "speechLanguage")
            compare(language.model.length, 3)
            language.currentIndex = 1
            language.activated(1)
            compare(settings.audio_speech_language, "de")
            language.currentIndex = 2
            language.activated(2)
            compare(settings.audio_speech_language, "es")
        }
        function test_zPreview() {
            _audioAnnouncements.saveRule(0, { source: 3, enabled: false, condition: 0, threshold: 50,
                cooldown: 30, filter: "", phrase: "Battery at {value} percent" })
            verify(page.width > 0 && page.height > 0)
            verify(waitForRendering(page))
            wait(200)
            var logPath = Qt.application.arguments.indexOf("-o")
            var snapshot = grabImage(page)
            // Qt 5's Windows software backend can return an empty image.
            if (logPath >= 0 && snapshot.width > 0) snapshot.save(Qt.application.arguments[logPath + 1].replace(/,txt$/, ".png"))
            mouseClick(findChild(page, "soundsTab"))
            wait(100)
            snapshot = grabImage(page)
            if (logPath >= 0 && snapshot.width > 0) snapshot.save(Qt.application.arguments[logPath + 1].replace(/,txt$/, "-sounds.png"))
        }
    }
}

