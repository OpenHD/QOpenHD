#include "UDPReceiver.h"
#include "common/StringHelper.hpp"
#include "common/SchedulingHelper.hpp"

#if defined(_WIN32)
#include <winsock2.h>
#define SHUT_RD SD_RECEIVE
#else
#include <arpa/inet.h>
#endif

#include <utility>
#include <vector>
#include <sstream>
#include <array>
#include <cstring>

#include <sys/time.h>

#include <iostream>

#include <qdebug.h>

UDPReceiver::UDPReceiver(std::string tag, Configuration config, DATA_CALLBACK onDataReceivedCallbackX)
    :
    m_tag(tag),
    m_config(config),
    m_on_data_received_cb(std::move(onDataReceivedCallbackX))
{
    qDebug() << "UDPReceiver " << m_tag.c_str() << "with " << m_config.to_string().c_str();
}

long UDPReceiver::getNReceivedBytes() const {
    return m_n_received_bytes;
}

std::string UDPReceiver::getSourceIPAddress() const {
    return m_sender_ip;
}

void UDPReceiver::startReceiving() {
    m_receiving = true;
    m_receive_thread = std::make_unique<std::thread>([this]{
        if(m_config.set_sched_param_max_realtime){
            SchedulingHelper::setThreadParamsMaxRealtime();
        }
        this->receiveFromUDPLoop();
    });
}

void UDPReceiver::stopReceiving() {
    m_receiving = false;
    const auto socket = m_socket.exchange(UDP_RECEIVER_INVALID_SOCKET);
    if (socket != UDP_RECEIVER_INVALID_SOCKET) {
        // This stops recvfrom even when the receiver is using blocking mode.
        shutdown(socket, SHUT_RD);
#if defined(_WIN32)
        closesocket(socket);
#else
        close(socket);
#endif
    }
    if (m_receive_thread && m_receive_thread->joinable()) {
        m_receive_thread->join();
    }
    m_receive_thread.reset();
}

void UDPReceiver::closeSocketIfOwned(UDPReceiverSocket socket) {
    UDPReceiverSocket expected = socket;
    if (!m_socket.compare_exchange_strong(expected, UDP_RECEIVER_INVALID_SOCKET)) {
        return;
    }
#if defined(_WIN32)
    closesocket(socket);
#else
    close(socket);
#endif
}

static void increase_socket_recv_buff_size(UDPReceiverSocket sockfd, const int wanted_rcvbuff_size_bytes) {
    int recvBufferSize = 0;
    socklen_t len = sizeof(recvBufferSize);
    getsockopt(sockfd, SOL_SOCKET, SO_RCVBUF, (char *)&recvBufferSize, &len);
    {
        std::stringstream ss;
        ss << "Default UDP socket recv buffer size: " << StringHelper::memorySizeReadable(recvBufferSize)
           << " wanted: " << StringHelper::memorySizeReadable(wanted_rcvbuff_size_bytes) << "\n";
        std::cerr << ss.str();
    }
    if (wanted_rcvbuff_size_bytes > (size_t)recvBufferSize) {
        int wanted_size = wanted_rcvbuff_size_bytes;
        recvBufferSize = wanted_rcvbuff_size_bytes;
        if (setsockopt(sockfd, SOL_SOCKET, SO_RCVBUF, (char *)&wanted_size, len)) {
            std::cerr << "Cannot increase UDP buffer size to " << StringHelper::memorySizeReadable(wanted_rcvbuff_size_bytes) << "\n";
        }
        recvBufferSize = -1;
        getsockopt(sockfd, SOL_SOCKET, SO_RCVBUF, (char *)&recvBufferSize, &len);
        std::cerr << "UDP Wanted " << StringHelper::memorySizeReadable(wanted_rcvbuff_size_bytes)
                  << " Set " << StringHelper::memorySizeReadable(recvBufferSize) << "\n";
    }
}

void UDPReceiver::receiveFromUDPLoop() {
    const auto socket_handle = socket(AF_INET, SOCK_DGRAM, IPPROTO_UDP);
    if (socket_handle == UDP_RECEIVER_INVALID_SOCKET) {
        std::cerr << "Error creating socket\n";
        return;
    }
    m_socket = socket_handle;
    int enable = 1;
    if (setsockopt(socket_handle, SOL_SOCKET, SO_REUSEADDR, (char *)&enable, sizeof(int)) < 0) {
        std::cout << "Error setting reuse\n";
    }

#ifndef _WIN32
    if (setsockopt(socket_handle, SOL_SOCKET, SO_REUSEPORT, &enable, sizeof(int)) < 0) {
        std::cout << "Error setting SO_REUSEPORT\n";
    }
#endif

    if (m_config.opt_os_receive_buff_size) {
        increase_socket_recv_buff_size(socket_handle, m_config.opt_os_receive_buff_size.value());
    }

    struct sockaddr_in myaddr;
    memset((uint8_t *)&myaddr, 0, sizeof(myaddr));
    myaddr.sin_family = AF_INET;
    myaddr.sin_port = htons(m_config.udp_port);
    if (m_config.udp_ip_address.has_value()) {
#ifdef _WIN32
        myaddr.sin_addr.s_addr = htonl(INADDR_ANY);
#else
        inet_aton(m_config.udp_ip_address.value().c_str(), (in_addr *)&myaddr.sin_addr.s_addr);
#endif
    } else {
        myaddr.sin_addr.s_addr = htonl(INADDR_ANY);
    }

#ifdef _WIN32
    if (bind(socket_handle, (struct sockaddr *)&myaddr, sizeof(myaddr)) == SOCKET_ERROR) {
        std::cerr << "Error binding to " << m_config.to_string() << "\n";
        closeSocketIfOwned(socket_handle);
        return;
    }
#else
    if (bind(socket_handle, (struct sockaddr *)&myaddr, sizeof(myaddr)) == -1) {
        std::cerr << "Error binding to " << m_config.to_string() << "\n";
        closeSocketIfOwned(socket_handle);
        return;
    }
#endif

    const auto buff = std::make_unique<std::array<uint8_t, UDP_PACKET_MAX_SIZE>>();
    sockaddr_in source;
    socklen_t sourceLen = sizeof(sockaddr_in);

    while (m_receiving) {
#ifdef _WIN32
        auto tmp = recvfrom(socket_handle, (char *)buff->data(), UDP_PACKET_MAX_SIZE, 0, (sockaddr *)&source, &sourceLen);
#else
        ssize_t tmp;
        if (m_config.enable_nonblocking) {
            tmp = recvfrom(socket_handle, buff->data(), UDP_PACKET_MAX_SIZE, MSG_DONTWAIT, (sockaddr *)&source, &sourceLen);
        } else {
            tmp = recvfrom(socket_handle, buff->data(), UDP_PACKET_MAX_SIZE, MSG_WAITALL, (sockaddr *)&source, &sourceLen);
        }
#endif
        const ssize_t message_length = tmp;
        if (message_length > 0) {
            m_last_received_packet_ts = std::chrono::steady_clock::now();
            m_on_data_received_cb(buff->data(), (size_t)message_length);
            m_n_received_bytes += message_length;
            const char *p = inet_ntoa(source.sin_addr);
            std::string s1 = std::string(p);
            if (m_sender_ip != s1) {
                m_sender_ip = s1;
            }
        } else {
#ifdef _WIN32
            const auto socket_error = WSAGetLastError();
            if (socket_error != WSAEWOULDBLOCK && m_receiving) {
                // Handle error
            }
#else
            if (errno != EWOULDBLOCK) {
                // Handle error
            }
#endif
        }
    }
    closeSocketIfOwned(socket_handle);
}

int UDPReceiver::getPort() const {
    return m_config.udp_port;
}
