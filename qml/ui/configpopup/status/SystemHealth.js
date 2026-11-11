.pragma library

// X20 reports a different temperature source and keeps its own defaults.
function thresholdPrefix(unit, ground) {
    return !ground && unit.ohd_platform_type === 30 ? "x20_status_" : (ground ? "ground_status_" : "air_status_")
}
function threshold(unit, ground, settings, kind, level) {
    var key = thresholdPrefix(unit, ground) + kind + "_" + level
    if (settings[key] !== undefined) return Number(settings[key])
    if (!ground && unit.ohd_platform_type === 30)
        return kind === "temp" ? (level === "warn" ? 78 : 74) : (level === "warn" ? 95 : 85)
    return kind === "temp" ? (level === "warn" ? 70 : 60) : (level === "warn" ? 70 : 50)
}
function muted(ground, settings, kind) {
    return settings[(ground ? "ground_status_" : "air_status_") + kind + "_muted"] === true
}
function evaluate(unit, ground, settings) {
    var live = !!unit.is_alive, temperature = Number(unit.curr_soc_temp_degree), cpu = Number(unit.curr_cpuload_perc)
    var hasTemperature = live && temperature > 0
    var hasCpu = live && cpu >= 0 && cpu <= 100 && (unit.onboard_uptime_ms >= 0 || hasTemperature)
    var tw = threshold(unit, ground, settings, "temp", "warn")
    var tc = threshold(unit, ground, settings, "temp", "caution")
    var cw = threshold(unit, ground, settings, "cpu", "warn")
    var cc = threshold(unit, ground, settings, "cpu", "caution")
    var severity = 0, reasons = [], alerts = [], mutedCount = 0
    function add(kind, level, detail, value) {
        var silenced = muted(ground, settings, kind)
        if (silenced) ++mutedCount
        else severity = Math.max(severity, level)
        reasons.push(detail + (silenced ? " " + qsTr("(Muted)") : ""))
        alerts.push({kind: kind, severity: level, muted: silenced, detail: detail, value: value})
    }
    if (hasTemperature && (temperature >= tc || temperature >= tw))
        add("temp", temperature >= tw ? 2 : 1,
            qsTr("Temperature: %1 \u00b0C").arg(temperature), temperature)
    if (hasCpu && (cpu >= cc || cpu >= cw))
        add("cpu", cpu >= cw ? 2 : 1,
            qsTr("CPU usage: %1%").arg(cpu), cpu)
    if (live && unit.rpi_undervolt_error)
        add("undervolt", 2, qsTr("Supply undervoltage"))
    var radios = live ? (unit.radio_temperature_warnings || []) : []
    if (radios.length) add("radio", 2, radios.map(function(card) {
        return qsTr("Radio %1: %2").arg(card.index + 1).arg(card.value)
    }).join(" / "))
    return {known: hasTemperature || hasCpu || (live && !!unit.rpi_undervolt_error) || radios.length > 0, severity: severity,
            reasons: reasons, alerts: alerts, mutedCount: mutedCount}
}
