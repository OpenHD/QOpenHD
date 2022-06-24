#include "logmessagesmodel.h"

#include <QByteArray>
#include <QTimer>
#include <cstdlib>

LogMessagesModel &LogMessagesModel::instance()
{
    static LogMessagesModel* instance=new LogMessagesModel();
    return *instance;
}

void LogMessagesModel::addLogMessage(LogMessageData logMessageData)
{
    LogMessagesModel::instance().addData(logMessageData);
}

LogMessagesModel::LogMessagesModel(QObject *parent) :
    QAbstractListModel(parent)
{
    m_data
        << LogMessageData{"tag1", "blablabla"}
        << LogMessageData{"tag2", "xxxxxxx"}
        << LogMessageData{"tag3", "yyyyyyy"};
}

int LogMessagesModel::rowCount( const QModelIndex& parent) const
{
    if (parent.isValid())
        return 0;

    return m_data.count();
}

QVariant LogMessagesModel::data(const QModelIndex &index, int role) const
{
    if ( !index.isValid() )
        return QVariant();

    const LogMessageData &data = m_data.at(index.row());
    if ( role == TagRole ){
        return data.tag;
    }
    else if ( role == MessageRole )
        return data.message;
    else if ( role == TimestampRole )
        return data.timestamp;
    else if ( role == SeverityColorRole)
        return data.severity_color;
    else
        return QVariant();
}

QHash<int, QByteArray> LogMessagesModel::roleNames() const
{
    static QHash<int, QByteArray> mapping {
        {TagRole, "tag"},
        {MessageRole, "message"},
        {TimestampRole, "timestamp"},
        {SeverityColorRole,"severity_color"}
    };
    return mapping;
}


void LogMessagesModel::removeData(int row)
{
    if (row < 0 || row >= m_data.count())
        return;

    beginRemoveRows(QModelIndex(), row, row);
    m_data.removeAt(row);
    endRemoveRows();
}

void LogMessagesModel::addData(LogMessageData logMessageData)
{
    beginInsertRows(QModelIndex(), rowCount(), rowCount());
    m_data.push_back(logMessageData);
    endInsertRows();
}

