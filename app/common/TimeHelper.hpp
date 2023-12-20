//
// Created by geier on 18/01/2020.
//

#ifndef LIVEVIDEO10MS_TIMEHELPER_HPP
#define LIVEVIDEO10MS_TIMEHELPER_HPP

#include <chrono>
#include <deque>
#include <algorithm>
#include <sstream>
#include <iostream>
#include "StringHelper.hpp"

#include <QDebug>

// This file holds various classes/namespaces usefully for measuring and comparing
// latency samples

namespace MyTimeHelper{
    static std::chrono::steady_clock::duration abs(const std::chrono::steady_clock::duration& dur){
        return dur>=std::chrono::nanoseconds(0) ? dur : -dur;
    }
    // R stands for readable. Convert a std::chrono::duration into a readable format
    // Readable format is somewhat arbitrary, in this case readable means that for example
    // 1second has 'ms' resolution since for values that big ns resolution probably isn't needed
    static std::string R(const std::chrono::steady_clock::duration& dur){
        //const auto durAbsolute=std::chrono::abs(dur);
        const auto durAbsolute=MyTimeHelper::abs(dur);
        if(durAbsolute>=std::chrono::seconds(1)){
            // More than one second, print as decimal with ms resolution.
            const auto ms=std::chrono::duration_cast<std::chrono::milliseconds>(dur).count();
            return StringHelper::to_string_with_precision(ms/1000.0f,2)+"s";
        }
        if(durAbsolute>=std::chrono::milliseconds(1)){
            // More than one millisecond, print as decimal with us resolution
            const auto us=std::chrono::duration_cast<std::chrono::microseconds>(dur).count();
            return StringHelper::to_string_with_precision(us/1000.0f,2)+"ms";
        }
        if(durAbsolute>=std::chrono::microseconds(1)){
            // More than one microsecond, print as decimal with ns resolution
            const auto ns=std::chrono::duration_cast<std::chrono::nanoseconds>(dur).count();
            return StringHelper::to_string_with_precision(ns/1000.0f,2)+"us";
        }
        const auto ns=std::chrono::duration_cast<std::chrono::nanoseconds>(dur).count();
        return std::to_string(ns)+"ns";
    }
    static std::string ReadableNS(uint64_t nanoseconds){
        return R(std::chrono::nanoseconds(nanoseconds));
    }
	static std::string timeSamplesAsString(const std::vector<std::chrono::nanoseconds>& samples){
		std::stringstream ss;
		int counter=0;
        for(const auto& sample:samples){
           ss<<","<<MyTimeHelper::R(sample);
		   counter++;
		   if(counter%10==0 && counter!=(int)samples.size()){
		     ss<<"\n";
		   }
        }
		return ss.str();
	}
};

// Use this class to compare many samples of the same kind
// Saves the minimum,maximum and average of all the samples
// The type of the samples is for example std::chrono::nanoseconds when measuring time intervalls
class AvgCalculator{
private:
    // do not forget the braces to initialize with 0
    std::chrono::nanoseconds sum{};
    long nSamples=0;
#ifndef __windows__
    std::chrono::nanoseconds min=std::chrono::nanoseconds::max();
#else
    std::chrono::nanoseconds min{10000000000};
#endif //__windows__
    std::chrono::nanoseconds max{};
    const std::string name;
    std::chrono::steady_clock::time_point last_log{};
public:
    AvgCalculator(std::string name1=""):name(name1){reset();};
    void add(const std::chrono::nanoseconds& value){
        if(value<std::chrono::nanoseconds(0)){
            std::cout<<"Cannot add negative value\n";
            return;
        }
        sum+=value;
        nSamples++;
        if(value<min){
            min=value;
        }
        if(value>max){
            max=value;
        }
    }
    void addUs(uint64_t valueUs){
        add(std::chrono::nanoseconds(valueUs*1000));
    }
    // Returns the average of all samples.
    // If 0 samples were recorded, return 0
    std::chrono::nanoseconds getAvg()const{
        if(nSamples == 0)return std::chrono::nanoseconds(0);
        return sum / nSamples;
    }
    // Returns the minimum value of all samples
    std::chrono::nanoseconds getMin()const{
        return min;
    }
    // Returns the maximum value of all samples
    std::chrono::nanoseconds getMax()const{
        return max;
    }
    // Returns the n of samples that were processed
    long getNSamples()const{
        return nSamples;
    }
    // Reset everything (as if zero samples were processed)
    void reset(){
        sum=std::chrono::nanoseconds(0);
        nSamples=0;
        // Workaround for std::numeric_limits returning 0 for std::chrono::nanoseconds
#ifdef __windows__
        min=std::chrono::nanoseconds(1000000000000);
#else
        min=std::chrono::nanoseconds::max();
#endif
        max={};
    }
    std::string getAvgReadable(const bool averageOnly=false)const{
        std::stringstream ss;
        if(averageOnly){
            ss<<"avg="<<MyTimeHelper::R(getAvg());
            return ss.str();
        }
        ss<<"min="<<MyTimeHelper::R(getMin())<<" max="<<MyTimeHelper::R(getMax())<<" avg="<<MyTimeHelper::R(getAvg());
        return ss.str();
    }
    float getAvg_ms(){
        return (float)(std::chrono::duration_cast<std::chrono::microseconds>(getAvg()).count())/1000.0f;
    }
    void printInIntervals(const int intervalSize,bool resetSamples=true){
        if(getNSamples()>=intervalSize){
            std::stringstream ss;
            ss<<"Avg "<<name<<":"<<getAvgReadable()<<"\n";
            std::cout<<ss.str();
            if(resetSamples)reset();
        }
    }
    void printInIntervals(const std::chrono::steady_clock::duration interval_duration_size,bool resetSamples=true){
        const auto timeSinceLastLog=std::chrono::steady_clock::now()-last_log;
        if(timeSinceLastLog>interval_duration_size){
            std::stringstream ss;
            ss<<"Avg "<<name<<":"<<getAvgReadable()<<"\n";
            std::cout<<ss.str();
            if(resetSamples)reset();
            last_log=std::chrono::steady_clock::now();
        }
    }
    std::chrono::nanoseconds time_since_last_log(){
        const auto timeSinceLastLog=std::chrono::steady_clock::now()-last_log;
        return timeSinceLastLog;
    }
    void set_last_log(){
        last_log=std::chrono::steady_clock::now();
    }
    typedef std::function<void(const AvgCalculator& self)> CUSTOM_CB;
    void recalculate_in_fixed_time_intervals(const std::chrono::steady_clock::duration interval_duration_size,CUSTOM_CB cb){
        const auto timeSinceLastLog=std::chrono::steady_clock::now()-last_log;
        if(timeSinceLastLog>interval_duration_size){
            cb(*this);
            reset();
            last_log=std::chrono::steady_clock::now();
        }
    }
    typedef std::function<void(const std::string name,const std::string message)> CUSTOM_PRINT_CB;
    void custom_print_in_intervals(const std::chrono::steady_clock::duration interval_duration_size,CUSTOM_PRINT_CB cb,bool resetSamples=true){
        const auto timeSinceLastLog=std::chrono::steady_clock::now()-last_log;
        if(timeSinceLastLog>interval_duration_size){
            auto tmp=getAvgReadable();
            cb(name,tmp);
            if(resetSamples)reset();
            last_log=std::chrono::steady_clock::now();
        }
    }
};


// Instead of storing only the min, max and average this stores
// The last n samples in a queue. However, this makes calculating the min/max/avg values much more expensive
// And therefore should only be used with a small sample size.
class AvgCalculator2{
private:
    const size_t sampleSize;
    std::deque<std::chrono::nanoseconds> samples;
public:
    // Use zero for infinite n of recorded samples
	// Be carefully with memory in this case
    explicit AvgCalculator2(size_t sampleSizeX=60):sampleSize(sampleSizeX){};
    //
    void add(const std::chrono::nanoseconds& value){
        if(value<std::chrono::nanoseconds(0)){
            std::cout<<"Cannot add negative value\n";
            return;
        }
        samples.push_back(value);
        // Remove the oldest sample if needed
        if(sampleSize!=0 &&samples.size()>sampleSize){
            samples.pop_front();
        }
    }
    std::chrono::nanoseconds getAvg()const{
        if(samples.empty()){
            return std::chrono::nanoseconds(0);
        }
        std::chrono::nanoseconds sum{0};
        for(const auto sample:samples){
            sum+=sample;
        }
        return sum / samples.size();
    }
    std::chrono::nanoseconds getMin()const{
        return *std::min_element(samples.begin(),samples.end());
    }
    std::chrono::nanoseconds getMax()const{
        return *std::max_element(samples.begin(),samples.end());
    }
    void reset(){
        samples.resize(0);
    }
	size_t getNSamples()const{
        return samples.size();
    }
    std::string getAvgReadable(const bool averageOnly=false)const{
        std::stringstream ss;
        if(averageOnly){
            ss<<"avg="<<MyTimeHelper::R(getAvg());
            return ss.str();
        }
        ss<<"min="<<MyTimeHelper::R(getMin())<<" max="<<MyTimeHelper::R(getMax())<<" avg="<<MyTimeHelper::R(getAvg())<<" N samples="<<samples.size();
        return ss.str();
    }
    std::string getAllSamplesAsString()const{
         std::stringstream ss;
         for(const auto& sample:samples){
            ss<<" "<<MyTimeHelper::R(sample);
         }
         return ss.str();
    }
    // Sort all the samples from low to high
    std::vector<std::chrono::nanoseconds> getSamplesSorted()const{
        auto ret=std::vector<std::chrono::nanoseconds>(samples.begin(),samples.end());
        std::sort(ret.begin(), ret.end());
        return ret;
    }
    std::string getAllSamplesSortedAsString()const{
        const auto valuesSorted=getSamplesSorted();
        return MyTimeHelper::timeSamplesAsString(valuesSorted);
    }
	// Returns up to count lowest and highest samples
	std::string getNValuesLowHigh(int n=10)const{
		auto valuesSorted=getSamplesSorted();
		if(n>(int)valuesSorted.size()/2){
			n=valuesSorted.size()/2;
		}
        const auto xPercentLow=std::vector<std::chrono::nanoseconds>(valuesSorted.begin(),valuesSorted.begin()+n);
        const auto tmpBegin=valuesSorted.begin()+valuesSorted.size()-n;
        const auto xPercentHigh=std::vector<std::chrono::nanoseconds>(tmpBegin,valuesSorted.end());
        std::stringstream ss;
        ss<<n<<" lowest values:\n";
        ss<<MyTimeHelper::timeSamplesAsString(xPercentLow);
        ss<<"\n"<<n<<" highest values:\n";
        ss<<MyTimeHelper::timeSamplesAsString(xPercentHigh);
		ss<<"\n";
        return ss.str();	
	}
	// returns the one percent low / high values
    std::string getOnePercentLowHigh()const{
        auto valuesSorted=getSamplesSorted();
        const auto sizeOnePercent=valuesSorted.size()/100;
        const auto onePercentLow=std::vector<std::chrono::nanoseconds>(valuesSorted.begin(),valuesSorted.begin()+sizeOnePercent);
        const auto tmpBegin=valuesSorted.begin()+valuesSorted.size()-sizeOnePercent;
        const auto onePercentHigh=std::vector<std::chrono::nanoseconds>(tmpBegin,valuesSorted.end());
        std::stringstream ss;
        ss<<"One Percent low:\n";
        ss<<MyTimeHelper::timeSamplesAsString(onePercentLow);
        ss<<"\nOne Percent high:\n";
        ss<<MyTimeHelper::timeSamplesAsString(onePercentHigh);
		ss<<"\n";
        return ss.str();
    }
};


class Chronometer:public AvgCalculator {
public:
    explicit Chronometer(std::string name="Unknown"): AvgCalculator(name),mName(name){}
    void start(){
        startTS=std::chrono::steady_clock::now();
    }
    void stop(){
        const auto now=std::chrono::steady_clock::now();
        const auto delta=(now-startTS);
        AvgCalculator::add(delta);
    }
    void printInIntervalls(const std::chrono::steady_clock::duration& interval,const bool avgOnly=true) {
        const auto now=std::chrono::steady_clock::now();
        if(now-lastLog>interval){
            lastLog=now;
            // avoid garbled output in multi thread
            std::stringstream ss;
            ss<<"Avg "<<(mName)<<" :"<<AvgCalculator::getAvgReadable(avgOnly)<<"\n";
            std::cout<<ss.str();
            reset();
        }
    }
private:
    const std::string mName;
    std::chrono::steady_clock::time_point startTS;
    std::chrono::steady_clock::time_point lastLog=std::chrono::steady_clock::now();
};

class RelativeCalculator{
private:
    long sum=0;
    long sumAtLastCall=0;
public:
    RelativeCalculator() = default;
    void add(unsigned long x){
        sum+=x;
    }
    long getDeltaSinceLastCall() {
        long ret = sum - sumAtLastCall;
        sumAtLastCall = sum;
        return ret;
    }
    long getAbsolute()const{
        return sum;
    }
    void reset(){
        sum=0;
        sumAtLastCall=0;
    }
};

static uint64_t  getTimeUs(){
    const auto time=std::chrono::steady_clock::now().time_since_epoch();
    return std::chrono::duration_cast<std::chrono::microseconds>(time).count();
}

static uint64_t  getTimeMs(){
    return getTimeUs()/1000;
}

// Helper to calculate current bitrate in intervals
class BitrateCalculator{
private:
    uint64_t nBytes;
    //
    bool first_time=true;
    std::chrono::steady_clock::time_point last_caluclation;
public:
    typedef std::function<void(const std::string bitrate)> CUSTOM_PRINT_CB;
    void addBytes(uint64_t bytes,CUSTOM_PRINT_CB cb=nullptr,const std::chrono::steady_clock::duration interval_duration_size=std::chrono::seconds(1)){
        nBytes+=bytes;
        calculate_in_intervals(interval_duration_size,cb);
    }
private:
    void calculate_in_intervals(const std::chrono::steady_clock::duration interval_duration_size=std::chrono::seconds(1),CUSTOM_PRINT_CB cb=nullptr){
        if(first_time){
            first_time=false;
            last_caluclation=std::chrono::steady_clock::now();
            return;
        }
        const auto delta=std::chrono::steady_clock::now()-last_caluclation;
        if(delta>=interval_duration_size){
            const int bits_per_second=(nBytes*8)/(std::chrono::duration_cast<std::chrono::milliseconds>(delta).count()/1000.0);
            //const double bytesPerSecond=nBytes/(std::chrono::duration_cast<std::chrono::milliseconds>(delta).count()/1000.0);
            //const double mBytesPerSecond=bytesPerSecond/1024.0/1024.0;
            //const double mBitsPerSecond=mBytesPerSecond*8.0;
            if(cb==nullptr){
                // avoid garbled output in multi thread
                std::stringstream ss;
                ss<<"Avg Bitrate:"<<StringHelper::bitrate_to_string(bits_per_second);
                qDebug()<<ss.str().c_str();
            }else{
                auto tmp=StringHelper::bitrate_to_string(bits_per_second);
                cb(tmp);
            }
            nBytes=0;
            last_caluclation=std::chrono::steady_clock::now();
        }
    }
    // return: bitrate in bits per second for the given data and time "delta".
    static double calculate_bitrate_bps(uint64_t n_bytes,std::chrono::steady_clock::duration delta){
        return n_bytes*8 /(std::chrono::duration_cast<std::chrono::milliseconds>(delta).count()/1000.0);
    }
};

class FPSCalculator{
private:
    int m_n_frames_since_last=0;
    std::chrono::steady_clock::time_point m_last_n_nalus_recalculation=std::chrono::steady_clock::now();
public:
    float recalculate_fps_and_clear(){
        const auto diff=std::chrono::steady_clock::now()-m_last_n_nalus_recalculation;
        const double runTimeS=std::chrono::duration_cast<std::chrono::milliseconds>(diff).count()/1000.0f;
        const float fps=(float)m_n_frames_since_last==0 ? 0 : m_n_frames_since_last/runTimeS;
        m_n_frames_since_last=0;
        m_last_n_nalus_recalculation=std::chrono::steady_clock::now();
        return fps;
    }
    void on_new_frame(){
        m_n_frames_since_last++;
    }
    std::chrono::steady_clock::duration time_since_last_recalculation(){
        return std::chrono::steady_clock::now()-m_last_n_nalus_recalculation;
    }
};

class PacketsPerSecondCalculator{
private:
    // return current packets per second
    // aka packets since last call / time delta since last call
    uint64_t recalculateSinceLast(uint64_t curr_packets){
        const auto now=std::chrono::steady_clock::now();
        const auto deltaTime=now-last_time;
        const auto deltaPackets=curr_packets-packets_last_time;
        last_time=now;
        packets_last_time=curr_packets;
        const auto delta_time_us=std::chrono::duration_cast<std::chrono::microseconds>(deltaTime).count();
        if(delta_time_us>0 && deltaPackets>0){
            const auto packets_per_second=(deltaPackets*1000*1000 / delta_time_us);
            return packets_per_second;
        }else{
            return 0;
        }
    }
public:
    uint64_t get_last_or_recalculate(uint64_t curr_packets,const std::chrono::steady_clock::duration& time_between_recalculations=std::chrono::seconds(2)){
        if(std::chrono::steady_clock::now()-last_time>=time_between_recalculations){
            curr_packets_per_second= recalculateSinceLast(curr_packets);
        }
        return curr_packets_per_second;
    }
    void reset(){
        packets_last_time=0;
        last_time=std::chrono::steady_clock::now();
        curr_packets_per_second=0;
    }
private:
    uint64_t packets_last_time=0;
    std::chrono::steady_clock::time_point last_time=std::chrono::steady_clock::now();
    //
    uint64_t curr_packets_per_second=0;
};
class BitrateCalculator2{
private:
    // return: current bitrate in bits per second.
    // aka bits received since last call / time delta since last call.
    uint64_t recalculateSinceLast(const uint64_t curr_bytes_received){
        const auto now=std::chrono::steady_clock::now();
        const auto deltaTime=now-last_time;
        const auto deltaBytes=curr_bytes_received-bytes_last_time;
        const auto delta_bits=deltaBytes*8;
        last_time=now;
        bytes_last_time=curr_bytes_received;
        const auto delta_time_us=std::chrono::duration_cast<std::chrono::microseconds>(deltaTime).count();
        if(delta_time_us>0 && delta_bits>0){
            const auto bits_per_second=(delta_bits*1000*1000 / delta_time_us);
            return bits_per_second;
        }else{
            return 0;
        }
    }
public:
    // returns bits per second -
    // calculated in the given interval
    uint64_t get_last_or_recalculate(uint64_t curr_bytes_received,const std::chrono::steady_clock::duration& time_between_recalculations=std::chrono::seconds(2)){
        if(std::chrono::steady_clock::now()-last_time>=time_between_recalculations){
            curr_bits_per_second= recalculateSinceLast(curr_bytes_received);
        }
        return curr_bits_per_second;
    }
    void reset(){
        bytes_last_time=0;
        last_time=std::chrono::steady_clock::now();
        curr_bits_per_second=0;
    }
private:
    uint64_t bytes_last_time=0;
    std::chrono::steady_clock::time_point last_time=std::chrono::steady_clock::now();
    uint64_t curr_bits_per_second=0;
};

#endif //LIVEVIDEO10MS_TIMEHELPER_HPP
