
#include "UDPReceiver.h"
#include "common/StringHelper.hpp"
#include "common/SchedulingHelper.hpp"
#include <arpa/inet.h>
#include <utility>
#include <vector>
#include <sstream>
#include <array>
#include <cstring>

#include <sys/time.h>
#include <sys/resource.h>
#include <iostream>

#include <qdebug.h>

UDPReceiver::UDPReceiver(IpAndPort ip_and_port,std::string name,DATA_CALLBACK  onDataReceivedCallbackX,
size_t wanted_receive_buff_size_btyes,const bool ENABLE_NONBLOCKINGX,const bool set_sched_param_max_realtime)
    : m_ip_and_port(ip_and_port),
    mName(std::move(name)),
    onDataReceivedCallback(std::move(onDataReceivedCallbackX)),
    WANTED_RCVBUF_SIZE_BYTES(wanted_receive_buff_size_btyes),
    ENABLE_NONBLOCKING(ENABLE_NONBLOCKINGX),
    m_set_sched_param_max_realtime(set_sched_param_max_realtime)
{
    qDebug()<<"UDPReceiver "<<mName.c_str()<<"with "<<m_ip_and_port.to_string().c_str();
}

long UDPReceiver::getNReceivedBytes()const {
    return nReceivedBytes;
}

std::string UDPReceiver::getSourceIPAddress()const {
    return senderIP;
}

void UDPReceiver::startReceiving() {
    receiving=true;
    mUDPReceiverThread=std::make_unique<std::thread>([this]{
        if(m_set_sched_param_max_realtime){
            SchedulingHelper::setThreadParamsMaxRealtime();
        }
        this->receiveFromUDPLoop();}
    );
}

void UDPReceiver::stopReceiving() {
    receiving=false;
    //this stops the recvfrom even if in blocking mode
    shutdown(mSocket,SHUT_RD);
    if(mUDPReceiverThread->joinable()){
        mUDPReceiverThread->join();
    }
    mUDPReceiverThread.reset();
	//std::cout<<"UDPReceiver avgDeltaBetween(recvfrom) "<<avgDeltaBetweenPackets.getAvgReadable()<<"\n";
}

// increase the UDP receive buffer size, needed for high bandwidth (at ~>20MBit/s the "default"
// udp receive buffer size is often not enough and the OS might (silently) drop packets on localhost)
static void increase_socket_recv_buff_size(int sockfd, const int wanted_rcvbuff_size_bytes) {
  int recvBufferSize=0;
  socklen_t len=sizeof(recvBufferSize);
  getsockopt(sockfd, SOL_SOCKET, SO_RCVBUF, &recvBufferSize, &len);
  {
    std::stringstream ss;
    ss<<"Default UDP socket recv buffer size:"<<StringHelper::memorySizeReadable(recvBufferSize)<<" wanted:"<<StringHelper::memorySizeReadable(wanted_rcvbuff_size_bytes)<<"\n";
    std::cerr<<ss.str();
  }
  // We never decrease the socket receive buffer size, only increase it when neccessary
  if(wanted_rcvbuff_size_bytes>(size_t)recvBufferSize){
    int wanted_size=wanted_rcvbuff_size_bytes;
    recvBufferSize=wanted_rcvbuff_size_bytes;
    if(setsockopt(sockfd, SOL_SOCKET, SO_RCVBUF, &wanted_size,len)) {
      std::cerr<<"Cannot increase UDP buffer size to "<<StringHelper::memorySizeReadable(wanted_rcvbuff_size_bytes)<<"\n";
    }
    // Fetch it again to double check
    recvBufferSize=-1;
    getsockopt(sockfd, SOL_SOCKET, SO_RCVBUF, &recvBufferSize, &len);
    std::cerr<<"UDP Wanted "<<StringHelper::memorySizeReadable(wanted_rcvbuff_size_bytes)<<" Set "<<StringHelper::memorySizeReadable(recvBufferSize)<<"\n";
  }
}

void UDPReceiver::receiveFromUDPLoop() {
    mSocket=socket(AF_INET, SOCK_DGRAM, IPPROTO_UDP);
    if (mSocket == -1) {
        std::cerr<<"Error creating socket\n";
        return;
    }
    int enable = 1;
    if (setsockopt(mSocket, SOL_SOCKET, SO_REUSEADDR, &enable, sizeof(int)) < 0){
        std::cout<<"Error setting reuse\n";
    }
    if(setsockopt(mSocket,SOL_SOCKET,SO_REUSEPORT,&enable,sizeof(int))<0){
        std::cout<<"Error setting SO_REUSEPORT\n";
    }
    increase_socket_recv_buff_size(mSocket,WANTED_RCVBUF_SIZE_BYTES);
    struct sockaddr_in myaddr;
    memset((uint8_t *) &myaddr, 0, sizeof(myaddr));
    myaddr.sin_family = AF_INET;
    myaddr.sin_port = htons(m_ip_and_port.udp_port);
    if(m_ip_and_port.udp_ip_address.has_value()){
        inet_aton(m_ip_and_port.udp_ip_address.value().c_str(), (in_addr *) &myaddr.sin_addr.s_addr);
    }else{
        myaddr.sin_addr.s_addr = htonl(INADDR_ANY);
    }
    if (bind(mSocket, (struct sockaddr *) &myaddr, sizeof(myaddr)) == -1) {
        std::cerr<<"Error binding to "<<m_ip_and_port.to_string()<<"\n";
        return;
    }
    //wrap into unique pointer to avoid running out of stack
    const auto buff=std::make_unique<std::array<uint8_t,UDP_PACKET_MAX_SIZE>>();

    sockaddr_in source;
    socklen_t sourceLen= sizeof(sockaddr_in);
    
    while (receiving) {
        //TODO investigate: does a big buffer size create latency with MSG_WAITALL ?
        //I do not think so. recvfrom should return as soon as new data arrived,not when the buffer is full
        //But with a bigger buffer we do not loose packets when the receiver thread cannot keep up for a short amount of time
        // MSG_WAITALL does not wait until we have __n data, but a new UDP packet (that can be smaller than __n)
        //NOTE: NONBLOCKING hogs a whole CPU core ! do not use whenever possible !
		ssize_t tmp;
		if(ENABLE_NONBLOCKING){
			tmp = recvfrom(mSocket,buff->data(),UDP_PACKET_MAX_SIZE, MSG_DONTWAIT,(sockaddr*)&source,&sourceLen);
		}else{
			tmp = recvfrom(mSocket,buff->data(),UDP_PACKET_MAX_SIZE, MSG_WAITALL,(sockaddr*)&source,&sourceLen);
		}
		const ssize_t message_length=tmp;
        if (message_length > 0) { //else -1 was returned;timeout/No data received
			if(lastReceivedPacket!=std::chrono::steady_clock::time_point{}){
				//const auto delta=std::chrono::steady_clock::now()-lastReceivedPacket;
				//avgDeltaBetweenPackets.add(delta);
			}
			lastReceivedPacket=std::chrono::steady_clock::now();
            //LOGD("Data size %d",(int)message_length);
            onDataReceivedCallback(buff->data(), (size_t)message_length);

            nReceivedBytes+=message_length;
            //The source ip stuff
            const char* p=inet_ntoa(source.sin_addr);
            std::string s1=std::string(p);
            if(senderIP!=s1){
                senderIP=s1;
            }
        }else{
            if(errno != EWOULDBLOCK) {
                //MLOGE<<"Error on recvfrom. errno="<<errno<<" "<<strerror(errno);
            }
        }
    }
    close(mSocket);
}

int UDPReceiver::getPort() const {
    return m_ip_and_port.udp_port;
}
