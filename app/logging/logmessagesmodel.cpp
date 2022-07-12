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

void LogMessagesModel::addLogMessage(LogMessageData logMessageData)
{
    //auto *myQObject = &LogMessagesModel::instance();
    //QMetaObject::invokeMethod(myQObject
    //                           , "addData"
    //                           , Qt::AutoConnection // Can also use any other except DirectConnection
    //                           , Q_ARG(LogMessagesModel::LogMessageData, logMessageData)); // And some more args if needed
    //emit LogMessagesModel::instance().signalAddLogMessage(logMessageData);
    //LogMessagesModel::instance().addData(logMessageData);
}

LogMessagesModel::LogMessagesModel(QObject *parent) :
    QAbstractListModel(parent)
{
    addData(LogMessageData{"tag1", "blablabla"});
    addData(LogMessageData{"tag2", "xxxxxxx"});
    addData(LogMessageData{"tag3", "yyyyyyy"});
    addData(LogMessageData{"tag4", "yyyyyyy"});
    addData(LogMessageData{"tag5", "yyyyyyy"});
    addData(LogMessageData{"tag6", "yyyyyyy"});
    //connect(this, &LogMessagesModel::signalAddLogMessage, this, &LogMessagesModel::addData);
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

void LogMessagesModel::addLogMessage(const QString tag, QString message,quint8 severity)
{
    LogMessageData data{tag,message,0,log_severity_to_color(severity)};
    addData(data);
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
    /*if(m_data.size()>=10){
        // remove oldest one
        removeData(0);
    }*/
    beginInsertRows(QModelIndex(), rowCount(), rowCount());
    m_data.push_back(logMessageData);
    endInsertRows();
}

