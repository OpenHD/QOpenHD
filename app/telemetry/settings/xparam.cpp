#include "xparam.h"
#include "util/qopenhdmavlinkhelper.hpp"

#include <sstream>

#include <qdebug.h>
#include "../MavlinkTelemetry.h"

XParam::XParam()
{
    m_timeout_thread=std::make_unique<std::thread>([this](){
        loop_timeout();
    });
}

bool XParam::process_message(const mavlink_message_t &msg)
{
    if(msg.msgid==MAVLINK_MSG_ID_PARAM_EXT_ACK){
        mavlink_param_ext_ack_t ack;
        mavlink_msg_param_ext_ack_decode(&msg,&ack);
        return handle_param_set_ack(ack,msg.sysid,msg.compid);
    }else if(msg.msgid==MAVLINK_MSG_ID_PARAM_EXT_VALUE){
        mavlink_param_ext_value_t response;
        mavlink_msg_param_ext_value_decode(&msg,&response);
        return handle_param_ext_value(response,msg.sysid,msg.compid);
    }
    return false;
}

bool XParam::try_set_param_async(const mavlink_param_ext_set_t cmd, RESULT_CB result_cb, std::chrono::milliseconds retransmit_delay, int n_wanted_retransmissions)
{
    assert(n_wanted_retransmissions>=1);
    assert(retransmit_delay.count()>=10);
    if(!result_cb){
        // the cb must not be nullptr
        qDebug()<<"No result cb,using dummy";
        auto dummy_cb=[](SetParamResult result){
            //qDebug()<<run_command_result_as_string(result).c_str();
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
    RunningParamCmdSet running_cmd{cmd,result_cb,n_wanted_retransmissions,retransmit_delay};
    m_running_commands.push_back(running_cmd);
    send_set_param(m_running_commands.back());
    return true;
}

bool XParam::try_get_param_all_async(const mavlink_param_ext_request_list_t cmd, RESULT_CB_GET_ALL result_cb)
{
    if(!result_cb){
        // the cb must not be nullptr
        qDebug()<<"No result cb,using dummy";
        auto dummy_cb=[](GetAllParamResult result){
            //qDebug()<<run_command_result_as_string(result).c_str();
        };
        result_cb=dummy_cb;
    }
    std::lock_guard<std::mutex> lock(m_mutex);
    RunningParamCmdGetAll running{cmd,result_cb,std::chrono::milliseconds(3000),std::chrono::milliseconds(100),std::chrono::steady_clock::now(),{}};
}


bool XParam::handle_param_set_ack(const mavlink_param_ext_ack_t &ack,int sender_sysid,int sender_compid)
{
    auto opt_running_cmd_set=find_remove_running_command_threadsafe(ack,sender_sysid,sender_compid);
    if(opt_running_cmd_set.has_value()){
        auto running_cmd_set=opt_running_cmd_set.value();
        SetParamResult result{ack,running_cmd_set.n_transmissions};
        running_cmd_set.cb(result);
        return true;
    }
    return false;
}

bool XParam::handle_param_ext_value(const mavlink_param_ext_value_t &response, int sender_sysid, int sender_compid)
{
    std::lock_guard<std::mutex> lock(m_mutex);
    for (auto it=m_running_get_all.begin(); it!=m_running_get_all.end(); ++it){
        RunningParamCmdGetAll& running=*it;
        if(running.base_cmd.target_system==sender_sysid && running.base_cmd.target_component==sender_compid){
            // The response fromt the server can be cosumed by a running "Get all params" action
            if(response.param_count<=0){
                qWarning()<<"Invalid param count";
                return false;
            }
            if(response.param_index>=response.param_count){
                qWarning()<<"Invalid param index";
                return false;
            }
            if(running.server_param_set.empty()){
                // Size is not yet known
                running.server_param_set.resize(response.param_count);
                running.server_param_set[response.param_index]=response;
            }else{
                // Size is known, check if we already have this param
                if(running.server_param_set[response.param_index]!=std::nullopt){
                    // we already have this param - nothing to do, we could validate it though
                    return true;
                }else{
                    running.server_param_set[response.param_index]=response;
                    const int missing=get_missing_count(running.server_param_set);
                    if(missing==0){
                        // We have all the params from this server
                        std::vector<mavlink_param_ext_value_t> valid_param_set;
                        for(auto& param:running.server_param_set){
                            assert(param.has_value());
                            valid_param_set.push_back(param.value());
                        }
                        GetAllParamResult result{valid_param_set};
                        RunningParamCmdGetAll tmp_copy=running;
                        m_running_get_all.erase(it);
                        tmp_copy.cb(result);
                    }
                }
            }
        }
    }
}


std::optional<XParam::RunningParamCmdSet> XParam::find_remove_running_command_threadsafe(const mavlink_param_ext_ack_t &ack,int sender_sysid,int sender_compid)
{
    std::lock_guard<std::mutex> lock(m_mutex);
    for (auto it=m_running_commands.begin(); it!=m_running_commands.end(); ++it){
        const auto& running=*it;
        const auto& cmd=running.cmd;
        if(cmd.param_id==ack.param_id && cmd.param_type==ack.param_type && cmd.target_system==sender_sysid && cmd.target_component==sender_compid){
            RunningParamCmdSet tmp=*it;
            m_running_commands.erase(it);
            return tmp;
        }
    }
    return std::nullopt;
}

mavlink_message_t XParam::pack_command_msg(const mavlink_param_ext_set_t &cmd)
{
    const auto self_sysid=QOpenHDMavlinkHelper::get_own_sys_id();
    const auto self_compid=QOpenHDMavlinkHelper::get_own_comp_id();
    mavlink_message_t msg{};
    mavlink_msg_param_ext_set_encode(self_sysid,self_compid,&msg,&cmd);
    return msg;
}

void XParam::send_set_param(RunningParamCmdSet &cmd)
{
    auto msg=pack_command_msg(cmd.cmd);
    MavlinkTelemetry::instance().sendMessage(msg);
    cmd.last_transmission=std::chrono::steady_clock::now();
    cmd.n_transmissions++;
}

void XParam::send_get_all(RunningParamCmdGetAll& running_cmd)
{
    if(running_cmd.server_param_set.size()==0){
        // No message ever received yet, size not yet known
        send_param_ext_request_list(running_cmd.base_cmd);
    }else{
        // We know how many params the server provides, request until we have all of them
        assert(running_cmd.server_param_set.size()>0);
        const int n_missing=get_missing_count(running_cmd.server_param_set);
        if(n_missing >= running_cmd.server_param_set.size()/2){
            // A lot are stil missing, request them all again
            send_param_ext_request_list(running_cmd.base_cmd);
        }else{
            // Request up to X specific missing cmds at a time
            for(int i=0;i<10 && i<running_cmd.server_param_set.size();i++){
                mavlink_param_ext_request_read_t cmd{};
                cmd.param_index=i;
                cmd.target_system=running_cmd.base_cmd.target_system;
                cmd.target_component=running_cmd.base_cmd.target_component;
                send_param_ext_request_read(cmd);
            }
        }
    }
}

void XParam::send_param_ext_request_list(const mavlink_param_ext_request_list_t& cmd)
{
    const auto self_sysid=QOpenHDMavlinkHelper::get_own_sys_id();
    const auto self_compid=QOpenHDMavlinkHelper::get_own_comp_id();
    mavlink_message_t msg{};
    mavlink_msg_param_ext_request_list_encode(self_sysid,self_compid,&msg,&cmd);
    MavlinkTelemetry::instance().sendMessage(msg);
}

void XParam::send_param_ext_request_read(const mavlink_param_ext_request_read_t &cmd)
{
    const auto self_sysid=QOpenHDMavlinkHelper::get_own_sys_id();
    const auto self_compid=QOpenHDMavlinkHelper::get_own_comp_id();
    mavlink_message_t msg{};
    mavlink_msg_param_ext_request_read_encode(self_sysid,self_compid,&msg,&cmd);
    MavlinkTelemetry::instance().sendMessage(msg);
}

int XParam::get_missing_count(const std::vector<std::optional<mavlink_param_ext_value_t> > &server_param_set)
{
    int ret=0;
    for(const auto& param:server_param_set){
        if(!param.has_value())ret++;
    }
    return ret;
}

void XParam::loop_timeout()
{
    while(true){
        std::this_thread::sleep_for(std::chrono::milliseconds(100));
        check_timeout_param_get_all();
        check_timeout_param_set();
    }
}

void XParam::check_timeout_param_set()
{
    std::lock_guard<std::mutex> lock(m_mutex);
    for (auto it=m_running_commands.begin(); it!=m_running_commands.end(); ++it){
        RunningParamCmdSet& running_cmd=*it;
        const auto elapsed=std::chrono::steady_clock::now()-running_cmd.last_transmission;
        if(elapsed>running_cmd.retransmit_delay){
            qDebug()<<"Param cmd set timeout";
            if(running_cmd.n_transmissions<running_cmd.n_wanted_retransmissions){
                qDebug()<<"Param cmd retransmit "<<running_cmd.n_transmissions;
                send_set_param(running_cmd);
            }else{
                qDebug()<<"Timeout after "<<running_cmd.n_transmissions<<" transmissions";
                SetParamResult result{std::nullopt,running_cmd.n_transmissions};
                running_cmd.cb(result);
                it=m_running_commands.erase(it);
            }
        }
    }
}

void XParam::check_timeout_param_get_all()
{

}
