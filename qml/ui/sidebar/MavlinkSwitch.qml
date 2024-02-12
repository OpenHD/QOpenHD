import QtQuick 2.12
import QtQuick.Controls 2.12
import QtQuick.Layouts 1.12
import QtQuick.Controls.Material 2.12

import Qt.labs.settings 1.0

import OpenHD 1.0

import "../../ui" as Ui
import "../elements"



//
// OBSOLETE
//
Switch{
    id: mavlink_switch

    property string m_param_name: "FILL ME"
    property var m_param_model: _ohdSystemGroundSettings

    // Values that should be overridden by implementation end
    property int m_update_count: _ohdSystemGroundSettings.update_count

    onM_update_countChanged: {
        console.log("Update done");
        update_from_cache();
    }

    function update_from_cache(){
        if(!_ohdSystemGroundSettings.system_is_alive()){
            //console.log("not alive");
            enabled=false;
            return;
        }
        if(!_ohdSystemGroundSettings.has_params_fetched){
            console.log("Param set not yet fetched");
            enabled = false;
            return;
        }
        // Check if the param exists
        if(!_ohdSystemGroundSettings.param_int_exists(m_param_name)){
            console.log("Param "+m_param_name+" does not exist");
            enabled=false;
            return;
        }
        // Get the current value from the model
        var value = _ohdSystemGroundSettings.get_cached_int(m_param_name);
        checked = value;
        enabled = true;
    }

    onVisibleChanged: {
        console.log("visible changed");
        if(visible){
            console.log("visible");
            update_from_cache()
        }
    }


    onClicked: {
        console.log("Clicked"+checked);
        // Temporarily disable
        //enabled =false;

        var new_value=0;
        if(checked){
            new_value=1;
        }
        // try updating the param
        _ohdSystemGroundSettings.try_set_param_int_async(m_param_name,new_value);
    }


}
