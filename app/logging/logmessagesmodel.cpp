#include "logmessagesmodel.h"
#include "qdebug.h"

#include <QByteArray>
#include <QTimer>
#include <cstdlib>

#include "hudlogmessagesmodel.h"

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

QColor LogMessagesModel::log_severity_to_color(quint8 severity){
    if(severity<=X_MAV_SEVERITY_ERROR){
        return QColor{255,0,0,255};//red
    }
    if(severity<=X_MAV_SEVERITY_WARNING){
        return QColor{255, 165, 0,255};//orange
    }
    return QColor{0,255,0,255};//green
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
    // hacky temporary
    if(logMessageData.message.contains("Scanning ")){
        HUDLogMessagesModel::instance().add_message_info(logMessageData.message);
    }
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

