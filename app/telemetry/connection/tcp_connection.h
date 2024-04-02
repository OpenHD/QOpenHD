#ifndef TCPCONNECTION2_H
#define TCPCONNECTION2_H

#include "../tutil/mavlink_include.h"

#include <thread>
#include <memory.h>
#include <atomic>
#include <sstream>
#include <optional>
#include <mutex>
#include <functional>

// TCP client connection that handles the following edge-case:
// If the server becomes unavailable (no message for more than X seconds)
// disconnect, then continously try re-connecting.
class TCPConnection{
public:
    typedef std::function<void(mavlink_message_t msg)> MAV_MSG_CB;
    TCPConnection(MAV_MSG_CB cb,std::string remote_ip,int remote_port,int mavlink_channel);
    ~TCPConnection();

    // Update the remote. Must not be in looping state when called.
    void set_remote(std::string remote_ip,int remote_port);

    bool is_looping();

    void start_looping();

    void stop_looping();
    void stop_looping_if();

    void send_message(const mavlink_message_t& msg);

    bool threadsafe_is_alive();
private:
    void process_data(const uint8_t* data,int data_len);
    void process_mavlink_message(mavlink_message_t msg);
    void receive_until_stopped();
private:
    MAV_MSG_CB m_cb;
    std::atomic<int> m_socket_fd=-1;
    mavlink_status_t m_recv_status{};
    std::unique_ptr<std::thread> m_receive_thread=nullptr;
    std::atomic_int32_t m_last_data_ms=0;
public:
    std::string m_remote_ip;
    int m_remote_port;
    std::atomic_bool m_keep_receiving=false;
    const int m_mav_channel=2;
private:
    void loop_connect_receive();
};

#endif // TCPCONNECTION2_H
