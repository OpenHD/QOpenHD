//
// Created by Constantin on 09.10.2017.
//

#ifndef OSDTESTER_STRINGHELPER_H
#define OSDTESTER_STRINGHELPER_H

#include <string>
#include <sstream>
#include <vector>
#include <cmath>
#include <iomanip>
#include <cassert>

class StringHelper{
public:
    template<typename T>
    static std::string vectorAsString(const std::vector<T>& v){
        std::stringstream ss;
        for (const auto i:v) {
            ss << (int)i << ",";
        }
        return ss.str();
    }

    template<typename T,std::size_t S>
    static std::string arrayAsString(const std::array<T,S>& a){
        std::stringstream ss;
        for (const auto i:a) {
            ss << (int)i << ",";
        }
        return ss.str();
    }

    template <typename T>
    static std::string to_string_with_precision(const T a_value, const int n = 6)
    {
        std::ostringstream out;
        out.precision(n);
        out << std::fixed << a_value;
        return out.str();
    }

    static std::string memorySizeReadable(const size_t sizeBytes){
        // more than one MB
        if(sizeBytes>1024*1024){
            float sizeMB=(float)sizeBytes /1024.0 / 1024.0;
            return std::to_string(sizeMB)+"mB";
        }
        // more than one KB
        if(sizeBytes>1024){
            float sizeKB=(float)sizeBytes /1024.0;
            return std::to_string(sizeKB)+"kB";
        }
        return std::to_string(sizeBytes)+"B";
    }

    static std::string bitrate_to_string(uint64_t bits_per_second){
      if(bits_per_second>1024*1024){
          const double mbits=static_cast<double>(bits_per_second)/(1024.0*1024.0);
          return to_string_with_precision(mbits,1)+" mBit/s";
      }
      if(bits_per_second>1024){
          const double kbits=static_cast<double>(bits_per_second)/(1024.0);
          return to_string_with_precision(kbits,2)+" kBit/s";
      }
      return std::to_string(bits_per_second)+" Bit/s";
    }

    /*static std::string bitrate_readable(const int bits_per_second){
         std::stringstream ss;
         ss.precision(3);
        if(bits_per_second>1024*1024){
            double mbits_per_second=(float)bits_per_second /1024.0 / 1024.0;
            ss<<mbits_per_second<<"MBit/s";
            return ss.str();
        }
        // more than one KB
        if(bits_per_second>1024){
            float sizeKB=(float)bits_per_second /1024.0;
            return std::to_string(sizeKB)+"kB";
        }
        return std::to_string(sizeBytes)+"B";
    }*/
};


#endif //OSDTESTER_STRINGHELPER_H
