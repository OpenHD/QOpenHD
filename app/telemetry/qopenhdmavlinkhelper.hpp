#ifndef QOPENHDMAVLINKHELPER_H
#define QOPENHDMAVLINKHELPER_H

#include <chrono>>

namespace QOpenHDMavlinkHelper{
static uint64_t getTimeMicroseconds(){
    const auto time=std::chrono::steady_clock::now().time_since_epoch();
    return std::chrono::duration_cast<std::chrono::microseconds>(time).count();
}

}

#endif // QOPENHDMAVLINKHELPER_H
