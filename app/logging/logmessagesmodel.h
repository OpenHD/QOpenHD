#ifndef LOGMESSAGESMODEL_H
#define LOGMESSAGESMODEL_H

#include <QAbstractListModel>
#include <QColor>


struct LogMessageData{
    QString tag;
    QString message;
    quint64 timestamp=0;
    QColor severity_color{0,255,0,255};
};

static QColor log_severity_to_color(quint8 severity){
    return QColor{0,255,0,255};
}

class LogMessagesModel : public QAbstractListModel
{
    Q_OBJECT

public:
    static  LogMessagesModel& instance();
    static void addLogMessage(LogMessageData logMessageData);
    enum Roles {
        TagRole = Qt::UserRole,
        MessageRole,
        TimestampRole,
        SeverityColorRole
    };

    explicit  LogMessagesModel(QObject *parent = nullptr);

    int rowCount(const QModelIndex& parent= QModelIndex()) const override;
    QVariant data( const QModelIndex& index, int role = Qt::DisplayRole ) const override;
    QHash<int, QByteArray> roleNames() const override;

public slots:
    void duplicateData(int row);
    void removeData(int row);
    void addData(LogMessageData logMessageData);

private slots:
    void growPopulation();

private: //members
    QVector< LogMessageData > m_data;
};

#endif // LOGMESSAGESMODEL_H
