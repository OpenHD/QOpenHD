import QtQuick 2.12
import QtQuick.Controls 2.12
import QtQuick.Layouts 1.12
import "../../video/ColorPreviewMath.js" as ColorPreview

Column {
    id: root
    spacing: 8
    property string exportResult: ""
    signal controlFocused(var item)
    function takeover_control() { enableSwitch.forceActiveFocus() }
    function reset() {
        settings.color_preview_enabled = false
        settings.color_preview_temperature = 6500
        settings.color_preview_red = 1
        settings.color_preview_green = 1
        settings.color_preview_blue = 1
    }
    Label {
        width: parent.width
        text: qsTr("Colour tuning preview")
        font.bold: true
        color: "white"
        horizontalAlignment: Text.AlignHCenter
        topPadding: 10
    }
    Switch {
        id: enableSwitch
        width: parent.width
        text: qsTr("Enable colour preview")
        palette.windowText: "white"
        palette.text: "white"
        checked: settings.color_preview_enabled
        onToggled: settings.color_preview_enabled = checked
        onActiveFocusChanged: if (activeFocus) root.controlFocused(this)
    }
    Repeater {
        model: [
            {label: qsTr("Temperature (relative K)"), key: "color_preview_temperature", min: 2000, max: 12000, step: 100},
            {label: qsTr("Red gain"), key: "color_preview_red", min: 0.25, max: 4, step: 0.01},
            {label: qsTr("Green gain"), key: "color_preview_green", min: 0.25, max: 4, step: 0.01},
            {label: qsTr("Blue gain"), key: "color_preview_blue", min: 0.25, max: 4, step: 0.01}
        ]
        delegate: Column {
            width: root.width
            spacing: 0
            Label {
                width: parent.width
                color: "white"
                text: modelData.label + ": " + (index === 0 ? settings[modelData.key] : settings[modelData.key].toFixed(2))
                elide: Text.ElideRight
            }
            Slider {
                width: parent.width
                from: modelData.min
                to: modelData.max
                stepSize: modelData.step
                value: settings[modelData.key]
                onMoved: settings[modelData.key] = value
                onActiveFocusChanged: if (activeFocus) root.controlFocused(this)
                Accessible.name: modelData.label
            }
        }
    }
    RowLayout {
        width: parent.width
        spacing: 6
        Button {
            Layout.fillWidth: true
            text: qsTr("Reset / bypass")
            onClicked: root.reset()
            onActiveFocusChanged: if (activeFocus) root.controlFocused(this)
        }
        Button {
            Layout.fillWidth: true
            text: qsTr("Export findings")
            onActiveFocusChanged: if (activeFocus) root.controlFocused(this)
            onClicked: {
                var gains = ColorPreview.gains(settings.color_preview_temperature, settings.color_preview_red, settings.color_preview_green, settings.color_preview_blue)
                var findings = {schema: 1, stage: "decoded_rgb_preview", enabled: settings.color_preview_enabled,
                    temperature_relative_kelvin: settings.color_preview_temperature,
                    channels: [settings.color_preview_red, settings.color_preview_green, settings.color_preview_blue],
                    effective_rgb_gain: [gains.x, gains.y, gains.z],
                    note: "Display RGB adjustment. ISP Bayer gains require conversion and validation against the active IQ profile."}
                var path = _qopenhd.export_color_preview(JSON.stringify(findings))
                root.exportResult = path.length ? qsTr("Saved: ") + path : qsTr("Export failed")
            }
        }
    }
    Label {
        width: parent.width
        wrapMode: Text.Wrap
        color: "#dddddd"
        font.pixelSize: 11
        text: qsTr("Primary video preview. Export saves findings for ISP tuning.") + (root.exportResult.length ? "\n" + root.exportResult : "")
    }
}
