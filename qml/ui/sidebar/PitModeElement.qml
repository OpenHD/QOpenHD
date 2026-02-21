import QtQuick 2.12
import QtQuick.Controls 2.12
import QtQuick.Layouts 1.12
import QtQuick.Controls.Material 2.12

import OpenHD 1.0

import "../../ui" as Ui
import "../elements"

//
// Pit mode selector (Air only): Off/On
// On  = disarmed uses LOWEST level when TX power levels are active
// Off = disarmed uses the same level as armed
//
BaseJoyEditElement2 {
    id: pitModeElement
    m_title: "Pit Mode"

    signal goto_previous()
    signal goto_next()

    property bool m_last_clickable: false
    property string m_display_text: "N/A"

    m_displayed_value: m_display_text

    ListModel {
        id: stateModel
        ListElement { value: 0; verbose: "OFF" }
        ListElement { value: 1; verbose: "ON" }
    }

    function can_use_model(model, require_param) {
        if (model === undefined) return false;
        if (!model.system_is_alive()) return false;
        if (require_param) {
            if (!model.has_params_fetched) return false;
            if (!model.param_int_exists("WB_PIT_MODE")) return false;
        }
        return true;
    }

    function ensure_params_fetched(model) {
        if (model === undefined) return;
        if (!model.system_is_alive()) return;
        if (model.has_params_fetched) return;
        if (model.ui_is_busy) return;
        model.try_refetch_all_parameters_async(false);
    }

    function pit_mode_status_for_model(model) {
        if (!can_use_model(model, true)) {
            if (model !== undefined && model.system_is_alive()) {
                return { state: "Pending", enabled: null };
            }
            return { state: "N/A", enabled: null };
        }
        var value = model.get_cached_int("WB_PIT_MODE");
        if (value === 1) {
            return { state: "ON", enabled: true };
        }
        if (value === 0) {
            return { state: "OFF", enabled: false };
        }
        return { state: "N/A", enabled: null };
    }

    function update_display() {
        var air_model = _ohdSystemAirSettingsModel;
        var air_status = pit_mode_status_for_model(air_model).state;
        m_display_text = air_status;
    }

    function open_state_menu(clickable) {
        m_last_clickable = clickable;
        var model = _ohdSystemAirSettingsModel;
        if (!can_use_model(model, false)) {
            _qopenhd.show_toast("N/A");
            return;
        }
        var is_on = false;
        if (can_use_model(model, true)) {
            var value = model.get_cached_int("WB_PIT_MODE");
            is_on = (value === 1);
        }
        choiceSelector.open_choices(stateModel, is_on ? 1 : 0, pitModeElement);
        choiceSelector.set_clickable(clickable);
        choiceSelector.set_force_callback(false);
    }

    function set_pit_mode(enabled) {
        var model = _ohdSystemAirSettingsModel;
        if (!can_use_model(model, false)) {
            _qopenhd.show_toast("Not connected");
            return;
        }
        model.try_set_param_int_async("WB_PIT_MODE", enabled ? 1 : 0);
        update_display();
    }

    property int m_update_count: _ohdSystemAirSettingsModel.update_count
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
    onVisibleChanged: {
        if (visible) {
            ensure_params_fetched(_ohdSystemAirSettingsModel);
            update_display();
        }
    }

    onBase_joy_edit_element_clicked: {
        if (choiceSelector.visible) {
            choiceSelector.close_choices();
        } else {
            open_state_menu(true);
        }
    }

    Keys.onPressed: (event)=> {
                        if (event.key == Qt.Key_Left) {
                            sidebar.regain_control_on_sidebar_stack();
                            event.accepted = true;
                        } else if (event.key == Qt.Key_Right) {
                            open_state_menu(false);
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
                            open_state_menu(false);
                            event.accepted = true;
                        }
                    }

    function user_selected_value(value_new) {
        var value_int = parseInt(value_new);
        set_pit_mode(value_int === 1);
    }
}
