#ifndef AUDIORULES_H
#define AUDIORULES_H

#include <QVariantMap>
#include <QString>
#include <cmath>

struct AudioRuleState {
    bool latched = false;
    qint64 lastSpoken = -1000000000;
};

inline bool audio_rule_due(const QVariantMap& rule, AudioRuleState& state,
                           double value, qint64 now)
{
    if (!rule.value("enabled").toBool() || !std::isfinite(value)) return false;
    const int condition = rule.value("condition", 0).toInt();
    const double threshold = rule.value("threshold", 50).toDouble();
    const bool matches = condition == 2 || (condition == 0 ? value <= threshold : value >= threshold);
    if (!matches) { state.latched = false; return false; }
    if (condition != 2 && state.latched) return false;
    const auto cooldown = qBound(5, rule.value("cooldown", 30).toInt(), 3600) * 1000LL;
    if (now - state.lastSpoken < cooldown) return false;
    state.lastSpoken = now;
    state.latched = true;
    return true;
}

inline QString audio_rule_phrase(const QVariantMap& rule, double value,
                                  const QString& unit, const QString& message = {}, const QString& language = "en")
{
    auto phrase = rule.value("phrase").toString().left(256);
    const QStringList english = {"Battery at {value} percent", "Wind speed {value} knots", "Altitude {value} meters", "Ground speed {value} kilometers per hour"};
    const QStringList german = {"Batterie bei {value} Prozent", "Windgeschwindigkeit {value} Knoten", "Höhe {value} Meter", "Geschwindigkeit {value} Kilometer pro Stunde"};
    const QStringList spanish = {"Batería al {value} por ciento", "Velocidad del viento {value} nudos", "Altitud {value} metros", "Velocidad {value} kilómetros por hora"};
    const int preset = english.indexOf(phrase);
    if (preset >= 0 && language == "de") phrase = german[preset];
    else if (preset >= 0 && language == "es") phrase = spanish[preset];
    QString spokenUnit = unit;
    if (language == "de") {
        if (unit == "percent") spokenUnit = "Prozent";
        else if (unit == "knots") spokenUnit = "Knoten";
        else if (unit == "meters") spokenUnit = "Meter";
        else if (unit == "kilometers per hour") spokenUnit = "Kilometer pro Stunde";
    } else if (language == "es") {
        if (unit == "percent") spokenUnit = "por ciento";
        else if (unit == "knots") spokenUnit = "nudos";
        else if (unit == "meters") spokenUnit = "metros";
        else if (unit == "kilometers per hour") spokenUnit = "kilómetros por hora";
    }
    phrase.replace("{value}", QString::number(qRound(value)));
    phrase.replace("{unit}", spokenUnit);
    phrase.replace("{message}", message.left(200));
    return phrase.left(512);
}

inline bool audio_message_rule_due(const QVariantMap& rule, AudioRuleState& state,
                                    int severity, const QString& text, qint64 now)
{
    if (severity < 0 || severity > 6 || !rule.value("enabled").toBool()) return false;
    const int source = severity <= 3 ? 1 : severity == 4 ? 0 : 2;
    if (rule.value("source").toInt() != source ||
        !text.contains(rule.value("filter").toString(), Qt::CaseInsensitive)) return false;
    const auto cooldown = qBound(5, rule.value("cooldown", 30).toInt(), 3600) * 1000LL;
    if (now - state.lastSpoken < cooldown) return false;
    state.lastSpoken = now;
    return true;
}

#endif
