#include "fcmavlinkmissionitemsmodel.h"
#include "qdebug.h"
#include "util/telemetryutil.hpp"

#include <qsettings.h>
#include "../MavlinkTelemetry.h"

FCMavlinkMissionHandler::FCMavlinkMissionHandler(QObject *parent): QObject(parent)
{
    m_mission_items.reserve(MAX_N_MISSION_ITEMS);
    m_missing_items.reserve(MAX_N_MISSION_ITEMS);
}

FCMavlinkMissionHandler &FCMavlinkMissionHandler::instance()
{
    static FCMavlinkMissionHandler instance;
    return instance;
}

void FCMavlinkMissionHandler::process_message(const mavlink_message_t &msg)
{
    switch(msg.msgid){
    case MAVLINK_MSG_ID_MISSION_CURRENT:{
        // https://mavlink.io/en/messages/common.html#MISSION_CURRENT
        mavlink_mission_current_t mission_current;
        mavlink_msg_mission_current_decode(&msg,&mission_current);
        update_mission_current(mission_current);
        break;
    }
    case MAVLINK_MSG_ID_MISSION_COUNT:{
        //qDebug()<<"Got MAVLINK_MSG_ID_MISSION_COUNT";
        // https://mavlink.io/en/messages/common.html#MISSION_COUNT
        mavlink_mission_count_t mission;
        mavlink_msg_mission_count_decode(&msg,&mission);
        update_mission_count(mission);
        break;
    }
    case MAVLINK_MSG_ID_MISSION_ITEM_INT:{
        mavlink_mission_item_int_t item;
        mavlink_msg_mission_item_int_decode(&msg, &item);
        update_mission(item);
        break;
    }
    default:
        assert(false);
    }
}

static mavlink_mission_request_list_t create_request_mission_count(){
    mavlink_mission_request_list_t command{};
    command.mission_type=MAV_MISSION_TYPE_MISSION;
    command.target_component=MAV_COMP_ID_AUTOPILOT1;
    command.target_system=1;
    return command;
}

static mavlink_message_t create_request_mission_count_msg(){
    const auto tmp=create_request_mission_count();
    mavlink_message_t message;
    const auto sys_id=QOpenHDMavlinkHelper::get_own_sys_id();
    const auto comp_id=QOpenHDMavlinkHelper::get_own_comp_id();
    mavlink_msg_mission_request_list_encode(sys_id,comp_id,&message,&tmp);
    return message;
}
static mavlink_message_t create_request_mission_msg(int sequence){
    mavlink_mission_request_int_t request{};
    request.mission_type=MAV_MISSION_TYPE_MISSION;
    request.target_component=MAV_COMP_ID_AUTOPILOT1;
    request.target_system=1;
    request.seq=sequence;
    mavlink_message_t message;
    const auto sys_id=QOpenHDMavlinkHelper::get_own_sys_id();
    const auto comp_id=QOpenHDMavlinkHelper::get_own_comp_id();
    mavlink_msg_mission_request_int_encode(sys_id,comp_id,&message,&request);
    return message;
}


void FCMavlinkMissionHandler::opt_send_messages()
{
    std::lock_guard<std::mutex> lock(m_mutex);
    if(!m_has_mission_count){
        const auto elapsed=std::chrono::steady_clock::now()-m_last_count_request;
        if(elapsed>std::chrono::seconds(1)){
            m_last_count_request=std::chrono::steady_clock::now();
            auto message=create_request_mission_count_msg();
            MavlinkTelemetry::instance().sendMessage(message);
            qDebug()<<"Requested";
        }
        return;
    }
    // check if we are missing missions
    if(!m_missing_items.empty()){
        const auto elapsed=std::chrono::steady_clock::now()-m_last_item_request;
        if(elapsed>std::chrono::seconds(1)){
            m_last_item_request=std::chrono::steady_clock::now();
            qDebug()<<"Missions missing: "<<m_missing_items.size();
            for(int i=0;i<m_missing_items.size() && i<2;i++){
                const int mission_to_request=m_missing_items[i];
                qDebug()<<"Resquesting mission:"<<mission_to_request;
                auto message=create_request_mission_msg(mission_to_request);
                MavlinkTelemetry::instance().sendMessage(message);
            }
        }
    }
}

void FCMavlinkMissionHandler::update_mission_count(const mavlink_mission_count_t& mission_count)
{
    qDebug()<<"Got MAVLINK_MSG_ID_MISSION_COUNT total:"<<mission_count.count;
    const int count=mission_count.count;
    set_mission_waypoints_current_total(count);
    set_mission_current_type(Telemetryutil::mavlink_mission_type_to_string(mission_count.mission_type));
    std::lock_guard<std::mutex> lock(m_mutex);
    if(count==m_mission_items.size()){
        qDebug()<<"Same size";
        return;
    }
    qDebug()<<"Mission count changed from "<<m_mission_items.size()<<" to "<<count;
    // Mission count has changed - this should happen rarely. We re-set the whole model in this case, and start requesting all the mission items.
    m_mission_items.resize(0);
    m_mission_items.reserve(count);
    for(int i=0;i<count;i++){
        m_mission_items.push_back(MItem{i,0,0,0,false});
    }
    m_has_mission_count=true;
    recalculate_missing();
    // update the QT UI model - this operation should happen rarely
    FCMavlinkMissionItemsModel::instance().p_initialize(count);
}

void FCMavlinkMissionHandler::update_mission(const mavlink_mission_item_int_t &mission_item)
{
     qDebug()<<"Got MAVLINK_MSG_ID_MISSION_ITEM_INT:"<<mission_item.seq;
    if(!(mission_item.frame==MAV_FRAME_GLOBAL || mission_item.frame==MAV_FRAME_GLOBAL_RELATIVE_ALT)){
        qDebug()<<"invalid mission item - wrong frame:"<<(int)mission_item.frame;
        return;
    }
    const double lat=static_cast<double>(mission_item.x)* 1e-7;
    const double lon=static_cast<double>(mission_item.y)* 1e-7;
    /*if(lat==0.0 || lon==0.0){
        qDebug()<<"invalid mission item - invalid lat/lon"<<lat<<":"<<lon;
        return;
    }*/
    const int mission_seq=mission_item.seq;
    std::lock_guard<std::mutex> lock(m_mutex);
    if(! (mission_seq>=0 && mission_seq<m_mission_items.size())){
        qDebug()<<"Invalid mission, seq:"<<mission_seq<<" curr size:"<<m_mission_items.size();
        return;
    }
    auto& item=m_mission_items[mission_item.seq];
    bool updated=false;
    if(item.latitude != lat){
        updated=true;
        item.latitude=lat;
    }
    if(item.longitude != lon){
        updated=true;
        item.longitude=lon;
    }
    item.updated=true;
    if(updated){
        qDebug()<<"Updated mission item "<<item.mission_index<<" "<<lat<<":"<<lon;
        FCMavlinkMissionItemsModel::instance().p_update(item.mission_index,item.latitude,item.longitude,item.altitude_meter);
    }
    recalculate_missing();
}

void FCMavlinkMissionHandler::update_mission_current(const mavlink_mission_current_t &mission_current)
{
    const int current_mission=mission_current.seq;
    qDebug()<<"Got MAVLINK_MSG_ID_MISSION_CURRENT seq:"<<mission_current.seq<<" total:"<<mission_current.total;
    set_mission_waypoints_current(mission_current.seq);
    //if(mission_current.total!=0){ // 0 == not supported
    //    set_mission_waypoints_current_total(mission_current.total);
    //}
    std::lock_guard<std::mutex> lock(m_mutex);
    if(!(current_mission>=0 && current_mission<=m_mission_items.size())){
        qDebug()<<"Invalid current mission "<<current_mission<<" total items:"<<m_mission_items.size();
        return;
    }
}

void FCMavlinkMissionHandler::recalculate_missing()
{
    m_missing_items.resize(0);
    for(const auto& tmp_item:m_mission_items){
        if(!tmp_item.updated){
            m_missing_items.push_back(tmp_item.mission_index);
        }
    }
    qDebug()<<"Currently missing "<<m_missing_items.size()<<" missionitems";
}



FCMavlinkMissionItemsModel::FCMavlinkMissionItemsModel(QObject *parent)
    :  QAbstractListModel(parent)
{
    connect(this, &FCMavlinkMissionItemsModel::signal_qt_ui_update_element, this, &FCMavlinkMissionItemsModel::qt_ui_update_element);
    connect(this, &FCMavlinkMissionItemsModel::signal_qt_ui_resize, this, &FCMavlinkMissionItemsModel::qt_ui_resize);
    QSettings settings;
    show_map=settings.value("show_map",false).toBool();
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
    qDebug()<<"FCMavlinkMissionItemsModel:::qt_ui_update_element:"<<mission_index;
    updateData(mission_index,FCMavlinkMissionItemsModel::Element{mission_index,lat,lon,alt_m,true,currently_active});
}

void FCMavlinkMissionItemsModel::qt_ui_resize(int total_mission_count)
{
    qDebug()<<"FCMavlinkMissionItemsModel:::qt_ui_resize:"<<total_mission_count;
    beginResetModel();
    m_data.resize(0);
    endResetModel();
    for(int i=0;i<total_mission_count;i++){
        auto element=FCMavlinkMissionItemsModel::Element{i,0,0,0,false};
        addData(element);
    }
}

