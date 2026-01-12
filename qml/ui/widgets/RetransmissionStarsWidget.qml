import QtQuick 2.12
import QtQuick.Controls 2.12
import QtQuick.Layouts 1.12

import Qt.labs.settings 1.0

import OpenHD 1.0

import "../../ui" as Ui
import "../elements"

BaseWidget {
    id: retransmissionStatsWidget
    width: 132
    height: 48

    visible: settings.show_retransmission_stats && settings.show_widgets && m_retransmission_enabled

    widgetIdentifier: "retransmission_stats_widget"
    bw_verbose_name: "RETRANSMISSION STATS"

    defaultAlignment: 0
    defaultXOffset: 420
    defaultYOffset: 0
    defaultHCenter: false
    defaultVCenter: false

    hasWidgetDetail: true

    property var m_param_ids: ["WB_ENABLE_RETRA", "WB_RTX_VIDEO"]
    property bool m_retransmission_enabled: false
    property int m_update_count: _ohdSystemAirSettingsModel.update_count
    property int m_missing_per_second: _cameraStreamModelPrimary.curr_missing_packets_per_second
    property int m_requests_per_second: _cameraStreamModelPrimary.curr_retransmission_requests_per_second
    property int m_fixed_per_second: _cameraStreamModelPrimary.curr_retransmission_packets_per_second

    function update_state(){
        if(!_ohdSystemAirSettingsModel.has_params_fetched){
            m_retransmission_enabled = false;
            return;
        }
        for(var i=0;i<m_param_ids.length;i++){
            var param_id=m_param_ids[i];
            if(!_ohdSystemAirSettingsModel.param_int_exists(param_id)){
                continue;
            }
            const value=_ohdSystemAirSettingsModel.get_cached_int(param_id);
            if(value > 0){
                m_retransmission_enabled = true;
                return;
            }
        }
        m_retransmission_enabled = false;
    }

    onM_update_countChanged: {
        update_state();
    }

    Component.onCompleted: {
        update_state();
    }

    function stat_value_or_na(value){
        if(value < 0){
            return "N/A";
        }
        return ""+value;
    }

    widgetDetailComponent: ScrollView {
        contentHeight: idBaseWidgetDefaultUiControlElements.height
        ScrollBar.horizontal.policy: ScrollBar.AlwaysOff
        clip: true

        BaseWidgetDefaultUiControlElements{
            id: idBaseWidgetDefaultUiControlElements
        }
    }

    Item {
        anchors.fill: parent

        Column {
            anchors.centerIn: parent
            spacing: 2

            Text {
                text: "RTX"
                color: settings.color_text
                font.bold: true
                font.pixelSize: 12
                style: Text.Outline
                styleColor: settings.color_glow
            }

            Text {
                text: "LOSS/s: "+stat_value_or_na(m_missing_per_second)
                color: settings.color_text
                font.pixelSize: 11
                style: Text.Outline
                styleColor: settings.color_glow
            }

            Text {
                text: "REQ/s: "+stat_value_or_na(m_requests_per_second)
                color: settings.color_text
                font.pixelSize: 11
                style: Text.Outline
                styleColor: settings.color_glow
            }

            Text {
                text: "FIX/s: "+stat_value_or_na(m_fixed_per_second)
                color: settings.color_text
                font.pixelSize: 11
                style: Text.Outline
                styleColor: settings.color_glow
            }
        }
    }
}
