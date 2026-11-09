import QtQuick 2.12
import QtQuick.Controls 2.12
import QtQuick.Layouts 1.12
import ".."
import "../openhd_settings"
import "../MenuTypography.js" as Typography

AdvancedCard {
    id: card
    objectName: "audioRuleCard" + ruleIndex
    property var rule
    property int ruleIndex
    property var sourceLabels: [qsTr("Warning message"), qsTr("Error message"), qsTr("Information message"), qsTr("Battery (%)"), qsTr("Wind speed (knots)"), qsTr("Relative altitude (m)"), qsTr("Ground speed (km/h)")]
    property var phrases: ["{message}", "{message}", "{message}", "Battery at {value} percent", "Wind speed {value} knots", "Altitude {value} meters", "Ground speed {value} kilometers per hour"]
    implicitHeight: 84
    function summary() {
        if (rule.source < 3) return rule.filter ? qsTr('When a message contains "%1"').arg(rule.filter) : qsTr("Read matching messages")
        if (rule.condition === 2) return qsTr("Read every %1 seconds").arg(rule.cooldown)
        return (rule.condition === 0 ? qsTr("At or below %1").arg(rule.threshold) : qsTr("At or above %1").arg(rule.threshold)) + " · " + qsTr("once until recovery")
    }
    RowLayout {
        anchors.fill: parent
        spacing: 12
        Switch {
            objectName: "ruleEnabled"
            checked: card.rule.enabled
            Accessible.name: qsTr("Enable %1 rule").arg(card.sourceLabels[card.rule.source])
            onToggled: { var updated = Object.assign({}, card.rule); updated.enabled = checked; _audioAnnouncements.saveRule(card.ruleIndex, updated) }
        }
        ColumnLayout {
            Layout.fillWidth: true
            spacing: 5
            Label { text: card.sourceLabels[card.rule.source]; color: settings_form.primaryText; font.family: Typography.family; font.pixelSize: Typography.body; font.bold: true }
            Label { text: card.summary(); color: settings_form.secondaryText; font.family: Typography.family; font.pixelSize: Typography.helper; Layout.fillWidth: true; elide: Text.ElideRight }
        }
        AdvancedActionButton { objectName: "editRule"; text: qsTr("Edit"); iconText: "\uf303"; onClicked: editor.open() }
        AdvancedActionButton { text: qsTr("Remove"); iconText: "\uf2ed"; destructive: true; onClicked: _audioAnnouncements.removeRule(card.ruleIndex) }
    }
    AdvancedDialog {
        id: editor
        objectName: "ruleEditor"
        parent: Overlay.overlay
        anchors.centerIn: parent
        width: Math.min(620, parent ? parent.width - 28 : 620)
        height: Math.min(590, parent ? parent.height - 28 : 590)
        title: qsTr("Edit voice rule")
        onOpened: {
            source.currentIndex = card.rule.source
            condition.currentIndex = card.rule.condition
            threshold.value = card.rule.threshold
            cooldown.value = card.rule.cooldown
            filter.text = card.rule.filter
            phrase.text = card.rule.phrase
            enabledSwitch.checked = card.rule.enabled
        }
        contentItem: ScrollView {
            clip: true
            contentWidth: availableWidth
            ColumnLayout {
                width: parent.width
                spacing: 10
                Switch { id: enabledSwitch; text: qsTr("Enable this rule") }
                Label { text: qsTr("What should trigger this announcement?"); color: "#edf4fa"; font.family: Typography.family; font.pixelSize: Typography.body }
                CompactLinkComboBox { id: source; objectName: "ruleSource"; Layout.fillWidth: true; model: card.sourceLabels; onActivated: phrase.text = card.phrases[currentIndex] }
                RowLayout {
                    Layout.fillWidth: true
                    visible: source.currentIndex >= 3
                    CompactLinkComboBox { id: condition; Layout.fillWidth: true; model: [qsTr("At or below"), qsTr("At or above"), qsTr("Every interval")] }
                    SpinBox { id: threshold; objectName: "ruleThreshold"; from: -10000; to: 10000; editable: true; visible: condition.currentIndex !== 2 }
                }
                Label { visible: source.currentIndex < 3; text: qsTr("Message contains (leave empty for any message)"); color: "#aebdcb"; font.family: Typography.family; font.pixelSize: Typography.helper }
                TextField { id: filter; visible: source.currentIndex < 3; Layout.fillWidth: true; maximumLength: 100; placeholderText: qsTr("For example: battery") }
                RowLayout {
                    Layout.fillWidth: true
                    Label { Layout.fillWidth: true; text: condition.currentIndex === 2 && source.currentIndex >= 3 ? qsTr("Repeat every (seconds)") : qsTr("Minimum pause (seconds)"); color: "#edf4fa"; font.family: Typography.family; font.pixelSize: Typography.body }
                    SpinBox { id: cooldown; from: 5; to: 3600; editable: true }
                }
                Label { text: qsTr("What should the voice say?"); color: "#edf4fa"; font.family: Typography.family; font.pixelSize: Typography.body }
                TextField { id: phrase; objectName: "rulePhrase"; Layout.fillWidth: true; maximumLength: 256; selectByMouse: true }
                Label { Layout.fillWidth: true; wrapMode: Text.WordWrap; text: source.currentIndex < 3 ? qsTr("Use {message} to read the received message.") : qsTr("Use {value} for the current number and {unit} for its unit. Standard phrases follow your selected speech language."); color: "#aebdcb"; font.family: Typography.family; font.pixelSize: Typography.helper }
            }
        }
        footer: RowLayout {
            spacing: 10
            AdvancedActionButton { Layout.fillWidth: true; text: qsTr("Cancel"); onClicked: editor.close() }
            AdvancedActionButton {
                objectName: "saveRule"; Layout.fillWidth: true; text: qsTr("Save rule"); primary: true
                onClicked: {
                    var updated = { enabled: enabledSwitch.checked, source: source.currentIndex, condition: condition.currentIndex, threshold: threshold.value, cooldown: cooldown.value, filter: filter.text, phrase: phrase.text }
                    editor.close()
                    _audioAnnouncements.saveRule(card.ruleIndex, updated)
                }
            }
        }
    }
}
