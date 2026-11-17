import QtQuick 2.12

BaseWidget {
    id: root
    width: 90
    height: 36
    widgetIdentifier: "focus_widget"
    bw_verbose_name: qsTr("Focus")
    defaultAlignment: 0
    defaultXOffset: 92
    defaultYOffset: 187
    hasWidgetDetail: false

    readonly property int cameraIndex: settings.qopenhd_switch_primary_secondary
                                       && settings.secondary_camera_available ? 1 : 0
    readonly property bool controlAvailable: {
        const airSettings = _ohdSystemAirSettingsModel
        airSettings.update_count
        if (!_ohdSystemAir.is_alive || !airSettings.has_params_fetched) return false
        return ["CAM_CTRL_ACTIVE", "SIYI_ACTIVE", "TOPOTEK_ACTIVE"].some(function(id) {
            return airSettings.param_int_exists(id) && airSettings.get_cached_int(id) === 1
        })
    }

    visible: settings.show_focus_widget && settings.show_widgets && controlAvailable
    activeFocusOnTab: visible
    Accessible.role: Accessible.Button
    Accessible.name: qsTr("Focus")
    Accessible.onPressAction: requestFocus()
    Keys.onReturnPressed: requestFocus()
    Keys.onSpacePressed: requestFocus()
    onWidgetTapped: requestFocus()

    function requestFocus() {
        if (!visible || widgetGalleryPreview || dragging || !controlAvailable) return
        const queued = _ohdAction.camera_autofocus(cameraIndex)
        _qopenhd.show_toast(queued ? qsTr("Autofocus requested") : qsTr("Could not send autofocus request"))
    }

    Timer {
        interval: 1500
        repeat: true
        running: settings.show_widgets && settings.show_focus_widget && _ohdSystemAir.is_alive
                 && !_ohdSystemAirSettingsModel.has_params_fetched
        onTriggered: _ohdSystemAirSettingsModel.ensure_parameters_available()
    }

    Rectangle {
        anchors.fill: parent
        radius: 8
        color: "#dd142638"
        border.color: root.activeFocus ? "#6fc5ff" : "#537a99"
        border.width: root.activeFocus ? 2 : 1
        Row {
            anchors.centerIn: parent
            spacing: 7
            Text {
                text: "\uf05b"
                font.family: "Font Awesome 5 Free"
                font.pixelSize: 13
                color: "#8dceff"
            }
            Text {
                text: qsTr("Focus")
                font.pixelSize: 13
                font.bold: true
                color: "#f2f6fb"
            }
        }
    }
}
