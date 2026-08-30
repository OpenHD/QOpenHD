import QtQuick 2.12
import QtQuick.Controls 2.12
import QtQuick.Layouts 1.12
import QtQuick.Controls.Material 2.12

import Qt.labs.settings 1.0

import OpenHD 1.0

import "../../ui" as Ui
import "../elements"

//
// Power selector: Air/Ground -> one of five user-facing targets (TX_PWR_LVL)
//
BaseJoyEditElement2 {
    id: powerChoiceElement
    m_title: "Power"

    signal goto_previous()
    signal goto_next()

    property bool m_target_air: true
    property int m_stage: 0 // 0 = target, 1 = level
    property bool m_last_clickable: false
    property string m_display_text: "N/A"

    m_displayed_value: m_display_text

    ListModel {
        id: targetModel
        ListElement { value: 0; verbose: "Air" }
        ListElement { value: 1; verbose: "Ground" }
    }

    ListModel {
        id: levelModel
        ListElement { value: 20; verbose: "20%" }
        ListElement { value: 40; verbose: "40%" }
        ListElement { value: 60; verbose: "60%" }
        ListElement { value: 80; verbose: "80%" }
        ListElement { value: 100; verbose: "100%" }
    }

    function level_to_label(level) {
        if (level === 20 || level === 40 || level === 60 ||
                level === 80 || level === 100) return level + "%";
        return qsTr("N/A");
    }

    function is_valid_level(level) {
        return level === 20 || level === 40 || level === 60 ||
                level === 80 || level === 100;
    }

    function get_model_for_target() {
        return m_target_air ? _ohdSystemAirSettingsModel : _ohdSystemGroundSettings;
    }

    function can_use_model(model, require_param) {
        if (model === undefined) return false;
        if (!model.system_is_alive()) return false;
        if (require_param) {
            if (!model.has_params_fetched) return false;
            if (!model.param_int_exists("TX_PWR_LVL")) return false;
        }
        return true;
    }

    function read_current_level() {
        var model = get_model_for_target();
        if (!can_use_model(model, true)) return null;
        return model.get_cached_int("TX_PWR_LVL");
    }

    function is_target_alive(is_air_target) {
        var model = is_air_target ? _ohdSystemAirSettingsModel : _ohdSystemGroundSettings;
        return model !== undefined && model.system_is_alive();
    }

    function ensure_params_fetched(model) {
        if (model === undefined) return;
        if (!model.system_is_alive()) return;
        if (model.has_params_fetched) return;
        if (model.ui_is_busy) return;
        model.try_refetch_all_parameters_async(false);
    }

    function refresh_target_model() {
        targetModel.clear();
        if (is_target_alive(true)) {
            targetModel.append({ value: 0, verbose: "Air" });
        }
        if (is_target_alive(false)) {
            targetModel.append({ value: 1, verbose: "Ground" });
        }
    }

    function update_display() {
        var air_label = qsTr("N/A");
        var gnd_label = qsTr("N/A");
        var air_model = _ohdSystemAirSettingsModel;
        var gnd_model = _ohdSystemGroundSettings;
        if (can_use_model(air_model, true)) {
            var air_level = air_model.get_cached_int("TX_PWR_LVL");
            air_label = level_to_label(air_level);
        } else if (air_model !== undefined && air_model.system_is_alive()) {
            air_label = air_model.has_params_fetched ? qsTr("N/A") : qsTr("Pending");
        }
        if (can_use_model(gnd_model, true)) {
            var gnd_level = gnd_model.get_cached_int("TX_PWR_LVL");
            gnd_label = level_to_label(gnd_level);
        } else if (gnd_model !== undefined && gnd_model.system_is_alive()) {
            gnd_label = gnd_model.has_params_fetched ? qsTr("N/A") : qsTr("Pending");
        }
        m_display_text = qsTr("Air %1\nGround %2").arg(air_label).arg(gnd_label);
    }

    property int m_update_count: _ohdSystemGroundSettings.update_count + _ohdSystemAirSettingsModel.update_count
    onM_update_countChanged: {
        if (visible) {
            update_display();
        }
    }
    property bool m_air_has_params_fetched: _ohdSystemAirSettingsModel.has_params_fetched
    onM_air_has_params_fetchedChanged: {
        if (visible) {
            update_display();
        }
    }
    property bool m_gnd_has_params_fetched: _ohdSystemGroundSettings.has_params_fetched
    onM_gnd_has_params_fetchedChanged: {
        if (visible) {
            update_display();
        }
    }
    onVisibleChanged: {
        if (visible) {
            ensure_params_fetched(_ohdSystemAirSettingsModel);
            ensure_params_fetched(_ohdSystemGroundSettings);
            update_display();
        }
    }

    function open_target_menu(clickable) {
        m_stage = 0;
        m_last_clickable = clickable;
        refresh_target_model();
        if (targetModel.count === 0) {
            _qopenhd.show_toast(qsTr("N/A"));
            return;
        }
        if (targetModel.count === 1) {
            m_target_air = (targetModel.get(0).value === 0);
            update_display();
            Qt.callLater(function() {
                open_level_menu(clickable);
            });
            return;
        }
        choiceSelector.open_choices(targetModel, m_target_air ? 0 : 1, powerChoiceElement);
        choiceSelector.set_clickable(clickable);
        choiceSelector.set_force_callback(true);
    }

    function open_level_menu(clickable) {
        m_stage = 1;
        m_last_clickable = clickable;
        var model = get_model_for_target();
        if (!can_use_model(model, false)) {
            _qopenhd.show_toast(qsTr("N/A"));
            return;
        }
        var level = read_current_level();
        if (level === null || !is_valid_level(level)) {
            level = 20;
        }
        choiceSelector.open_choices(levelModel, level, powerChoiceElement);
        choiceSelector.set_clickable(clickable);
        choiceSelector.set_force_callback(false);
    }

    function apply_level(level) {
        var model = get_model_for_target();
        if (!can_use_model(model, false)) {
            _qopenhd.show_toast(qsTr("Not connected"));
            return;
        }
        if (!is_valid_level(level)) {
            _qopenhd.show_toast(qsTr("Invalid"));
            return;
        }
        model.try_set_param_int_async("TX_PWR_LVL", level);
        update_display();
    }

    onBase_joy_edit_element_clicked: {
        if (choiceSelector.visible) {
            choiceSelector.close_choices();
        } else {
            open_target_menu(true);
        }
    }

    Keys.onPressed: (event)=> {
                        if (event.key == Qt.Key_Left) {
                            sidebar.regain_control_on_sidebar_stack();
                            event.accepted = true;
                        } else if (event.key == Qt.Key_Right) {
                            open_target_menu(false);
                            event.accepted = true;
                        } else if (event.key == Qt.Key_Up) {
                            choiceSelector.discard_and_close();
                            goto_previous();
                            event.accepted = true;
                        } else if (event.key == Qt.Key_Down) {
                            choiceSelector.discard_and_close();
                            goto_next();
                            event.accepted = true;
                        } else if (event.key == Qt.Key_Enter || event.key == Qt.Key_Return) {
                            open_target_menu(false);
                            event.accepted = true;
                        }
                    }

    function user_selected_value(value_new) {
        var value_int = parseInt(value_new);
        if (m_stage === 0) {
            m_target_air = (value_int === 0);
            update_display();
            Qt.callLater(function() {
                open_level_menu(m_last_clickable);
            });
        } else if (m_stage === 1) {
            apply_level(value_int);
        }
    }
}
