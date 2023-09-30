#include "fcmavlinkmissionitemsmodel.h"
#include "qdebug.h"
#include <qsettings.h>


FCMavlinkMissionItemsModel::FCMavlinkMissionItemsModel(QObject *parent)
    :  QAbstractListModel(parent)
{
    connect(this, &FCMavlinkMissionItemsModel::signal_qt_ui_update_element, this, &FCMavlinkMissionItemsModel::qt_ui_update_element);
    connect(this, &FCMavlinkMissionItemsModel::signal_qt_ui_resize, this, &FCMavlinkMissionItemsModel::qt_ui_resize);
}

FCMavlinkMissionItemsModel& FCMavlinkMissionItemsModel::instance()
{
    static FCMavlinkMissionItemsModel instance;
    return instance;
}


void FCMavlinkMissionItemsModel::p_initialize(int total_mission_count)
{
    emit signal_qt_ui_resize(total_mission_count);
}

void FCMavlinkMissionItemsModel::p_update(int mission_index, double lat, double lon, double alt_m)
{
    emit signal_qt_ui_update_element(mission_index,lat,lon,alt_m,false);
}


int FCMavlinkMissionItemsModel::rowCount( const QModelIndex& parent) const
{
    if (parent.isValid())
        return 0;

    return m_data.count();
}

QVariant FCMavlinkMissionItemsModel::data(const QModelIndex &index, int role) const
{
    //qDebug()<<"FCMavlinkMissionItemsModel::data at "<<index<<" Role:"<<role;
    if ( !index.isValid() ){
        //qDebug()<<"invalid index";
        return QVariant();
    }

    const FCMavlinkMissionItemsModel::Element &data = m_data.at(index.row());
    if ( role == LatitudeRole ){
        return data.latitude;
    }else if ( role == LongitudeRole ){
        return data.longitude;
    }else if ( role == AltitudeRole ){
        return data.altitude_meter;
    }else if (role==IndexRole){
        return data.mission_index;
    }else if (role==ValidRole){
        return data.valid;
    }else if (role==CurrentlyActiveRole){
        return data.currently_active;
    }
    else
        return QVariant();
}

QHash<int, QByteArray> FCMavlinkMissionItemsModel::roleNames() const
{
    static QHash<int, QByteArray> mapping {
        {IndexRole, "index"},
        {LatitudeRole, "latitude"},
        {LongitudeRole, "longitude"},
        {AltitudeRole, "altitude_m"},
        {ValidRole, "valid"},
        {CurrentlyActiveRole, "currently_active"},
    };
    return mapping;
}

void FCMavlinkMissionItemsModel::addData(FCMavlinkMissionItemsModel::Element data)
{
    //qDebug()<<"FCMavlinkMissionItemsModel::addData"<<data.latitude<<","<<data.longitude<<","<<data.mission_index;
    beginInsertRows(QModelIndex(), rowCount(), rowCount());
    m_data.push_back(data);
    endInsertRows();
}

void FCMavlinkMissionItemsModel::updateData(int row,FCMavlinkMissionItemsModel::Element data)
{
    if (row < 0 || row >= m_data.count()){
        qDebug()<<"row out of bounds"<<row;
        return;
    }
    m_data[row]=data;
    QModelIndex topLeft = createIndex(row,0);
    emit dataChanged(topLeft, topLeft);
}

void FCMavlinkMissionItemsModel::qt_ui_update_element(int mission_index,double lat,double lon,double alt_m,bool currently_active)
{
    //qDebug()<<"FCMavlinkMissionItemsModel:::qt_ui_update_element:"<<mission_index;
    updateData(mission_index,FCMavlinkMissionItemsModel::Element{mission_index,lat,lon,alt_m,true,currently_active});
}

void FCMavlinkMissionItemsModel::qt_ui_resize(int total_mission_count)
{
    //qDebug()<<"FCMavlinkMissionItemsModel:::qt_ui_resize:"<<total_mission_count;
    beginResetModel();
    m_data.resize(0);
    endResetModel();
    for(int i=0;i<total_mission_count;i++){
        auto element=FCMavlinkMissionItemsModel::Element{i,0,0,0,false};
        addData(element);
    }
}

