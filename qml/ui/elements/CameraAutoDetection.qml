import QtQuick 2.12

// Session logic must live outside Qt.labs.settings: QObject timers are not settings values.
Timer {
    property var settingsObject
    interval: 500; running: true; repeat: true
    onTriggered: {
        if (_qopenhd.debugMenuPreview || !_ohdSystemAir.is_alive) return
        var model = _airCameraSettingsModel2
        var enabled
        if (model.has_params_fetched && model.param_int_exists("STREAMING_E"))
            enabled = model.get_cached_int("STREAMING_E") !== 0
        else if (_cameraStreamModelSecondary.camera_status === 1)
            enabled = true
        else return
        var count = enabled ? 2 : 1
        if (settingsObject.dev_qopenhd_n_cameras !== count) {
            settingsObject.dev_qopenhd_n_cameras = count
            if (!enabled) settingsObject.qopenhd_switch_primary_secondary = false
        }
    }
}
