import QtQuick 2.12
import QtQuick.Controls 2.12
import QtQuick.Layouts 1.12

import QtQuick.Controls.Material 2.12

import Qt.labs.settings 1.0

import OpenHD 1.0

import "../../../ui" as Ui
import "../../elements"

ScrollView {
    id: appScreenSettingsView
    width: parent.width
    height: parent.height
    contentHeight: screenColumn.height

    clip: true
    property var screen_modes: _qopenhd.get_screen_modes()
    property string screen_mode_current: _qopenhd.get_screen_mode_current()
    function refresh_modes() {
        screen_modes = _qopenhd.get_screen_modes()
        screen_mode_current = _qopenhd.get_screen_mode_current()
    }
    onVisibleChanged: {
        if (visible) {
            refresh_modes()
        }
    }

    Item {
        anchors.fill: parent

        Column {
            id: screenColumn
            spacing: 0
            anchors.left: parent.left
            anchors.right: parent.right

            SettingBaseElement{
                m_short_description: "Screen Scale"
                Text {
                    text: Number(settings.global_scale).toLocaleString(Qt.locale(), 'f', 1) + "x";
                    font.pixelSize: 16
                    anchors.right: screenScaleSpinBox.left
                    anchors.rightMargin: 12
                    verticalAlignment: Text.AlignVCenter
                    anchors.verticalCenter: parent.verticalCenter
                    width: 32
                    height: elementHeight

                }

                Slider {
                    id: screenScaleSpinBox
                    height: elementHeight
                    width: 210
                    font.pixelSize: 14
                    anchors.right: parent.right
                    anchors.verticalCenter: parent.verticalCenter
                    from : 0.3
                    to : 2.5
                    // Important: Looks as without .1 steps, we can get rendering artfacts
                    stepSize: .1

                    anchors.rightMargin: Qt.inputMethod.visible ? 78 : 18
                    value: settings.global_scale

                    onValueChanged: {
                        if(settings.global_scale != value){
                            _restartqopenhdmessagebox.show();
                        }
                        settings.global_scale = value
                    }
                }
            }
            SettingBaseElement{
                m_short_description: "Auto hide cursor"

                Switch {
                    width: 32
                    height: elementHeight
                    anchors.rightMargin: Qt.inputMethod.visible ? 96 : 36

                    anchors.right: parent.right
                    anchors.verticalCenter: parent.verticalCenter
                    checked: settings.enable_cursor_auto_hide
                    onCheckedChanged: {
                        if(settings.enable_cursor_auto_hide!=checked){
                            settings.enable_cursor_auto_hide=checked;
                            _mouseHelper.set_hide_cursor_inactive_enable(settings.enable_cursor_auto_hide);
                        }
                    }
                }
            }
            SettingBaseElement{
                m_short_description: "Set cursor Skin"
                SpinBox {
                    width: 210
                    font.pixelSize: 14
                    height: elementHeight
                    anchors.rightMargin: Qt.inputMethod.visible ? 96 : 36
                    anchors.right: parent.right
                    anchors.verticalCenter: parent.verticalCenter

                    from: 0
                    to: 7
                    stepSize: 1
                    value: settings.custom_cursor_type
                    onValueChanged: {
                        settings.custom_cursor_type = value
                        _mouseHelper.set_active_cursor_type_and_scale(settings.custom_cursor_type,settings.custom_cursor_scale)
                    }
                }
            }
            SettingBaseElement{
                m_short_description: "Cursor Scale"

                SpinBox {
                    width: 210
                    font.pixelSize: 14
                    height: elementHeight
                    anchors.rightMargin: Qt.inputMethod.visible ? 96 : 36
                    anchors.right: parent.right
                    anchors.verticalCenter: parent.verticalCenter

                    from: 0
                    to: 7
                    stepSize: 1
                    value: settings.custom_cursor_scale
                    onValueChanged: {
                        settings.custom_cursor_scale = value
                        _mouseHelper.set_active_cursor_type_and_scale(settings.custom_cursor_type,settings.custom_cursor_scale)
                    }
                }
            }
            SettingsCategory{
                m_description: "Advanced settings"
                m_hide_elements: true

                SettingBaseElement{
                    visible: _qopenhd.is_platform_rock()
                    m_short_description: "Screen mode"

                    Row {
                        spacing: 8
                        anchors.right: parent.right
                        anchors.rightMargin: Qt.inputMethod.visible ? 78 : 18
                        anchors.verticalCenter: parent.verticalCenter
                        ComboBox {
                            id: screenModeCombo
                            height: elementHeight
                            width: 240
                            model: appScreenSettingsView.screen_modes
                            enabled: model && model.length > 0
                            Component.onCompleted: {
                                appScreenSettingsView.refresh_modes()
                                for (var i = 0; i < model.length; i++) {
                                    if (model[i] === appScreenSettingsView.screen_mode_current) {
                                        currentIndex = i;
                                        break;
                                    }
                                }
                            }
                            onActivated: {
                                const mode = model[currentIndex]
                                if (mode === appScreenSettingsView.screen_mode_current) {
                                    return;
                                }
                                if (_qopenhd.set_screen_mode(mode)) {
                                    appScreenSettingsView.screen_mode_current = mode
                                    _restartqopenhdmessagebox.show_with_text("Screen mode changed. Restart QOpenHD if the UI looks wrong.")
                                } else {
                                    _qopenhd.show_toast("Failed to set screen mode " + mode, true)
                                }
                            }
                        }
                        Button {
                            text: qsTr("Refresh")
                            height: elementHeight
                            onClicked: {
                                appScreenSettingsView.refresh_modes()
                                const err = _qopenhd.get_screen_modes_last_error()
                                if (!screenModeCombo.model || screenModeCombo.model.length === 0) {
                                    _qopenhd.show_toast("Screen modes empty: " + err, true)
                                } else if (err && err !== "ok") {
                                    _qopenhd.show_toast("Screen modes: " + err, false)
                                }
                            }
                        }
                    }
                }
                SettingBaseElement{
                    m_short_description: "Screen rotation"
                    // anything other than 0 and 180 can breaks things
                    ComboBox {
                        height: elementHeight
                        anchors.right: parent.right
                        anchors.rightMargin: Qt.inputMethod.visible ? 78 : 18
                        anchors.verticalCenter: parent.verticalCenter
                        anchors.horizontalCenter: parent.horizonatalCenter
                        width: 320
                        model: ListModel {
                            id: screen_rotations
                            ListElement { text: qsTr("0°") ; value: 0 }
                            ListElement { text: qsTr("90° (WARNING)") ; value: 90 }
                            ListElement { text: qsTr("180°") ; value: 180 }
                            ListElement { text: qsTr("270° (WARNING)") ; value: 270 }
                        }
                        textRole: "text"
                        Component.onCompleted: {
                            for (var i = 0; i < model.count; i++) {
                                var choice = model.get(i);
                                if (choice.value == settings.general_screen_rotation) {
                                    currentIndex = i;
                                }
                            }
                        }
                        onCurrentIndexChanged: {
                            settings.general_screen_rotation = screen_rotations.get(currentIndex).value
                        }
                    }
                }
                SettingBaseElement{
                    m_short_description: "Transparent Background"

                    Switch {
                        width: 32
                        height: elementHeight
                        anchors.rightMargin: Qt.inputMethod.visible ? 96 : 36

                        anchors.right: parent.right
                        anchors.verticalCenter: parent.verticalCenter
                        checked: settings.app_background_transparent
                        onCheckedChanged: settings.app_background_transparent = checked
                    }
                }
                SettingBaseElement{
                    m_short_description: "Full screen"

                    Switch {
                        width: 32
                        height: elementHeight
                        anchors.rightMargin: Qt.inputMethod.visible ? 96 : 36

                        anchors.right: parent.right
                        anchors.verticalCenter: parent.verticalCenter
                        checked: settings.dev_force_show_full_screen
                        onCheckedChanged: settings.dev_force_show_full_screen = checked
                    }
                }
                SettingBaseElement{
                    m_short_description: "Swap interval 0"
                    m_long_description: "Can decrease latency on x86 / laptop. Requires restart. Experimental."

                    Switch {
                        width: 32
                        height: elementHeight
                        anchors.rightMargin: Qt.inputMethod.visible ? 96 : 36

                        anchors.right: parent.right
                        anchors.verticalCenter: parent.verticalCenter
                        checked: settings.dev_set_swap_interval_zero
                        onCheckedChanged: settings.dev_set_swap_interval_zero = checked
                    }
                }
                SettingBaseElement{
                    visible: _qopenhd.is_platform_rock()
                    m_short_description: "UI FPS cap"
                    m_long_description: "Limits QML render rate to reduce CPU usage (restart required)."
                    ComboBox {
                        height: elementHeight
                        anchors.right: parent.right
                        anchors.rightMargin: Qt.inputMethod.visible ? 78 : 18
                        anchors.verticalCenter: parent.verticalCenter
                        anchors.horizontalCenter: parent.horizonatalCenter
                        width: 320
                        model: ListModel {
                            ListElement { text: qsTr("0 (uncapped)") ; value: 0 }
                            ListElement { text: qsTr("30 fps") ; value: 30 }
                            ListElement { text: qsTr("60 fps") ; value: 60 }
                            ListElement { text: qsTr("120 fps") ; value: 120 }
                        }
                        textRole: "text"
                        Component.onCompleted: {
                            for (var i = 0; i < model.count; i++) {
                                var choice = model.get(i);
                                if (choice.value == settings.ui_fps_cap) {
                                    currentIndex = i;
                                }
                            }
                        }
                        onActivated:{
                            const value_cap = model.get(currentIndex).value
                            if(settings.ui_fps_cap != value_cap){
                                settings.ui_fps_cap = value_cap
                                _restartqopenhdmessagebox.show_with_text("UI FPS cap changed. Restart QOpenHD to apply.")
                            }
                        }
                    }
                }

                // SettingBaseElement{
                //     m_short_description: "Settings window scale"

                //     SpinBox {
                //         width: 210
                //         font.pixelSize: 14
                //         height: elementHeight
                //         anchors.rightMargin: Qt.inputMethod.visible ? 96 : 36
                //         anchors.right: parent.right
                //         anchors.verticalCenter: parent.verticalCenter

                //         from: 50
                //         to: 100
                //         stepSize: 1
                //         value: settings.screen_settings_overlay_size_percent
                //         onValueChanged: {
                //             settings.screen_settings_overlay_size_percent = value
                //         }
                //     }
                // }
                SettingBaseElement{
                    m_short_description: "Transparent settings"

                    Switch {
                        width: 32
                        height: elementHeight
                        anchors.rightMargin: Qt.inputMethod.visible ? 96 : 36

                        anchors.right: parent.right
                        anchors.verticalCenter: parent.verticalCenter
                        checked: settings.screen_settings_openhd_parameters_transparent
                        onCheckedChanged: settings.screen_settings_openhd_parameters_transparent = checked
                    }
                }
                SettingBaseElement{
                    m_short_description: "Font DPI"
                    m_long_description: "Scale the text / line size of the artifical horizon / ladders, requires restart of QOpenHD."
                    ComboBox {
                        height: elementHeight
                        anchors.right: parent.right
                        anchors.rightMargin: Qt.inputMethod.visible ? 78 : 18
                        anchors.verticalCenter: parent.verticalCenter
                        anchors.horizontalCenter: parent.horizonatalCenter
                        width: 320
                        model: ListModel {
                            ListElement { text: qsTr("-1 Disable") ; value: -1 }
                            ListElement { text: qsTr("0 Auto (Recommended)") ; value: 0 }
                            ListElement { text: qsTr("50 (ultra small)") ; value: 50 }
                            ListElement { text: qsTr("72 (smaller)") ; value: 72 }
                            ListElement { text: qsTr("100") ; value: 100 }
                            ListElement { text: qsTr("120 (bigger)") ; value: 120 }
                            ListElement { text: qsTr("150 (ultra big)") ; value: 150 }
                        }
                        textRole: "text"
                        Component.onCompleted: {
                            for (var i = 0; i < model.count; i++) {
                                var choice = model.get(i);
                                if (choice.value == settings.screen_custom_font_dpi) {
                                    currentIndex = i;
                                }
                            }
                        }
                        onActivated:{
                            const value_fdpi = model.get(currentIndex).value
                            if(settings.screen_custom_font_dpi != value_fdpi){
                                console.log("font dpi changed from :"+settings.screen_custom_font_dpi+" to:"+value_fdpi);
                                _restartqopenhdmessagebox.show();
                                settings.screen_custom_font_dpi = value_fdpi
                            }

                        }
                    }
                }
            }
        }
    }
}
