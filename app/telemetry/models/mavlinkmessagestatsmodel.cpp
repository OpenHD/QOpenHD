#include "mavlinkmessagestatsmodel.h"

#include <QDebug>
#include <algorithm>
#include <QtEndian>
#include <cstring>
#include <QStringList>

#include "../tutil/openhd_defines.hpp"
#include "../tutil/qopenhdmavlinkhelper.hpp"
#include "../tutil/mavlink_include.h"

namespace {
struct Key {
    int sysid;
    int compid;
    int msgid;
    bool operator==(const Key& other) const {
        return sysid == other.sysid && compid == other.compid && msgid == other.msgid;
    }
};
}

MavlinkMessageStatsModel &MavlinkMessageStatsModel::instance()
{
    static MavlinkMessageStatsModel instance;
    return instance;
}

MavlinkMessageStatsModel::MavlinkMessageStatsModel(QObject *parent)
    : QAbstractListModel(parent)
{
    connect(this, &MavlinkMessageStatsModel::signal_record_message, this, &MavlinkMessageStatsModel::handle_record_message, Qt::QueuedConnection);
}

int MavlinkMessageStatsModel::rowCount(const QModelIndex &parent) const
{
    if (parent.isValid()) {
        return 0;
    }
    return static_cast<int>(m_data.size());
}

QVariant MavlinkMessageStatsModel::data(const QModelIndex &index, int role) const
{
    if (!index.isValid() || index.row() < 0 || index.row() >= rowCount()) {
        return {};
    }
    const auto &entry = m_data.at(static_cast<size_t>(index.row()));
    switch (role) {
    case SourceLabelRole:
        return source_label_for(entry);
    case OriginCategoryRole:
        return entry.origin_category;
    case SystemIdRole:
        return entry.system_id;
    case ComponentIdRole:
        return entry.component_id;
    case MessageIdRole:
        return entry.message_id;
    case MessageNameRole:
        return entry.message_name;
    case LastSeenRole:
        return entry.last_seen_ms;
    case LastSeenReadableRole:
        return last_seen_readable(entry.last_seen_ms);
    case UpdateCountRole:
        return entry.update_count;
    default:
        break;
    }
    return {};
}

QHash<int, QByteArray> MavlinkMessageStatsModel::roleNames() const
{
    static QHash<int, QByteArray> roles {
        {SourceLabelRole, "source_label"},
        {OriginCategoryRole, "origin_category"},
        {SystemIdRole, "system_id"},
        {ComponentIdRole, "component_id"},
        {MessageIdRole, "message_id"},
        {MessageNameRole, "message_name"},
        {LastSeenRole, "last_seen_ms"},
        {LastSeenReadableRole, "last_seen_readable"},
        {UpdateCountRole, "update_count"}
    };
    return roles;
}

void MavlinkMessageStatsModel::clear()
{
    beginResetModel();
    m_data.clear();
    endResetModel();
}

QString MavlinkMessageStatsModel::decodeMessage(int messageId) const
{
    const mavlink_message_info_t *info = mavlink_get_message_info_by_id(static_cast<uint32_t>(messageId));
    if (info != nullptr) {
        auto type_to_string = [](uint8_t type) -> QString {
            switch (type) {
            case MAVLINK_TYPE_CHAR: return QStringLiteral("char");
            case MAVLINK_TYPE_UINT8_T: return QStringLiteral("uint8");
            case MAVLINK_TYPE_INT8_T: return QStringLiteral("int8");
            case MAVLINK_TYPE_UINT16_T: return QStringLiteral("uint16");
            case MAVLINK_TYPE_INT16_T: return QStringLiteral("int16");
            case MAVLINK_TYPE_UINT32_T: return QStringLiteral("uint32");
            case MAVLINK_TYPE_INT32_T: return QStringLiteral("int32");
            case MAVLINK_TYPE_UINT64_T: return QStringLiteral("uint64");
            case MAVLINK_TYPE_INT64_T: return QStringLiteral("int64");
            case MAVLINK_TYPE_FLOAT: return QStringLiteral("float");
            case MAVLINK_TYPE_DOUBLE: return QStringLiteral("double");
            default: return QStringLiteral("unknown");
            }
        };

        QStringList fields;
        fields.reserve(static_cast<int>(info->num_fields));
        for (unsigned int i = 0; i < info->num_fields; ++i) {
            const auto &field = info->fields[i];
            const auto type_str = type_to_string(field.type);
            const auto array_len = field.array_length == 0 ? 1u : field.array_length;
            if (array_len > 1) {
                fields.push_back(QStringLiteral("%1: %2[%3]")
                                     .arg(QString::fromUtf8(field.name))
                                     .arg(type_str)
                                     .arg(array_len));
            } else {
                fields.push_back(QStringLiteral("%1: %2")
                                     .arg(QString::fromUtf8(field.name))
                                     .arg(type_str));
            }
        }
        const QString fieldSummary = fields.isEmpty() ? QStringLiteral("No fields") : fields.join(QStringLiteral("\n"));
        return QStringLiteral("%1 (ID %2)\nField count: %3\n\n%4")
            .arg(QString::fromUtf8(info->name))
            .arg(messageId)
            .arg(info->num_fields)
            .arg(fieldSummary);
    }
    return QStringLiteral("Unknown message ID %1").arg(messageId);
}

QVariantMap MavlinkMessageStatsModel::decodeMessageDetails(int row) const
{
    QVariantMap result;
    if (row < 0 || row >= rowCount()) {
        result.insert(QStringLiteral("messageId"), -1);
        result.insert(QStringLiteral("messageName"), QStringLiteral("Unknown message"));
        result.insert(QStringLiteral("fieldCount"), 0);
        result.insert(QStringLiteral("fields"), QVariantList{});
        return result;
    }

    const auto &entry = m_data.at(static_cast<size_t>(row));
    const int messageId = entry.message_id;
    result.insert(QStringLiteral("messageId"), messageId);
    result.insert(QStringLiteral("messageName"), entry.message_name);
    result.insert(QStringLiteral("fieldCount"), 0);
    QVariantList fields;
    const auto payload_len = entry.has_payload ? static_cast<int>(entry.last_payload_len) : 0;
    const auto *payload = entry.has_payload ? entry.last_payload.data() : nullptr;

    const mavlink_message_info_t *info = mavlink_get_message_info_by_id(static_cast<uint32_t>(messageId));
    if (info != nullptr) {
        auto type_to_string = [](uint8_t type) -> QString {
            switch (type) {
            case MAVLINK_TYPE_CHAR: return QStringLiteral("char");
            case MAVLINK_TYPE_UINT8_T: return QStringLiteral("uint8");
            case MAVLINK_TYPE_INT8_T: return QStringLiteral("int8");
            case MAVLINK_TYPE_UINT16_T: return QStringLiteral("uint16");
            case MAVLINK_TYPE_INT16_T: return QStringLiteral("int16");
            case MAVLINK_TYPE_UINT32_T: return QStringLiteral("uint32");
            case MAVLINK_TYPE_INT32_T: return QStringLiteral("int32");
            case MAVLINK_TYPE_UINT64_T: return QStringLiteral("uint64");
            case MAVLINK_TYPE_INT64_T: return QStringLiteral("int64");
            case MAVLINK_TYPE_FLOAT: return QStringLiteral("float");
            case MAVLINK_TYPE_DOUBLE: return QStringLiteral("double");
            default: return QStringLiteral("unknown");
            }
        };

        result.insert(QStringLiteral("messageName"), QString::fromUtf8(info->name));
        result.insert(QStringLiteral("fieldCount"), static_cast<int>(info->num_fields));

        auto type_size = [](uint8_t type) -> int {
            switch (type) {
            case MAVLINK_TYPE_CHAR: return sizeof(char);
            case MAVLINK_TYPE_UINT8_T: return sizeof(uint8_t);
            case MAVLINK_TYPE_INT8_T: return sizeof(int8_t);
            case MAVLINK_TYPE_UINT16_T: return sizeof(uint16_t);
            case MAVLINK_TYPE_INT16_T: return sizeof(int16_t);
            case MAVLINK_TYPE_UINT32_T: return sizeof(uint32_t);
            case MAVLINK_TYPE_INT32_T: return sizeof(int32_t);
            case MAVLINK_TYPE_UINT64_T: return sizeof(uint64_t);
            case MAVLINK_TYPE_INT64_T: return sizeof(int64_t);
            case MAVLINK_TYPE_FLOAT: return sizeof(float);
            case MAVLINK_TYPE_DOUBLE: return sizeof(double);
            default: return 0;
            }
        };

        auto read_scalar_string = [](const uint8_t *ptr, uint8_t type) -> QString {
            switch (type) {
            case MAVLINK_TYPE_CHAR:
                return QString(QChar(static_cast<unsigned char>(*ptr)));
            case MAVLINK_TYPE_UINT8_T:
                return QString::number(static_cast<unsigned int>(*ptr));
            case MAVLINK_TYPE_INT8_T:
                return QString::number(static_cast<int>(static_cast<int8_t>(*ptr)));
            case MAVLINK_TYPE_UINT16_T:
                return QString::number(qFromLittleEndian<uint16_t>(ptr));
            case MAVLINK_TYPE_INT16_T:
                return QString::number(static_cast<int16_t>(qFromLittleEndian<uint16_t>(ptr)));
            case MAVLINK_TYPE_UINT32_T:
                return QString::number(qFromLittleEndian<uint32_t>(ptr));
            case MAVLINK_TYPE_INT32_T:
                return QString::number(static_cast<int32_t>(qFromLittleEndian<uint32_t>(ptr)));
            case MAVLINK_TYPE_UINT64_T:
                return QString::number(qFromLittleEndian<uint64_t>(ptr));
            case MAVLINK_TYPE_INT64_T:
                return QString::number(static_cast<int64_t>(qFromLittleEndian<uint64_t>(ptr)));
            case MAVLINK_TYPE_FLOAT: {
                uint32_t raw = qFromLittleEndian<uint32_t>(ptr);
                float value;
                std::memcpy(&value, &raw, sizeof(float));
                return QString::number(value);
            }
            case MAVLINK_TYPE_DOUBLE: {
                uint64_t raw = qFromLittleEndian<uint64_t>(ptr);
                double value;
                std::memcpy(&value, &raw, sizeof(double));
                return QString::number(value);
            }
            default:
                return QStringLiteral("n/a");
            }
        };

        for (unsigned int i = 0; i < info->num_fields; ++i) {
            const auto &field = info->fields[i];
            const int size = type_size(field.type);
            const auto array_len = field.array_length == 0 ? 1u : field.array_length;
            QVariantMap fieldMap;
            fieldMap.insert(QStringLiteral("name"), QString::fromUtf8(field.name));
            fieldMap.insert(QStringLiteral("type"), type_to_string(field.type));
            fieldMap.insert(QStringLiteral("arrayLength"), static_cast<int>(array_len));

            if (payload == nullptr || size == 0) {
                fieldMap.insert(QStringLiteral("value"), QStringLiteral("n/a"));
                fields.push_back(fieldMap);
                continue;
            }

            const int field_offset = static_cast<int>(field.wire_offset);
            const int total_needed = field_offset + (size * static_cast<int>(array_len));
            if (total_needed > payload_len) {
                fieldMap.insert(QStringLiteral("value"), QStringLiteral("truncated"));
                fields.push_back(fieldMap);
                continue;
            }

            QStringList values;
            const uint8_t *curr_ptr = payload + field_offset;

            if (field.type == MAVLINK_TYPE_CHAR && array_len > 1) {
                QByteArray raw(reinterpret_cast<const char *>(curr_ptr), static_cast<int>(array_len));
                const int null_index = raw.indexOf('\0');
                if (null_index >= 0) {
                    raw.truncate(null_index);
                }
                const bool printable = std::all_of(raw.cbegin(), raw.cend(), [](char c) {
                    const unsigned char uc = static_cast<unsigned char>(c);
                    return uc == '\n' || uc == '\r' || uc == '\t' || (uc >= 0x20 && uc <= 0x7E);
                });
                if (printable) {
                    fieldMap.insert(QStringLiteral("value"), QString::fromLatin1(raw));
                } else {
                    values.reserve(static_cast<int>(array_len));
                    for (unsigned int j = 0; j < array_len; ++j) {
                        values.push_back(QString::number(static_cast<unsigned int>(static_cast<unsigned char>(*(curr_ptr + (j * size))))));
                    }
                    fieldMap.insert(QStringLiteral("value"), QStringLiteral("[%1]").arg(values.join(QStringLiteral(", "))));
                }
            } else {
                values.reserve(static_cast<int>(array_len));
                for (unsigned int j = 0; j < array_len; ++j) {
                    values.push_back(read_scalar_string(curr_ptr + (j * size), field.type));
                }
                if (array_len > 1) {
                    fieldMap.insert(QStringLiteral("value"), QStringLiteral("[%1]").arg(values.join(QStringLiteral(", "))));
                } else {
                    fieldMap.insert(QStringLiteral("value"), values.value(0));
                }
            }
            fields.push_back(fieldMap);
        }
    }

    result.insert(QStringLiteral("fields"), fields);
    return result;
}

QVariantMap MavlinkMessageStatsModel::get(int row) const
{
    QVariantMap result;
    if (row < 0 || row >= rowCount()) {
        return result;
    }
    const auto &entry = m_data.at(static_cast<size_t>(row));
    result.insert(QStringLiteral("source_label"), source_label_for(entry));
    result.insert(QStringLiteral("origin_category"), entry.origin_category);
    result.insert(QStringLiteral("system_id"), entry.system_id);
    result.insert(QStringLiteral("component_id"), entry.component_id);
    result.insert(QStringLiteral("message_id"), entry.message_id);
    result.insert(QStringLiteral("message_name"), entry.message_name);
    result.insert(QStringLiteral("last_seen_ms"), entry.last_seen_ms);
    result.insert(QStringLiteral("last_seen_readable"), last_seen_readable(entry.last_seen_ms));
    result.insert(QStringLiteral("update_count"), entry.update_count);
    return result;
}

void MavlinkMessageStatsModel::setEnabled(bool enabled)
{
    const bool wasEnabled = m_enabled.load(std::memory_order_relaxed);
    if (wasEnabled == enabled) {
        return;
    }
    m_enabled.store(enabled, std::memory_order_relaxed);
    emit enabledChanged();
}

bool MavlinkMessageStatsModel::enabled() const
{
    return m_enabled.load(std::memory_order_relaxed);
}

void MavlinkMessageStatsModel::record_message(const mavlink_message_t &msg)
{
    if (!m_enabled.load(std::memory_order_relaxed)) {
        return;
    }
    QByteArray payload(reinterpret_cast<const char*>(msg.payload64), msg.len);
    emit signal_record_message(msg.sysid, msg.compid, msg.msgid, payload);
}

void MavlinkMessageStatsModel::handle_record_message(int sysid, int compid, int msgid, const QByteArray &payload)
{
    Entry entry;
    entry.system_id = sysid;
    entry.component_id = compid;
    entry.message_id = msgid;
    entry.origin_category = origin_category_for_sysid(sysid);
    entry.message_name = message_name_for_id(msgid);
    entry.last_seen_ms = QOpenHDMavlinkHelper::getTimeMilliseconds();
    entry.last_payload_len = static_cast<uint8_t>(std::min<int>(payload.size(), MAVLINK_MAX_PAYLOAD_LEN));
    if (entry.last_payload_len > 0) {
        std::copy_n(reinterpret_cast<const uint8_t*>(payload.constData()), entry.last_payload_len, entry.last_payload.begin());
        entry.has_payload = true;
    }
    update_or_insert_entry(entry);
}

QString MavlinkMessageStatsModel::source_label_for(const Entry &entry) const
{
    return QStringLiteral("%1/%2/%3").arg(entry.system_id).arg(entry.component_id).arg(entry.message_id);
}

QString MavlinkMessageStatsModel::origin_category_for_sysid(int sysid) const
{
    if (sysid == OHD_SYS_ID_AIR || sysid == OHD_SYS_ID_GROUND) {
        return QStringLiteral("OpenHD");
    }
    return QStringLiteral("Flight Controller");
}

QString MavlinkMessageStatsModel::message_name_for_id(int msgid) const
{
    const mavlink_message_info_t *info = mavlink_get_message_info_by_id(static_cast<uint32_t>(msgid));
    if (info != nullptr && info->name != nullptr) {
        return QString::fromUtf8(info->name);
    }
    return QStringLiteral("ID %1").arg(msgid);
}

QString MavlinkMessageStatsModel::last_seen_readable(qint64 last_seen_ms) const
{
    const auto now_ms = QOpenHDMavlinkHelper::getTimeMilliseconds();
    const auto delta_ms = now_ms - last_seen_ms;
    if (delta_ms < 0) {
        return QStringLiteral("-");
    }
    if (delta_ms < 1000) {
        return QStringLiteral("%1 ms ago").arg(delta_ms);
    }
    const int seconds = delta_ms / 1000;
    if (seconds < 60) {
        return QStringLiteral("%1 s ago").arg(seconds);
    }
    const int minutes = seconds / 60;
    return QStringLiteral("%1 m ago").arg(minutes);
}

void MavlinkMessageStatsModel::update_or_insert_entry(const Entry &entry_template)
{
    const Key needle{entry_template.system_id, entry_template.component_id, entry_template.message_id};
    auto it = std::find_if(m_data.begin(), m_data.end(), [&needle](const Entry &e) {
        return e.system_id == needle.sysid && e.component_id == needle.compid && e.message_id == needle.msgid;
    });

    if (it != m_data.end()) {
        const int row = static_cast<int>(std::distance(m_data.begin(), it));
        it->last_seen_ms = entry_template.last_seen_ms;
        it->update_count += 1;
        if (entry_template.has_payload) {
            it->last_payload_len = entry_template.last_payload_len;
            it->has_payload = entry_template.has_payload;
            std::copy_n(entry_template.last_payload.begin(), entry_template.last_payload_len, it->last_payload.begin());
        }
        emit dataChanged(index(row, 0), index(row, 0));
        sort_entries();
        return;
    }

    const int insert_row = rowCount();
    beginInsertRows(QModelIndex(), insert_row, insert_row);
    m_data.push_back(entry_template);
    m_data.back().update_count = 1;
    endInsertRows();
    sort_entries();
}

void MavlinkMessageStatsModel::sort_entries()
{
    if (m_data.empty()) {
        return;
    }
    // Sort by origin, then system id, then component id, then message id for stable grouping
    std::stable_sort(m_data.begin(), m_data.end(), [](const Entry &a, const Entry &b) {
        if (a.origin_category != b.origin_category)
            return a.origin_category < b.origin_category;
        if (a.system_id != b.system_id)
            return a.system_id < b.system_id;
        if (a.component_id != b.component_id)
            return a.component_id < b.component_id;
        return a.message_id < b.message_id;
    });
    // Notify views that ordering changed
    emit dataChanged(index(0, 0), index(rowCount() - 1, 0));
}
