#ifndef XPARAM_H
#define XPARAM_H

#include <chrono>
#include <list>
#include <mutex>
#include <optional>
#include <thread>

#include "../util/mavlink_include.h"

class XParam
{
public:
    XParam();
    /**
     * returns true if this message has been consumed, false otherwise.
     */
    bool process_message(const mavlink_message_t& msg);
public:
    struct SetParamResult{
        // Response from the recipient, if there is any (otherwise, the message got lost on each re-transmit)
        std::optional<mavlink_param_ext_ack_t> response;
        // How often this command was transmitted until success / failure
        int n_transmissions=-1;
    };
    typedef std::function<void(SetParamResult result)> RESULT_CB;
    bool try_set_param_async(const mavlink_param_ext_set_t cmd,RESULT_CB result,std::chrono::milliseconds retransmit_delay=std::chrono::milliseconds(500),int n_wanted_retransmissions=3);

    struct GetAllParamResult{
        // Full server param set on success, empty param set otherwise
        std::vector<mavlink_param_ext_value_t> param_set;
    };
    typedef std::function<void(GetAllParamResult result)> RESULT_CB_GET_ALL;
    bool try_get_param_all_async(const mavlink_param_ext_request_list_t cmd,RESULT_CB_GET_ALL result_cb);
private:
    std::mutex m_mutex;
    // A currently active set param action
    struct RunningParamCmdSet{
        mavlink_param_ext_set_t cmd;
        RESULT_CB cb;
        // How often this command should be retransmitted
        int n_wanted_retransmissions;
        // Delay between each retransmission
        std::chrono::milliseconds retransmit_delay;
        // How often this command has already been sent
        int n_transmissions=0;
        // last time it was sent
        std::chrono::steady_clock::time_point last_transmission=std::chrono::steady_clock::now();
    };
    // A currently active get all params action
    struct RunningParamCmdGetAll{
        mavlink_param_ext_request_list_t base_cmd;
        RESULT_CB_GET_ALL cb;
        std::chrono::milliseconds max_delay_until_timeout;
        std::chrono::milliseconds retransmit_delay;
        std::chrono::steady_clock::time_point last_transmission=std::chrono::steady_clock::now();
        std::vector<std::optional<mavlink_param_ext_value_t>> server_param_set;
    };

    bool handle_param_set_ack(const mavlink_param_ext_ack_t& ack,int sender_sysid,int sender_compid);
    bool handle_param_ext_value(const mavlink_param_ext_value_t& response,int sender_sysid,int sender_compid);

    // searches for a Running param set command that matches the given param ack
    // if found, remove the command and return it.
    // ootherwise, return nullopt
    std::optional<RunningParamCmdSet> find_remove_running_command_threadsafe(const mavlink_param_ext_ack_t& ack,int sender_sysid,int sender_compid);
    //
    //
    mavlink_message_t pack_command_msg(const mavlink_param_ext_set_t& cmd);
    void send_set_param(RunningParamCmdSet& cmd);
    void send_get_all(RunningParamCmdGetAll& cmd);
    void send_param_ext_request_list(const mavlink_param_ext_request_list_t& cmd);
    void send_param_ext_request_read(const mavlink_param_ext_request_read_t& cmd);
    static int get_missing_count(const std::vector<std::optional<mavlink_param_ext_value_t>>& server_param_set);
private:
    std::list<RunningParamCmdSet> m_running_commands;
    std::list<RunningParamCmdGetAll> m_running_get_all;
    static constexpr auto MAX_N_SIMULTANOEUS_COMMANDS=5;
private:
    std::unique_ptr<std::thread> m_timeout_thread;
    void loop_timeout();
    void check_timeout_param_set();
    void check_timeout_param_get_all();
};

#endif // XPARAM_H
