#ifndef QOPENHDMAVLINKHELPER_H
#define QOPENHDMAVLINKHELPER_H

#include <chrono>
#include <qsettings.h>
#include <QByteArray>
#include <sstream>
#include "mavlink_include.h"

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
static uint8_t get_own_sys_id(){
    QSettings settings;
    // NOTE: QGroundControll also uses a sys id of 255 - we need a hard coded 255 sys id for the rc channels override hack in openhd
    // (And in general, for now, you should never have 2 GCS open at the same time connected to OpenHD anyways)
    const int qopenhd_mavlink_sysid = settings.value("qopenhd_mavlink_sysid", 255).toInt();
    return qopenhd_mavlink_sysid;
}

// Return: the mavlink comonent id of QOpenHD. We are basicalyy a mission planner lke QGroundControll, just with a slightly different feature set.
static uint8_t get_own_comp_id(){
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
