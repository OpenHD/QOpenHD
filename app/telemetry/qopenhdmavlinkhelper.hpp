#ifndef QOPENHDMAVLINKHELPER_H
#define QOPENHDMAVLINKHELPER_H

#include <chrono>
#include <qsettings.h>
#include <openhd/mavlink.h>

namespace QOpenHDMavlinkHelper{

// time in us, for mavlink
static uint64_t getTimeMicroseconds(){
    const auto time=std::chrono::steady_clock::now().time_since_epoch();
    return std::chrono::duration_cast<std::chrono::microseconds>(time).count();
}

// Return: The mavlink sys id of QOpenHD. By default, same as QGroundControl. However, in case one uses multiple ground controlls
// with OpenHD (or QOpenHD AND QGroundCOntroll at the same time) this value needs to be changed
static uint8_t getSysId(){
    QSettings settings;
    int mavlink_sysid = settings.value("mavlink_sysid", 225).toInt();
    return mavlink_sysid;
}

static uint8_t getCompId(){
    return MAV_COMP_ID_MISSIONPLANNER;
}

// convert a mavlink message to the raw byte array that can be transmitted
static std::vector<uint8_t> mavlinkMessageToSendBuffer(const mavlink_message_t& msg){
    std::vector<uint8_t> buf(MAVLINK_MAX_PACKET_LEN);
    auto size = mavlink_msg_to_send_buffer(buf.data(), &msg);
    buf.resize(size);
    return buf;
}
}

#endif // QOPENHDMAVLINKHELPER_H
