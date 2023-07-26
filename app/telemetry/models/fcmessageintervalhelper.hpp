#ifndef FCMESSAGEINTERVALHELPER_H
#define FCMESSAGEINTERVALHELPER_H

#include <mutex>
#include <qdebug.h>
#include <vector>
#include "../mavsdk_include.h"
#include <optional>
#include <qsettings.h>
#include "../../logging/hudlogmessagesmodel.h"
#include "qopenhdmavlinkhelper.hpp"

/**
 * We need to manually request / set the message interval(s) for specific messages on ardupilot
 * (It doesn't send them by default).
 * The way this works is not ideal in regards to reliability - but I implemented a similar pattern like QGroundControl here.
 */
class FCMessageIntervalHelper{
public:
    struct MessageInterval{
        // for which message
        int msg_id;
        // interval in hertz
        int interval_hz;
    };
    static mavlink_command_long_t create_cmd_set_msg_interval(int msg_type,int interval_us){
        mavlink_command_long_t command{};
        command.target_system=1;
        command.target_component=0;
        command.command=MAV_CMD_SET_MESSAGE_INTERVAL;
        command.confirmation=0;
        command.param1=msg_type;
        command.param2=interval_us;
        return command;
    }
    std::optional<mavlink_command_long_t> create_command_if_needed(){
        // Can be disabled by the user
        QSettings settings;
        const bool set_mavlink_message_rates = settings.value("set_mavlink_message_rates",true).toBool();
        if(!set_mavlink_message_rates){
            return std::nullopt;
        }
        // Stop after we've tried setting a rate N times and never got an ack
        if(m_n_times_already_sent>=20){
            if(!logged_once_fail){
                HUDLogMessagesModel::instance().add_message_info("Cannot set message interval(s)");
                logged_once_fail=true;
            }
            return std::nullopt;
        }
        // Send out once every second until done
        const auto elapsed=std::chrono::steady_clock::now()-m_last_command;
        if(elapsed<std::chrono::seconds(1)){
            return std::nullopt;
        }
        m_last_command=std::chrono::steady_clock::now();
        // Set the next rate in order unless already done
        const auto tmp=m_last_successfully_set_rate;
        if(tmp<m_intervals.size()){
            // One of the intervals is not succesfully set yet
            const auto interval=m_intervals.at(tmp);
            const auto interval_us=1000*1000/interval.interval_hz;
            auto command=create_cmd_set_msg_interval(interval.msg_id,interval_us);
            m_n_times_already_sent++;
            return command;
        }else{
            if(!logged_once_success){
                HUDLogMessagesModel::instance().add_message_info("Successfully set message interval(s)");
                logged_once_success=true;
            }
        }
        return std::nullopt;
    }

    void check_acknowledgement(const mavlink_message_t &msg){
        if(msg.msgid==MAVLINK_MSG_ID_COMMAND_ACK){
            mavlink_command_ack_t ack;
            mavlink_msg_command_ack_decode(&msg,&ack);
            if(ack.command==MAV_CMD_SET_MESSAGE_INTERVAL && ack.result==MAV_RESULT_ACCEPTED &&
                ack.target_system== QOpenHDMavlinkHelper::get_own_sys_id()){
                qDebug()<<"Message interval acknowledged "<<m_last_successfully_set_rate;
                // request the next message interval if needed
                m_last_successfully_set_rate++;
                m_n_times_already_sent=0;
            }
        }
    }

private:
    static constexpr int RATE_LOW=1; // Once per second
    static constexpr int RATE_MEDIUM=5; // 5 times per second

    std::vector<MessageInterval> m_intervals={
        MessageInterval{MAVLINK_MSG_ID_SYS_STATUS,5}, // battery and more
        MessageInterval{MAVLINK_MSG_ID_SYSTEM_TIME,1},
        MessageInterval{MAVLINK_MSG_ID_GPS_RAW_INT,1}, // we get hdop, vdop, usw from this - not lat /long though (they are from global position int,aka fused)
        MessageInterval{MAVLINK_MSG_ID_ATTITUDE,30},
        MessageInterval{MAVLINK_MSG_ID_GLOBAL_POSITION_INT,10},
        MessageInterval{MAVLINK_MSG_ID_RC_CHANNELS,10},
        //MessageInterval{MAVLINK_MSG_ID_GPS_GLOBAL_ORIGIN,0},
        MessageInterval{MAVLINK_MSG_ID_VFR_HUD,1},
        MessageInterval{MAVLINK_MSG_ID_BATTERY_STATUS,2},
        MessageInterval{MAVLINK_MSG_ID_HOME_POSITION,1},
        MessageInterval{ MAVLINK_MSG_ID_WIND,1},
        //MessageInterval{0,0},
        //MessageInterval{0,0},
        //MessageInterval{0,0},
    };
    int m_last_successfully_set_rate=0;
    int m_n_times_already_sent=0;
    bool logged_once_fail=false;
    bool logged_once_success=false;
    std::chrono::steady_clock::time_point m_last_command=std::chrono::steady_clock::now();
};

#endif // FCMESSAGEINTERVALHELPER_H
