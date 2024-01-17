#include "tcp_connection2.h"
#include "util/qopenhdmavlinkhelper.hpp"

#ifdef __windows__
#define _WIN32_WINNT 0x0600 //TODO dirty
#include <winsock2.h>
#include <Ws2tcpip.h> // For InetPton
#else
#include <arpa/inet.h>
#include <netinet/in.h>
#include <sys/socket.h>
#include <unistd.h>
#include <fcntl.h>
#endif

#include <qdebug.h>

#include "mavlinkchannel.h"

static int linux_tcp_socket_try_connect(const std::string remote_ip, const int remote_port,const int timeout_seconds){
    //qDebug()<<"linux_tcp_socket_try_connect:"<<remote_ip.c_str()<<":"<<remote_port<<" timeout:"<<timeout_seconds<<"s";
    int sockfd=socket(AF_INET, SOCK_STREAM, 0);
    if(sockfd<0){
        qDebug()<<"Cannot create socket"<<strerror(errno);
        return -1;
    }
    if(fcntl(sockfd, F_SETFL, O_NONBLOCK)<0){
        qDebug()<<"Cannot set non-blocking";
        close(sockfd);
        return -1;
    }
    struct sockaddr_in remote_addr {};
    remote_addr.sin_family = AF_INET;
    remote_addr.sin_port = htons(remote_port);
    remote_addr.sin_addr.s_addr = inet_addr(remote_ip.c_str());
    const int connect_result=connect(sockfd, reinterpret_cast<sockaddr*>(&remote_addr), sizeof(struct sockaddr_in));
    if(connect_result==0){
        qDebug()<<"Got connection immeiately";
        return sockfd;
    }
    if ((connect_result== -1) && (errno != EINPROGRESS)) {
        qDebug()<<"Didnt get EINPROGRESS"<<(int)connect_result;
        close(sockfd);
        return -1;
    }
    // Wait for up to X seconds to connect
    fd_set fdset;
    struct timeval tv;
    FD_ZERO(&fdset);
    FD_SET(sockfd, &fdset);
    tv.tv_sec = timeout_seconds;
    tv.tv_usec = 0;
    const int rc= select(sockfd + 1, NULL, &fdset, NULL, &tv);
    if(rc!=1){
        qDebug()<<"Timed out or other crap";
        close(sockfd);
        return -1;
    }
    // Check if there are any errors
    int so_error;
    // data to read
    socklen_t len = sizeof(so_error);
    getsockopt(sockfd, SOL_SOCKET, SO_ERROR, &so_error, &len);
    if (so_error != 0) {
        //qDebug()<<"Any socket error";
        close(sockfd);
        return -1;
    }
    qDebug()<<"Success";
    return sockfd;
}

static bool linux_send_message(int sockfd,const std::string& dest_ip,const int dest_port,const uint8_t* data,int data_len){
    struct sockaddr_in dest_addr {};
    dest_addr.sin_family = AF_INET;
    inet_pton(AF_INET, dest_ip.c_str(), &dest_addr.sin_addr.s_addr);
    dest_addr.sin_port = htons(dest_port);
#ifdef MSG_NOSIGNAL
    auto flags = MSG_NOSIGNAL;
#else
    auto flags = 0; // No MSG_NOSIGNAL available, handle it accordingly
#endif
    const auto send_len = sendto(
        sockfd,
        reinterpret_cast<const char*>(data),
        data_len,
        flags,
        reinterpret_cast<const sockaddr*>(&dest_addr),
        sizeof(dest_addr));

    if (send_len != data_len) {
        return false;
    }
    return true;
}

TCPConnection2::TCPConnection2(MAV_MSG_CB cb):m_cb(cb)
  //,m_mav_channel(MavlinkChannel::instance().get_free_channel())
{
}

TCPConnection2::~TCPConnection2()
{
    stop_receiving();
    //MavlinkChannel::instance().give_back_channel(m_mav_channel);
}


void TCPConnection2::start_async(const std::string remote_ip, const int remote_port)
{
    assert(m_receive_thread==nullptr);
    m_remote_ip=remote_ip;
    m_remote_port=remote_port;
    m_keep_receiving=true;
    m_receive_thread=std::make_unique<std::thread>(&TCPConnection2::loop_connect_receive,this);
}

void TCPConnection2::stop_receiving()
{
    if(m_receive_thread!=nullptr){
        m_keep_receiving=false;
#ifdef __windows__
        shutdown(m_socket_fd, SD_BOTH);

        closesocket(m_socket_fd);

        WSACleanup();
#else \
    // This should interrupt a recv/recvfrom call.
        shutdown(m_socket_fd, SHUT_RDWR);
        // But on Mac, closing is also needed to stop blocking recv/recvfrom.
        close(m_socket_fd);
#endif
        m_receive_thread->join();
        m_receive_thread=nullptr;
    }
}


void TCPConnection2::send_message(const mavlink_message_t &msg)
{
    uint8_t buffer[MAVLINK_MAX_PACKET_LEN];
    const int buffer_len = mavlink_msg_to_send_buffer(buffer, &msg);
    if(!m_keep_receiving){
        return; // Otherwise sendto blocks
    }
    if(!linux_send_message(m_socket_fd,m_remote_ip,m_remote_port,buffer,buffer_len)){
        qDebug()<<"Cannot send message";
    }
}

bool TCPConnection2::threadsafe_is_alive()
{
    const int32_t now_ms=QOpenHDMavlinkHelper::getTimeMilliseconds();;
    const auto elapsed=now_ms-m_last_data_ms;
    return elapsed <= 3*1000;
}

void TCPConnection2::process_data(const uint8_t *data, int data_len)
{
    m_last_data_ms=QOpenHDMavlinkHelper::getTimeMilliseconds();
    mavlink_message_t msg;
    for (int i = 0; i < data_len; i++) {
        uint8_t res = mavlink_parse_char(m_mav_channel,data[i], &msg, &m_recv_status);
        if (res) {
            process_mavlink_message(msg);
        }
    }
}

void TCPConnection2::process_mavlink_message(mavlink_message_t message)
{
    m_cb(message);
}


void TCPConnection2::receive_until_stopped()
{
    // Enough for MTU 1500 bytes.
    auto buffer=std::make_unique<std::vector<uint8_t>>();
    buffer->resize(1500);
    while (m_keep_receiving) {
        const auto recv_len = recvfrom(
            m_socket_fd,
            (char*)buffer->data(),
            buffer->size(),
            0,
            nullptr,
            nullptr);

        if (recv_len == 0) {
            // This can happen when shutdown is called on the socket,
            // therefore we check _should_exit again.
            return;
        }

        if (recv_len < 0) {
            // This happens on desctruction when close(_socket_fd) is called,
            // therefore be quiet.
            // LogErr() << "recvfrom error: " << GET_ERROR(errno);
            // Something went wrong, we should try to re-connect in next iteration.
            return;
        }
        process_data(buffer->data(),recv_len);
    }
}

void TCPConnection2::loop_connect_receive()
{
    while(m_keep_receiving){
         m_socket_fd=linux_tcp_socket_try_connect(m_remote_ip,m_remote_port,1);
         if(m_socket_fd!=-1){
             receive_until_stopped();
             qDebug()<<"Broke out of receive loop";
             close(m_socket_fd);
             m_socket_fd=-1;
         }
    }
}
