import QtQuick 2.12
import QtQuick.Controls 2.12
import QtQuick.Layouts 1.12
import ".."
import "../openhd_settings"
import "../MenuTypography.js" as Typography

AdvancedCard {
    id: root
    property var warningTypes: []
    property string sectionTitle: ""
    property bool includeTelemetryRules: false
    readonly property bool allOff: {
        for (var i = 0; i < warningTypes.length; ++i) {
            if (settings["audio_warning_tts_" + warningTypes[i].key + "_enabled"] === true) return false
        }
        if (includeTelemetryRules) {
            for (var j = 0; j < _audioAnnouncements.rules.length; ++j) {
                if (_audioAnnouncements.rules[j].enabled) return false
            }
        }
        return true
    }
    function setAllOff(off) {
        for (var i = 0; i < warningTypes.length; ++i)
            settings["audio_warning_tts_" + warningTypes[i].key + "_enabled"] = !off
        if (includeTelemetryRules) {
            for (var j = 0; j < _audioAnnouncements.rules.length; ++j) {
                var rule = Object.assign({}, _audioAnnouncements.rules[j])
                rule.enabled = !off
                _audioAnnouncements.saveRule(j, rule)
            }
        }
    }
    Layout.fillWidth: true
    Layout.preferredHeight: warningRows.implicitHeight + 32
    ColumnLayout {
        id: warningRows
        anchors { left: parent.left; right: parent.right; top: parent.top }
        spacing: 10
        RowLayout {
            Layout.fillWidth: true
            Label { Layout.fillWidth: true; text: sectionTitle; color: settings_form.primaryText; font.family: Typography.family; font.pixelSize: Typography.sectionTitle; font.bold: true; wrapMode: Text.WordWrap }
            Switch {
                objectName: root.includeTelemetryRules ? "mavlinkAllOff" : "openhdAllOff"
                text: qsTr("All off")
                checked: root.allOff
                onToggled: root.setAllOff(checked)
            }
        }
        RowLayout {
            Layout.fillWidth: true
            Label { Layout.fillWidth: true; text: qsTr("Repeat every (seconds)"); color: settings_form.primaryText }
            SpinBox { Layout.minimumWidth: 110; Layout.preferredWidth: 140; Layout.maximumWidth: 160; objectName: "warningSpeechInterval"; from: 5; to: 3600; editable: true; value: settings.audio_warning_tts_interval; onValueModified: settings.audio_warning_tts_interval = value }
        }
        Repeater {
            model: warningTypes
            delegate: ColumnLayout {
                id: warningTypeSection
                property string warningType: modelData.key
                Layout.fillWidth: true
                RowLayout {
                    Layout.fillWidth: true
                    Label { Layout.fillWidth: true; text: modelData.title; color: settings_form.primaryText; font.family: Typography.family; font.pixelSize: Typography.body }
                    Switch {
                        Layout.preferredWidth: 60
                        Layout.maximumWidth: 60
                        objectName: "warningSpeechEnabled_" + modelData.key
                        checked: settings["audio_warning_tts_" + modelData.key + "_enabled"] === true
                        onToggled: settings["audio_warning_tts_" + modelData.key + "_enabled"] = checked
                    }
                }
                RowLayout {
                    visible: modelData.key !== "message" && modelData.key !== "openhd_message"
                    Label { text: qsTr("Warnings"); color: settings_form.secondaryText }
                    CheckBox {
                        text: modelData.key === "fc" ? qsTr("Flight controller") : qsTr("Air")
                        checked: modelData.key === "fc" ? !settings.fc_status_health_muted : settings["air_status_" + modelData.key + "_muted"] !== true
                        onToggled: {
                            if (modelData.key === "fc") settings.fc_status_health_muted = !checked
                            else settings["air_status_" + modelData.key + "_muted"] = !checked
                        }
                    }
                    CheckBox {
                        visible: modelData.key !== "fc"
                        text: qsTr("Ground")
                        checked: settings["ground_status_" + modelData.key + "_muted"] !== true
                        onToggled: settings["ground_status_" + modelData.key + "_muted"] = !checked
                    }
                }
                Repeater {
                    model: modelData.key === "temp" || modelData.key === "cpu" ?
                        [{prefix:"air_status_",title:qsTr("Air")}, {prefix:"ground_status_",title:qsTr("Ground")}, {prefix:"x20_status_",title:"X20"}] : []
                    delegate: GridLayout {
                        columns: warningTypeSection.width < 560 ? 2 : 5
                        Layout.fillWidth: true
                        Label { Layout.columnSpan: parent.columns === 2 ? 2 : 1; Layout.preferredWidth: 56; text: modelData.title; color: settings_form.primaryText }
                        Label { text: qsTr("Caution"); color: settings_form.secondaryText }
                        SpinBox {
                            Layout.minimumWidth: 90
                            Layout.preferredWidth: 130
                            Layout.maximumWidth: 160
                            Layout.fillWidth: true
                            from: 1; to: warningTypeSection.warningType === "temp" ? 149 : 99
                            property string key: modelData.prefix + warningTypeSection.warningType
                            objectName: key + "_caution"
                            value: settings[key + "_caution"]
                            onValueModified: { settings[key + "_caution"] = value; if (settings[key + "_warn"] <= value) settings[key + "_warn"] = value + 1 }
                        }
                        Label { text: qsTr("Warning"); color: settings_form.secondaryText }
                        SpinBox {
                            Layout.minimumWidth: 90
                            Layout.preferredWidth: 130
                            Layout.maximumWidth: 160
                            Layout.fillWidth: true
                            from: 2; to: warningTypeSection.warningType === "temp" ? 150 : 100
                            property string key: modelData.prefix + warningTypeSection.warningType
                            objectName: key + "_warn"
                            value: settings[key + "_warn"]
                            onValueModified: { settings[key + "_warn"] = value; if (settings[key + "_caution"] >= value) settings[key + "_caution"] = value - 1 }
                        }
                    }
                }
                CompactLinkComboBox {
                    objectName: "warningAlertMode_" + modelData.key
                    Layout.fillWidth: true
                    model: [qsTr("Speech"), qsTr("Soft tone"), qsTr("Double tone"), qsTr("Urgent tone")]
                    currentIndex: settings["audio_warning_tts_" + modelData.key + "_mode"] || 0
                    onActivated: settings["audio_warning_tts_" + modelData.key + "_mode"] = currentIndex
                }
                TextField {
                    visible: (settings["audio_warning_tts_" + modelData.key + "_mode"] || 0) === 0
                    objectName: "warningSpeechPhrase_" + modelData.key
                    Layout.fillWidth: true
                    text: settings["audio_warning_tts_" + modelData.key + "_phrase"]
                    placeholderText: "{message}"
                    maximumLength: 256
                    selectByMouse: true
                    onEditingFinished: settings["audio_warning_tts_" + modelData.key + "_phrase"] = text.trim().length ? text.trim() : "{message}"
                }
            }
        }
    }
                    }
