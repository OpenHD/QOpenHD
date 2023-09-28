#include "fcmsgintervalhandler.h"

#include "create_cmd_helper.hpp"

#include "../../logging/hudlogmessagesmodel.h"
#include "impl/cmdsender.h"
#include "../MavlinkTelemetry.h"

FCMsgIntervalHandler &FCMsgIntervalHandler::instance()
{
    static FCMsgIntervalHandler instance;
    return instance;
}

void FCMsgIntervalHandler::opt_send_messages(){
    QSettings settings;
    const bool set_mavlink_message_rates = settings.value("set_mavlink_message_rates",true).toBool();
    if(!set_mavlink_message_rates){
        return;
    }
    std::lock_guard<std::mutex> lock(m_mutex);
    if(m_ready_for_next_command){
        // last command was set successfully
        if(m_next_rate_index<m_intervals.size()){
            // queue up the next set rate cmd
            const auto interval=m_intervals.at(m_next_rate_index);
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
            const auto fc_id=MavlinkTelemetry::instance().get_fc_mav_id();
            auto command=cmd::helper::create_cmd_set_msg_interval(fc_id.sys_id,fc_id.comp_id,interval.msg_id,interval_us);
            auto cb=[this](CmdSender::RunCommandResult result){
                std::lock_guard<std::mutex> lock(m_mutex);
                if(result.is_accepted()){
                    qDebug()<<"Succesfully set rate number"<<m_next_rate_index;
                    // success
                    m_ready_for_next_command=true;
                }else{
                    // failure
                    HUDLogMessagesModel::instance().add_message_warning("Cannot set FC message interval(s)");
                    m_ready_for_next_command=false;
                }
            };
            // We try setting each rate up to 20 times - we only send the command as long as the FC is active (we receive data from it)
            // so we don't need to worry about the case where we start before the FC is connected.
            const bool enqueue_success=CmdSender::instance().send_command_long_async(command,cb,std::chrono::milliseconds(500),20);
            if(enqueue_success){
                m_ready_for_next_command=false;
                m_next_rate_index++;
            }else{
                qDebug()<<"Cannot enqueue set rate cmd";
            }
        }else{
            // we are done
            HUDLogMessagesModel::instance().add_message_info("FC message interval(s) set");
            m_ready_for_next_command=false;
        }
    }
}

void FCMsgIntervalHandler::restart(){
    std::lock_guard<std::mutex> lock(m_mutex);
    // Sets the state to 0, again set all the rate(s) again -
    // Needed if the user changes any rate
    m_next_rate_index=0;
    m_ready_for_next_command=true;
}


