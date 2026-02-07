//
// Created by ChatGPT for tracking incoming mavlink messages in a debug view.
//

#ifndef MAVLINKMESSAGESTATSMODEL_H
#define MAVLINKMESSAGESTATSMODEL_H

#include <QAbstractListModel>
#include <QTimer>
#include <QVariantList>
#include <QVariantMap>
#include <atomic>
#include <array>
#include <deque>
#include <mutex>
#include <unordered_map>
#include <vector>

#include "../tutil/mavlink_include.h"

/**
 * QAbstractListModel that keeps track of incoming mavlink messages.
 * Entries are keyed by (sysid, compid, msgid) and updated in place so the
 * debug table does not duplicate rows.
 */
class MavlinkMessageStatsModel : public QAbstractListModel
{
    Q_OBJECT
    Q_PROPERTY(bool enabled READ enabled WRITE setEnabled NOTIFY enabledChanged)
    Q_PROPERTY(int maxEntries READ maxEntries WRITE setMaxEntries NOTIFY maxEntriesChanged)
public:
    enum MessageRoles {
        SourceLabelRole = Qt::UserRole + 1,
        OriginCategoryRole,
        SystemIdRole,
        ComponentIdRole,
        MessageIdRole,
        MessageNameRole,
        LastSeenRole,
        LastSeenReadableRole,
        UpdateCountRole
    };
    Q_ENUM(MessageRoles)

    struct Entry {
        int system_id;
        int component_id;
        int message_id;
        qint64 last_seen_ms;
        int update_count{0};
        std::array<uint8_t, MAVLINK_MAX_PAYLOAD_LEN> last_payload{};
        uint8_t last_payload_len{0};
        bool has_payload{false};
    };

    struct PendingMessage {
        int system_id;
        int component_id;
        int message_id;
        qint64 timestamp_ms;
        std::array<uint8_t, MAVLINK_MAX_PAYLOAD_LEN> payload{};
        uint8_t payload_len{0};
        bool has_payload{false};
    };

    static MavlinkMessageStatsModel& instance();

    int rowCount(const QModelIndex &parent = QModelIndex()) const override;
    QVariant data(const QModelIndex &index, int role) const override;
    QHash<int, QByteArray> roleNames() const override;

    Q_INVOKABLE void clear();
    Q_INVOKABLE QString decodeMessage(int messageId) const;
    Q_INVOKABLE QVariantMap decodeMessageDetails(int row) const;
    Q_INVOKABLE QVariantMap get(int row) const;
    Q_INVOKABLE void setEnabled(bool enabled);
    Q_INVOKABLE bool enabled() const;
    Q_INVOKABLE int maxEntries() const;
    Q_INVOKABLE void setMaxEntries(int maxEntries);

    // Thread-safe entry point used by the telemetry pipeline to record a new message.
    void record_message(const mavlink_message_t& msg);

signals:
    void enabledChanged();
    void maxEntriesChanged();

private slots:
    void flush_pending();

private:
    explicit MavlinkMessageStatsModel(QObject *parent = nullptr);
    QString source_label_for(const Entry& entry) const;
    QString origin_category_for_sysid(int sysid) const;
    QString message_name_for_id(int msgid) const;
    QString last_seen_readable(qint64 last_seen_ms) const;
    void sort_entries();
    void update_or_insert_entry(const PendingMessage& pending);
    void prune_entries();
    void rebuild_index();

    struct Key {
        int sysid;
        int compid;
        int msgid;
        bool operator==(const Key& other) const {
            return sysid == other.sysid && compid == other.compid && msgid == other.msgid;
        }
    };

    struct KeyHash {
        size_t operator()(const Key& key) const noexcept {
            const auto h1 = std::hash<int>{}(key.sysid);
            const auto h2 = std::hash<int>{}(key.compid);
            const auto h3 = std::hash<int>{}(key.msgid);
            return h1 ^ (h2 << 1) ^ (h3 << 2);
        }
    };

    std::atomic_bool m_enabled{false};
    int m_maxEntries{300};
    int m_maxPendingMessages{500};
    QTimer m_flush_timer;
    std::mutex m_pending_mutex;
    std::deque<PendingMessage> m_pending_messages;
    std::vector<Entry> m_data;
    std::unordered_map<Key, size_t, KeyHash> m_index;
};

#endif // MAVLINKMESSAGESTATSMODEL_H
