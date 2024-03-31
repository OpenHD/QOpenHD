#include "rcchannelsmodel.h"
#include <qdebug.h>
#include "tutil/qopenhdmavlinkhelper.hpp"



RCChannelsModel::RCChannelsModel(QObject *parent)
    : QAbstractListModel(parent)
{
    m_alive_timer = std::make_unique<QTimer>(this);
    QObject::connect(m_alive_timer.get(), &QTimer::timeout, this, &RCChannelsModel::update_alive);
    m_alive_timer->start(1000);
    assert(m_data.size()==18);
}

RCChannelsModel &RCChannelsModel::instanceGround()
{
    static RCChannelsModel ground{};
    return ground;
}

RCChannelsModel &RCChannelsModel::instanceFC()
{
    static RCChannelsModel fc{};
    return fc;
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
    set_control_yaw(channels[0]); // A
    set_control_roll(channels[1]); // E
    set_control_throttle(channels[2]); // T
    set_control_pitch(channels[3]); // R
    m_last_update_ms=QOpenHDMavlinkHelper::getTimeMilliseconds();
}

void RCChannelsModel::set_channels_debug()
{
    int count=1000;
    RCChannelsModel::RC_CHANNELS channels;
    for(int i=0;i<18;i++){
        channels[i]=count;
        count+=20;
    }
    update_all_channels(channels);
}

void RCChannelsModel::update_alive()
{
    if(m_last_update_ms==-1){
        // we did not get any updates yet
        set_is_alive(false);
    }else{
        const auto elapsed_ms=QOpenHDMavlinkHelper::getTimeMilliseconds()-m_last_update_ms;
        // after X seconds, consider as "not alive"
        const bool alive=elapsed_ms < 4*1000;
        set_is_alive(alive);
    }
}

