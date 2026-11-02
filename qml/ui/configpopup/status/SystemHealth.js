.pragma library

function evaluate(unit, ground, settings) {
    var live = !!unit.is_alive, temperature = Number(unit.curr_soc_temp_degree), cpu = Number(unit.curr_cpuload_perc)
    var hasTemperature = live && temperature > 0
    var hasCpu = live && cpu >= 0 && cpu <= 100 && (unit.onboard_uptime_ms >= 0 || hasTemperature)
    var x20 = !ground && unit.ohd_platform_type === 30
    var tw = x20 ? 78 : ground ? settings.ground_status_temp_warn : settings.air_status_temp_warn
    var tc = x20 ? 74 : ground ? settings.ground_status_temp_caution : settings.air_status_temp_caution
    var cw = x20 ? 95 : ground ? settings.ground_status_cpu_warn : settings.air_status_cpu_warn
    var cc = x20 ? 85 : ground ? settings.ground_status_cpu_caution : settings.air_status_cpu_caution
    var severity = 0, reasons = []
    if (hasTemperature && (temperature >= tc || temperature >= tw)) {
        severity = Math.max(severity, temperature >= tw ? 2 : 1)
        reasons.push(qsTr("Temperature: %1 °C (configured threshold: %2 °C). Improve cooling or airflow.").arg(temperature).arg(temperature >= tw ? tw : tc))
    }
    if (hasCpu && (cpu >= cc || cpu >= cw)) {
        severity = Math.max(severity, cpu >= cw ? 2 : 1)
        reasons.push(qsTr("CPU usage: %1% (configured threshold: %2%). Reduce processing load if this persists.").arg(cpu).arg(cpu >= cw ? cw : cc))
    }
    if (live && unit.rpi_undervolt_error) {
        severity = 2
        reasons.push(qsTr("Supply undervoltage reported. Check the power supply and cable."))
    }
    return {known: hasTemperature || hasCpu || (live && !!unit.rpi_undervolt_error), severity: severity, reasons: reasons}
}
