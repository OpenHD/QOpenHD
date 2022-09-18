//
// Created by geier on 18/01/2020.
//

#ifndef LIVEVIDEO10MS_TIMEHELPER_HPP
#define LIVEVIDEO10MS_TIMEHELPER_HPP

#include <sys/time.h>
#include <chrono>
#include <deque>
#include <algorithm>
#include <sstream>
#include <iostream>
#include "StringHelper.hpp"

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
            return std::to_string(ms/1000.0f)+"s";
        }
        if(durAbsolute>=std::chrono::milliseconds(1)){
            // More than one millisecond, print as decimal with us resolution
            const auto us=std::chrono::duration_cast<std::chrono::microseconds>(dur).count();
            return std::to_string(us/1000.0f)+"ms";
        }
        if(durAbsolute>=std::chrono::microseconds(1)){
            // More than one microsecond, print as decimal with ns resolution
            const auto ns=std::chrono::duration_cast<std::chrono::nanoseconds>(dur).count();
            return std::to_string(ns/1000.0f)+"us";
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
    std::chrono::nanoseconds min=std::chrono::nanoseconds::max();
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
        min=std::chrono::nanoseconds::max();
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

static __attribute__((unused)) std::chrono::nanoseconds timevalToDuration(timeval tv){
    auto duration = std::chrono::seconds{tv.tv_sec}
                    + std::chrono::microseconds{tv.tv_usec};
    return std::chrono::duration_cast<std::chrono::nanoseconds>(duration);
}
static __attribute__((unused)) std::chrono::time_point<std::chrono::system_clock, std::chrono::nanoseconds>
timevalToTimePointSystemClock(timeval tv){
    return std::chrono::time_point<std::chrono::system_clock,std::chrono::nanoseconds>{
            std::chrono::duration_cast<std::chrono::system_clock::duration>(timevalToDuration(tv))};
}
static __attribute__((unused)) std::chrono::time_point<std::chrono::steady_clock,std::chrono::nanoseconds>
timevalToTimePointSteadyClock(timeval tv){
    return std::chrono::time_point<std::chrono::steady_clock,std::chrono::nanoseconds>{
            std::chrono::duration_cast<std::chrono::steady_clock::duration>(timevalToDuration(tv))};
}

static __attribute__((unused)) std::chrono::time_point<std::chrono::steady_clock,std::chrono::nanoseconds>
nanosecondsToTimePointSteadyClock(std::chrono::nanoseconds nanoseconds){
    return std::chrono::time_point<std::chrono::steady_clock,std::chrono::nanoseconds>{
            std::chrono::duration_cast<std::chrono::steady_clock::duration>(nanoseconds)};
}


static uint64_t __attribute__((unused)) getTimeUs(){
    struct timeval time;
    gettimeofday(&time, NULL);
    uint64_t micros = (time.tv_sec * ((uint64_t)1000*1000)) + ((uint64_t)time.tv_usec);
    return micros;
}

static uint64_t __attribute__((unused)) getTimeMs(){
    return getTimeUs()/1000;
}

class BitrateCalculator{
private:
    uint64_t nBytes;
    std::chrono::steady_clock::time_point begin;
    bool firstTime=true;
public:
    void addBytes(uint64_t bytes){
        nBytes+=bytes;
        if(firstTime){
            begin=std::chrono::steady_clock::now();
            firstTime=false;
        }
        const auto delta=std::chrono::steady_clock::now()-begin;
        if(delta>=std::chrono::seconds(1)){
            const double bytesPerSecond=nBytes/(std::chrono::duration_cast<std::chrono::milliseconds>(delta).count()/1000.0);
            const double mBytesPerSecond=bytesPerSecond/1024.0/1024.0;
            const double mBitsPerSecond=mBytesPerSecond*8.0;
            // avoid garbled output in multi thread
            std::stringstream ss;
            ss<<"Avg Bitrate:"<<mBitsPerSecond<<" MBit/s\n";
            std::cout<<ss.str();
            nBytes=0;
            begin=std::chrono::steady_clock::now();
        }
    }
};

static void busySleep(const long microseconds){
    const auto start=getTimeUs();
    while ((getTimeUs()-start)<microseconds){
        // busy wait
    }
}

#endif //LIVEVIDEO10MS_TIMEHELPER_HPP