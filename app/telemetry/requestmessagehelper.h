#ifndef REQUESTMESSAGEHELPER_H
#define REQUESTMESSAGEHELPER_H

#include "mavsdk_include.h"

#include <mutex>
#include <qdebug.h>
#include <thread>

class RequestMessageHelper
{
public:
    RequestMessageHelper();


    bool request_message(const int sys_id,const int comp_id,int message_id){
        Request request{sys_id,comp_id,message_id};
        std::lock_guard<std::mutex> lock(m_mutex);
        if(m_curr_request!=std::nullopt){
            qDebug()<<"Request still ongoing";
            return false;
        }
        m_curr_request=request;
        return true;
    }

    std::optional<mavlink_message_t> get_last_requested_message(){
        std::lock_guard<std::mutex> lock(m_mutex);
        if(m_request_success!=std::nullopt){
            auto ret=m_request_success.value();
            m_request_success=std::nullopt;
            return ret;
        }
        return std::nullopt;
    }

    void handle_incoming_message(const mavlink_message_t& msg){
        std::lock_guard<std::mutex> lock(m_mutex);
        if(m_curr_request==std::nullopt){
            return;
        }
        const auto request=m_curr_request.value();
        if(message_matches_request(msg,request)){
            qDebug()<<"Got message for request";
            m_request_success=msg;
            m_curr_request=std::nullopt;
        }
    }

private:
    std::mutex m_mutex;
    struct Request{
        int target_sys_id;
        int target_comp_id;
        int message_id;
    };
    std::optional<Request> m_curr_request=std::nullopt;
    std::optional<mavlink_message_t> m_request_success=std::nullopt;

    static bool message_matches_request(const mavlink_message_t& msg,const Request& request){
        if(msg.sysid==request.target_sys_id && msg.compid==request.target_comp_id && msg.msgid==request.message_id){
            return true;
        }
        return false;
    }
};

#endif // REQUESTMESSAGEHELPER_H
