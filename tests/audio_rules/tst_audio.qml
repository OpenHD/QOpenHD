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

