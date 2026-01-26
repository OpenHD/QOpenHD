#include "lowlagdecoder.h"

#include <unistd.h>
#include <sstream>
#include <vector>

#include <android/native_window_jni.h>
#include <media/NdkMediaFormat.h>
#include <utility>
#define MLOGD if(m_printDebugInfo) qDebug()<<"["<<m_logTag.c_str()<<"]"

using namespace std::chrono;

static void h264_configureAMediaFormat(CodecConfigFinder& kff, AMediaFormat* format, bool verboseLogging,
                                       const std::string &logTag){
    const auto sps=kff.getCSD0();
    const auto pps=kff.getCSD1();
    const auto videoWH= sps.sps_get_width_height();
    AMediaFormat_setInt32(format,AMEDIAFORMAT_KEY_WIDTH,videoWH[0]);
    AMediaFormat_setInt32(format,AMEDIAFORMAT_KEY_HEIGHT,videoWH[1]);
    AMediaFormat_setBuffer(format,"csd-0",sps.getData(),(size_t)sps.getSize());
    AMediaFormat_setBuffer(format,"csd-1",pps.getData(),(size_t)pps.getSize());
    if (verboseLogging) {
        qDebug() << "[" << logTag.c_str() << "]" << "Video WH:" << videoWH[0] << " H:" << videoWH[1];
    }
    //AMediaFormat_setInt32(format,AMEDIAFORMAT_KEY_BIT_RATE,5*1024*1024);
    //AMediaFormat_setInt32(format,AMEDIAFORMAT_KEY_FRAME_RATE,60);
    //AVCProfileBaseline==1
    //AMediaFormat_setInt32(decoder.format,AMEDIAFORMAT_KEY_PROFILE,1);
    //AMediaFormat_setInt32(decoder.format,AMEDIAFORMAT_KEY_PRIORITY,0);
    //writeAndroidPerformanceParams(format);
}
static void h265_configureAMediaFormat(CodecConfigFinder& kff, AMediaFormat* format, bool verboseLogging,
                                       const std::string &logTag){
    std::vector<uint8_t> buff={};
    const auto SPS=kff.getCSD0();
    const auto PPS=kff.getCSD1();
    const auto VPS=kff.getVPS();
    buff.reserve(SPS.getSize()+PPS.getSize()+VPS.getSize());
    CodecConfigFinder::appendNaluData(buff,VPS);
    CodecConfigFinder::appendNaluData(buff,SPS);
    CodecConfigFinder::appendNaluData(buff,PPS);
    const auto videoWH= std::array<int,2>{1280,720};
    AMediaFormat_setInt32(format,AMEDIAFORMAT_KEY_WIDTH,videoWH[0]);
    AMediaFormat_setInt32(format,AMEDIAFORMAT_KEY_HEIGHT,videoWH[1]);
    AMediaFormat_setBuffer(format,"csd-0",buff.data(),buff.size());
    if (verboseLogging) {
        qDebug() << "[" << logTag.c_str() << "]" << "Video WH:" << videoWH[0] << " H:" << videoWH[1];
    }
    //writeAndroidPerformanceParams(format);
}

LowLagDecoder::LowLagDecoder(JNIEnv* env, bool verboseLogging, std::string logTag)
    : m_printDebugInfo(verboseLogging), m_logTag(std::move(logTag)){
    //env->GetJavaVM(&javaVm);
    resetStatistics();
}

void LowLagDecoder::releaseDecoderResources(bool releaseWindow)
{
    std::lock_guard<std::mutex> lock(mMutexInputPipe);
    releaseDecoderResourcesLocked(releaseWindow);
}

void LowLagDecoder::releaseDecoderResourcesLocked(bool releaseWindow)
{
    inputPipeClosed=true;
    if(decoder.configured){
        if (decoder.codec) {
            AMediaCodec_stop(decoder.codec);
            AMediaCodec_delete(decoder.codec);
            decoder.codec=nullptr;
        }
        mKeyFrameFinder.reset();
        decoder.configured=false;
        if(mCheckOutputThread && mCheckOutputThread->joinable()){
            mCheckOutputThread->join();
        }
        mCheckOutputThread.reset();
    }
    if (releaseWindow && decoder.window) {
        ANativeWindow_release(decoder.window);
        decoder.window=nullptr;
    }
    resetStatistics();
    if (!releaseWindow && decoder.window) {
        inputPipeClosed=false;
    }
}

void LowLagDecoder::setOutputSurface(JNIEnv* env,jobject surface){
    USE_SW_DECODER_INSTEAD=false;

    std::lock_guard<std::mutex> lock(mMutexInputPipe);

    if(surface==nullptr){
        if(decoder.window== nullptr){
            return;
        }
        releaseDecoderResourcesLocked(true);
        return;
    }

    if(decoder.window!=nullptr){
        releaseDecoderResourcesLocked(true);
    }

    decoder.window=ANativeWindow_fromSurface(env,surface);
    // open the input pipe - now the decoder will start as soon as enough data is available
    inputPipeClosed=false;
}

void LowLagDecoder::registerOnDecoderRatioChangedCallback(DECODER_RATIO_CHANGED decoderRatioChangedC) {
    onDecoderRatioChangedCallback=std::move(decoderRatioChangedC);
}

void LowLagDecoder::registerOnDecodingInfoChangedCallback(DECODING_INFO_CHANGED_CALLBACK decodingInfoChangedCallback){
    onDecodingInfoChangedCallback=std::move(decodingInfoChangedCallback);
}

void LowLagDecoder::interpretNALU(const NALU& nalu){
    //return;
    // TODO: RN switching between h264 / h265 requires re-setting the surface
    std::lock_guard<std::mutex> lock(mMutexInputPipe);
    if(decoder.configured && nalu.IS_H265_PACKET!=IS_H265){
        MLOGD << "Codec change detected while decoder is configured; restarting decoder";
        releaseDecoderResourcesLocked(false);
    }
    IS_H265=nalu.IS_H265_PACKET;
    //MLOGD<<"Is H265 "<<nalu.IS_H265_PACKET;
    //MLOGD<<"NALU size "<<StringHelper::memorySizeReadable(nalu.getSize());
    //MLOGD<<"NALU type "<<nalu.get_nal_name();
    //nalu.debug();
    //MLOGD<<"DATA:"<<nalu.dataAsString();
    //return;
    decodingInfo.nNALU++;
    if(nalu.getSize()<=4){
        //No data in NALU (e.g at the beginning of a stream)
        return;
    }
    //if(nalu.get_nal_unit_type()==NAL_UNIT_TYPE_AUD){
    //    return;
    //}
    nNALUBytesFed.add(nalu.getSize());
    if(inputPipeClosed){
        //A feedD thread (e.g. file or udp) thread might be running even tough no output surface was set
        //But at least we can buffer the sps/pps data
        mKeyFrameFinder.save_if_config(nalu);
        return;
    }
    if(decoder.configured){
        feedDecoder(nalu);
        decodingInfo.nNALUSFeeded++;
        // manually feeding AUDs doesn't seem to change anything for high latency streams
        // Only for the x264 sw encoded example stream it might improve latency slightly
        //if(!nalu.IS_H265_PACKET && nalu.get_nal_unit_type()==NAL_UNIT_TYPE_CODED_SLICE_NON_IDR){
            //MLOGD<<"Feeding special AUD";
            //feedDecoder(NALU::createExampleH264_AUD());
        //}
    }else{
        //Store sps,pps, vps(H265 only)
        // As soon as enough data has been buffered to initialize the decoder,do so.
        mKeyFrameFinder.save_if_config(nalu);
        if(mKeyFrameFinder.all_config_available(IS_H265)){
            configureStartDecoder();
        }
    }
}

void LowLagDecoder::configureStartDecoder(){
    const std::string MIME=IS_H265 ? "video/hevc" : "video/avc";
    
     if(USE_SW_DECODER_INSTEAD){
        if(IS_H265){
            // Not sure if google.hevc.decoder is even SW ?!
            decoder.codec = AMediaCodec_createCodecByName("OMX.google.hevc.decoder");
        }else{
            decoder.codec = AMediaCodec_createCodecByName("OMX.google.h264.decoder");
        }
    }else {
        decoder.codec = AMediaCodec_createDecoderByType(MIME.c_str());
        //decoder.codec = AMediaCodec_createDecoderByType("video/mjpeg");
        //const std::string s=(decoder.codec== nullptr ? "No" : "YES");
        //MDebug::log("Created decoder"+s);
        //char* name;
        //AMediaCodec_getName(decoder.codec,&name);
        //MLOGD<<"Created decoder "<<std::string(name);
        //AMediaCodec_releaseName(decoder.codec,name);
    }
    if (decoder.codec== nullptr) {
        MLOGD<<"Cannot create decoder";
        //set csd-0 and csd-1 back to 0, maybe they were just faulty but we have better luck with the next ones
        mKeyFrameFinder.reset();
        return;
    }


    
    AMediaFormat* format=AMediaFormat_new();
    AMediaFormat_setString(format,AMEDIAFORMAT_KEY_MIME,MIME.c_str());
    
    if(IS_H265){
        h265_configureAMediaFormat(mKeyFrameFinder, format, m_printDebugInfo, m_logTag);
    }else{
        h264_configureAMediaFormat(mKeyFrameFinder, format, m_printDebugInfo, m_logTag);
    }

    // ===== LOW-LATENCY OPTIMIZATIONS START =====
    
    // 1. Enable low-latency mode (Qualcomm)
    AMediaFormat_setInt32(format, "vendor.qti-ext-dec-low-latency.enable", 1);
    
    // 2. Set highest priority (Qualcomm)
    AMediaFormat_setInt32(format, "vendor.qti-ext-dec-priority.value", 0);
    
    // 3. Generic low-latency hint
    AMediaFormat_setInt32(format, "low-latency", 1);
    
    // 4. Request maximum performance
    AMediaFormat_setFloat(format, "operating-rate", INT32_MAX);
    // 6. Disable frame dropping - we want all frames for real-time
    AMediaFormat_setInt32(format, "allow-frame-drop", 0);
    
    // 7. Priority hint
    AMediaFormat_setInt32(format, "priority", 0);
    
    // ===== LOW-LATENCY OPTIMIZATIONS END =====

    MLOGD << "Configuring decoder:" << AMediaFormat_toString(format);

    AMediaCodec_configure(decoder.codec, format, decoder.window, nullptr, 0);
    AMediaFormat_delete(format);
    format=AMediaCodec_getOutputFormat(decoder.codec);
    //MLOGD<<"Output format"<<AMediaFormat_toString(format);
    AMediaFormat_delete(format);

    if (decoder.codec== nullptr) {
        MLOGD<<"Cannot configure decoder";
        //set csd-0 and csd-1 back to 0, maybe they were just faulty but we have better luck with the next ones
        mKeyFrameFinder.reset();
        return;
    }
    AMediaCodec_start(decoder.codec);
    mCheckOutputThread=std::make_unique<std::thread>(&LowLagDecoder::checkOutputLoop,this);
    //NDKThreadHelper::setName(mCheckOutputThread->native_handle(),"LLDCheckOutput");
    decoder.configured=true;
}


void LowLagDecoder::feedDecoder(const NALU& nalu){
    if(IS_H265 && (nalu.isSPS() || nalu.isPPS() || nalu.isVPS())){
        return;
    }
    
    const auto now=std::chrono::steady_clock::now();
    const auto deltaParsing=now-nalu.creationTime;
    
    // Try immediate dequeue first
    ssize_t index = AMediaCodec_dequeueInputBuffer(decoder.codec, 0);
    
    if (index < 0) {
        // If no buffer immediately available, try with small timeout
        index = AMediaCodec_dequeueInputBuffer(decoder.codec, 5000); // 5ms
    }
    
    if (index >= 0) {
        size_t inputBufferSize;
        void* buf = AMediaCodec_getInputBuffer(decoder.codec, (size_t)index, &inputBufferSize);
        
        if(nalu.getSize() > inputBufferSize){
            MLOGD << "NALU too big: " << nalu.getSize();
            return;
        }
        
        std::memcpy(buf, nalu.getData(), (size_t)nalu.getSize());
        const uint64_t presentationTimeUS = (uint64_t)duration_cast<microseconds>(
            steady_clock::now().time_since_epoch()).count();
        
        AMediaCodec_queueInputBuffer(decoder.codec, (size_t)index, 0, 
                                     (size_t)nalu.getSize(), presentationTimeUS, 0);
        
        waitForInputB.add(steady_clock::now() - now);
        parsingTime.add(deltaParsing);
        return;
    }
    
    // Buffer unavailable - in real-time streaming, dropping is better than blocking
    if(index == AMEDIACODEC_INFO_TRY_AGAIN_LATER){
        MLOGD << "Input buffer unavailable, dropping NALU";
        // You could implement smart dropping here - only drop non-keyframes
        return;
    }
    
    MLOGD << "dequeueInputBuffer error: " << (int)index;
}

void LowLagDecoder::checkOutputLoop() {
    //NDKThreadHelper::setProcessThreadPriorityAttachDetach(javaVm,FPV_VR_PRIORITY::CPU_PRIORITY_DECODER_OUTPUT,"DecoderCheckOutput");
    AMediaCodecBufferInfo info;
    bool decoderSawEOS=false;
    bool decoderProducedUnknown=false;
    
    // Set high priority for output thread
    //#include <sys/resource.h>
    //setpriority(PRIO_PROCESS, 0, -19); // Highest priority (-20 to 19, lower = higher priority)
    
    while(!decoderSawEOS && !decoderProducedUnknown) {
        // Use shorter timeout for more responsive polling
        const ssize_t index = AMediaCodec_dequeueOutputBuffer(decoder.codec, &info, 10000); // 10ms
        
        if (index >= 0) {
            const auto now = steady_clock::now();
            const int64_t nowUS = (int64_t)duration_cast<microseconds>(now.time_since_epoch()).count();
            
            const bool renderFrame = info.size > 0 && decoder.window != nullptr;
            
            if (renderFrame) {
                // Alternative: Use immediate rendering with current time in nanoseconds
                const int64_t renderTimeNs = duration_cast<nanoseconds>(
                    steady_clock::now().time_since_epoch()).count();
                AMediaCodec_releaseOutputBufferAtTime(decoder.codec, (size_t)index, renderTimeNs);
            } else {
                AMediaCodec_releaseOutputBuffer(decoder.codec, (size_t)index, false);
            }
            
            decodingTime.add(std::chrono::microseconds(nowUS - info.presentationTimeUs));
            nDecodedFrames.add(1);
            
            if (info.flags & AMEDIACODEC_BUFFER_FLAG_END_OF_STREAM) {
                MLOGD << "Decoder saw EOS";
                decoderSawEOS = true;
                continue;
            }
        } else if (index == AMEDIACODEC_INFO_OUTPUT_FORMAT_CHANGED) {
            // ... existing format change handling ...
            auto format = AMediaCodec_getOutputFormat(decoder.codec);
            int width=0, height=0;
            AMediaFormat_getInt32(format, AMEDIAFORMAT_KEY_WIDTH, &width);
            AMediaFormat_getInt32(format, AMEDIAFORMAT_KEY_HEIGHT, &height);
            MLOGD << "Output format: " << width << "x" << height;
            
            if(onDecoderRatioChangedCallback != nullptr && width != 0 && height != 0){
                onDecoderRatioChangedCallback({width, height});
            }
            AMediaFormat_delete(format);
        } else if(index == AMEDIACODEC_INFO_OUTPUT_BUFFERS_CHANGED){
            // This is deprecated in newer Android versions
            MLOGD << "OUTPUT_BUFFERS_CHANGED";
        } else if(index == AMEDIACODEC_INFO_TRY_AGAIN_LATER) {
            // Normal timeout - continue
        } else {
            MLOGD << "dequeueOutputBuffer error: " << (int)index;
            decoderProducedUnknown = true;
            continue;
        }
        
        // ... existing stats calculation code ...
        const auto now=steady_clock::now();
        const auto delta=now-decodingInfo.lastCalculation;
        if(delta>DECODING_INFO_RECALCULATION_INTERVAL){
            decodingInfo.lastCalculation=steady_clock::now();
            decodingInfo.currentFPS=(float)nDecodedFrames.getDeltaSinceLastCall()/(float)duration_cast<seconds>(delta).count();
            decodingInfo.currentKiloBitsPerSecond=((float)nNALUBytesFed.getDeltaSinceLastCall()/duration_cast<seconds>(delta).count())/1024.0f*8.0f;
            decodingInfo.avgDecodingTime_ms=decodingTime.getAvg_ms();
            decodingInfo.avgParsingTime_ms=parsingTime.getAvg_ms();
            decodingInfo.avgWaitForInputBTime_ms=waitForInputB.getAvg_ms();
            decodingInfo.nDecodedFrames=nDecodedFrames.getAbsolute();
            printAvgLog();
            if(onDecodingInfoChangedCallback != nullptr){
                onDecodingInfoChangedCallback(decodingInfo);
            }
        }
    }
    MLOGD << "Exit CheckOutputLoop";
}

void LowLagDecoder::printAvgLog() {
    if(!m_printDebugInfo){
        return;
    }
    auto now=steady_clock::now();
    if((now-lastLog)>TIME_BETWEEN_LOGS){
        lastLog=now;
        std::ostringstream frameLog;
        frameLog<<std::fixed;
        float avgDecodingLatencySum=decodingInfo.avgParsingTime_ms+decodingInfo.avgWaitForInputBTime_ms+
                                    decodingInfo.avgDecodingTime_ms;
        frameLog<<"......................Decoding Latency Averages......................"<<
                "\nParsing:"<<decodingInfo.avgParsingTime_ms
                <<" | WaitInputBuffer:"<<decodingInfo.avgWaitForInputBTime_ms
                <<" | Decoding:"<<decodingInfo.avgDecodingTime_ms
                <<" | Decoding Latency Sum:"<<avgDecodingLatencySum<<
                "\nN NALUS:"<<decodingInfo.nNALU
                <<" | N NALUES feeded:" <<decodingInfo.nNALUSFeeded<<" | N Decoded Frames:"<<nDecodedFrames.getAbsolute()<<
                "\nFPS:"<<decodingInfo.currentFPS;
        MLOGD<<frameLog.str().c_str();
    }
}

void LowLagDecoder::resetStatistics() {
    nDecodedFrames.reset();
    nNALUBytesFed.reset();
    parsingTime.reset();
    waitForInputB.reset();
    decodingTime.reset();
    decodingInfo={};
}
