
#ifndef FPV_VR_UDPRECEIVER_H
#define FPV_VR_UDPRECEIVER_H

#include <stdio.h>
#include <sys/socket.h>
#include <netinet/in.h>
#include <unistd.h>
#include <iostream>
#include <thread>
#include <atomic>
#include <functional>
#include <chrono>
#include <optional>
#include <sstream>

//Starts a new thread that continuously checks for new data on UDP port
class UDPReceiver {
public:
    typedef std::function<void(const uint8_t[],size_t)> DATA_CALLBACK;
    struct IpAndPort{
        std::optional<std::string> udp_ip_address="127.0.0.1";
        int udp_port=5600;
        std::string to_string()const{
            std::stringstream ss;
            ss<<udp_ip_address.value_or("INADDR_ANY")<<":"<<udp_port;
            return ss.str();
        }
    };
public:
    /**
     * @param port : The port to listen on
     * @param onDataReceivedCallback: called every time new data is received
     * @param WANTED_RCVBUF_SIZE: The buffer allocated by the OS might not be sufficient to buffer incoming data when receiving at a high data rate
     * If @param WANTED_RCVBUF_SIZE is bigger than the size allocated by the OS a bigger buffer is requested, but it is not
     * guaranteed that the size is actually increased. Use 0 to leave the buffer size untouched
     */
    UDPReceiver(IpAndPort ip_and_port,std::string name,DATA_CALLBACK onDataReceivedCallbackX,
    size_t wanted_receive_buff_size_btyes,const bool ENABLE_NONBLOCKINGX,const bool set_sched_param_max_realtime);
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
    const IpAndPort m_ip_and_port;
    const std::string mName;
    const DATA_CALLBACK onDataReceivedCallback=nullptr;
    const size_t WANTED_RCVBUF_SIZE_BYTES;
    ///We need this reference to stop the receiving thread
    int mSocket=0;
    std::string senderIP="0.0.0.0";
    std::unique_ptr<std::thread> mUDPReceiverThread;
    std::atomic<bool> receiving={false};
    std::atomic<long> nReceivedBytes={0};
    //https://en.wikipedia.org/wiki/User_Datagram_Protocol
    //65,507 bytes (65,535 − 8 byte UDP header − 20 byte IP header).
    static constexpr const size_t UDP_PACKET_MAX_SIZE=65507;
	std::chrono::steady_clock::time_point lastReceivedPacket{};
	//AvgCalculator avgDeltaBetweenPackets;
	const bool ENABLE_NONBLOCKING;
    const bool m_set_sched_param_max_realtime;
};

#endif // FPV_VR_UDPRECEIVER_H
