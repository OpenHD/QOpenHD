#include "logmessagesmodel.h"
#include "qdebug.h"

#include <QByteArray>
#include <QTimer>
#include <cstdlib>

LogMessagesModel &LogMessagesModel::instance()
{
    static LogMessagesModel* instance=new LogMessagesModel();
    return *instance;
}

LogMessagesModel::LogMessagesModel(QObject *parent) :
    QAbstractListModel(parent)
{
    /*addData(LogMessageData{"tag1", "blablabla"});
    addData(LogMessageData{"tag2", "xxxxxxx"});
    addData(LogMessageData{"tag3", "yyyyyyy"});
    addData(LogMessageData{"tag4", "yyyyyyy"});
    addData(LogMessageData{"tag5", "yyyyyyy"});
    addData(LogMessageData{"tag6", "yyyyyyy"});*/
    connect(this, &LogMessagesModel::signalAddLogMessage, this, &LogMessagesModel::do_not_call_me_addLogMessage);
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

void LogMessagesModel::addLogMessage(const QString tag, QString message,quint8 severity){
    //qDebug()<<"Add log message:"<<tag<<message;
    // See .h documentation, here we have to emit a signal instead of modifying the model directly.
    emit signalAddLogMessage(tag,message,severity);
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
    //qDebug()<<"LogMessagesModel::addData"<<logMessageData.message;
    // We limit logging to X log messages here
    if(m_data.size()>=30){
        // remove oldest one
        removeData(0);
    }
    beginInsertRows(QModelIndex(), rowCount(), rowCount());
    m_data.push_back(logMessageData);
    endInsertRows();
}

