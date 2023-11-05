#ifndef TCPCONNECTION_H
#define TCPCONNECTION_H

#include "../util/mavlink_include.h"

#include <thread>
#include <memory.h>
#include <atomic>
#include <sstream>
#include <optional>
#include <mutex>
#include <functional>

class TCPConnection
{
public:
    typedef std::function<void(mavlink_message_t msg)> MAV_MSG_CB;
    TCPConnection(MAV_MSG_CB cb);
    ~TCPConnection();
    // This returns after 3 max 3 seconds.
    // On success, true is returned and the receive thread is started (runs untl stop_receiving is called)
    // Otherwise, return false;
    bool try_connect_and_receive(const std::string remote_ip,const int remote_port);

    // If currently receiving, terminate and clean up
    // Otherwise, do nothing
    void stop_receiving();

    void send_message(const mavlink_message_t& msg);

    bool threadsafe_is_alive();
private:
    void process_data(const uint8_t* data,int data_len);
    void process_mavlink_message(mavlink_message_t msg);
    void receive_until_stopped();
private:
    MAV_MSG_CB m_cb;
    int m_socket_fd=-1;
    mavlink_status_t m_recv_status{};
    std::unique_ptr<std::thread> m_receive_thread=nullptr;
    std::atomic_int32_t m_last_data_ms=0;
public:
    std::string m_remote_ip;
    int m_remote_port;
    std::atomic_bool m_keep_receiving=false;
};

#endif // TCPCONNECTION_H
