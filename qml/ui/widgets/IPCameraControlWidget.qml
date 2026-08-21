import QtQuick 2.12
import QtQuick.Window 2.12
import QtQuick.Controls 2.12
import QtQuick.Layouts 1.12

import OpenHD 1.0

BaseWidget {
    id: root
    width: 116
    height: 34

    property int airSettingsUpdateCount: _ohdSystemAirSettingsModel.update_count
    property bool pluginReported: {
        var unused = airSettingsUpdateCount
        if (!_ohdSystemAirSettingsModel.has_params_fetched) return false
        return (_ohdSystemAirSettingsModel.param_int_exists("CAM_CTRL_ACTIVE")
                && _ohdSystemAirSettingsModel.get_cached_int("CAM_CTRL_ACTIVE") === 1)
                || (_ohdSystemAirSettingsModel.param_int_exists("TOPOTEK_ACTIVE")
                    && _ohdSystemAirSettingsModel.get_cached_int("TOPOTEK_ACTIVE") === 1)
                || (_ohdSystemAirSettingsModel.param_int_exists("SIYI_ACTIVE")
                    && _ohdSystemAirSettingsModel.get_cached_int("SIYI_ACTIVE") === 1)
    }
    property bool cameraControlActive: _ohdSystemAir.is_alive
                                       || _ohdSystemAirSettingsModel.has_params_fetched
    property bool topotekActive: _ohdSystemAirSettingsModel.has_params_fetched
                                  && _ohdSystemAirSettingsModel.param_int_exists("TOPOTEK_ACTIVE")
                                  && _ohdSystemAirSettingsModel.get_cached_int("TOPOTEK_ACTIVE") === 1
    property bool siyiActive: _ohdSystemAirSettingsModel.has_params_fetched
                              && _ohdSystemAirSettingsModel.param_int_exists("SIYI_ACTIVE")
                              && _ohdSystemAirSettingsModel.get_cached_int("SIYI_ACTIVE") === 1
    property bool rollAvailable: topotekActive || (pluginReported && !siyiActive)
    property int cameraIndex: 0
    property bool recording: false

    // A directly attached air unit has no radio uplink-quality report, so the
    // normal global autofetch deliberately waits forever. Fetch its parameters
    // here as soon as the air heartbeat is visible over Ethernet.
    Timer {
        interval: 1500
        repeat: true
        running: _ohdSystemAir.is_alive
                 && !_ohdSystemAirSettingsModel.has_params_fetched
                 && !_ohdSystemAirSettingsModel.ui_is_busy
        onTriggered: _ohdSystemAirSettingsModel.try_refetch_all_parameters_async(false)
    }

    visible: settings.show_ip_camera_control_widget && settings.show_widgets
    widgetIdentifier: "ip_camera_control_widget"
    bw_verbose_name: qsTr("IP Camera Control")
    defaultAlignment: 0
    defaultXOffset: 92
    defaultYOffset: 145
    hasWidgetDetail: false
    hasWidgetAction: true
    // Each side is capped below half the active screen, so the open panel
    // never occupies more than one quarter of the display area.
    widgetActionWidth: Math.min(292, Math.floor(Screen.width * 0.48))
    widgetActionHeight: Math.min(334, Math.floor(Screen.height * 0.48))

    Rectangle {
        anchors.fill: parent
        radius: 7
        color: cameraControlActive ? "#cc172027" : "#aa343434"
        border.color: cameraControlActive ? "#4bb3fd" : "#777777"
        border.width: 1
        RowLayout {
            anchors.fill: parent
            anchors.leftMargin: 7
            anchors.rightMargin: 7
            Label { text: "\uf03d"; font.family: "Font Awesome 5 Free"; color: "white" }
            Label {
                Layout.fillWidth: true
                text: cameraControlActive ? qsTr("IP CAMERA") : qsTr("CAMERA OFFLINE")
                color: "white"
                font.bold: true
                font.pixelSize: 11
                horizontalAlignment: Text.AlignHCenter
            }
        }
    }

    widgetActionComponent: ScrollView {
        id: controlPanel
        anchors.fill: parent
        clip: true
        ScrollBar.horizontal.policy: ScrollBar.AlwaysOff
        ScrollBar.vertical.policy: ScrollBar.AsNeeded
        contentWidth: availableWidth
        contentHeight: controls.implicitHeight + 28
        font.pixelSize: 9

        function stopGimbal() { _ohdAction.camera_gimbal_rate(0, 0, root.cameraIndex) }
        function stopRoll() { _ohdAction.camera_gimbal_roll_rate(0, root.cameraIndex) }

        ColumnLayout {
            id: controls
            x: 8
            y: 8
            width: controlPanel.availableWidth - 16
            spacing: 4

            RowLayout {
                Layout.fillWidth: true
                Label {
                    Layout.fillWidth: true
                    text: topotekActive ? qsTr("TOPOTEK CAMERA")
                                         : siyiActive ? qsTr("SIYI CAMERA")
                                                      : qsTr("IP CAMERA")
                    color: "white"
                    font.pixelSize: 14
                    font.bold: true
                }
                Label {
                    text: cameraControlActive ? qsTr("CONNECTED") : qsTr("NO PLUGIN")
                    color: cameraControlActive ? "#4bd477" : "#ef7777"
                    font.pixelSize: 9
                }
            }

            ComboBox {
                Layout.fillWidth: true
                Layout.preferredHeight: 26
                font.pixelSize: 9
                model: [qsTr("Camera 1"), qsTr("Camera 2")]
                currentIndex: root.cameraIndex
                onActivated: root.cameraIndex = currentIndex
            }

            RowLayout {
                Layout.fillWidth: true
                Layout.preferredHeight: 90

                GridLayout {
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    columns: 3
                    rowSpacing: 5
                    columnSpacing: 5
                    Item { Layout.fillWidth: true; Layout.fillHeight: true }
                    Button {
                        Layout.fillWidth: true; Layout.fillHeight: true; text: "\u25B2"; font.pixelSize: 9
                        onPressed: _ohdAction.camera_gimbal_rate(45, 0, root.cameraIndex)
                        onReleased: controlPanel.stopGimbal()
                        onCanceled: controlPanel.stopGimbal()
                    }
                    Item { Layout.fillWidth: true; Layout.fillHeight: true }
                    Button {
                        Layout.fillWidth: true; Layout.fillHeight: true; text: "\u25C0"; font.pixelSize: 9
                        onPressed: _ohdAction.camera_gimbal_rate(0, -45, root.cameraIndex)
                        onReleased: controlPanel.stopGimbal()
                        onCanceled: controlPanel.stopGimbal()
                    }
                    Button {
                        Layout.fillWidth: true; Layout.fillHeight: true; text: qsTr("RESET"); font.pixelSize: 8
                        onClicked: _ohdAction.camera_gimbal_center(root.cameraIndex)
                    }
                    Button {
                        Layout.fillWidth: true; Layout.fillHeight: true; text: "\u25B6"; font.pixelSize: 9
                        onPressed: _ohdAction.camera_gimbal_rate(0, 45, root.cameraIndex)
                        onReleased: controlPanel.stopGimbal()
                        onCanceled: controlPanel.stopGimbal()
                    }
                    Item { Layout.fillWidth: true; Layout.fillHeight: true }
                    Button {
                        Layout.fillWidth: true; Layout.fillHeight: true; text: "\u25BC"; font.pixelSize: 9
                        onPressed: _ohdAction.camera_gimbal_rate(-45, 0, root.cameraIndex)
                        onReleased: controlPanel.stopGimbal()
                        onCanceled: controlPanel.stopGimbal()
                    }
                    Item { Layout.fillWidth: true; Layout.fillHeight: true }
                }

                ColumnLayout {
                    Layout.preferredWidth: 56
                    Layout.fillHeight: true
                    Label { text: qsTr("ZOOM"); color: "white"; font.pixelSize: 9; Layout.alignment: Qt.AlignHCenter }
                    Button {
                        Layout.fillWidth: true; Layout.fillHeight: true; text: "+"; font.pixelSize: 10
                        onPressed: _ohdAction.camera_zoom(1, root.cameraIndex)
                        onReleased: _ohdAction.camera_zoom(0, root.cameraIndex)
                        onCanceled: _ohdAction.camera_zoom(0, root.cameraIndex)
                    }
                    Button {
                        Layout.fillWidth: true; Layout.fillHeight: true; text: "-"; font.pixelSize: 10
                        onPressed: _ohdAction.camera_zoom(-1, root.cameraIndex)
                        onReleased: _ohdAction.camera_zoom(0, root.cameraIndex)
                        onCanceled: _ohdAction.camera_zoom(0, root.cameraIndex)
                    }
                }
            }

            RowLayout {
                Layout.fillWidth: true
                Layout.preferredHeight: 26
                Button {
                    Layout.preferredWidth: 62
                    Layout.fillHeight: true
                    text: qsTr("CALIBRATE")
                    font.pixelSize: 7
                    enabled: topotekActive
                    onClicked: _ohdAction.camera_gimbal_calibrate(root.cameraIndex)
                }
                Label {
                    text: qsTr("ROLL")
                    color: rollAvailable ? "white" : "#777777"
                    font.pixelSize: 9
                    Layout.preferredWidth: 34
                }
                Button {
                    Layout.fillWidth: true; Layout.fillHeight: true; text: "\u21B6"; enabled: rollAvailable; font.pixelSize: 9
                    onPressed: _ohdAction.camera_gimbal_roll_rate(-0.45, root.cameraIndex)
                    onReleased: controlPanel.stopRoll()
                    onCanceled: controlPanel.stopRoll()
                }
                Button {
                    Layout.fillWidth: true; Layout.fillHeight: true; text: "\u21B7"; enabled: rollAvailable; font.pixelSize: 9
                    onPressed: _ohdAction.camera_gimbal_roll_rate(0.45, root.cameraIndex)
                    onReleased: controlPanel.stopRoll()
                    onCanceled: controlPanel.stopRoll()
                }
                ComboBox {
                    Layout.preferredWidth: 112
                    Layout.fillHeight: true
                    font.pixelSize: 9
                    model: topotekActive
                           ? [qsTr("Lock mode"), qsTr("Follow mode")]
                           : [qsTr("Lock mode"), qsTr("Follow mode"), qsTr("FPV mode")]
                    onActivated: _ohdAction.camera_gimbal_mode(currentIndex, root.cameraIndex)
                }
            }

            RowLayout {
                Layout.fillWidth: true
                Layout.preferredHeight: 26
                ComboBox {
                    id: viewMode
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    font.pixelSize: 9
                    model: [qsTr("EO"), qsTr("Thermal"), qsTr("EO + Thermal"), qsTr("Thermal + EO")]
                    onActivated: _ohdAction.camera_set_image_type(currentIndex, root.cameraIndex)
                }
                Button {
                    Layout.fillHeight: true
                    font.pixelSize: 8
                    text: qsTr("SWITCH CAM")
                    onClicked: {
                        viewMode.currentIndex = (viewMode.currentIndex + 1) % viewMode.count
                        _ohdAction.camera_set_image_type(viewMode.currentIndex, root.cameraIndex)
                    }
                }
            }

            RowLayout {
                Layout.fillWidth: true
                Layout.preferredHeight: 26
                ComboBox {
                    id: palette
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    font.pixelSize: 9
                    model: [qsTr("White hot"), qsTr("Black hot"), qsTr("Rainbow"),
                            qsTr("Iron red"), qsTr("Lava"), qsTr("Arctic"),
                            qsTr("Glowbow"), qsTr("Graded fire"), qsTr("Hottest"),
                            qsTr("Medical"), qsTr("Palette 11")]
                    onActivated: _ohdAction.camera_set_thermal_palette(
                                     currentIndex === 0 ? 0 : currentIndex + 1,
                                     root.cameraIndex)
                }
            }

            RowLayout {
                Layout.fillWidth: true
                Layout.preferredHeight: 26
                Button {
                    Layout.fillWidth: true; Layout.fillHeight: true; text: qsTr("FOCUS -"); font.pixelSize: 8
                    onPressed: _ohdAction.camera_focus(-1, root.cameraIndex)
                    onReleased: _ohdAction.camera_focus(0, root.cameraIndex)
                    onCanceled: _ohdAction.camera_focus(0, root.cameraIndex)
                }
                Button {
                    Layout.fillWidth: true; Layout.fillHeight: true; text: qsTr("AUTO FOCUS"); font.pixelSize: 8
                    onClicked: _ohdAction.camera_autofocus(root.cameraIndex)
                }
                Button {
                    Layout.fillWidth: true; Layout.fillHeight: true; text: qsTr("FOCUS +"); font.pixelSize: 8
                    onPressed: _ohdAction.camera_focus(1, root.cameraIndex)
                    onReleased: _ohdAction.camera_focus(0, root.cameraIndex)
                    onCanceled: _ohdAction.camera_focus(0, root.cameraIndex)
                }
            }

            RowLayout {
                Layout.fillWidth: true
                Layout.preferredHeight: 30
                Button {
                    Layout.fillWidth: true; Layout.fillHeight: true; font.pixelSize: 9
                    text: qsTr("SNAP")
                    onClicked: _ohdAction.camera_take_photo(root.cameraIndex)
                }
                Button {
                    Layout.fillWidth: true; Layout.fillHeight: true; font.pixelSize: 9
                    text: root.recording ? qsTr("STOP REC") : qsTr("REC")
                    highlighted: root.recording
                    onClicked: {
                        root.recording = !root.recording
                        _ohdAction.camera_set_recording(root.recording, root.cameraIndex)
                    }
                }
            }
        }
    }
}
