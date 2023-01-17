#ifndef QOPENHDMAVLINKHELPER_H
#define QOPENHDMAVLINKHELPER_H

#include <chrono>
#include <qsettings.h>
#include "mavsdk_include.h"
#include <QByteArray>
#include <sstream>

namespace QOpenHDMavlinkHelper{

// time in us, for mavlink
static uint64_t getTimeMicroseconds(){
    const auto time=std::chrono::steady_clock::now().time_since_epoch();
    return std::chrono::duration_cast<std::chrono::microseconds>(time).count();
}
// for the heartbeat
static uint64_t getTimeMilliseconds(){
    const auto time=std::chrono::steady_clock::now().time_since_epoch();
    return std::chrono::duration_cast<std::chrono::milliseconds>(time).count();
}

// Return: The mavlink sys id of QOpenHD. By default, same as QGroundControl. However, in case one uses multiple ground controlls
// with OpenHD (or QOpenHD AND QGroundCOntroll at the same time) this value needs to be changed
static uint8_t getSysId(){
    QSettings settings;
    const int qopenhd_mavlink_sysid = settings.value("qopenhd_mavlink_sysid", 225).toInt();
    return qopenhd_mavlink_sysid;
}

// Return: the mavlink comonent id of QOpenHD. We are basicalyy a mission planner lke QGroundControll, just with a slightly different feature set.
static uint8_t getCompId(){
    return MAV_COMP_ID_MISSIONPLANNER;
}

static int get_vehicle_battery_n_cells(){
    QSettings settings;
    const int vehicle_battery_n_cells = settings.value("vehicle_battery_n_cells", 3).toInt();
    return vehicle_battery_n_cells;
}
static double calclate_voltage_per_cell(double voltage){
    const auto vehicle_battery_n_cells=get_vehicle_battery_n_cells();
    // do not divide by 0
    if(vehicle_battery_n_cells>0){
        return voltage / (double) vehicle_battery_n_cells;
    }
    return vehicle_battery_n_cells;
}

// convert a mavlink message to the raw byte array that can be transmitted
static std::vector<uint8_t> mavlinkMessageToSendBuffer(const mavlink_message_t& msg){
    std::vector<uint8_t> buf(MAVLINK_MAX_PACKET_LEN);
    auto size = mavlink_msg_to_send_buffer(buf.data(), &msg);
    buf.resize(size);
    return buf;
}

static QString safe_string(const char* text,int text_size){
     QByteArray param_id(text,text_size);
     /*
      * If there's no null in the text array, the mavlink docs say it has to be exactly 50 characters,
      * so we add a null to the end and then continue. This guarantees that QString below will always find
      * a null terminator.
      *
      */
     if (!param_id.contains('\0')) {
        param_id.append('\0');
     }
     QString s(param_id.data());
     return s;
}

static QString debug_mavlink_message(const mavlink_message_t& msg){
    std::stringstream ss;
    ss<<"MavlinkMessage{id: "<<(int)msg.msgid
                           <<", sequence: "<<(int)msg.seq
                          <<" from component "<<(int)msg.compid
                         <<" of system "<<(int)msg.sysid<<"}";
    return ss.str().c_str();
}

static std::string time_microseconds_readable(int64_t micros){
    if(micros > 1000*1000){
       float seconds=micros/1000.0f/1000.0f;
       std::stringstream ss;
       ss<<seconds<<"s";
       return ss.str();
    }
    const float deltaMs=micros/1000.0f;
    std::stringstream ss;
    ss<<deltaMs<<"ms";
    return ss.str();
}

}

#endif // QOPENHDMAVLINKHELPER_H
