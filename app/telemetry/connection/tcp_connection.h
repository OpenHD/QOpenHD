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
    TCPConnection(const std::string remote_ip,const int remote_port,MAV_MSG_CB cb);
    ~TCPConnection();

    void start();
    void stop();

    void send_message(const mavlink_message_t& msg);
private:
    void process_data(const uint8_t* data,int data_len);
    void process_mavlink_message(mavlink_message_t msg);
    void loop_receive();
    bool setup_socket();
    void connect_once();
private:
    const std::string m_remote_ip;
    const int m_remote_port;
    const MAV_MSG_CB m_cb;
    int m_socket_fd=-1;
    mavlink_status_t m_recv_status{};
    std::unique_ptr<std::thread> m_receive_thread=nullptr;
    std::atomic<bool> m_keep_receiving=false;
    std::atomic<bool> m_is_connected=false;
};

#endif // TCPCONNECTION_H
