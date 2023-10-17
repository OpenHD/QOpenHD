#ifndef MUDPLINK_H
#define MUDPLINK_H

#include "../util/mavlink_include.h"

#include <thread>
#include <memory.h>
#include <atomic>
#include <sstream>
#include <optional>
#include <mutex>
#include <functional>

/**
 * @brief Mavlink udp connection  - follows the semi-established pattern
 * of using udp, listening but sending responses to whoever supplied
 * us with data
 */
class UDPConnection
{
public:
    typedef std::function<void(mavlink_message_t msg)> MAV_MSG_CB;
    UDPConnection(const std::string local_ip,const int local_port,MAV_MSG_CB cb);
    ~UDPConnection();

    void start();

    void stop();

    void send_message(const mavlink_message_t& msg);

    // Returns true if the last received message is not older than X seconds
    bool threadsafe_is_alive();

private:
    void process_data(const uint8_t* data,int data_len);
    void process_mavlink_message(mavlink_message_t msg);
    void loop_receive();
    bool setup_socket();
    void connect_once();
    struct Remote{
        std::string ip;
        int port;
        std::string to_string()const{
            std::stringstream ss;
            ss<<ip<<":"<<port;
            return ss.str();
        }
    };
    std::optional<Remote> get_current_remote();
    void set_remote(const std::string ip,int port);
    void clear_remote();
private:
    const std::string m_local_ip;
    const int m_local_port;
    const MAV_MSG_CB m_cb;
    int m_socket_fd=-1;
    mavlink_status_t m_recv_status{};
    std::unique_ptr<std::thread> m_receive_thread=nullptr;
    std::atomic<bool> m_keep_receiving=false;
    std::mutex m_remote_nutex;
    std::optional<Remote> m_curr_remote;
    std::atomic_int32_t m_last_data_ms=0;
};

#endif // MUDPLINK_H
