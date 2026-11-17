import QtQuick 2.12
import QtTest 1.2
import "../../qml/ui/widgets" as Widgets

Item {
    width: 500
    height: 300
    property bool globalDragLock: false

    QtObject {
        id: settings
        property bool show_widgets: true
        property bool show_focus_widget: false
        property bool qopenhd_switch_primary_secondary: false
        property bool secondary_camera_available: false
        function value(key, fallbackValue) { return fallbackValue }
        function setValue(key, value) {}
        function sync() {}
    }
    QtObject { id: hudOverlayGrid; property bool widgetGalleryPreviewActive: false }
    QtObject { id: _ohdSystemAir; property bool is_alive: true }
    QtObject {
        id: _ohdSystemAirSettingsModel
        property bool has_params_fetched: true
        property int update_count: 0
        property int cameraControl: 0
        function param_int_exists(param) { return param === "CAM_CTRL_ACTIVE" }
        function get_cached_int(param) { return cameraControl }
        function ensure_parameters_available() {}
    }
    QtObject {
        id: _ohdAction
        property var requests: []
        function camera_autofocus(index) { requests = requests.concat([index]); return true }
    }
    QtObject { id: _qopenhd; function show_toast(message) {} }

    Widgets.FocusWidget { id: focusButton }

    TestCase {
        name: "FocusWidget"
        when: windowShown

        function test_focus_requires_available_camera_control() {
            verify(!focusButton.visible)
            settings.show_focus_widget = true
            verify(!focusButton.visible)

            _ohdSystemAirSettingsModel.cameraControl = 1
            _ohdSystemAirSettingsModel.update_count++
            verify(focusButton.visible)
            mouseClick(focusButton)
            compare(_ohdAction.requests, [0])

            settings.qopenhd_switch_primary_secondary = true
            settings.secondary_camera_available = true
            mouseClick(focusButton)
            compare(_ohdAction.requests, [0, 1])

            hudOverlayGrid.widgetGalleryPreviewActive = true
            mouseClick(focusButton)
            compare(_ohdAction.requests, [0, 1])
            _ohdSystemAir.is_alive = false
            verify(!focusButton.visible)
        }
    }
}
