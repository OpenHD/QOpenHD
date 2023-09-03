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
};

#endif // TCPCONNECTION_H
