//
// Created by geier on 07/02/2020.
//

#ifndef LIVEVIDEO10MS_KEYFRAMEFINDER_HPP
#define LIVEVIDEO10MS_KEYFRAMEFINDER_HPP

#include "NALU.hpp"
#include <vector>
#include <memory>
#include <qdebug.h>
#include <array>

// Takes a continuous stream of NALUs and save SPS / PPS data
// For later use
class KeyFrameFinder{
private:
    std::unique_ptr<NALU> SPS=nullptr;
    std::unique_ptr<NALU> PPS=nullptr;
    // VPS are only used in H265
    std::unique_ptr<NALU> VPS=nullptr;
public:
    bool saveIfKeyFrame(const NALU &nalu){
        if(nalu.getSize()<=0)return false;
        if(nalu.isSPS()){
            SPS=std::make_unique<NALU>(nalu);
            qDebug()<<"SPS found";
            return true;
        }else if(nalu.isPPS()){
            PPS=std::make_unique<NALU>(nalu);
            qDebug()<<"PPS found";
            return true;
        }else if(nalu.IS_H265_PACKET && nalu.isVPS()){
            VPS=std::make_unique<NALU>(nalu);
            qDebug()<<"VPS found";
            return true;
        }
        return false;
    }
    // H264 needs sps and pps
    // H265 needs sps,pps and vps
    bool allKeyFramesAvailable(const bool IS_H265=false){
        if(IS_H265){
            return SPS != nullptr && PPS != nullptr && VPS!=nullptr;
        }
        return SPS != nullptr && PPS != nullptr;
    }
    std::shared_ptr<std::vector<uint8_t>> get_keyframe_data(const bool IS_H265=false){
        assert(allKeyFramesAvailable(IS_H265));
        if(IS_H265){
            // Looks like avcodec wants the VPS before sps and pps
            const auto size=SPS->getSize()+PPS->getSize()+VPS->getSize();
            auto ret=std::make_unique<std::vector<uint8_t>>(size);
            std::memcpy(ret->data(),VPS->getData(),VPS->getSize());
            auto offset=VPS->getSize();
            std::memcpy(ret->data()+offset,SPS->getData(),SPS->getSize());
            offset+=SPS->getSize();
            std::memcpy(ret->data()+offset,PPS->getData(),PPS->getSize());
            return ret;
        }
        const auto size=SPS->getSize()+PPS->getSize();
        auto ret=std::make_shared<std::vector<uint8_t>>(size);
        std::memcpy(ret->data(),SPS->getData(),SPS->getSize());
        std::memcpy(ret->data()+SPS->getSize(),PPS->getData(),PPS->getSize());
        return ret;
    }    
    // returns false if the config data (SPS,PPS,optional VPS) has changed
    // true otherwise
    bool check_is_still_same_config_data(const NALU &nalu){
        assert(allKeyFramesAvailable(nalu.IS_H265_PACKET));
        if(nalu.isSPS()){
            return compare(nalu,*SPS);
        }else if(nalu.isPPS()){
            return compare(nalu,*PPS);
        }else if(nalu.IS_H265_PACKET && nalu.isVPS()){
            return compare(nalu,*VPS);
        }
        return true;
    }
    //SPS
    const NALU& getCSD0()const{
        return *SPS;
    }
    //PPS
    const NALU& getCSD1()const{
        return *PPS;
    }
    static void appendNaluData(std::vector<uint8_t>& buff,const NALU& nalu){
        buff.insert(buff.begin(),nalu.getData(),nalu.getData()+nalu.getSize());
    }
    void reset(){
        SPS=nullptr;
        PPS=nullptr;
        VPS=nullptr;
    }
    std::array<int,2> sps_get_width_height()const{
        assert(SPS!=nullptr);
        return SPS->sps_get_width_height();
    }
public:
    static bool compare(const NALU& n1,const NALU& n2){
        if(n1.getSize()!=n2.getSize())return false;
        const int res=std::memcmp(n1.getData(),n2.getData(),n1.getSize());
        return res==0;
    }

};

#endif //LIVEVIDEO10MS_KEYFRAMEFINDER_HPP
