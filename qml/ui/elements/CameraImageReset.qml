import QtQuick 2.12
import QtQuick.Controls 2.12
import QtQuick.Controls.Material 2.12

Button {
    id: root
    property bool iconOnly: false
    property var settingsModel
    property int revision: settingsModel ? settingsModel.update_count : 0
    property var pending: []
    property string awaiting: ""
    property bool resetting: false
    property string resultText: ""
    // Generic defaults from camera_settings.hpp and arducam_modes.hpp.
    // GX uses an explicit OpenHD image preset, not the camera's destructive
    // factory reset (which also resets transport settings and rewrites flash).
    // Only reset image controls actually advertised by this camera.
    readonly property var defaults: [
        ["ISP_EXPOSURE_US", 1000], ["ISP_GAIN", 100],
        ["ISP_WB_K", 6500], ["ISP_GAMMA", 0],
        ["BRIGHTNESS", 100], ["CONTRAST", 100],
        ["SATURATION", 100], ["SHARPNESS", 100],
        ["ISP_AE_PROFILE", 0], ["ISP_WB_AUTO", 1], ["ISP_AE_MODE", 0],
        ["GX_DAYNIGHT", 0], ["GX_IRCUT_DIR", 0], ["GX_IRCUT_TIMER", 0],
        ["GX_SHUTTER_US", 10000], ["GX_GAIN", 0],
        ["GX_AE_TARGET", 128], ["GX_AE_MAX_US", 33333],
        ["GX_AE_MAX_GAIN", 453], ["GX_AE_STRATEGY", 0],
        ["GX_WB_RED", 1024], ["GX_WB_BLUE", 1024],
        ["GX_SHARPNESS", 128], ["GX_DENOISE_2D", 128], ["GX_DENOISE_3D", 128],
        ["GX_SATURATION", 50], ["GX_CONTRAST", 50], ["GX_HUE", 50],
        ["GX_GAMMA", 1], ["GX_DRC", 0], ["GX_WB_MODE", 2], ["GX_EXPOSURE", 2]
    ]
    readonly property bool available: {
        var unused = revision
        if (!settingsModel || !settingsModel.has_params_fetched) return false
        for (var i = 0; i < defaults.length; ++i)
            if (settingsModel.param_int_exists(defaults[i][0])) return true
        return false
    }
    text: iconOnly ? "\uf0e2" : resetting ? qsTr("Resetting camera…") : qsTr("Reset camera / ISP")
    font.family: iconOnly ? "Font Awesome 5 Free" : Qt.application.font.family
    font.pixelSize: iconOnly ? 22 : 14
    flat: iconOnly
    Material.foreground: iconOnly ? "#ffffff" : undefined
    Accessible.name: qsTr("Reset camera / ISP")
    ToolTip.visible: hovered
    ToolTip.text: resetting ? qsTr("Resetting camera…") : qsTr("Reset camera / ISP")
    enabled: available && !resetting && !settingsModel.ui_is_busy && settingsModel.system_is_alive()
    onClicked: confirmation.open()

    function startReset() {
        if (!enabled) return
        pending = []
        for (var i = 0; i < defaults.length; ++i) {
            var entry = defaults[i]
            if (settingsModel.param_int_exists(entry[0]) &&
                    settingsModel.get_cached_int(entry[0]) !== entry[1])
                pending.push(entry)
        }
        resultText = ""
        resetting = true
        advance.start()
    }
    function next() {
        if (!pending.length) {
            resetting = false
            resultText = qsTr("Camera image defaults restored")
            _qopenhd.show_toast(resultText)
            return
        }
        if (!settingsModel.system_is_alive() || settingsModel.ui_is_busy) {
            fail()
            return
        }
        var entry = pending.shift()
        awaiting = entry[0]
        timeout.start()
        settingsModel.try_set_param_int_async(entry[0], entry[1], false)
    }
    function fail() {
        timeout.stop()
        pending = []
        awaiting = ""
        resetting = false
        resultText = qsTr("Camera reset incomplete. Check the connection and retry.")
        _qopenhd.show_toast(resultText)
    }
    Timer { id: timeout; interval: 6000; onTriggered: root.fail() }
    Timer { id: advance; interval: 1; onTriggered: root.next() }
    Connections {
        target: root.settingsModel
        function onBackupParameterFinished(id, success) {
            if (!root.resetting || id !== root.awaiting) return
            timeout.stop()
            root.awaiting = ""
            if (!success) root.fail()
            else advance.start() // Leave the parameter callback before the next write.
        }
    }
    Dialog {
        id: confirmation
        parent: Overlay.overlay
        anchors.centerIn: parent
        width: Math.min(360, parent.width - 24)
        height: Math.min(220, parent.height - 24)
        modal: true
        title: qsTr("Reset camera / ISP?")
        standardButtons: Dialog.Reset | Dialog.Cancel
        contentItem: Label {
            text: qsTr("Restore image adjustments, exposure and white balance to OpenHD defaults? Video format and link settings stay as configured.")
            font.pixelSize: 14
            wrapMode: Text.WordWrap
        }
        onReset: { close(); root.startReset() }
    }
}
