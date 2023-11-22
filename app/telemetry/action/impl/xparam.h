#ifndef XPARAM_H
#define XPARAM_H

#include <chrono>
#include <list>
#include <mutex>
#include <optional>
#include <thread>
#include <functional>
#include <vector>

#include "../../util/mavlink_include.h"

class XParam
{
public:
    explicit XParam();
    ~XParam();
    void terminate();
    static XParam& instance();
    /**
     * returns true if this message has been consumed, false otherwise.
     */
    bool process_message(const mavlink_message_t& msg);
public:
    // Progress CB - no heavy load must be performed on the progress cb,
    // as well as any try_() method since lock might be hold
    typedef std::function<void(float progress_perc)> PROGRESS_CB;

    // Not easy to use API, but exposes pretty much all info one could need
    struct SetParamResult{
        // Response from the recipient, if there is any (otherwise, the message got lost on each re-transmit)
        std::optional<mavlink_param_ext_ack_t> response;
        // How often this command was transmitted until success / failure
        int n_transmissions=-1;
        bool is_accepted(){
            return response.has_value() && response.value().param_result==PARAM_ACK_ACCEPTED;
        }
    };
    typedef std::function<void(SetParamResult result)> SET_PARAM_RESULT_CB;
    bool try_set_param_async(const mavlink_param_ext_set_t cmd,SET_PARAM_RESULT_CB result,PROGRESS_CB opt_progress_cb=nullptr,std::chrono::milliseconds retransmit_delay=std::chrono::milliseconds(500),int n_wanted_retransmissions=3);
    bool try_set_param_blocking(const mavlink_param_ext_set_t cmd,std::chrono::milliseconds retransmit_delay=std::chrono::milliseconds(500),int n_wanted_retransmissions=3);

    struct GetAllParamResult{
        bool success;
        // Full server param set on success, empty param set otherwise
        std::vector<mavlink_param_ext_value_t> param_set;
    };
    typedef std::function<void(GetAllParamResult result)> GET_ALL_PARAM_RESULT_CB;
    void try_get_param_all_async(const mavlink_param_ext_request_list_t cmd,GET_ALL_PARAM_RESULT_CB result_cb,PROGRESS_CB opt_progress_cb=nullptr);
    std::optional<std::vector<mavlink_param_ext_value_t>> try_get_param_all_blocking(const int target_sysid,const int target_compid);
public:
    static mavlink_param_ext_set_t create_cmd_set_int(int target_sysid,int target_compid,std::string param_name,int value);
    static mavlink_param_ext_set_t create_cmd_set_string(int target_sysid,int target_compid,std::string param_id,std::string value);
    static mavlink_param_ext_request_list_t create_cmd_get_all(int target_sysid,int target_compid);

    struct ParamVariant{
        std::string param_id;
        std::optional<std::string> string_param;
        std::optional<int> int_param;
    };
    static std::vector<ParamVariant> parse_server_param_set(const std::vector<mavlink_param_ext_value_t>& param_set);
public:
    // easy to use API
    enum EasySetParamResult{
        NO_RESPONSE, // no response from recipient
        VALUE_DENIED, // response from recipient, but negative (some error code)
        VALUE_SUCCESS // positive response from recipient
    };

    //template<typename T>
    //bool try_set_param_async(const int target_sys_id,const int target_comp_id,)

private:
    std::mutex m_mutex;
    // A currently active set param action
    struct RunningParamCmdSet{
        mavlink_param_ext_set_t cmd;
        SET_PARAM_RESULT_CB cb;
        PROGRESS_CB opt_progress_cb;
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
        GET_ALL_PARAM_RESULT_CB cb;
        PROGRESS_CB opt_progress_cb;
        std::chrono::milliseconds max_delay_until_timeout;
        std::chrono::milliseconds retransmit_delay;
        std::chrono::steady_clock::time_point last_transmission=std::chrono::steady_clock::now();
        std::vector<std::optional<mavlink_param_ext_value_t>> server_param_set;
        //
        int n_wanted_retransmissions;
        int n_transmissions=0;
    };
    
    bool handle_param_ext_ack(const mavlink_param_ext_ack_t& ack,int sender_sysid,int sender_compid);
    bool handle_param_ext_value(const mavlink_param_ext_value_t& response,int sender_sysid,int sender_compid);

    // searches for a Running param set command that matches the given param ack
    // if found, remove the command and return it.
    // ootherwise, return nullopt
    std::optional<RunningParamCmdSet> find_remove_running_command_threadsafe(const mavlink_param_ext_ack_t& ack,int sender_sysid,int sender_compid);
    // Searches for a running get all command
    // if found, checks if the param set is completely full - in this case, return the param set
    // otherwise, leave the command on the queue (timeout will remvove it in case it finally times out)
    std::optional<RunningParamCmdGetAll> find_remove_running_command_get_all_threadsafe(const mavlink_param_ext_value_t &response, int sender_sysid, int sender_compid);
    //
    void send_next_message_running_set(RunningParamCmdSet& cmd);
    void send_next_message_running_get_all(RunningParamCmdGetAll& cmd);
    void send_param_ext_set(const mavlink_param_ext_set_t &cmd);
    void send_param_ext_request_list(const mavlink_param_ext_request_list_t& cmd);
    void send_param_ext_request_read(const mavlink_param_ext_request_read_t& cmd);
    static int get_missing_count(const std::vector<std::optional<mavlink_param_ext_value_t>>& server_param_set);
    void update_progress_set(const RunningParamCmdSet& cmd,bool done);
    void update_progress_get_all(const RunningParamCmdGetAll& cmd);
private:
    std::list<RunningParamCmdSet> m_running_commands;
    std::list<RunningParamCmdGetAll> m_running_get_all;
    static constexpr auto MAX_N_SIMULTANOEUS_COMMANDS=5;
private:
    std::unique_ptr<std::thread> m_timeout_thread;
    bool m_timeout_thread_run=true;
    void loop_timeout();
    void check_timeout_param_set();
    void check_timeout_param_get_all();
};

#endif // XPARAM_H
