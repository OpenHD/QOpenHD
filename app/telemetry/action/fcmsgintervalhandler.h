#ifndef FCMSGINTERVALHANDLER_H
#define FCMSGINTERVALHANDLER_H

#include <mutex>
#include <qdebug.h>
#include <vector>
#include <optional>
#include <qsettings.h>

#include "../util/mavlink_include.h"


/**
 * We need to manually request / set the message interval(s) for specific messages on ardupilot
 * (It doesn't send them by default).
 * The way this works is not ideal in regards to reliability - but I implemented a similar pattern like QGroundControl here.
 * Basically, call create_command_if_needed() and check_acknowledgement() every time a msg from the FC is received
 * and at some point in the future, all rates should be set succesfully in almost all cases.
 */
class FCMsgIntervalHandler{
public:
    static FCMsgIntervalHandler& instance();
    // should be called every time a message from the FC is received,this handler takes care of not polluting the link.
    void opt_send_messages();
    // should be called every time a message from the FC is received
    void check_acknowledgement(const mavlink_message_t &msg);
    // re-apply all rates
    void restart();
private:
    struct MessageInterval{
        // for which message
        int msg_id;
        // interval in hertz
        int interval_hz;
    };
    std::optional<mavlink_command_long_t> create_command_if_needed();

private:
    static constexpr int RATE_LOW=1; // Once per second
    static constexpr int RATE_MEDIUM=5; // 5 times per second
    // Intervals are in Hertz
    std::vector<MessageInterval> m_intervals={
        MessageInterval{MAVLINK_MSG_ID_SYS_STATUS,2}, // battery and more
        MessageInterval{MAVLINK_MSG_ID_SYSTEM_TIME,1},
        MessageInterval{MAVLINK_MSG_ID_GPS_RAW_INT,1}, // we get hdop, vdop, usw from this - not lat /long though (they are from global position int,aka fused)
        MessageInterval{MAVLINK_MSG_ID_ATTITUDE,30},
        MessageInterval{MAVLINK_MSG_ID_GLOBAL_POSITION_INT,2},
        MessageInterval{MAVLINK_MSG_ID_RC_CHANNELS,2},
        //MessageInterval{MAVLINK_MSG_ID_GPS_GLOBAL_ORIGIN,0},
        MessageInterval{MAVLINK_MSG_ID_VFR_HUD,2}, //(air) speed, climb, ...
        MessageInterval{MAVLINK_MSG_ID_BATTERY_STATUS,1},
        MessageInterval{MAVLINK_MSG_ID_HOME_POSITION,1},
        MessageInterval{ MAVLINK_MSG_ID_WIND,1},
        MessageInterval{MAVLINK_MSG_ID_AOA_SSA,1},
        MessageInterval{MAVLINK_MSG_ID_SCALED_PRESSURE,1},
        MessageInterval{MAVLINK_MSG_ID_MISSION_CURRENT,1},
        //MessageInterval{MAVLINK_MSG_ID_MISSION_COUNT,1}, Doesn't work broadcast
        // NOTE: We cannot set broadcast on this one !
        //MessageInterval{MAVLINK_MSG_ID_MISSION_ITEM_INT,1},
        //MessageInterval{0,0},
        //MessageInterval{0,0},
        };
    std::mutex m_mutex;
    int m_last_successfully_set_rate=0;
    int m_n_times_already_sent=0;
    bool logged_once_fail=false;
    bool logged_once_success=false;
    std::chrono::steady_clock::time_point m_last_command=std::chrono::steady_clock::now();
};

#endif // FCMSGINTERVALHANDLER_H
