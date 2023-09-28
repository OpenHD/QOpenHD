#include "hudlogmessagesmodel.h"

#include "loghelper.h"
#include "qdebug.h"

HUDLogMessagesModel::HUDLogMessagesModel(QObject *parent)
    :  QAbstractListModel(parent)
{
    //addData(HUDLogMessagesModel::Element{"message_hello",0});
    //addData(HUDLogMessagesModel::Element{"message_hello2",0,std::chrono::steady_clock::now()+std::chrono::seconds(2)});
    //addData(HUDLogMessagesModel::Element{"message_hello3",0,std::chrono::steady_clock::now()+std::chrono::seconds(3)});
    connect(this, &HUDLogMessagesModel::signalAddLogMessage, this, &HUDLogMessagesModel::do_not_call_me_addLogMessage);
    m_cleanup_timer = new QTimer(this);
    QObject::connect(m_cleanup_timer, &QTimer::timeout, this, &HUDLogMessagesModel::handle_cleanup);
    m_cleanup_timer->start(1000);
}

HUDLogMessagesModel &HUDLogMessagesModel::instance()
{
    static HUDLogMessagesModel instance;
    return instance;
}

void HUDLogMessagesModel::add_message(int severity, QString message)
{
    emit signalAddLogMessage(severity,message);
}

void HUDLogMessagesModel::add_message_info(QString message)
{
    add_message(6,message);
}

void HUDLogMessagesModel::add_message_warning(QString message)
{
     add_message(4,message);
}

int HUDLogMessagesModel::rowCount( const QModelIndex& parent) const
{
    if (parent.isValid())
        return 0;

    return m_data.count();
}

QVariant HUDLogMessagesModel::data(const QModelIndex &index, int role) const
{
    if ( !index.isValid() )
        return QVariant();

    const HUDLogMessagesModel::Element &data = m_data.at(index.row());
    if ( role == MessageRole )
        return data.message;
    else if ( role == LevelRole )
        return data.severity;
    else
        return QVariant();
}

QHash<int, QByteArray> HUDLogMessagesModel::roleNames() const
{
    static QHash<int, QByteArray> mapping {
        {MessageRole, "message"},
        {LevelRole, "level"}
    };
    return mapping;
}

void HUDLogMessagesModel::do_not_call_me_addLogMessage(int severity, QString message){
    HUDLogMessagesModel::Element element{};
    element.message=message;
    element.severity=severity;
    addData(element);
}

void HUDLogMessagesModel::removeData(int row)
{
    if (row < 0 || row >= m_data.count())
        return;

    //qDebug()<<"Removing "<<row;
    beginRemoveRows(QModelIndex(), row, row);
    m_data.removeAt(row);
    endRemoveRows();
}

void HUDLogMessagesModel::addData(HUDLogMessagesModel::Element logMessageData)
{
    //qDebug()<<"LogMessagesModel::addData"<<logMessageData.message;
    // We limit logging to X log messages here
    if(m_data.size()>=MAX_N_ELEMENTS){
        // remove oldest one
        removeData(0);
    }
    beginInsertRows(QModelIndex(), rowCount(), rowCount());
    m_data.push_back(logMessageData);
    endInsertRows();
}

void HUDLogMessagesModel::handle_cleanup()
{
    //qDebug()<<"timer";
    for(int i=0;i<m_data.size();i++){
        const auto& el=m_data.at(i);
        const auto age=std::chrono::steady_clock::now()-el.added_time_point;
        if(age>std::chrono::seconds(5)){
            removeData(i);
            i--;
        }
    }
}
