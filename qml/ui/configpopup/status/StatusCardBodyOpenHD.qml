import QtQuick 2.12

Column {
    id: body
    width: parent.width
    spacing: 0

    property bool m_is_ground: false

    property var m_model: m_is_ground ? _ohdSystemGround : _ohdSystemAir

    property string m_version: m_model.openhd_version
    property bool m_is_alive: m_model.is_alive
    property int m_ground_settings_update_count: _ohdSystemGroundSettings.update_count
    property int m_air_settings_update_count: _ohdSystemAirSettingsModel.update_count

    readonly property int temperature: m_model.curr_soc_temp_degree
    readonly property int cpuLoad: m_model.curr_cpuload_perc
    // Legacy core telemetry defaults to zero until a sample arrives.
    readonly property bool hasTemperature: m_is_alive && temperature > 0
    readonly property bool hasCpuLoad: m_is_alive && cpuLoad >= 0 && cpuLoad <= 100
                                       && (m_model.onboard_uptime_ms >= 0 || hasTemperature)
    readonly property bool x20: !m_is_ground && m_model.ohd_platform_type === 30
    readonly property int temperatureWarn: x20 ? 78 : (m_is_ground ? settings.ground_status_temp_warn : settings.air_status_temp_warn)
    readonly property int temperatureCaution: x20 ? 74 : (m_is_ground ? settings.ground_status_temp_caution : settings.air_status_temp_caution)
    readonly property int cpuWarn: x20 ? 95 : (m_is_ground ? settings.ground_status_cpu_warn : settings.air_status_cpu_warn)
    readonly property int cpuCaution: x20 ? 85 : (m_is_ground ? settings.ground_status_cpu_caution : settings.air_status_cpu_caution)
    readonly property bool healthWarning: (hasTemperature && temperature >= temperatureWarn)
                                         || (hasCpuLoad && cpuLoad >= cpuWarn)
                                         || (m_is_alive && m_model.rpi_undervolt_error)
    readonly property bool healthCaution: (hasTemperature && temperature >= temperatureCaution)
                                         || (hasCpuLoad && cpuLoad >= cpuCaution)

    function get_gnd_active_cards(){
        var ret=0;
        if(_wifi_card_gnd0.alive) ret++;
        if(_wifi_card_gnd1.alive) ret++;
        if(_wifi_card_gnd2.alive) ret++;
        if(_wifi_card_gnd3.alive) ret++;
        return ret;
    }
    function ground_artosyn_detected(){
        return _ohdSystemGround.artosyn_link_detected
                || _ohdSystemGround.primary_link_type === 4
                || _ohdSystemGround.artosyn_debug_stats_available
                || ground_primary_link_is_artosyn()
                || _wifi_card_gnd0.card_type_as_string === "ARTOSYN";
    }
    function air_artosyn_detected(){
        return _ohdSystemAir.artosyn_link_detected
                || _ohdSystemAir.primary_link_type === 4
                || _ohdSystemAir.artosyn_debug_stats_available
                || air_primary_link_is_artosyn()
                || ground_artosyn_detected()
                || _wifi_card_air.card_type_as_string === "ARTOSYN";
    }
    function settings_string_contains_artosyn(model, param_id, update_count){
        var unused = update_count;
        if(!model.system_is_alive()) return false;
        if(!model.has_params_fetched) return false;
        if(!model.param_string_exists(param_id)) return false;
        var value = model.get_cached_string(param_id);
        return value.indexOf("ARTOSYN") >= 0 || value.indexOf("artosyn") >= 0;
    }
    function settings_primary_link_is_artosyn(model, update_count){
        return settings_string_contains_artosyn(model, "PRIMARY_LINK", update_count)
                || settings_string_contains_artosyn(model, "WIFI_IFACES", update_count);
    }
    function ground_primary_link_is_artosyn(){
        return settings_primary_link_is_artosyn(_ohdSystemGroundSettings, m_ground_settings_update_count);
    }
    function air_primary_link_is_artosyn(){
        return settings_primary_link_is_artosyn(_ohdSystemAirSettingsModel, m_air_settings_update_count);
    }

    readonly property bool healthKnown: hasTemperature || hasCpuLoad || (m_is_alive && m_model.rpi_undervolt_error)
    readonly property string healthText: !healthKnown ? qsTr("Not reported") : (healthWarning ? qsTr("Warning") : (healthCaution ? qsTr("Caution") : qsTr("Healthy")))
    readonly property color healthColor: !healthKnown ? "#94a9b9" : (healthWarning ? settings_form.errorColor : (healthCaution ? settings.color_caution : "#3bda69"))
    function linkText() {
        if (!m_is_alive) return qsTr("Not reported")
        var names = [], usage = m_model.link_usage
        var labels = {1: "WiFiBroadcast", 2: "Ethernet", 3: "UART", 4: "Microhard", 5: "ARTOSYN", 6: "FleetControl", 7: "mLRS"}
        for (var i = 0; usage && i < usage.length; ++i)
            if (labels[usage[i].id] && names.indexOf(labels[usage[i].id]) < 0) names.push(labels[usage[i].id])
        if (names.length) return names.join(" + ")
        if (m_is_ground ? ground_artosyn_detected() : air_artosyn_detected()) return "ARTOSYN"
        if (m_model.primary_link_type === 1) return "WiFiBroadcast"
        if (m_model.primary_link_type === 2) return "Ethernet"
        if (m_model.primary_link_type === 3) return "Microhard"
        if (m_is_ground ? get_gnd_active_cards() > 0 : _wifi_card_air.alive) return "WiFiBroadcast"
        return qsTr("Not reported")
    }
    StatusCardRow { m_left_text: qsTr("Platform"); m_icon: "\uf0e8"; m_right_text: m_model.ohd_platform_type_as_string }
    StatusCardRow { m_left_text: qsTr("Version"); m_icon: "\uf013"; m_right_text: m_version }
    StatusCardRow { m_left_text: qsTr("Link"); m_icon: "\uf0c1"; m_value_icon: m_right_text.indexOf("WiFiBroadcast") >= 0 ? "\uf1eb" : ""; m_right_text: body.linkText() }
    StatusCardRow { m_left_text: qsTr("System health"); m_icon: "\uf2db"; m_right_text: body.healthText; m_status_dot: body.healthKnown; m_right_text_color: body.healthColor }
    StatusCardRow {
        m_left_text: qsTr("Battery"); m_icon: "\uf2c2"
        m_right_text: m_is_alive && m_model.ina219_voltage_millivolt > 0
                      ? qsTr("%1 V (%2 %)").arg((m_model.ina219_voltage_millivolt / 1000).toFixed(1)).arg(m_model.battery_percent)
                      : qsTr("Not reported")
    }
    StatusCardRow { m_left_text: qsTr("Temperature"); m_icon: "\uf2c9"; m_right_text: body.hasTemperature ? qsTr("%1 \u00b0C").arg(body.temperature) : qsTr("Not reported") }
}
