//
// Created by ChatGPT for tracking incoming mavlink messages in a debug view.
//

#ifndef MAVLINKMESSAGESTATSMODEL_H
#define MAVLINKMESSAGESTATSMODEL_H

#include <QAbstractListModel>
#include <QDateTime>
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
        QString message_name;
        QString origin_category;
        qint64 last_seen_ms;
        int update_count{0};
    };

    static MavlinkMessageStatsModel& instance();

    int rowCount(const QModelIndex &parent = QModelIndex()) const override;
    QVariant data(const QModelIndex &index, int role) const override;
    QHash<int, QByteArray> roleNames() const override;

    Q_INVOKABLE void clear();

    // Thread-safe entry point used by the telemetry pipeline to record a new message.
    void record_message(const mavlink_message_t& msg);

signals:
    void signal_record_message(int sysid, int compid, int msgid);

private slots:
    void handle_record_message(int sysid, int compid, int msgid);

private:
    explicit MavlinkMessageStatsModel(QObject *parent = nullptr);
    QString source_label_for(const Entry& entry) const;
    QString origin_category_for_sysid(int sysid) const;
    QString message_name_for_id(int msgid) const;
    QString last_seen_readable(qint64 last_seen_ms) const;
    void sort_entries();
    void update_or_insert_entry(const Entry& entry_template);

    std::vector<Entry> m_data;
};

#endif // MAVLINKMESSAGESTATSMODEL_H
