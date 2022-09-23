//
// Created by consti10 on 17.11.21.
//

#ifndef RV1126_RV1109_V2_2_0_20210825_HELPER_H
#define RV1126_RV1109_V2_2_0_20210825_HELPER_H

#include <cstdio>
#include <cstdlib>
#include <cerrno>
#include <resolv.h>
#include <cstring>
#include <utime.h>
#include <unistd.h>
#include <getopt.h>
#include <endian.h>
#include <fcntl.h>
#include <ctime>
#include <sys/mman.h>
#include <string>
#include <vector>
#include <chrono>
#include <cstdarg>
#include <sys/socket.h>
#include <netinet/in.h>
#include <arpa/inet.h>
#include <netinet/ether.h>
#include <netpacket/packet.h>
#include <termio.h>
#include <sys/ioctl.h>
#include <net/if.h>
#include <iostream>
#include <memory>
#include <cassert>

namespace GenericHelper{
    // fill buffer with random bytes
    static void fillBufferWithRandomData(std::vector<uint8_t>& data){
        const std::size_t size=data.size();
        for(std::size_t i=0;i<size;i++){
            data[i] = rand() % 255;
        }
    }
    template<std::size_t size>
    static void fillBufferWithRandomData(std::array<uint8_t,size>& data){
        for(std::size_t i=0;i<size;i++){
            data[i] = rand() % 255;
        }
    }
    // Create a buffer filled with random data of size sizeByes
    std::vector<uint8_t> createRandomDataBuffer(const ssize_t sizeBytes){
        std::vector<uint8_t> buf(sizeBytes);
        fillBufferWithRandomData(buf);
        return buf;
    }
    // same as above but return shared ptr
    std::shared_ptr<std::vector<uint8_t>> createRandomDataBuffer2(const ssize_t sizeBytes){
        return std::make_shared<std::vector<uint8_t>>(createRandomDataBuffer(sizeBytes));
    }
    // Create a buffer filled with random data where size is chosen Randomly between [minSizeB,...,maxSizeB]
    std::vector<uint8_t> createRandomDataBuffer(const ssize_t minSizeB,const ssize_t maxSizeB){
        // https://stackoverflow.com/questions/12657962/how-do-i-generate-a-random-number-between-two-variables-that-i-have-stored
        const auto sizeBytes = rand()%(maxSizeB-minSizeB + 1) + minSizeB;
        return createRandomDataBuffer(sizeBytes);
    }
    // create n random data buffers with size [minSizeB,...,maxSizeB]
    std::vector<std::vector<uint8_t>> createRandomDataBuffers(const std::size_t nBuffers, const std::size_t minSizeB, const std::size_t maxSizeB){
        assert(minSizeB >= 0);
        std::vector<std::vector<uint8_t>> buffers;
        for(std::size_t i=0;i<nBuffers;i++){
            buffers.push_back(GenericHelper::createRandomDataBuffer(minSizeB, maxSizeB));
        }
        return buffers;
    }
    template<std::size_t size>
    static std::vector<std::array<uint8_t,size>> createRandomDataBuffers(const std::size_t nBuffers){
        std::vector<std::array<uint8_t,size>> ret(nBuffers);
        for(auto& buff:ret){
            GenericHelper::fillBufferWithRandomData(buff);
        }
        return ret;
    }
    bool compareVectors(const std::vector<uint8_t>& sb,const std::vector<uint8_t>& rb){
        if(sb.size()!=rb.size()){
            return false;
        }
        const int result=memcmp (sb.data(),rb.data(),sb.size());
        return result==0;
    }
    void assertVectorsEqual(const std::vector<uint8_t>& sb,const std::vector<uint8_t>& rb){
        assert(sb.size()==rb.size());
        const int result=memcmp (sb.data(),rb.data(),sb.size());
        assert(result==0);
    }
    template<std::size_t S>
    void assertArraysEqual(const std::array<uint8_t,S>& sb,const std::array<uint8_t,S>& rb){
        const int result=memcmp (sb.data(),rb.data(),sb.size());
        if(result!=0){
            //std::cout<<"Data1:"<<StringHelper::arrayAsString(sb)<<"\n";
            //std::cout<<"Data2:"<<StringHelper::arrayAsString(rb)<<"\n";
        }
        assert(result==0);
    }
    /**
     * take @param nElements random elements from @param values, without duplicates
     */
    std::vector<unsigned int> takeNRandomElements(std::vector<unsigned int> values, const std::size_t nElements){
        assert(nElements<=values.size());
        std::vector<unsigned int> ret;
        for(std::size_t i=0;i<nElements;i++){
            const auto idx=rand() % values.size();
            ret.push_back(values[idx]);
            values.erase(values.begin()+idx);
        }
        assert(ret.size()==nElements);
        std::sort(ret.begin(),ret.end());
        return ret;
    }
    std::vector<unsigned int> createIndices(const std::size_t nIndices){
        std::vector<unsigned int> ret(nIndices);
        for(std::size_t i=0;i<ret.size();i++){
            ret[i]=i;
        }
        return ret;
    }
    template<std::size_t S>
    static std::vector<uint8_t*> convertToP(std::vector<std::array<uint8_t,S>>& buff,std::size_t offset=0,std::size_t n=-1){
        if(n==-1)n=buff.size();
        std::vector<uint8_t*> ret(n);
        for(int i=0;i<ret.size();i++){
            ret[i]=buff[offset+i].data();
        }
        return ret;
    }
    // given an array of available indices, for each index int the rane [0...range[, check if this index is contained in the input array.
    // if not, the index is "missing" and added to the return array
    static std::vector<unsigned int> findMissingIndices(const std::vector<unsigned int>& indicesAvailable,const std::size_t range){
        std::vector<unsigned int> indicesMissing;
        for(unsigned int i=0;i<range;i++){
            auto found= indicesAvailable.end() != std::find(indicesAvailable.begin(), indicesAvailable.end(), i);
            if(!found){
                // if not found, add to missing
                //std::cout<<"Not found:"<<i<<"\n";
                indicesMissing.push_back(i);
            }
        }
        return indicesMissing;
    }
}

// this is just a NALU with no content
static __attribute__((unused)) uint8_t fakeNALU[4]={0,0,0,1};
// this is the data for an h264 AUD unit
static __attribute__((unused)) uint8_t EXAMPLE_AUD[6]={0,0,0,1,9,48};

static __attribute__((unused)) uint8_t NAL_HDR[4]={0,0,0,1};

#endif //RV1126_RV1109_V2_2_0_20210825_HELPER_H
