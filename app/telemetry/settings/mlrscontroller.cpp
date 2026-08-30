#include "mlrscontroller.h"

#include <cstring>

#include "../MavlinkTelemetry.h"
#include "../tutil/qopenhdmavlinkhelper.hpp"

namespace {
constexpr char BIND_CHARS[] = "abcdefghijklmnopqrstuvwxyz0123456789_#-.";
constexpr quint32 BIND_RADIX = 40;
}

MLRSController &MLRSController::instance()
{
    static MLRSController instance;
    return instance;
}

MLRSController::MLRSController(QObject *parent) : QObject(parent)
{
    m_alive_timer.setInterval(1000);
    connect(&m_alive_timer, &QTimer::timeout, this, [this]() {
        if (m_alive && m_last_seen.isValid() && m_last_seen.elapsed() > 5000) {
            set_alive(false);
            m_requested_parameters = false;
            set_status_text(QStringLiteral("mLRS connection lost"));
        }
    });
    m_alive_timer.start();
}

bool MLRSController::process_message(const mavlink_message_t &msg)
{
    if (msg.sysid != SYSTEM_ID || msg.compid != COMPONENT_ID) {
        return false;
    }

    m_last_seen.restart();
    set_alive(true);

    if (!m_requested_parameters && msg.msgid == MAVLINK_MSG_ID_HEARTBEAT) {
        m_requested_parameters = true;
        refresh();
    }

    if (msg.msgid != MAVLINK_MSG_ID_PARAM_VALUE) {
        return true;
    }

    mavlink_param_value_t value{};
    mavlink_msg_param_value_decode(&msg, &value);
    const QString id = QOpenHDMavlinkHelper::safe_string(value.param_id,
                                                         sizeof(value.param_id));
    m_parameters.insert(id, Parameter{decode_value(value.param_value,
                                                    value.param_type),
                                      value.param_type});

    const bool now_loaded = m_parameters.contains(QStringLiteral("TX_POWER")) &&
                            m_parameters.contains(QStringLiteral("RX_POWER")) &&
                            m_parameters.contains(QStringLiteral("MODE")) &&
                            m_parameters.contains(QStringLiteral("RF_BAND")) &&
                            m_parameters.contains(QStringLiteral("BIND_PHRASE_U32"));
    if (now_loaded != m_parameters_loaded) {
        m_parameters_loaded = now_loaded;
        emit parametersLoadedChanged();
    }
    if (m_parameters_loaded) {
        set_status_text(QStringLiteral("mLRS connected — changes are temporary until Save"));
    } else {
        set_status_text(QStringLiteral("Reading mLRS settings…"));
    }
    emit parametersChanged();
    return true;
}

void MLRSController::refresh()
{
    mavlink_message_t msg{};
    mavlink_msg_param_request_list_pack(QOpenHDMavlinkHelper::get_own_sys_id(),
                                        QOpenHDMavlinkHelper::get_own_comp_id(),
                                        &msg, SYSTEM_ID, COMPONENT_ID);
    MavlinkTelemetry::instance().sendMessage(msg);
    set_status_text(QStringLiteral("Requesting mLRS settings…"));
}

bool MLRSController::applySettings(int tx_power, int rx_power, int new_mode,
                                   int rf_band, int rf_ortho,
                                   const QString &bind_phrase)
{
    if (!m_alive || !m_parameters_loaded) {
        set_status_text(QStringLiteral("Cannot apply: mLRS is not connected"));
        return false;
    }

    quint32 encoded_phrase = 0;
    if (!encode_bind_phrase(bind_phrase, encoded_phrase)) {
        set_status_text(QStringLiteral("Bind phrase must be exactly 6 characters: a-z, 0-9, _, #, - or ."));
        return false;
    }

    bool ok = true;
    ok &= set_parameter("TX_POWER", tx_power, MAV_PARAM_TYPE_UINT8);
    ok &= set_parameter("RX_POWER", rx_power, MAV_PARAM_TYPE_UINT8);
    ok &= set_parameter("MODE", new_mode, MAV_PARAM_TYPE_UINT8);
    ok &= set_parameter("RF_BAND", rf_band, MAV_PARAM_TYPE_UINT8);
    ok &= set_parameter("RF_ORTHO", rf_ortho, MAV_PARAM_TYPE_UINT8);
    ok &= set_parameter("BIND_PHRASE_U32", encoded_phrase, MAV_PARAM_TYPE_UINT32);
    set_status_text(ok
        ? QStringLiteral("Settings sent — press Save to make them persistent")
        : QStringLiteral("One or more mLRS settings were unavailable"));
    return ok;
}

bool MLRSController::save()
{
    if (!m_alive) {
        set_status_text(QStringLiteral("Cannot save: mLRS is not connected"));
        return false;
    }
    const bool ok = set_parameter("PSTORE", 1, MAV_PARAM_TYPE_UINT8);
    set_status_text(ok ? QStringLiteral("Save requested; mLRS will update Tx and Rx")
                       : QStringLiteral("mLRS does not expose persistent save"));
    return ok;
}

int MLRSController::parameter_value(const char *name) const
{
    const auto it = m_parameters.constFind(QString::fromLatin1(name));
    return it == m_parameters.cend() ? -1 : static_cast<int>(it->value);
}

QString MLRSController::bindPhrase() const
{
    const auto it = m_parameters.constFind(QStringLiteral("BIND_PHRASE_U32"));
    return it == m_parameters.cend()
        ? QString()
        : decode_bind_phrase(static_cast<quint32>(it->value));
}

void MLRSController::set_alive(bool alive)
{
    if (m_alive == alive) return;
    m_alive = alive;
    emit aliveChanged();
}

void MLRSController::set_status_text(const QString &text)
{
    if (m_status_text == text) return;
    m_status_text = text;
    emit statusTextChanged();
}

bool MLRSController::set_parameter(const char *name, qint64 value,
                                   uint8_t fallback_type)
{
    const QString id = QString::fromLatin1(name);
    const auto it = m_parameters.constFind(id);
    if (it == m_parameters.cend() && std::strcmp(name, "PSTORE") != 0) {
        return false;
    }
    const uint8_t type = it == m_parameters.cend() ? fallback_type : it->type;
    char id_bytes[16]{};
    const QByteArray id_latin1 = id.toLatin1();
    std::memcpy(id_bytes, id_latin1.constData(),
                static_cast<size_t>(qMin(id_latin1.size(), 15)));
    mavlink_message_t msg{};
    mavlink_msg_param_set_pack(QOpenHDMavlinkHelper::get_own_sys_id(),
                               QOpenHDMavlinkHelper::get_own_comp_id(),
                               &msg, SYSTEM_ID, COMPONENT_ID,
                               id_bytes, encode_value(value, type), type);
    return MavlinkTelemetry::instance().sendMessage(msg);
}

qint64 MLRSController::decode_value(float encoded, uint8_t type)
{
    union { float f; uint32_t u32; int32_t i32; uint16_t u16; int16_t i16; uint8_t u8; int8_t i8; } v{};
    v.f = encoded;
    switch (type) {
    case MAV_PARAM_TYPE_UINT8: return v.u8;
    case MAV_PARAM_TYPE_INT8: return v.i8;
    case MAV_PARAM_TYPE_UINT16: return v.u16;
    case MAV_PARAM_TYPE_INT16: return v.i16;
    case MAV_PARAM_TYPE_UINT32: return v.u32;
    case MAV_PARAM_TYPE_INT32: return v.i32;
    case MAV_PARAM_TYPE_REAL32: return static_cast<qint64>(encoded);
    default: return static_cast<qint64>(encoded);
    }
}

float MLRSController::encode_value(qint64 value, uint8_t type)
{
    union { float f; uint32_t u32; int32_t i32; uint16_t u16; int16_t i16; uint8_t u8; int8_t i8; } v{};
    switch (type) {
    case MAV_PARAM_TYPE_UINT8: v.u8 = static_cast<uint8_t>(value); break;
    case MAV_PARAM_TYPE_INT8: v.i8 = static_cast<int8_t>(value); break;
    case MAV_PARAM_TYPE_UINT16: v.u16 = static_cast<uint16_t>(value); break;
    case MAV_PARAM_TYPE_INT16: v.i16 = static_cast<int16_t>(value); break;
    case MAV_PARAM_TYPE_UINT32: v.u32 = static_cast<uint32_t>(value); break;
    case MAV_PARAM_TYPE_INT32: v.i32 = static_cast<int32_t>(value); break;
    case MAV_PARAM_TYPE_REAL32: return static_cast<float>(value);
    default: return static_cast<float>(value);
    }
    return v.f;
}

QString MLRSController::decode_bind_phrase(quint32 value)
{
    QString phrase(6, QLatin1Char('a'));
    quint32 base = BIND_RADIX * BIND_RADIX * BIND_RADIX * BIND_RADIX * BIND_RADIX;
    for (int i = 0; i < 6; ++i) {
        const quint32 index = value / base;
        phrase[5 - i] = QLatin1Char(index < BIND_RADIX ? BIND_CHARS[index] : 'a');
        value -= index * base;
        base /= BIND_RADIX;
    }
    return phrase;
}

bool MLRSController::encode_bind_phrase(const QString &phrase, quint32 &value)
{
    if (phrase.size() != 6) return false;
    quint64 result = 0;
    quint64 base = 1;
    const QByteArray bytes = phrase.toLower().toLatin1();
    for (char c : bytes) {
        const char *found = std::strchr(BIND_CHARS, c);
        if (!found) return false;
        result += static_cast<quint64>(found - BIND_CHARS) * base;
        base *= BIND_RADIX;
    }
    value = static_cast<quint32>(result);
    return true;
}
