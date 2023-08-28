#ifndef FCMESSAGEINTERVALHELPER_H
#define FCMESSAGEINTERVALHELPER_H

#include <mutex>
#include <qdebug.h>
#include <vector>
#include <optional>
#include <qsettings.h>
#include "../../logging/hudlogmessagesmodel.h"

#include "../util/mavsdk_include.h"
#include "util/qopenhdmavlinkhelper.hpp"

/**
 * We need to manually request / set the message interval(s) for specific messages on ardupilot
 * (It doesn't send them by default).
 * The way this works is not ideal in regards to reliability - but I implemented a similar pattern like QGroundControl here.
 * Basically, call create_command_if_needed() and check_acknowledgement() every time a msg from the FC is received
 * and at some point in the future, all rates should be set succesfully in almost all cases.
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
        std::lock_guard<std::mutex> lock(m_mutex);
        // Can be disabled by the user
        QSettings settings;
        const bool set_mavlink_message_rates = settings.value("set_mavlink_message_rates",true).toBool();
        const bool mavlink_message_rates_high_speed=settings.value("mavlink_message_rates_high_speed",false).toBool();
        const bool mavlink_message_rates_high_speed_rc_channels=settings.value("mavlink_message_rates_high_speed_rc_channels",false).toBool();
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
            auto interval_hz=interval.interval_hz;
            if(mavlink_message_rates_high_speed_rc_channels && interval.msg_id==MAVLINK_MSG_ID_RC_CHANNELS){
                interval_hz=15;
            }
            if(mavlink_message_rates_high_speed){
                interval_hz*=2;
            }
            const auto interval_us=1000*1000/interval_hz;
            auto command=create_cmd_set_msg_interval(interval.msg_id,interval_us);
            m_n_times_already_sent++;
            qDebug()<<"Requesting rate "<<(int)interval.msg_id;
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
        std::lock_guard<std::mutex> lock(m_mutex);
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
    void restart(){
        std::lock_guard<std::mutex> lock(m_mutex);
        // Sets the state to 0, again set all the rate(s) again -
        // Needed if the user changes any rate
        m_last_successfully_set_rate=0;
        m_n_times_already_sent=0;
        logged_once_fail=false;
        logged_once_success=false;
        m_last_command=std::chrono::steady_clock::now();
    }
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

#endif // FCMESSAGEINTERVALHELPER_H
