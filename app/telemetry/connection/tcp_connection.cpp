#include "tcp_connection.h"
#ifdef __windows__
#else
#include <arpa/inet.h>
#include <netinet/in.h>
#include <sys/socket.h>
#endif
#include <qdebug.h>
#include <unistd.h>


TCPConnection::TCPConnection(const std::string remote_ip, const int remote_port, MAV_MSG_CB cb)
    :m_remote_ip(remote_ip),m_remote_port(remote_port),m_cb(cb)
{

}

TCPConnection::~TCPConnection()
{
    stop();
}

void TCPConnection::start()
{
    m_keep_receiving=true;
    m_receive_thread=std::make_unique<std::thread>(&TCPConnection::loop_receive,this);
}

void TCPConnection::stop()
{
    m_keep_receiving=false;
#ifdef __windows__
#else
    // This should interrupt a recv/recvfrom call.
    shutdown(m_socket_fd, SHUT_RDWR);
    // But on Mac, closing is also needed to stop blocking recv/recvfrom.
    close(m_socket_fd);
#endif
    if(m_receive_thread){
        m_receive_thread->join();
    }
    m_receive_thread=nullptr;
}

void TCPConnection::send_message(const mavlink_message_t &msg)
{
#ifdef __windows__
#else
    struct sockaddr_in dest_addr {};
    dest_addr.sin_family = AF_INET;
    inet_pton(AF_INET, m_remote_ip.c_str(), &dest_addr.sin_addr.s_addr);
    dest_addr.sin_port = htons(m_remote_port);

    uint8_t buffer[MAVLINK_MAX_PACKET_LEN];
    const uint16_t buffer_len = mavlink_msg_to_send_buffer(buffer, &msg);

    // TODO: remove this assert again
    assert(buffer_len <= MAVLINK_MAX_PACKET_LEN);
    auto flags = MSG_NOSIGNAL;
    const auto send_len = sendto(
        m_socket_fd,
        reinterpret_cast<char*>(buffer),
        buffer_len,
        flags,
        reinterpret_cast<const sockaddr*>(&dest_addr),
        sizeof(dest_addr));

    if (send_len != buffer_len) {
        qDebug()<<"Cannot send message";
    }
#endif
}

void TCPConnection::process_data(const uint8_t *data, int data_len)
{
    for (int i = 0; i < data_len; i++) {
        mavlink_message_t msg;
        uint8_t res = mavlink_parse_char(1, (uint8_t)data[i], &msg, &m_recv_status);
        if (res) {
            process_mavlink_message(msg);
        }
    }
}

void TCPConnection::process_mavlink_message(mavlink_message_t message)
{
    m_cb(message);
}

void TCPConnection::loop_receive()
{
    while (m_keep_receiving) {
        qDebug()<<"TCP start on "<<m_remote_ip.c_str()<<":"<<m_remote_port;
        connect_once();
        if(m_keep_receiving)std::this_thread::sleep_for(std::chrono::seconds(2));// try again in X seconds
    }
}


void TCPConnection::connect_once()
{
#ifdef __windows__
#else
    m_socket_fd = socket(AF_INET, SOCK_STREAM, 0);

    if (m_socket_fd < 0) {
        qDebug()<<"Cannot create socket"<<strerror(errno);
        return;
    }

    struct sockaddr_in remote_addr {};
    remote_addr.sin_family = AF_INET;
    remote_addr.sin_port = htons(m_remote_port);
    remote_addr.sin_addr.s_addr = inet_addr(m_remote_ip.c_str());

    if (connect(m_socket_fd, reinterpret_cast<sockaddr*>(&remote_addr), sizeof(struct sockaddr_in)) <0) {
        qDebug()<<"Socket connect failed: "<<strerror(errno);
        return;
    }
    // Enough for MTU 1500 bytes.
    uint8_t buffer[2048];
    while (m_keep_receiving) {
        const auto recv_len = recv(m_socket_fd, buffer, sizeof(buffer), 0);

        if (recv_len == 0) {
            // This can happen when shutdown is called on the socket,
            // therefore we check _should_exit again.
            continue;
        }

        if (recv_len < 0) {
            // This happens on desctruction when close(_socket_fd) is called,
            // therefore be quiet.
            // LogErr() << "recvfrom error: " << GET_ERROR(errno);
            // Something went wrong, we should try to re-connect in next iteration.
            continue;
        }
        process_data(buffer,recv_len);
    }
#endif
}
