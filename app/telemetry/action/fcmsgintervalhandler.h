#ifndef FCMSGINTERVALHANDLER_H
#define FCMSGINTERVALHANDLER_H

#include <mutex>
#include <qdebug.h>
#include <vector>
#include <optional>
#include <qsettings.h>

#include "tutil/mavlink_include.h"

/**
 * We need to manually request / set the message interval(s) for specific messages on ardupilot
 * (It doesn't send them by default).
 * The way this works is not ideal in regards to reliability - but I implemented a similar pattern like QGroundControl here.
 * Basically, we enqueue one message intervall command after each other, and stop in case one of them times out -
 * but we use a really high retransmit intervall, so if the commands time out, we should probably stop.
 */
class FCMsgIntervalHandler{
public:
    static FCMsgIntervalHandler& instance();
    // should be called every time a message from the FC is received,this handler takes care of not polluting the link.
    void opt_send_messages();
    // re-apply all rate(s)
    void restart();
private:
    struct MessageInterval{
        // for which message
        int msg_id;
        // interval in hertz
        int interval_hz;
    };
    static constexpr int RATE_LOW=1; // Once per second
    static constexpr int RATE_MEDIUM=5; // 5 times per second
    // Intervals are in Hertz
    const std::vector<MessageInterval> m_intervals={
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
    bool m_ready_for_next_command=true;
    int m_next_rate_index=0;
};

#endif // FCMSGINTERVALHANDLER_H
