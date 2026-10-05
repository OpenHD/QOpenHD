#ifndef TEMPERATURESTATE_H
#define TEMPERATURESTATE_H

#include <QString>

#include <algorithm>

namespace TemperatureTelemetry {

// Stable UI-facing values. Keep the numeric order: callers use the highest
// value as the worst state when a receiver has multiple radio cards.
enum State {
    Unknown = -1,
    Cold = 0,
    Ok = 1,
    Hot = 2,
    SuperHot = 3
};

inline int fromLegacyCelsius(const int celsius)
{
    // Legacy OpenHD messages use 0 when the driver has no temperature.
    if (celsius <= 5) return Unknown;
    if (celsius < 40) return Cold;
    if (celsius < 70) return Ok;
    if (celsius < 85) return Hot;
    return SuperHot;
}

inline int fromDevourerDelta(const bool valid, const int delta)
{
    if (!valid) return Unknown;
    if (delta < 8) return Cold;
    if (delta < 15) return Ok;
    if (delta < 25) return Hot;
    return SuperHot;
}

inline QString toString(const int state)
{
    switch (state) {
    case Cold: return QStringLiteral("COLD");
    case Ok: return QStringLiteral("OK");
    case Hot: return QStringLiteral("HOT");
    case SuperHot: return QStringLiteral("SUPER HOT");
    default: return QStringLiteral("N/A");
    }
}

inline int worst(const int lhs, const int rhs)
{
    return std::max(lhs, rhs);
}

inline QString displayCelsius(const int celsius)
{
    return fromLegacyCelsius(celsius) == Unknown ? QStringLiteral("N/A")
        : QString::number(celsius) + QStringLiteral("\u00b0C");
}

inline QString displayDevourer(const bool valid, const int delta)
{
    if (!valid) return QStringLiteral("N/A");
    // Relative RF readings cannot give a reliable absolute temperature.
    // Negative deltas simply mean the radio is below its reference reading.
    switch (fromDevourerDelta(valid, delta)) {
    case Cold: return QStringLiteral("Normal");
    case Ok: return QStringLiteral("Warm");
    case Hot: return QStringLiteral("Hot");
    case SuperHot: return QStringLiteral("Overheating");
    default: return QStringLiteral("N/A");
    }
}

} // namespace TemperatureTelemetry

#endif // TEMPERATURESTATE_H
