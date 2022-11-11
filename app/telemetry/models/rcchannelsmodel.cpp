#include "rcchannelsmodel.h"
#include "qdebug.h"



RCChannelsModel::RCChannelsModel(QObject *parent)
    : QAbstractListModel(parent)
{
    m_alive_timer = std::make_unique<QTimer>(this);
    QObject::connect(m_alive_timer.get(), &QTimer::timeout, this, &RCChannelsModel::update_alive);
    m_alive_timer->start(1000);
}

RCChannelsModel &RCChannelsModel::instanceGround()
{
    static RCChannelsModel ground{};
    return ground;
}

int RCChannelsModel::rowCount(const QModelIndex &parent) const
{
    return m_data.size();
}

QVariant RCChannelsModel::data(const QModelIndex &index, int role) const
{
    if ( !index.isValid() )
        return QVariant();

    const auto& data = m_data.at(index.row());
    if ( role == CurrValueRole ){
        return data;
    }
    return QVariant();
}

QHash<int, QByteArray> RCChannelsModel::roleNames() const
{
    static QHash<int, QByteArray> mapping {
        {CurrValueRole, "curr_value"},
    };
    return mapping;
}

void RCChannelsModel::updateData(int row, int value)
{
    if (row < 0 || row >= m_data.count()){
         qDebug()<<"Channel out of bounds"<<row;
         return;
    }
    m_data[row]=value;
    QModelIndex topLeft = createIndex(row,0);
    emit dataChanged(topLeft, topLeft);
}

void RCChannelsModel::update_all_channels(const RC_CHANNELS &channels)
{
    for(int i=0;i<channels.size();i++){
        updateData(i,channels[i]);
    }
    m_last_update=std::chrono::steady_clock::now();
}

void RCChannelsModel::update_alive()
{
    const auto delay_since_last=std::chrono::steady_clock::now()-m_last_update;
    if(delay_since_last<std::chrono::seconds(2)){
        set_is_alive(true);
    }else{
        set_is_alive(false);
    }
}

