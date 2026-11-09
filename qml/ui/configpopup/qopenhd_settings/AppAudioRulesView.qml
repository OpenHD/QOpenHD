import QtQuick 2.12
import QtQuick.Controls 2.12
import QtQuick.Layouts 1.12
import ".."
import "../openhd_settings"
import "../MenuTypography.js" as Typography

AdvancedPage {
    id: root
    pageTitle: qsTr("AUDIO")
    pageIcon: "\uf028"
    initialFocusItem: soundsTab
    onBackRequested: settings_form.side_bar_regain_focus()
    ColumnLayout {
        anchors.fill: parent
        spacing: 12
        AdvancedTabBar {
            id: tabs
            Layout.fillWidth: true
            AdvancedTabButton { id: soundsTab; objectName: "soundsTab"; text: qsTr("SOUNDS & SPEECH"); iconText: "\uf028" }
            AdvancedTabButton { objectName: "rulesTab"; text: qsTr("VOICE RULES"); iconText: "\uf086" }
        }
        StackLayout {
            Layout.fillWidth: true
            Layout.fillHeight: true
            currentIndex: tabs.currentIndex
            ScrollView {
                id: soundScroll
                clip: true
                contentWidth: availableWidth
                ColumnLayout {
                    width: soundScroll.availableWidth
                    spacing: 12
                    AdvancedCard {
                        Layout.fillWidth: true
                        Layout.preferredHeight: soundRows.implicitHeight + 32
                        ColumnLayout {
                            id: soundRows
                            anchors { left: parent.left; right: parent.right; top: parent.top }
                            spacing: 10
                            Label { text: qsTr("Local sounds"); color: settings_form.primaryText; font.family: Typography.family; font.pixelSize: Typography.sectionTitle; font.bold: true }
                            RowLayout {
                                Layout.fillWidth: true
                                Label { text: qsTr("Play a welcome sound at startup"); color: settings_form.primaryText; font.family: Typography.family; font.pixelSize: Typography.body; Layout.fillWidth: true; wrapMode: Text.WordWrap }
                                Switch { objectName: "welcomeSound"; checked: settings.audio_welcome_sound; onToggled: settings.audio_welcome_sound = checked }
                            }
                            RowLayout {
                                Layout.fillWidth: true
                                Label { text: qsTr("Play a sound for warnings and errors"); color: settings_form.primaryText; font.family: Typography.family; font.pixelSize: Typography.body; Layout.fillWidth: true; wrapMode: Text.WordWrap }
                                Switch { checked: settings.audio_warning_sound; onToggled: settings.audio_warning_sound = checked }
                            }
                        }
                    }
                    AdvancedCard {
                        Layout.fillWidth: true
                        Layout.preferredHeight: speechRows.implicitHeight + 32
                        ColumnLayout {
                            id: speechRows
                            anchors { left: parent.left; right: parent.right; top: parent.top }
                            spacing: 12
                            RowLayout {
                                Layout.fillWidth: true
                                Label { text: qsTr("Voice announcements"); color: settings_form.primaryText; font.family: Typography.family; font.pixelSize: Typography.sectionTitle; font.bold: true; Layout.fillWidth: true }
                                Switch { checked: settings.enable_speech; onToggled: settings.enable_speech = checked }
                            }
                            RowLayout {
                                Layout.fillWidth: true
                                Label { text: qsTr("Speech language"); color: settings_form.primaryText; font.family: Typography.family; font.pixelSize: Typography.body; Layout.fillWidth: true }
                                CompactLinkComboBox {
                                    objectName: "speechLanguage"
                                    Layout.preferredWidth: Math.min(240, root.width * 0.45)
                                    property var values: ["en", "de", "es"]
                                    model: ["English", "Deutsch", "Español"]
                                    currentIndex: Math.max(0, values.indexOf(settings.audio_speech_language))
                                    onActivated: function(index) { settings.audio_speech_language = values[index] }
                                }
                            }
                            RowLayout {
                                Layout.fillWidth: true
                                Label { text: qsTr("Speech speed"); color: settings_form.primaryText; font.family: Typography.family; font.pixelSize: Typography.body; Layout.fillWidth: true }
                                Slider { Layout.preferredWidth: Math.min(280, root.width * 0.45); from: 0.5; to: 2; stepSize: 0.05; value: settings.speech_rate; onMoved: settings.speech_rate = value }
                                Label { text: Math.round(settings.speech_rate * 100) + "%"; color: settings_form.secondaryText; font.family: Typography.family; font.pixelSize: Typography.body }
                            }
                            Label { Layout.fillWidth: true; wrapMode: Text.WordWrap; text: qsTr("Choose a language, then test the voice. If a system voice is missing, install that language's speech voice in your operating system."); color: settings_form.secondaryText; font.family: Typography.family; font.pixelSize: Typography.helper }
                        }
                    }
                    AdvancedCard {
                        Layout.fillWidth: true
                        Layout.preferredHeight: testRows.implicitHeight + 32
                        ColumnLayout {
                            id: testRows
                            anchors { left: parent.left; right: parent.right; top: parent.top }
                            spacing: 12
                            RowLayout {
                                Layout.fillWidth: true
                                Label { text: qsTr("Announcement volume"); color: settings_form.primaryText; font.family: Typography.family; font.pixelSize: Typography.body; Layout.fillWidth: true }
                                Slider { Layout.preferredWidth: Math.min(280, root.width * 0.45); from: 0; to: 100; stepSize: 1; value: settings.audio_notification_volume; onMoved: settings.audio_notification_volume = Math.round(value) }
                                Label { text: settings.audio_notification_volume + "%"; color: settings_form.secondaryText; font.family: Typography.family; font.pixelSize: Typography.body }
                            }
                            RowLayout {
                                AdvancedActionButton { objectName: "testSound"; text: qsTr("Test sound"); iconText: "\uf028"; enabled: _audioAnnouncements.supported; onClicked: _audioAnnouncements.testSound() }
                                AdvancedActionButton { objectName: "testVoice"; text: qsTr("Test voice"); iconText: "\uf075"; enabled: _audioAnnouncements.supported && _audioAnnouncements.speechAvailable && settings.enable_speech; onClicked: _audioAnnouncements.testVoice() }
                            }
                            Label { Layout.fillWidth: true; text: _audioAnnouncements.status; color: settings_form.secondaryText; font.family: Typography.family; font.pixelSize: Typography.helper; wrapMode: Text.WordWrap }
                        }
                    }
                }
            }
            ScrollView {
                id: ruleScroll
                clip: true
                contentWidth: availableWidth
                ColumnLayout {
                    width: ruleScroll.availableWidth
                    spacing: 10
                    RowLayout {
                        Layout.fillWidth: true
                        Label { text: qsTr("Spoken alerts"); color: settings_form.primaryText; font.family: Typography.family; font.pixelSize: Typography.sectionTitle; font.bold: true; Layout.fillWidth: true }
                        AdvancedActionButton {
                            text: qsTr("Add rule"); iconText: "\uf067"; primary: true
                            enabled: _audioAnnouncements.rules.length < 16
                            onClicked: addMenu.open()
                            Menu {
                                id: addMenu
                                Repeater {
                                    model: [qsTr("Warning message"), qsTr("Error message"), qsTr("Information message"), qsTr("Battery"), qsTr("Wind speed"), qsTr("Relative altitude"), qsTr("Ground speed")]
                                    MenuItem { text: modelData; onTriggered: _audioAnnouncements.addRule(index) }
                                }
                            }
                        }
                    }
                    Label { Layout.fillWidth: true; text: qsTr("Turn on a preset or choose Edit to change when it speaks. Rules never change flight-controller settings."); wrapMode: Text.WordWrap; color: settings_form.secondaryText; font.family: Typography.family; font.pixelSize: Typography.helper }
                    Repeater { model: _audioAnnouncements.rules; delegate: AudioRuleCard { Layout.fillWidth: true; rule: modelData; ruleIndex: index } }
                    Label { visible: _audioAnnouncements.rules.length === 0; text: qsTr("No rules yet. Add a rule to get started."); color: settings_form.secondaryText; font.family: Typography.family; font.pixelSize: Typography.body }
                }
            }
        }
    }
}
