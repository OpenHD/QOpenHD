
#ifndef FPV_VR_UDPRECEIVER_H
#define FPV_VR_UDPRECEIVER_H

#include <stdio.h>
#ifdef __linux__
#include <sys/socket.h>
#include <netinet/in.h>
#endif
#include <unistd.h>
#include <iostream>
#include <thread>
#include <atomic>
#include <functional>
#include <chrono>
#include <optional>
#include <sstream>

//Starts a new thread that continuously checks for new data on UDP port and
// forward the received data (packet for packet) via a callback
class UDPReceiver {
public:
    typedef std::function<void(const uint8_t[],size_t)> DATA_CALLBACK;
    // Custom struct to keep the constructor simple / documented
    struct Configuration{
        // If no IP addr is given, uses INADRR_ANY
        // otherwise, uses the given ip
        std::optional<std::string> udp_ip_address="127.0.0.1";
        // The udp port to listen on
        int udp_port=5600;
        // linux for example allows increasing / decreasing the amount of data it buffers on an UDP port
        // before it starts dropping packates. On high bitrates, you might have to increase this buffer
        std::optional<size_t> opt_os_receive_buff_size=std::nullopt;
        // we create a thread that fetches the UDP data - set this to true to assign the highest prio possible to this thread
        // (can decrease OS scheduling latency)
        bool set_sched_param_max_realtime=false;
        // busy instead of blocking receive - hogs one cpu core, experimental
        bool enable_nonblocking=false;
        std::string to_string()const{
            std::stringstream ss;
            ss<<udp_ip_address.value_or("INADDR_ANY")<<":"<<udp_port;
            if(opt_os_receive_buff_size.has_value()){
                ss<<" os_receive_buff_size:"<<opt_os_receive_buff_size.value();
            }
            if(set_sched_param_max_realtime){
                ss<<" set_sched_param_max_realtime";
            }
            if(enable_nonblocking){
                ss<<" enable_nonblocking";
            }
            return ss.str();
        }
    };
    /**
     * @param tag: tag for logging
     * @param config: see config documentation for more info
     * @param onDataReceivedCallback: called every time new data is received
     */
    UDPReceiver(std::string tag,Configuration config,DATA_CALLBACK onDataReceivedCallbackX);
    /**
     * Start receiver thread,which opens UDP port
     */
    void startReceiving();
    /**
     * Stop and join receiver thread, which closes port
     */
    void stopReceiving();
    //Get function(s) for private member variables
    long getNReceivedBytes()const;
    std::string getSourceIPAddress()const;
    int getPort()const;
    static constexpr auto BIG_UDP_RECEIVE_BUFFER_SIZE=1024*1024*50;
    static constexpr auto MEDIUM_UDP_RECEIVE_BUFFER_SIZE=1024*1024*25;
private:
    void receiveFromUDPLoop();
    const std::string m_tag;
    const Configuration m_config;
    const DATA_CALLBACK m_on_data_received_cb=nullptr;
    ///We need this reference to stop the receiving thread
    int m_socket=0;
    std::string m_sender_ip="0.0.0.0";
    std::unique_ptr<std::thread> m_receive_thread;
    std::atomic<bool> m_receiving={false};
    std::atomic<long> m_n_received_bytes={0};
    //https://en.wikipedia.org/wiki/User_Datagram_Protocol
    //65,507 bytes (65,535 − 8 byte UDP header − 20 byte IP header).
    static constexpr const size_t UDP_PACKET_MAX_SIZE=65507;
    std::chrono::steady_clock::time_point m_last_received_packet_ts{};
};

#endif // FPV_VR_UDPRECEIVER_H
