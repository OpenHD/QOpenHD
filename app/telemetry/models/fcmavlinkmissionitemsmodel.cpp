#include "fcmavlinkmissionitemsmodel.h"
#include "qdebug.h"

#include <qsettings.h>


FCMavlinkMissionItemsModel::FCMavlinkMissionItemsModel(QObject *parent)
    :  QAbstractListModel(parent)
{
    connect(this, &FCMavlinkMissionItemsModel::signal_qt_ui_update_element, this, &FCMavlinkMissionItemsModel::qt_ui_update_element);
    QSettings settings;
    show_map=settings.value("show_map",false).toBool();
}

FCMavlinkMissionItemsModel& FCMavlinkMissionItemsModel::instance()
{
    static FCMavlinkMissionItemsModel instance;
    return instance;
}


void FCMavlinkMissionItemsModel::update_mission(int mission_index,double lat,double lon,double alt_m,bool currently_active)
{
    // save performance if map is not enabled
    if(!show_map)return;
    emit signal_qt_ui_update_element(mission_index,lat,lon,alt_m,currently_active);
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

/*void FCMavlinkMissionItemsModel::removeData(int row)
{
    if (row < 0 || row >= m_data.count())
        return;

    //qDebug()<<"Removing "<<row;
    beginRemoveRows(QModelIndex(), row, row);
    m_data.removeAt(row);
    endRemoveRows();
}*/

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
    if(mission_index>MAX_N_ELEMENTS){
        qDebug()<<"We only support up to "<<MAX_N_ELEMENTS<<" missions:"<<mission_index;
        return;
    }
    if(mission_index<0){
        qDebug()<<"Invalid mission index "<<mission_index;
        return;
    }
    const auto n_elements=m_data.size();
    if(mission_index>=n_elements){
        // add as many (dummy) elements as we need
        for(int i=n_elements;i<=mission_index;i++){
            addData(FCMavlinkMissionItemsModel::Element{i,0,0,0,false,false});
        }
    }
    assert(mission_index<m_data.size());
    updateData(mission_index,FCMavlinkMissionItemsModel::Element{mission_index,lat,lon,alt_m,true,currently_active});
}

