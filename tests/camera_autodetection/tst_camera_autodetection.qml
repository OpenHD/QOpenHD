import QtQuick 2.12
import QtTest 1.2
import "../../qml/ui/elements" as Elements
import "video" as Video

Item {
    width: 800; height: 480
    QtObject { id: _qopenhd; property bool debugMenuPreview: false }
    QtObject { id: _ohdSystemAir; property bool is_alive: true }
    QtObject { id: _cameraStreamModelSecondary; property int camera_status: -1 }
    QtObject { id: _decodingStatistics; property bool secondary_video_active: false }
    QtObject { id: backendLifecycle; property int starts: 0; property int stops: 0 }
    QtObject {
        id: _airCameraSettingsModel2
        property bool has_params_fetched: false
        property bool supported: false
        property int streaming: 0
        function param_int_exists(id) { return supported && id === "STREAMING_E" }
        function get_cached_int(id) { return streaming }
    }
    Elements.AppSettings { id: settings; fileName: "TEST_SETTINGS_FILE" }
    Elements.CameraAutoDetection { id: detection; settingsObject: settings }
    Video.SecondaryVideoGStreamer { id: panel }

    TestCase {
        name: "CameraAutodetection"
        when: windowShown
        function init() {
            detection.running = false
            _qopenhd.debugMenuPreview = false
            _ohdSystemAir.is_alive = true
            _cameraStreamModelSecondary.camera_status = -1
            _airCameraSettingsModel2.supported = false
            _airCameraSettingsModel2.has_params_fetched = false
            _airCameraSettingsModel2.streaming = 0
            settings.dev_qopenhd_n_cameras = 1
            settings.qopenhd_switch_primary_secondary = false
            wait(1)
            backendLifecycle.starts = 0
            backendLifecycle.stops = 0
            detection.restart()
        }
        function backend() { return findChild(panel, "secondaryBackend") }
        function expectVisible(value) {
            tryCompare(settings, "secondary_camera_available", value, 1800)
            tryCompare(panel, "visible", value, 1800)
            tryVerify(function() { return (backend() !== null) === value }, 1800)
        }
        function test_no_camera() {
            wait(600)
            compare(settings.dev_qopenhd_n_cameras, 1)
            expectVisible(false)
        }
        function test_status_detection_data() {
            return [{tag: "unknown", status: 0}, {tag: "streaming", status: 1},
                    {tag: "restarting", status: 2}]
        }
        function test_status_detection(data) {
            _cameraStreamModelSecondary.camera_status = data.status
            expectVisible(true)
            compare(settings.dev_qopenhd_n_cameras, 2)
            compare(backendLifecycle.starts, 1)
        }
        function test_enabled_before_status_or_complete_params() {
            _airCameraSettingsModel2.supported = true
            _airCameraSettingsModel2.streaming = 1
            expectVisible(true)
            compare(_cameraStreamModelSecondary.camera_status, -1)
            compare(_airCameraSettingsModel2.has_params_fetched, false)
            var original = backend()
            _cameraStreamModelSecondary.camera_status = 0
            wait(600)
            _cameraStreamModelSecondary.camera_status = 2
            wait(600)
            _cameraStreamModelSecondary.camera_status = 1
            wait(600)
            compare(backend(), original)
            compare(backendLifecycle.starts, 1)
            compare(backendLifecycle.stops, 0)
        }
        function test_disable_parameter_overrides_status() {
            _cameraStreamModelSecondary.camera_status = 1
            expectVisible(true)
            settings.qopenhd_switch_primary_secondary = true
            _airCameraSettingsModel2.supported = true
            _airCameraSettingsModel2.streaming = 0
            expectVisible(false)
            compare(settings.dev_qopenhd_n_cameras, 1)
            compare(settings.qopenhd_switch_primary_secondary, false)
            _airCameraSettingsModel2.streaming = 1
            expectVisible(true)
        }
        function test_disabled_status() {
            _cameraStreamModelSecondary.camera_status = 2
            expectVisible(true)
            settings.qopenhd_switch_primary_secondary = true
            _cameraStreamModelSecondary.camera_status = 3
            expectVisible(false)
            compare(settings.qopenhd_switch_primary_secondary, false)
        }
        function test_disconnect_and_preview() {
            _cameraStreamModelSecondary.camera_status = 1
            expectVisible(true)
            _ohdSystemAir.is_alive = false
            expectVisible(false)
            _airCameraSettingsModel2.supported = true
            _airCameraSettingsModel2.streaming = 0
            wait(600)
            compare(settings.dev_qopenhd_n_cameras, 2)
            _qopenhd.debugMenuPreview = true
            _ohdSystemAir.is_alive = true
            wait(600)
            compare(settings.dev_qopenhd_n_cameras, 2)
            _qopenhd.debugMenuPreview = false
            expectVisible(false)
        }
    }
}
