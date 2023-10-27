#include "cmdsender.h"

#include <qdebug.h>

#include "../../util/qopenhdmavlinkhelper.hpp"
#include "../../MavlinkTelemetry.h"
#include "util/mavlink_enum_to_string.h"
#include <future>

CmdSender::CmdSender()
{
    m_timeout_thread=std::make_unique<std::thread>([this](){
        loop_timeout();
    });
}

CmdSender::~CmdSender()
{
    m_timeout_thread_run=false;
    m_timeout_thread->join();
    m_timeout_thread=nullptr;
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
    assert(n_wanted_retransmissions>=1);
    assert(retransmit_delay.count()>=10);
    if(!result_cb){
        // the cb must not be nullptr
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
    //qDebug()<<"Sent command"<<m_running_commands.size();
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
    if(!send_command_long_async(cmd,cb,retransmit_delay,n_wanted_retransmissions)){
        return CmdSender::QUEUE_FULL;
    }
    auto tmp=fut.get();
    qDebug()<<"send_command_long_blocking end";
    return tmp;
}

bool CmdSender::handle_cmd_ack(const mavlink_command_ack_t &ack)
{
    // Optmization: Hold lock only when neccessary
    // We don't need to hold it while we call the result cb
    auto opt_running_command=find_remove_running_command_threadsafe(ack.command);
    if(opt_running_command.has_value()){
        auto running_command=opt_running_command.value();
        qDebug()<<"Got ack for command:"<<(int)running_command.cmd.command;
        RunCommandResult result{ack,running_command.n_transmissions};
        running_command.cb(result);
        return true;
    }
    qDebug()<<"Got ACK for non-existing command";
    return false;
}

void CmdSender::handle_timeout()
{
    // Optimization: We store the commands that timed out (being removed) temporary while we hold the lock
    // and then call their cb without the lock hold (it is a bad idea to call a cb with a lock hold)
    std::vector<std::pair<RunningCommand,RunCommandResult>> timed_out_commands{};
    {
        std::lock_guard<std::mutex> lock(m_mutex);
        //qDebug()<<"CmdSender::handle_timeou::CommandQueue"<<m_running_commands.size();
        for (auto it=m_running_commands.begin(); it!=m_running_commands.end(); ++it){
            RunningCommand& running_cmd=*it;
            const auto elapsed=std::chrono::steady_clock::now()-running_cmd.last_transmission;
            //qDebug()<<"Elapsed:"<<elapsed.count();
            if(elapsed>running_cmd.retransmit_delay){
                qDebug()<<"CMD Timeout";
                if(running_cmd.n_transmissions<running_cmd.n_wanted_retransmissions){
                    qDebug()<<"Retransmit cmd "<<running_cmd.n_transmissions;
                    send_command(running_cmd);
                }else{
                    qDebug()<<"Timeout after "<<running_cmd.n_transmissions<<" transmissions";
                    RunCommandResult result{std::nullopt,running_cmd.n_transmissions};
                    timed_out_commands.push_back(std::make_pair(running_cmd,result));
                    it=m_running_commands.erase(it);
                }
            }
        }
    }
    for(auto& timed_out:timed_out_commands){
        timed_out.first.cb(timed_out.second);
    }
}

std::optional<CmdSender::RunningCommand> CmdSender::find_remove_running_command_threadsafe(int command_id)
{
    std::lock_guard<std::mutex> lock(m_mutex);
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
    send_mavlink_command_long(cmd.cmd);
    cmd.last_transmission=std::chrono::steady_clock::now();
    cmd.n_transmissions++;
    cmd.cmd.confirmation=cmd.n_transmissions;
}

void CmdSender::send_mavlink_command_long(const mavlink_command_long_t &cmd)
{
    const auto self_sysid=QOpenHDMavlinkHelper::get_own_sys_id();
    const auto self_compid=QOpenHDMavlinkHelper::get_own_comp_id();
    mavlink_message_t msg{};
    mavlink_msg_command_long_encode(self_sysid,self_compid,&msg,&cmd);
    MavlinkTelemetry::instance().sendMessage(msg);
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
