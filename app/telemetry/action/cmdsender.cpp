#include "cmdsender.h"

#include <qdebug.h>

#include "../util/qopenhdmavlinkhelper.hpp"
#include "../MavlinkTelemetry.h"
#include "util/mavlink_enum_to_string.h"
#include <future>

CmdSender::CmdSender()
{
    m_timeout_thread=std::make_unique<std::thread>([this](){
        loop_timeout();
    });
}

CmdSender &CmdSender::instance()
{
    static CmdSender instance;
    return instance;
}

bool CmdSender::process_message(const mavlink_message_t &msg)
{
    if(msg.msgid==MAVLINK_MSG_ID_COMMAND_ACK){
        mavlink_command_ack_t ack;
        mavlink_msg_command_ack_decode(&msg,&ack);
        const auto self_sysid=QOpenHDMavlinkHelper::get_own_sys_id();
        const auto self_compid=QOpenHDMavlinkHelper::get_own_comp_id();
        if(ack.target_system==self_sysid && ack.target_component==self_compid){
            return handle_cmd_ack(ack);
        }else{
            qDebug()<<"Got cmd ack for someone else "<<(int)ack.target_system<<":"<<(int)ack.target_component;
            return false;
        }
    }
    return false;
}


bool CmdSender::send_command_long_async(mavlink_command_long_t cmd, RESULT_CB result_cb,std::chrono::milliseconds retransmit_delay,int n_wanted_retransmissions)
{
    if(!result_cb){
        qDebug()<<"No result cb,using dummy";
        auto dummy_cb=[](RunCommandResult result){
            qDebug()<<run_command_result_as_string(result).c_str();
        };
        result_cb=dummy_cb;
    }
    std::lock_guard<std::mutex> lock(m_mutex);
    if(m_running_commands.size()>=MAX_N_SIMULTANOEUS_COMMANDS){
        std::stringstream ss;
        ss<<"cannot enqueue, curr:"<<m_running_commands.size()<<" max:"<<MAX_N_SIMULTANOEUS_COMMANDS;
        qDebug()<<ss.str().c_str();
        return false;
    }
    RunningCommand running_cmd{cmd,result_cb,n_wanted_retransmissions,retransmit_delay};
    m_running_commands.push_back(running_cmd);
    send_command(m_running_commands.back());
    return true;
}

CmdSender::Result CmdSender::send_command_long_blocking(const mavlink_command_long_t cmd,std::chrono::milliseconds retransmit_delay,int n_wanted_retransmissions)
{
    const std::chrono::milliseconds max_delay=retransmit_delay*n_wanted_retransmissions;
    qDebug()<<"Blocking for up to "<<max_delay.count()<<"ms";
    std::promise<CmdSender::Result> prom;
    auto fut = prom.get_future();
    auto cb=[&prom](RunCommandResult result){
        //qDebug()<<run_command_result_as_string(result).c_str();
        if(!result.opt_ack.has_value()){
            prom.set_value(CmdSender::NO_RESPONSE);
        }else{
            const auto ack=result.opt_ack.value();
            if(ack.result==MAV_RESULT_ACCEPTED){
                prom.set_value(CmdSender::CMD_SUCCESS);
            }else{
                prom.set_value(CmdSender::CMD_DENIED);
            }
        }
    };
    send_command_long_async(cmd,cb,retransmit_delay,n_wanted_retransmissions);
    return fut.get();
}

bool CmdSender::handle_cmd_ack(const mavlink_command_ack_t &ack)
{
    std::lock_guard<std::mutex> lock(m_mutex);
    auto opt_running_command=find_remove_running_command(ack.command);
    if(opt_running_command.has_value()){
        auto running_command=opt_running_command.value();
        RunCommandResult result{ack,running_command.n_transmissions};
        running_command.cb(result);
        return true;
    }
    qDebug()<<"Got ACK for non-existing command";
    return false;
}

void CmdSender::handle_timeout()
{
    std::lock_guard<std::mutex> lock(m_mutex);
    for (auto it=m_running_commands.begin(); it!=m_running_commands.end(); ++it){
        RunningCommand& cmd=*it;
        const auto elapsed=std::chrono::steady_clock::now()-cmd.last_transmission;
        if(elapsed>std::chrono::milliseconds(500)){
            qDebug()<<"CMD Timeout";
            if(cmd.n_transmissions<cmd.n_wanted_retransmissions){
                qDebug()<<"Retransmit cmd "<<cmd.n_transmissions;
                send_command(cmd);
            }else{
                qDebug()<<"Timeout after "<<cmd.n_transmissions<<" transmissions";
                RunCommandResult result{std::nullopt,cmd.n_transmissions};
                cmd.cb(result);
                it=m_running_commands.erase(it);
            }
        }
    }
}

std::optional<CmdSender::RunningCommand> CmdSender::find_remove_running_command(int command_id)
{
    for (auto it=m_running_commands.begin(); it!=m_running_commands.end(); ++it){
        const RunningCommand& cmd=*it;
        if(cmd.cmd.command==command_id){
            RunningCommand tmp=cmd;
            m_running_commands.erase(it);
            return tmp;
        }
    }
    return std::nullopt;
}

void CmdSender::send_command(RunningCommand &cmd)
{
    auto msg=pack_command_msg(cmd.cmd);
    MavlinkTelemetry::instance().sendMessage(msg);
    cmd.last_transmission=std::chrono::steady_clock::now();
    cmd.n_transmissions++;
    cmd.cmd.confirmation=cmd.n_transmissions;
}

mavlink_message_t CmdSender::pack_command_msg(const mavlink_command_long_t &cmd)
{
    const auto self_sysid=QOpenHDMavlinkHelper::get_own_sys_id();
    const auto self_compid=QOpenHDMavlinkHelper::get_own_comp_id();
    mavlink_message_t msg{};
    mavlink_msg_command_long_encode(self_sysid,self_compid,&msg,&cmd);
    return msg;
}

void CmdSender::loop_timeout()
{
    while(true){
        std::this_thread::sleep_for(std::chrono::milliseconds(100));
        handle_timeout();
    }
}

std::string CmdSender::run_command_result_as_string(const RunCommandResult& res)
{
    std::stringstream ss;
    if(!res.opt_ack.has_value()){
        ss<<"No ack after "<<res.n_transmissions<<" tries";
    }else{
        ss<<"Ack after "<<res.n_transmissions<<" tries,"<<qopenhd::mavlink_command_ack_to_string(res.opt_ack.value());
    }
    return ss.str();
}
