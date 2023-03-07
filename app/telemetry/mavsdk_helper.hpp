#ifndef MAVSDK_HELPER_H
#define MAVSDK_HELPER_H

#include "mavsdk_include.h"
#include <string>

namespace mavsdk::helper{


static std::string to_string(const mavsdk::MavlinkPassthrough::Result& res){
    std::stringstream ss;
    ss<<res;
    return ss.str();
}
static std::string to_string2(const std::string& p1,const mavsdk::MavlinkPassthrough::Result& res){
    std::stringstream ss;
    ss<<p1<<res;
    return ss.str();
}

}

#endif // MAVSDK_HELPER_H
