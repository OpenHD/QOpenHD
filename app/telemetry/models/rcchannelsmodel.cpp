#include "rcchannelsmodel.h"
#include "qdebug.h"



RCChannelsModel::RCChannelsModel(QObject *parent)
    : QAbstractListModel(parent)
{

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
}
