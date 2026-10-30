import QtQuick 2.12
import QtQuick.Controls 2.12
import QtQuick.Layouts 1.12
import ".."
import "../MenuTypography.js" as Typography
import "AirSettingsLayout.js" as AirLayout

Item {
    id: row
    objectName: "airSetting_" + paramId
    property bool stacked: false
    property var settingsModel
    property var validateChange: null
    signal validationFailed(string reason)
    property bool connectionAlive: _ohdSystemAir.is_alive
    property string labelOverride: ""
    property string descriptionOverride: ""
    property string paramId
    readonly property int revision: settingsModel.update_count
    readonly property var metadata: { var changed = revision; return settingsModel.get_ui_metadata(paramId) }
    readonly property bool integer: { var changed = revision; return settingsModel.param_int_exists(paramId) }
    readonly property var value: { var changed = revision; return integer ? settingsModel.get_cached_int(paramId) : settingsModel.get_cached_string(paramId) }
    readonly property bool infoOnly: ["FC_FW_INFO", "FC_FW_EVID", "SIYI_ACTIVE", "TOPOTEK_ACTIVE", "CAM_CTRL_ACTIVE"].indexOf(paramId) >= 0
    readonly property bool locked: _qopenhd.debugMenuPreview || metadata.readOnly === true || infoOnly
    readonly property bool busy: settingsModel.ui_is_busy || !connectionAlive || _qopenhd.debugMenuPreview
    readonly property bool toggle: integer && (metadata.control === "toggle" || ["ETH_LINK_EN", "FC_UART_FLWCTL", "OHD_UART_EN", "OHD_UART_FLW", "TRACK_UART_FLOW", "LOG_OPENHD", "LOG_MAVLINK", "ADSB_ENABLE", "SBUS_EN", "CONFIG_BOOT_AIR"].indexOf(paramId) >= 0)
    readonly property bool port: ["FC_UART_CONN", "OHD_UART_TLM", "SBUS_DEV", "TRACKER_UART_OUT"].indexOf(paramId) >= 0
    readonly property bool portFallback: port && !settingsModel.string_param_has_enum(paramId)
    readonly property bool cells: paramId === "FC_BATT_N_CELLS"
    readonly property var choices: {
        if (cells) {
            var entries = [{label: qsTr("Not set"), value: 0}]
            for(var n=2;n<=8;n++) entries.push({label: n + "S", value: n})
            if(entries.filter(function(e) { return e.value === Number(value) }).length === 0) entries.push({label: value + "S", value: Number(value)})
            return entries
        }
        var ports = [{label: qsTr("Disabled"), value: ""}, {label: qsTr("Board default"), value: "DEFAULT"}]
        if(String(value) !== "" && String(value) !== "DEFAULT") ports.push({label: String(value), value: String(value)})
        ports.push({label: qsTr("Custom port..."), value: null})
        return ports
    }
    readonly property bool password: paramId === "WIFI_HS_PW" || paramId === "WIFI_CL_PW"
    readonly property string label: labelOverride || AirLayout.labels[paramId] || metadata.label || paramId
    readonly property string description: descriptionOverride || AirLayout.descriptions[paramId] || metadata.description || ""
    readonly property string displayValue: {
        if ((paramId === "FC_FW_INFO" || paramId === "FC_FW_EVID") && !String(value).length) return qsTr("Not reported")
        if (paramId === "FC_FW_INFO" && String(value).charAt(0) === "{") {
            try { var info = JSON.parse(String(value)); return info.ver || info.version || qsTr("Not reported") } catch(error) { return qsTr("Not reported") }
        }
        if (paramId === "FC_FW_EVID" && String(value).charAt(0) === "{") {
            try { return JSON.parse(String(value)).evidence || qsTr("Not reported") } catch(error) { return qsTr("Not reported") }
        }
        if (["SIYI_ACTIVE", "TOPOTEK_ACTIVE", "CAM_CTRL_ACTIVE"].indexOf(paramId) >= 0)
            return Number(value) ? qsTr("Active") : qsTr("Inactive")
        if (paramId === "MULTI_LINK_CAP") return Number(value) ? qsTr("Supported") : qsTr("Not supported")
        return String(value)
    }
    implicitHeight: stacked ? wording.implicitHeight + editor.height + 26 : Math.max(60, wording.implicitHeight + 18, editor.height + 18)
    signal backRequested()
    function changeAllowed(value) {
        if (!validateChange) return true
        var error = validateChange(paramId, value)
        if (!error) return true
        validationFailed(error)
        return false
    }
    function commitToggle(enabled) {
        if (locked || busy || !changeAllowed(enabled ? 1 : 0)) return
        var warning = settingsModel.get_warning_before_safe(paramId)
        if (warning) _messageBoxInstance.set_text_and_show(warning)
        settingsModel.try_set_param_int_async(paramId, enabled ? 1 : 0, true)
    }
    function commitChoice(selected) {
        if (locked || busy) return
        if (selected === null) { customPortEditor.text = String(value); customPortDialog.open(); return }
        if (!changeAllowed(selected)) return
        var warning = settingsModel.get_warning_before_safe(paramId)
        if (warning) _messageBoxInstance.set_text_and_show(warning)
        if (integer) settingsModel.try_set_param_int_async(paramId, Number(selected), true)
        else settingsModel.try_set_param_string_async(paramId, String(selected), true)
    }

    Column {
        id: wording
        anchors.left: parent.left
        anchors.verticalCenter: row.stacked ? undefined : parent.verticalCenter
        anchors.top: row.stacked ? parent.top : undefined
        anchors.topMargin: row.stacked ? 8 : 0
        width: row.stacked ? row.width : Math.max(0, row.width - editor.width - 12)
        spacing: 3
        Text { width: parent.width; text: row.label; color: settings_form.primaryText; font.family: Typography.family; font.pixelSize: Typography.body; font.bold: true; wrapMode: Text.Wrap }

    }
    Loader {
        id: editor
        anchors.right: parent.right
        anchors.verticalCenter: row.stacked ? undefined : parent.verticalCenter
        anchors.top: row.stacked ? wording.bottom : undefined
        anchors.topMargin: row.stacked ? 8 : 0
        width: row.stacked ? row.width : Math.min(215, row.width * 0.43)
        height: row.infoOnly && item ? Math.max(36, item.implicitHeight) : 36
        sourceComponent: row.infoOnly ? informationControl : row.toggle ? toggleControl : row.cells || row.portFallback ? choiceControl : row.password ? passwordControl : inlineControl
    }
    Component {
        id: informationControl
        Text {
            text: row.displayValue; wrapMode: Text.WrapAnywhere
            color: settings_form.secondaryText; font.family: Typography.family; font.pixelSize: Typography.body
            horizontalAlignment: Text.AlignRight; verticalAlignment: Text.AlignVCenter
        }
    }
    Component {
        id: choiceControl
        CompactLinkComboBox {
            model: row.choices.map(function(entry) { return entry.label })
            currentIndex: { for(var i=0;i<row.choices.length;i++) if(String(row.choices[i].value) === String(row.value)) return i; return -1 }
            enabled: !row.locked && !row.busy
            onActivated: if(currentIndex >= 0) row.commitChoice(row.choices[currentIndex].value)
        }
    }
    Component {
        id: inlineControl
        InlineMavlinkParamControl {
            settingsModel: row.settingsModel
            paramId: row.paramId
            valueType: row.integer ? 0 : 1
            paramValue: row.value
            displayValue: row.displayValue
            readOnly: row.locked
            busy: row.busy
            minimumOverride: row.paramId === "SBUS_HZ" ? 1 : undefined
            maximumOverride: row.paramId === "SBUS_HZ" ? 200 : undefined
        }
    }
    Component {
        id: toggleControl
        Switch {
            id: toggleEditor
            objectName: "airToggle_" + row.paramId
            checked: Number(row.value) !== 0
            enabled: !row.locked && !row.busy
            onToggled: row.commitToggle(checked)
            Accessible.name: row.label
            indicator: Rectangle {
                implicitWidth: 38; implicitHeight: 22
                x: toggleEditor.width - width; y: (toggleEditor.height - height) / 2
                radius: 11
                color: toggleEditor.checked ? settings_form.accentColor : settings_form.lineColor
                opacity: toggleEditor.enabled ? 1 : 0.5
                Rectangle {
                    width: 18; height: 18; radius: 9; y: 2
                    x: toggleEditor.checked ? parent.width - width - 2 : 2
                    color: "white"
                }
            }
        }
    }
    Component {
        id: passwordControl
        TextField { verticalAlignment: TextInput.AlignVCenter; leftPadding: 12; rightPadding: 12; topPadding: 6; bottomPadding: 6;
            text: String(row.value)
            echoMode: TextInput.Password
            readOnly: row.locked || row.busy
            color: settings_form.primaryText
            font.family: Typography.family; font.pixelSize: Typography.body
            selectByMouse: true
            onEditingFinished: if (!readOnly && text !== String(row.value)) row.settingsModel.try_set_param_string_async(row.paramId, text, true)
            background: Rectangle { radius: 7; color: settings_form.panelBackgroundRaised; border.color: parent.activeFocus ? settings_form.accentColor : settings_form.lineColor }
        }
    }
    Rectangle { anchors.bottom: parent.bottom; width: parent.width; height: 1; color: settings_form.lineColor }
    Keys.onEscapePressed: backRequested()
    AdvancedDialog {
        id: customPortDialog
        parent: Overlay.overlay
        x: parent ? (parent.width - width) / 2 : 0
        y: parent ? (parent.height - height) / 2 : 0
        width: Math.min(380, parent ? parent.width - 32 : 380)
        title: qsTr("Serial port")
        standardButtons: Dialog.Ok | Dialog.Cancel
        contentItem: TextField { verticalAlignment: TextInput.AlignVCenter; leftPadding: 12; rightPadding: 12; topPadding: 6; bottomPadding: 6; id: customPortEditor; placeholderText: qsTr("Device path, e.g. /dev/ttyUSB0"); selectByMouse: true }
        onAccepted: if(!row.locked && !row.busy && customPortEditor.text.trim()) row.commitChoice(customPortEditor.text.trim())
    }
}
