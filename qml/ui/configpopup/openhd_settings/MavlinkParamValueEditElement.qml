import QtQuick 2.12
import QtQuick.Controls 2.12
import QtQuick.Layouts 1.12

import QtQuick.Controls.Material 2.12

import Qt.labs.settings 1.0

import OpenHD 1.0

import "../../../ui" as Ui
import "../../elements"


ComboBox{
    property string m_display_text: "FILL ME"
    property string m_param_id: "TODO"

    property var m_settings_model: _ohdSystemGroundSettings

    property bool m_is_int: false;

    displayText: m_display_text


    onActivated: {
        console.log("onActivated:"+currentIndex);
        // Check if we have an enum mapping for this param
        if(m_is_int){

        }
    }
    onM_display_textChanged: {
        if(m_display_text=="FILL ME")return
        // Check if we have an enum mapping for this param
        var has_mapped_enum = false;
        var enum_keys;
        var enum_values;
        if(m_is_int){
            has_mapped_enum = m_settings_model.int_param_has_enum_keys_values(m_param_id);
            enum_keys = m_settings_model.int_param_get_enum_keys(m_param_id);
            enum_values = m_settings_model.int_param_get_enum_values(m_param_id);

        }else{
            has_mapped_enum = m_settings_model.string_param_has_enum(m_param_id);
            enum_keys = m_settings_model.string_param_get_enum_keys(m_param_id);
            enum_values = m_settings_model.string_param_get_enum_values(m_param_id);
        }
        if(has_mapped_enum){
            console.log("Param "+m_param_id+" has enum mapping")
            // Check if the current value is inside the enum - otherwise we open the advanced editor
            var current_value = m_settings_model.int_par
            for(var i=0;i<enum_keys;i++){

            }


            var values = m_settings_model
        }

    }

}
