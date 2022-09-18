//
// Created by geier on 28/02/2020.
//

#include "UDPSender.h"
#include <cstdlib>
#include <pthread.h>
#include <cerrno>
#include <sys/ioctl.h>
#include <endian.h>
#include <sys/socket.h>
#include <arpa/inet.h>
#include <cstring>
#include "StringHelper.hpp"
#include <iostream>

UDPSender::UDPSender(const std::string &IP,const int Port,const int WANTED_SNDBUFF_SIZEX):
        WANTED_SNDBUFF_SIZE(WANTED_SNDBUFF_SIZEX)
{
    //create the socket
    sockfd = socket(AF_INET,SOCK_DGRAM,0);
    if (sockfd < 0) {
        std::cout<<"Cannot create socket\n";
    }
    //Create the address
    address.sin_family = AF_INET;
    address.sin_port = htons(Port);
    inet_pton(AF_INET,IP.c_str(), &address.sin_addr);
    //
    int sendBufferSize=0;
    socklen_t len=sizeof(sendBufferSize);
    getsockopt(sockfd, SOL_SOCKET, SO_SNDBUF, &sendBufferSize, &len);
    std::cout<<"Default socket send buffer is "<<StringHelper::memorySizeReadable(sendBufferSize)<<"\n";
    if(WANTED_SNDBUFF_SIZE!=0){
        if(setsockopt(sockfd, SOL_SOCKET, SO_SNDBUF, &WANTED_SNDBUFF_SIZE,len)) {
            std::cout<<"Cannot increase buffer size to "<<StringHelper::memorySizeReadable(WANTED_SNDBUFF_SIZE)<<"\n";
        }
        sendBufferSize=0;
        getsockopt(sockfd, SOL_SOCKET, SO_SNDBUF, &sendBufferSize, &len);
        std::cout<<"Wanted "<<StringHelper::memorySizeReadable(WANTED_SNDBUFF_SIZE)<<" Set "<<StringHelper::memorySizeReadable(sendBufferSize)<<"\n";
    }
}

void UDPSender::mySendTo(const uint8_t* data, ssize_t data_length) {
    if((size_t)data_length>UDP_PACKET_MAX_SIZE){
        std::cerr<<"Data size exceeds UDP packet size\n";
        return;
    }
    nSentBytes+=data_length;
    // Measure the time this call takes (is there some funkiness ? )
    timeSpentSending.start();
    const auto result= sendto(sockfd, data, data_length, 0, (struct sockaddr *) &(address),
                                sizeof(struct sockaddr_in));
    if(result<0){
        std::cerr<<"Cannot send data "<<data_length<<" "<<strerror(errno)<<"\n";
    }else if((ssize_t)result!=data_length){
        std::cerr<<"Sent "<<result<<" bytes instead of "<<data_length<<" bytes\n";
    }else{
        //std::cout<<"Sent "<<data_length;
    }
    timeSpentSending.stop();
    //if(timeSpentSending.getNSamples()>100){
        //std::cout<<"TimeSS "<<timeSpentSending.getAvgReadable();
    //    timeSpentSending.reset();
    //}
}

void UDPSender::splitAndSend(const uint8_t *data, ssize_t data_length,const ssize_t chunk_size) {
    timeSpentSendingChunks.start();
    if(data_length>chunk_size){
        int nChunks=0;
        // if the data size exceeds the size of one UDP packet, just chunck it - note though that this means
        // that one udp frame now might not contain a whole NALU, but only parts of it. RTP would be better.
        int remaining=data_length;
        int offset=0;
        while(remaining>0){
            const int thisChunkSize=(int)(remaining > chunk_size ? chunk_size : remaining);
            mySendTo(&((uint8_t*)data)[offset],thisChunkSize);
            remaining-=thisChunkSize;
            offset+=thisChunkSize;
            nChunks++;
        }
        if(remaining!=0){
            std::cout<<"Algorithm error\n";
        }
        std::cout<<"Split "<<data_length<<" bytes into "<<nChunks<<" chunks of size "<<chunk_size<<" bytes\n";
    }else{
        mySendTo(data,data_length);
    }
    timeSpentSendingChunks.stop();
    if(timeSpentSendingChunks.getNSamples()>100){
        std::cout<<"TimeSendingChunks:"<<timeSpentSendingChunks.getAvgReadable()<<"\n";
        timeSpentSendingChunks.reset();
    }
}

void UDPSender::logSendtoDelay() {
    //std::cout<<"Time UDPSender "<<timeSpentSending.getAvgReadable()<<"\n";
}


UDPSender::~UDPSender() {
    //TODO
}
