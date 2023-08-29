#include "fcmsgintervalhandler.h"

#include "create_cmd_helper.hpp"
#include "util/qopenhdmavlinkhelper.hpp"
#include "util/mavlink_enum_to_string.h"

#include "../../logging/hudlogmessagesmodel.h"

FCMsgIntervalHandler &FCMsgIntervalHandler::instance()
{
    static FCMsgIntervalHandler instance;
    return instance;
}

void FCMsgIntervalHandler::opt_send_messages(){
    const auto opt_command=create_command_if_needed();
    if(opt_command.has_value()){
        // TODO
    }
}

void FCMsgIntervalHandler::check_acknowledgement(const mavlink_message_t &msg){
    std::lock_guard<std::mutex> lock(m_mutex);
    if(msg.msgid==MAVLINK_MSG_ID_COMMAND_ACK){
        mavlink_command_ack_t ack;
        mavlink_msg_command_ack_decode(&msg,&ack);
        if(ack.command==MAV_CMD_SET_MESSAGE_INTERVAL && ack.result==MAV_RESULT_ACCEPTED &&
            ack.target_system== QOpenHDMavlinkHelper::get_own_sys_id()){
            qDebug()<<"Message interval acknowledged "<<m_last_successfully_set_rate;
            qDebug()<<qopenhd::mavlink_command_ack_to_string(ack).c_str();
            // request the next message interval if needed
            m_last_successfully_set_rate++;
            m_n_times_already_sent=0;
        }
    }
}

void FCMsgIntervalHandler::restart(){
    std::lock_guard<std::mutex> lock(m_mutex);
    // Sets the state to 0, again set all the rate(s) again -
    // Needed if the user changes any rate
    m_last_successfully_set_rate=0;
    m_n_times_already_sent=0;
    logged_once_fail=false;
    logged_once_success=false;
    m_last_command=std::chrono::steady_clock::now();
}

std::optional<mavlink_command_long_t> FCMsgIntervalHandler::create_command_if_needed(){
    std::lock_guard<std::mutex> lock(m_mutex);
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
        auto interval_hz=interval.interval_hz;
        const bool mavlink_message_rates_high_speed=settings.value("mavlink_message_rates_high_speed",false).toBool();
        const bool mavlink_message_rates_high_speed_rc_channels=settings.value("mavlink_message_rates_high_speed_rc_channels",false).toBool();
        if(mavlink_message_rates_high_speed_rc_channels && interval.msg_id==MAVLINK_MSG_ID_RC_CHANNELS){
            interval_hz=15;
        }
        if(mavlink_message_rates_high_speed){
            interval_hz*=2;
        }
        const auto interval_us=1000*1000/interval_hz;
        const auto fc_sys_id=1;
        const auto fc_comp_id=MAV_COMP_ID_AUTOPILOT1;
        auto command=cmd::helper::create_cmd_set_msg_interval(fc_sys_id,fc_comp_id,interval.msg_id,interval_us);
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
